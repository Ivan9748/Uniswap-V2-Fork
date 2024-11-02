pragma solidity >=0.5.0;

interface IUniswapV2Reward {
    function factory() external view returns(address);
    function WETH() external view returns(address);
    function owner() external view returns(address);
    function myToken() external view returns(address);
    function threshold() external view returns(uint);
    function feeBalances(address _address) external view returns(uint);
    function reserve() external view returns(uint);

    function check(address _token, uint _amount) external returns(bool result);
    function buyBack(address _token, uint _amount) external;
    function callDistribute(address pair) external;
    function setThreshold(uint _threshold) external;
}
