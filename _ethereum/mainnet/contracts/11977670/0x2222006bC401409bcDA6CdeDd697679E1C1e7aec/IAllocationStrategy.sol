pragma solidity 0.6.6;

interface IAllocationStrategy {
    function balanceOfUnderlying() external returns (uint256);
    function balanceOfUnderlyingView() external view returns(uint256);
    function investETH(uint256 _amountOutMin, uint256 _deadline) external payable returns (uint256);
    function investUnderlying(uint256 _investAmount, uint256 _deadline) external returns (uint256);
    function invest(address _tokenIn, uint256 _investAmount, uint256 _amountOutMin, uint256 _deadline) external returns (uint256);
    function redeemUnderlying(uint256 _redeemAmount) external returns (uint256);
    function redeemAll() external;
}
