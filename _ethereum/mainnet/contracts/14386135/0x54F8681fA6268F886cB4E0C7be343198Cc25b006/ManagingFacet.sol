// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./IERC721.sol";

import "./LibAppStorage.sol";
import "./LibDistribution.sol";
import "./LibGetters.sol";
import "./LibDiamond.sol";

contract ManagingFacet {
    AppStorage internal s;

    function setTreasury(address _treasury) external {
        LibDiamond.enforceIsContractOwner();
        s.treasury = _treasury;
    }

    // ---------------- Distribution ----------------
    function halveRewards() external {
        LibDiamond.enforceIsContractOwner();
        for (uint256 i; i < s.baseTokens.length; i++) {
            DistPoolInfo storage distPoolInfo = s.distPools[s.baseTokens[i]];
            distPoolInfo.rewardParameter <<= 1;
        }
    }

    function setRewardParameter(address _baseToken, uint128 _rewardParameter) external {
        LibDiamond.enforceIsContractOwner();
        require(_rewardParameter > 0, "Pilgrim: Invalid rewardParamter");
        DistPoolInfo storage distPoolInfo = s.distPools[_baseToken];
        require(distPoolInfo.rewardParameter > 0, "Pilgrim: baseToken Not Found");
        distPoolInfo.rewardParameter = _rewardParameter;
    }

    function setGasReward(address _baseToken, uint128 _gasReward) external {
        LibDiamond.enforceIsContractOwner();
        DistPoolInfo storage distPoolInfo = s.distPools[_baseToken];
        require(distPoolInfo.rewardParameter > 0, "Pilgrim: baseToken Not Found");
        distPoolInfo.gasReward = _gasReward;
    }

    function setRewardEpoch(uint32 _rewardEpoch) external {
        LibDiamond.enforceIsContractOwner();
        s.rewardEpoch = _rewardEpoch;
    }

    function createPool(address _baseToken, uint128 _rewardParameter, uint128 _gasReward) external {
        LibDiamond.enforceIsContractOwner();
        require(_rewardParameter > 0, "Pilgrim: Invalid rewardParamter");
        DistPoolInfo storage distPoolInfo = s.distPools[_baseToken];
        require(distPoolInfo.rewardParameter == 0, "Pilgrim: Duplicated baseToken");
        distPoolInfo.rewardParameter = _rewardParameter;
        distPoolInfo.gasReward = _gasReward;
        s.baseTokens.push(_baseToken);
    }

    function setUniV3ExtraRewardParam(address _tokenA, address _tokenB, uint32 _value) external {
        LibDiamond.enforceIsContractOwner();
        LibDistribution._setUniExtraRewardParam(_tokenA, _tokenB, _value);
    }

    // ---------------- NFT/MetaNFT trading ----------------
    function setBidTimeout(uint32 _bidTimeout) external {
        LibDiamond.enforceIsContractOwner();
        require(_bidTimeout > 0, "Pilgrim: Invalid bidTimeout");
        s.bidTimeout = _bidTimeout;
    }

    // ---------------- Trading fee ----------------
    function setBaseFee(uint32 _baseFeeNumerator) external {
        LibDiamond.enforceIsContractOwner();
        s.baseFeeNumerator = _baseFeeNumerator;
    }

    function setRoundFee(uint32 _roundFeeNumerator) external {
        LibDiamond.enforceIsContractOwner();
        s.roundFeeNumerator = _roundFeeNumerator;
    }

    function setNftFee(uint32 _nftFeeNumerator) external {
        LibDiamond.enforceIsContractOwner();
        s.nftFeeNumerator = _nftFeeNumerator;
    }
}
