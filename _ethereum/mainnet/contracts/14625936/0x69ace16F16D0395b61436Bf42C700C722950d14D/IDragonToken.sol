pragma solidity ^0.8.9;

interface IDragonToken {

    function updateReward(address _from, address _to, uint256 _tokenId) external;

    function getClaimableReward(address _account) external view returns(uint256);

    function claimReward() external;
}
