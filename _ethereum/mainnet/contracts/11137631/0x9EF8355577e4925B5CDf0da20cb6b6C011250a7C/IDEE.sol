pragma solidity =0.6.6;

interface IDEE {
    function addPendingETHRewards() external payable;
    function calculateAmountsAfterFee(address _sender, uint _amount) external view returns(uint256, uint256);
}