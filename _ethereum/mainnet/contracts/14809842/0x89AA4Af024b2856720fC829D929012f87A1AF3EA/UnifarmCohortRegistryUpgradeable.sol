// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import "./UnifarmCohortRegistryUpgradeableStorage.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IUnifarmCohortRegistryUpgradeable.sol";

/// @title UnifarmCohortRegistryUpgradeable Contract
/// @author UNIFARM
/// @notice maintain collection of cohorts of unifarm
/// @dev All State mutation function are restricted to only owner access and multicall

contract UnifarmCohortRegistryUpgradeable is
    IUnifarmCohortRegistryUpgradeable,
    Initializable,
    OwnableUpgradeable,
    UnifarmCohortRegistryUpgradeableStorage
{
    /// @notice modifier for vailidate sender
    modifier onlyMulticallOrOwner() {
        onlyOwnerOrMulticall();
        _;
    }

    /**
     * @notice initialize Unifarm Registry contract
     * @param master master role address
     * @param trustedForwarder trusted forwarder address
     * @param  multiCall_ multicall contract address
     */

    function __UnifarmCohortRegistryUpgradeable_init(
        address master,
        address trustedForwarder,
        address multiCall_
    ) external initializer {
        __UnifarmCohortRegistryUpgradeable_init_unchained(multiCall_);
        __Ownable_init(master, trustedForwarder);
    }

    /**
     * @dev internal function to set registry state
     * @param  multiCall_ multicall contract address
     */

    function __UnifarmCohortRegistryUpgradeable_init_unchained(address multiCall_) internal {
        multiCall = multiCall_;
    }

    /**
     * @dev modifier to prevent malicious user
     */

    function onlyOwnerOrMulticall() internal view {
        require(_msgSender() == multiCall || _msgSender() == owner(), 'ONA');
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function setTokenMetaData(
        address cohortId,
        uint32 fid_,
        address farmToken_,
        uint256 userMinStake_,
        uint256 userMaxStake_,
        uint256 totalStakeLimit_,
        uint8 decimals_,
        bool skip_
    ) external override onlyMulticallOrOwner {
        require(fid_ > 0, 'WFID');
        require(farmToken_ != address(0), 'IFT');
        require(userMaxStake_ > 0 && totalStakeLimit_ > 0, 'IC');
        require(totalStakeLimit_ > userMaxStake_, 'IC');

        tokenDetails[cohortId][fid_] = TokenMetaData({
            fid: fid_,
            farmToken: farmToken_,
            userMinStake: userMinStake_,
            userMaxStake: userMaxStake_,
            totalStakeLimit: totalStakeLimit_,
            decimals: decimals_,
            skip: skip_
        });

        emit TokenMetaDataDetails(cohortId, farmToken_, fid_, userMinStake_, userMaxStake_, totalStakeLimit_, decimals_, skip_);
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function setCohortDetails(
        address cohortId,
        string memory cohortVersion_,
        uint256 startBlock_,
        uint256 endBlock_,
        uint256 epochBlocks_,
        bool hasLiquidityMining_,
        bool hasContainsWrappedToken_,
        bool hasCohortLockinAvaliable_
    ) external override onlyMulticallOrOwner {
        require(cohortId != address(0), 'ICI');
        require(endBlock_ > startBlock_, 'IBR');

        cohortDetails[cohortId] = CohortDetails({
            cohortVersion: cohortVersion_,
            startBlock: startBlock_,
            endBlock: endBlock_,
            epochBlocks: epochBlocks_,
            hasLiquidityMining: hasLiquidityMining_,
            hasContainsWrappedToken: hasContainsWrappedToken_,
            hasCohortLockinAvaliable: hasCohortLockinAvaliable_
        });

        emit AddedCohortDetails(
            cohortId,
            cohortVersion_,
            startBlock_,
            endBlock_,
            epochBlocks_,
            hasLiquidityMining_,
            hasContainsWrappedToken_,
            hasCohortLockinAvaliable_
        );
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function addBoosterPackage(
        address cohortId_,
        address paymentToken_,
        address boosterVault_,
        uint256 bpid_,
        uint256 boosterPackAmount_
    ) external override onlyMulticallOrOwner {
        require(bpid_ > 0, 'WBPID');
        boosterInfo[cohortId_][bpid_] = BoosterInfo({
            cohortId: cohortId_,
            paymentToken: paymentToken_,
            boosterVault: boosterVault_,
            boosterPackAmount: boosterPackAmount_
        });
        emit BoosterDetails(cohortId_, bpid_, paymentToken_, boosterPackAmount_);
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function updateMulticall(address newMultiCallAddress) external override onlyOwner {
        require(newMultiCallAddress != multiCall, 'SMA');
        multiCall = newMultiCallAddress;
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function setWholeCohortLock(address cohortId, bool status) external override onlyMulticallOrOwner {
        require(cohortId != address(0), 'ICI');
        wholeCohortLock[cohortId] = status;
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function setCohortLockStatus(
        address cohortId,
        bytes4 actionToLock,
        bool status
    ) external override onlyMulticallOrOwner {
        require(cohortId != address(0), 'ICI');
        lockCohort[cohortId][actionToLock] = status;
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function setCohortTokenLockStatus(
        bytes32 cohortSalt,
        bytes4 actionToLock,
        bool status
    ) external override onlyMulticallOrOwner {
        tokenLockedStatus[cohortSalt][actionToLock] = status;
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function validateStakeLock(address cohortId, uint32 farmId) public view override {
        bytes32 salt = keccak256(abi.encodePacked(cohortId, farmId));
        require(!wholeCohortLock[cohortId] && !lockCohort[cohortId][STAKE_MAGIC_VALUE] && !tokenLockedStatus[salt][STAKE_MAGIC_VALUE], 'LC');
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function validateUnStakeLock(address cohortId, uint32 farmId) public view override {
        bytes32 salt = keccak256(abi.encodePacked(cohortId, farmId));
        require(!wholeCohortLock[cohortId] && !lockCohort[cohortId][UNSTAKE_MAGIC_VALUE] && !tokenLockedStatus[salt][UNSTAKE_MAGIC_VALUE], 'LC');
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function getCohortToken(address cohortId, uint32 farmId)
        public
        view
        override
        returns (
            uint32 fid,
            address farmToken,
            uint256 userMinStake,
            uint256 userMaxStake,
            uint256 totalStakeLimit,
            uint8 decimals,
            bool skip
        )
    {
        TokenMetaData memory token = tokenDetails[cohortId][farmId];
        return (token.fid, token.farmToken, token.userMinStake, token.userMaxStake, token.totalStakeLimit, token.decimals, token.skip);
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function getCohort(address cohortId)
        public
        view
        override
        returns (
            string memory cohortVersion,
            uint256 startBlock,
            uint256 endBlock,
            uint256 epochBlocks,
            bool hasLiquidityMining,
            bool hasContainsWrappedToken,
            bool hasCohortLockinAvaliable
        )
    {
        CohortDetails memory cohort = cohortDetails[cohortId];
        return (
            cohort.cohortVersion,
            cohort.startBlock,
            cohort.endBlock,
            cohort.epochBlocks,
            cohort.hasLiquidityMining,
            cohort.hasContainsWrappedToken,
            cohort.hasCohortLockinAvaliable
        );
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function getBoosterPackDetails(address cohortId, uint256 bpid)
        public
        view
        override
        returns (
            address cohortId_,
            address paymentToken_,
            address boosterVault,
            uint256 boosterPackAmount
        )
    {
        BoosterInfo memory booster = boosterInfo[cohortId][bpid];
        return (booster.cohortId, booster.paymentToken, booster.boosterVault, booster.boosterPackAmount);
    }

    uint256[49] private __gap;
}
