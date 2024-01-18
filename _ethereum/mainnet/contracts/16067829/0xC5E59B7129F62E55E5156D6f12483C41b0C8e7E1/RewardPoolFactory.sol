// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
import "./ICurve.sol";
import "./Collectionswap.sol";
import "./RewardPool.sol";

contract RewardPoolFactory {

    Collectionswap public collectionswap;

    constructor(address payable _collectionSwapAddress) {
        collectionswap = Collectionswap(_collectionSwapAddress);
    }

    event NewRewardPool(
        address indexed rewardPoolAddress, 
        address indexed nftAddress, 
        address indexed moneyAddress
        );

    function createRewardPool(
        address _nftAddress,
        address _moneyAddress,
        address _bondingCurveAddress,
        uint96 _fee,
        uint128 _delta,
        uint128 _initialSpotPrice
    ) public returns (address rewardPoolAddress) {
        // TBD
        RewardPool rewardPool = new RewardPool(
            _nftAddress, 
            _moneyAddress, 
            _bondingCurveAddress,
            payable(collectionswap), 
            _fee, 
            _delta, 
            _initialSpotPrice
            );

        rewardPool.transferOwnership(msg.sender);
        address rewardPoolAddress = address(rewardPool);
        emit NewRewardPool(rewardPoolAddress, _nftAddress, _moneyAddress);
        return rewardPoolAddress;
    }
}