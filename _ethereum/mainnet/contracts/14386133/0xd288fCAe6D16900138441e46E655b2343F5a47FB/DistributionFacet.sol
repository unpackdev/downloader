// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./IERC721.sol";

import "./LibAppStorage.sol";
import "./IPilgrimTreasury.sol";

contract DistributionFacet {
    AppStorage internal s;

    /// @notice The Claim Pair Reward Event.
    ///
    /// @param  _metaNftId  The Meta NFT ID.
    /// @param  _amount     The amount earned.
    ///
    event ClaimPairReward(uint256 _metaNftId, uint128 _amount);

    /// @notice The Claim User Reward Event.
    ///
    /// @param  _userAddress    The user address.
    /// @param  _amount         The amount earned.
    ///
    event ClaimUserReward(address _userAddress, uint128 _amount);

    function getRewardEpoch() external view returns (uint256 _rewardEpoch) {
        _rewardEpoch = s.rewardEpoch;
    }

    function getDistPoolInfo(address _baseToken) external view returns (uint256 _rewardParameter, uint256 _gasReward) {
        DistPoolInfo storage distPoolInfo = s.distPools[_baseToken];
        _rewardParameter = distPoolInfo.rewardParameter;
        _gasReward = distPoolInfo.gasReward;
    }

    function getPairReward(uint256 _metaNftId) public view returns (uint128 _amount) {
        _amount = s.pairRewards[_metaNftId];
    }

    function getUserReward(address _userAddress) public view returns (uint128 _amount) {
        _amount = s.userRewards[_userAddress];
    }

    function claimPairReward(uint256 _metaNftId) external {
        uint128 amount = getPairReward(_metaNftId);
        require(amount > 0, "Pilgrim: No Reward");
        s.pairRewards[_metaNftId] = 0;
        address metaNftOwner = IERC721(s.metaNFT).ownerOf(_metaNftId);
        IPilgrimTreasury(s.treasury).withdraw(metaNftOwner, amount);
        emit ClaimPairReward(_metaNftId, amount);
    }

    function claimUserReward() external {
        uint128 amount = getUserReward(msg.sender);
        require(amount > 0, "Pilgrim: No Reward");
        s.userRewards[msg.sender] = 0;
        IPilgrimTreasury(s.treasury).withdraw(msg.sender, amount);
        emit ClaimUserReward(msg.sender, amount);
    }
}
