pragma solidity 0.6.6;

interface IAllocationStrategy {
    function balanceOfUnderlying() external returns (uint256);
    function balanceOfUnderlyingView() external view returns(uint256);
    function investUnderlying(uint256 _investAmount) external returns (uint256);
    function redeemUnderlying(uint256 _redeemAmount, address _receiver) external returns (uint256);
    function redeemAll() external;
}
