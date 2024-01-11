// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import "./OwnableUpgradeable.sol";
import "./TransferHelpers.sol";
import "./IWETH.sol";
import "./Initializable.sol";
import "./UnifarmRewardRegistryUpgradeableStorage.sol";
import "./IUnifarmRewardRegistryUpgradeable.sol";

/// @title UnifarmRewardRegistryUpgradeable Contract
/// @author UNIFARM
/// @notice contract handles rewards mechanism of unifarm cohorts

contract UnifarmRewardRegistryUpgradeable is
    IUnifarmRewardRegistryUpgradeable,
    UnifarmRewardRegistryUpgradeableStorage,
    Initializable,
    OwnableUpgradeable
{
    /**
     * @dev not throws if called by owner or multicall
     */

    modifier onlyMulticallOrOwner() {
        onlyOwnerOrMulticall();
        _;
    }

    /**
     * @dev verifying valid caller
     */

    function onlyOwnerOrMulticall() internal view {
        require(_msgSender() == multiCall || _msgSender() == owner(), 'IS');
    }

    /**
     * @notice initialize the reward registry
     * @param masterAddress master wallet address
     * @param trustedForwarder trusted forwarder address
     * @param multiCall_ multicall contract address
     * @param referralPercentage referral percentage in 3 precised decimals
     */

    function __UnifarmRewardRegistryUpgradeable_init(
        address masterAddress,
        address trustedForwarder,
        address multiCall_,
        uint256 referralPercentage
    ) external initializer {
        __UnifarmRewardRegistryUpgradeable_init_unchained(multiCall_, referralPercentage);
        __Ownable_init(masterAddress, trustedForwarder);
    }

    /**
     * @dev set default referral and multicall
     * @param multiCall_ multicall contract address
     * @param referralPercentage referral percentage in 3 precised decimals
     */

    function __UnifarmRewardRegistryUpgradeable_init_unchained(address multiCall_, uint256 referralPercentage) internal {
        multiCall = multiCall_;
        refPercentage = referralPercentage;
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function updateRefPercentage(uint256 newRefPercentage) external override onlyMulticallOrOwner {
        refPercentage = newRefPercentage;
        emit UpdatedRefPercentage(newRefPercentage);
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function addInfluencers(address[] memory userAddresses, uint256[] memory referralPercentages) external override onlyMulticallOrOwner {
        require(userAddresses.length == referralPercentages.length, 'AIF');
        uint8 usersLength = uint8(userAddresses.length);
        uint8 k;
        while (k < usersLength) {
            referralConfig[userAddresses[k]] = ReferralConfiguration({userAddress: userAddresses[k], referralPercentage: referralPercentages[k]});
            k++;
        }
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function updateMulticall(address newMultiCallAddress) external onlyOwner {
        require(newMultiCallAddress != multiCall, 'SMA');
        multiCall = newMultiCallAddress;
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function setRewardCap(
        address cohortId,
        address[] memory rewardTokenAddresses,
        uint256[] memory rewards
    ) external override onlyMulticallOrOwner returns (bool) {
        require(cohortId != address(0), 'ICI');
        require(rewardTokenAddresses.length == rewards.length, 'IL');
        uint8 rewardTokensLength = uint8(rewardTokenAddresses.length);
        for (uint8 v = 0; v < rewardTokensLength; v++) {
            require(rewards[v] > 0, 'IRA');
            rewardCap[cohortId][rewardTokenAddresses[v]] = rewards[v];
        }
        return true;
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function setRewardTokenDetails(address cohortId, bytes calldata rewards) external onlyMulticallOrOwner {
        require(cohortId != address(0), 'ICI');
        _rewards[cohortId] = rewards;
        emit SetRewardTokenDetails(cohortId, rewards);
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function getRewardTokens(address cohortId) public view returns (address[] memory rewardTokens, uint256[] memory pbr) {
        bytes memory rewardByte = _rewards[cohortId];
        (rewardTokens, pbr) = abi.decode(rewardByte, (address[], uint256[]));
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function getInfluencerReferralPercentage(address influencerAddress) public view override returns (uint256 referralPercentage) {
        ReferralConfiguration memory referral = referralConfig[influencerAddress];
        bool isConfigurationAvailable = referral.userAddress != address(0);
        if (isConfigurationAvailable) {
            referralPercentage = referral.referralPercentage;
        } else {
            referralPercentage = refPercentage;
        }
    }

    /**
     * @dev performs single token transfer to user
     * @param cohortId cohort contract address
     * @param rewardTokenAddress reward token address
     * @param user user address
     * @param referralAddress influencer address
     * @param referralPercentage referral percentage
     * @param pbr1 per block reward for first reward token
     * @param rValue Aggregated R Value
     * @param hasContainWrapToken has reward contain wToken
     */

    function sendOne(
        address cohortId,
        address rewardTokenAddress,
        address user,
        address referralAddress,
        uint256 referralPercentage,
        uint256 pbr1,
        uint256 rValue,
        bool hasContainWrapToken
    ) internal {
        uint256 rewardValue = (pbr1 * rValue) / (1e12);
        require(rewardCap[cohortId][rewardTokenAddress] >= rewardValue, 'RCR');
        uint256 refEarned = (rewardValue * referralPercentage) / (100000);
        uint256 userEarned = rewardValue - refEarned;
        bool zero = referralAddress != address(0);
        if (hasContainWrapToken) {
            IWETH(rewardTokenAddress).withdraw(rewardValue);
            if (zero) TransferHelpers.safeTransferParentChainToken(referralAddress, refEarned);
            TransferHelpers.safeTransferParentChainToken(user, userEarned);
        } else {
            if (zero) TransferHelpers.safeTransfer(rewardTokenAddress, referralAddress, refEarned);
            TransferHelpers.safeTransfer(rewardTokenAddress, user, userEarned);
        }
        rewardCap[cohortId][rewardTokenAddress] = rewardCap[cohortId][rewardTokenAddress] - rewardValue;
    }

    /**
     * @dev perform multi token transfers to user
     * @param cohortId cohort contract address
     * @param rewardTokens array of reward token addresses
     * @param pbr array of per block rewards
     * @param userAddress user address
     * @param referralAddress influencer address
     * @param referralPercentage referral percentage
     * @param rValue Aggregated R Value
     */

    function sendMulti(
        address cohortId,
        address[] memory rewardTokens,
        uint256[] memory pbr,
        address userAddress,
        address referralAddress,
        uint256 referralPercentage,
        uint256 rValue
    ) internal {
        uint8 rTokensLength = uint8(rewardTokens.length);
        for (uint8 r = 1; r < rTokensLength; r++) {
            uint256 exactReward = (pbr[r] * rValue) / 1e12;
            require(rewardCap[cohortId][rewardTokens[r]] >= exactReward, 'RCR');
            uint256 refEarned = (exactReward * referralPercentage) / 100000;
            uint256 userEarned = exactReward - refEarned;
            if (referralAddress != address(0)) TransferHelpers.safeTransfer(rewardTokens[r], referralAddress, refEarned);
            TransferHelpers.safeTransfer(rewardTokens[r], userAddress, userEarned);
            rewardCap[cohortId][rewardTokens[r]] = rewardCap[cohortId][rewardTokens[r]] - exactReward;
        }
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function distributeRewards(
        address cohortId,
        address userAddress,
        address influcenerAddress,
        uint256 rValue,
        bool hasContainsWrappedToken
    ) external override {
        require(_msgSender() == cohortId, 'IS');
        (address[] memory rewardTokens, uint256[] memory pbr) = getRewardTokens(cohortId);
        uint256 referralPercentage = getInfluencerReferralPercentage(influcenerAddress);
        sendOne(cohortId, rewardTokens[0], userAddress, influcenerAddress, referralPercentage, pbr[0], rValue, hasContainsWrappedToken);
        sendMulti(cohortId, rewardTokens, pbr, userAddress, influcenerAddress, referralPercentage, rValue);
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function safeWithdrawEth(address withdrawableAddress, uint256 amount) external onlyOwner returns (bool) {
        require(withdrawableAddress != address(0), 'IWA');
        TransferHelpers.safeTransferParentChainToken(withdrawableAddress, amount);
        return true;
    }

    /**
     * @inheritdoc IUnifarmRewardRegistryUpgradeable
     */

    function safeWithdrawAll(
        address withdrawableAddress,
        address[] memory tokens,
        uint256[] memory amounts
    ) external onlyOwner {
        require(withdrawableAddress != address(0), 'IWA');
        require(tokens.length == amounts.length, 'SF');
        uint8 i = 0;
        uint8 tokensLength = uint8(tokens.length);
        while (i < tokensLength) {
            TransferHelpers.safeTransfer(tokens[i], withdrawableAddress, amounts[i]);
            i++;
        }
    }

    uint256[49] private __gap;
}
