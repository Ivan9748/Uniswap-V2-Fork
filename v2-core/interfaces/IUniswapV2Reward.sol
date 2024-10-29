pragma solidity >=0.5.0;

interface IUniswapV2Reward {
    function factory() external view returns(address);

    function check(address _token, uint _amount) external returns(bool result);
    function buyBack(address _token, uint _amount) external;
    function callDistribute(address pair) external;
    function setThreshold(uint _threshold) external;
}
