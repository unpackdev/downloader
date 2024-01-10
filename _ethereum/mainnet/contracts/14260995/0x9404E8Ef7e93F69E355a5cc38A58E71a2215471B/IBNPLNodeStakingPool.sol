// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BNPLKYCStore.sol";
import "./IUserTokenLockup.sol";

/// @dev Interface of the IBankNodeStakingPoolInitializableV1 standard
/// @author BNPL
interface IBankNodeStakingPoolInitializableV1 {
    /// @dev StakingPool contract is created and initialized by the BankNodeManager contract
    ///
    /// - This contract is called through the proxy.
    ///
    /// @param bnplToken BNPL token address
    /// @param poolBNPLToken pool BNPL token address
    /// @param bankNodeContract BankNode contract address associated with stakingPool
    /// @param bankNodeManagerContract BankNodeManager contract address
    /// @param tokenBonder The address of the BankNode creator
    /// @param tokensToBond The amount of BNPL bound by the BankNode creator (initial liquidity amount)
    /// @param bnplKYCStore_ KYC store contract address
    /// @param kycDomainId_ KYC store domain id
    function initialize(
        address bnplToken,
        address poolBNPLToken,
        address bankNodeContract,
        address bankNodeManagerContract,
        address tokenBonder,
        uint256 tokensToBond,
        BNPLKYCStore bnplKYCStore_,
        uint32 kycDomainId_
    ) external;
}

/**
 * @dev Interface of the IBankNode standard
 */
interface IBNPLNodeStakingPool is IBankNodeStakingPoolInitializableV1, IUserTokenLockup {
    /// @notice Allows a user to donate `donateAmount` of BNPL to the pool (user must first approve)
    /// @param donateAmount The donate amount of BNPL
    function donate(uint256 donateAmount) external;

    /// @notice Allows a user to donate `donateAmount` of BNPL to the pool (not conted in total) (user must first approve)
    /// @param donateAmount The donate amount of BNPL
    function donateNotCountedInTotal(uint256 donateAmount) external;

    /// @notice Allows a user to bond `bondAmount` of BNPL to the pool (user must first approve)
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "NODE_REWARDS_MANAGER_ROLE"
    ///
    /// @param bondAmount The bond amount of BNPL
    function bondTokens(uint256 bondAmount) external;

    /// @notice Allows a user to unbond BNPL from the pool
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "NODE_REWARDS_MANAGER_ROLE"
    ///
    function unbondTokens() external;

    /// @notice Allows a user to stake `stakeAmount` of BNPL to the pool (user must first approve)
    /// @param stakeAmount Stake token amount
    function stakeTokens(uint256 stakeAmount) external;

    /// @notice Allows a user to unstake `unstakeAmount` of BNPL from the pool (puts it into a lock up for a 7 day cool down period)
    /// @param unstakeAmount Unstake token amount
    function unstakeTokens(uint256 unstakeAmount) external;

    /// @notice Allows an authenticated contract/user (in this case, only BNPLBankNode) to slash `slashAmount` of BNPL from the pool
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "SLASHER_ROLE"
    ///
    /// @param slashAmount The slash amount
    function slash(uint256 slashAmount) external;

    /// @notice Returns pool total assets value
    /// @return poolTotalAssetsValue
    function getPoolTotalAssetsValue() external view returns (uint256);

    /// @notice Returns pool withdraw conversion
    ///
    /// @param withdrawAmount The withdraw tokens amount
    /// @return poolWithdrawConversion
    function getPoolWithdrawConversion(uint256 withdrawAmount) external view returns (uint256);

    /// @notice Pool BNPL token balance
    /// @return virtualPoolTokensCount
    function virtualPoolTokensCount() external view returns (uint256);

    /// @notice Total assets value
    /// @return baseTokenBalance
    function baseTokenBalance() external view returns (uint256);

    /// @notice Returns unstake lockup period
    /// @return unstakeLockupPeriod
    function getUnstakeLockupPeriod() external pure returns (uint256);

    /// @notice Cumulative value of bonded tokens
    /// @return tokensBondedAllTime
    function tokensBondedAllTime() external view returns (uint256);

    /// @notice Pool BNPL token effective supply
    /// @return poolTokenEffectiveSupply
    function poolTokenEffectiveSupply() external view returns (uint256);

    /// @notice Claim node owner BNPL token rewards
    /// @return rewards Claimed reward BNPL token amount
    function getNodeOwnerBNPLRewards() external view returns (uint256);

    /// @notice Claim node owner pool BNPL token rewards
    /// @return rewards Claimed reward pool token amount
    function getNodeOwnerPoolTokenRewards() external view returns (uint256);

    /// @notice Returns pool tokens circulating
    /// @return poolTokensCirculating
    function poolTokensCirculating() external view returns (uint256);

    /// @notice Returns whether the BankNode has been decommissioned
    ///
    /// - When the liquidity tokens amount of the BankNode is less than minimum BankNode bonded amount, it is decommissioned
    ///
    /// @return isNodeDecomissioning
    function isNodeDecomissioning() external view returns (bool);

    /// @notice Claim node owner pool token rewards to address `to`
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "NODE_REWARDS_MANAGER_ROLE"
    ///
    /// @param to Address to receive rewards
    function claimNodeOwnerPoolTokenRewards(address to) external;
}
