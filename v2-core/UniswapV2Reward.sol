pragma solidity =0.5.16;

import './UniswapV2Pair.sol';
import './interfaces/IUniswapV2Reward.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2ERC20.sol';
import './interfaces/IERC20.sol';

import './libraries/SafeMath.sol';
import './libraries/UniswapV2Library.sol';

contract UniswapV2Reward is IUniswapV2Reward{
    using SafeMath for uint;

    address public factory;
    address public WETH;
    address public owner;
    address public myToken;
    uint public threshold;

    mapping(address => uint) public feeBalances;
    uint public reserve;

    constructor(address _factory, address _WETH, address _owner, address _myToken, uint _threshold) public {
        factory = _factory;
        WETH = _WETH;
        owner = _owner;
        myToken = _myToken;
        threshold = _threshold;
    }

    function check(address _token, uint _amount) external returns(bool result){
        require(UniswapV2Pair(msg.sender).factory() == factory, "Not allowed");

        if(_token != myToken){
            if(IUniswapV2Factory(factory).getPair(_token, myToken) == address(0)){
                if(IUniswapV2Factory(factory).getPair(_token, WETH) == address(0)) {
                    return false;
                }else{
                    if(IUniswapV2Factory(factory).getPair(myToken, WETH) == address(0)) {
                        return false;
                    }else{
                        uint amountWETHOut;
                        {
                            (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(factory, _token, WETH);
                            amountWETHOut = _amount.mul(reserveOut) / reserveIn.add(_amount);
                            (address token0, ) = UniswapV2Library.sortTokens(_token, WETH);
                            (uint amount0Out, uint amount1Out) = _token == token0 ? (uint(0), amountWETHOut) : (amountWETHOut, uint(0));
                            if(amount0Out > reserveIn && amount1Out > reserveOut) return false;
                        }

                        (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(factory, myToken, WETH);
                        uint amountOut = amountWETHOut.mul(reserveOut) / reserveIn.add(amountWETHOut);
                        (address token0, ) = UniswapV2Library.sortTokens(myToken, WETH);
                        (uint amount0Out, uint amount1Out) = WETH == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
                        if(amount0Out > reserveIn && amount1Out > reserveOut) return false;
                    }
                }
            } else{
                (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(factory, _token, myToken);
                uint amountOut = _amount.mul(reserveOut) / reserveIn.add(_amount);
                (address token0, ) = UniswapV2Library.sortTokens(_token, myToken);
                (uint amount0Out, uint amount1Out) = _token == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
                if(amount0Out > reserveIn && amount1Out > reserveOut) return false;
            }
        }

        result = true;
    }

    function buyBack(address _token, uint _amount) external {
        require(UniswapV2Pair(msg.sender).factory() == factory, "Not allowed");
        //require(IUniswapV2Pair(msg.sender).factory() == factory, "Not allowed");

        if (_token == myToken){
            feeBalances[msg.sender] = feeBalances[msg.sender].add(_amount);
            reserve = reserve.add(_amount);
        } else{
            address pair = IUniswapV2Factory(factory).getPair(_token, myToken);

            if (pair == address(0)){
                pair = IUniswapV2Factory(factory).getPair(_token, WETH);

                uint balance0 = IERC20(WETH).balanceOf(address(this));

                (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(factory, _token, WETH);
                uint amountOut = _amount.mul(reserveOut) / reserveIn.add(_amount);
                (address token0, ) = UniswapV2Library.sortTokens(_token, WETH);
                (uint amount0Out, uint amount1Out) = _token == token0 ? (uint(0), amountOut) : (amountOut, uint(0));

                IERC20(_token).transfer(pair, _amount);
                IUniswapV2Pair(pair).swapWithoutFee(
                    amount0Out, amount1Out, address(this)
                );

                uint balance1 = IERC20(WETH).balanceOf(address(this));

                _token = WETH;
                _amount = balance1 - balance0;
                pair = IUniswapV2Factory(factory).getPair(myToken, WETH);
            }

            uint balance0 = IERC20(myToken).balanceOf(address(this));

            (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(factory, _token, myToken);
            uint amountOut = UniswapV2Library.getAmountOut(_amount, reserveIn, reserveOut);
            (address token0, ) = UniswapV2Library.sortTokens(_token, myToken);
            (uint amount0Out, uint amount1Out) = _token == token0 ? (uint(0), amountOut) : (amountOut, uint(0));

            IERC20(_token).transfer(pair, _amount);
            IUniswapV2Pair(pair).swapWithoutFee(
                amount0Out, amount1Out, address(this)
            );

            uint balance1 = IERC20(myToken).balanceOf(address(this));
            
            feeBalances[msg.sender] = feeBalances[msg.sender].add(balance1.sub(balance0));
            reserve = reserve.add(balance1.sub(balance0));
        }

        if (feeBalances[msg.sender] >= threshold){
            distribute(msg.sender);
        }
    }

    function distribute(address _pair) private {
        address[] memory holders = IUniswapV2ERC20(_pair).getAddresses();

        for(uint i; i < holders.length; i++){
            // amount = balance/supply * fee
            uint amount = IUniswapV2Pair(_pair).balanceOf(holders[i]) / IUniswapV2Pair(_pair).totalSupply();
            IERC20(myToken).transfer(holders[i], amount);
        }
        reserve = reserve.sub(feeBalances[_pair]);
        feeBalances[_pair] = 0;
    }

    function callDistribute(address pair) public {
        require(msg.sender == owner, "Not the owner!");
        distribute(pair);
    }

    function setThreshold(uint _threshold) public {
        require(msg.sender == owner, "Not the owner!");
        threshold = _threshold;
    }
}
