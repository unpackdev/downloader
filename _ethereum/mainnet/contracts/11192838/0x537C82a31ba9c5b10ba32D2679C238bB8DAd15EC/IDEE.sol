pragma solidity >=0.6.2;

interface IDEE {
    function addPendingETHRewards() external payable;
    function addPendingTokenRewards(uint256 _transferFee, address _token) external;
    function calculateAmountsAfterFee(address _sender, uint _amount) external view returns(uint256, uint256);
}