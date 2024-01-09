// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BNPLKYCStore.sol";
import "./IUserTokenLockup.sol";

/**
 * @dev Interface of the IBankNodeStakingPoolInitializableV1 standard
 */
interface IBankNodeStakingPoolInitializableV1 {
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
    function donate(uint256 donateAmount) external;

    function donateNotCountedInTotal(uint256 donateAmount) external;

    function bondTokens(uint256 bondAmount) external;

    function unbondTokens() external;

    function stakeTokens(uint256 stakeAmount) external;

    function unstakeTokens(uint256 unstakeAmount) external;

    function slash(uint256 slashAmount) external;

    function getPoolTotalAssetsValue() external view returns (uint256);

    function getPoolWithdrawConversion(uint256 withdrawAmount) external view returns (uint256);

    function virtualPoolTokensCount() external view returns (uint256);

    function baseTokenBalance() external view returns (uint256);

    function getUnstakeLockupPeriod() external pure returns (uint256);

    function tokensBondedAllTime() external view returns (uint256);

    function poolTokenEffectiveSupply() external view returns (uint256);

    function getNodeOwnerBNPLRewards() external view returns (uint256);

    function getNodeOwnerPoolTokenRewards() external view returns (uint256);

    function poolTokensCirculating() external view returns (uint256);

    function isNodeDecomissioning() external view returns (bool);

    function claimNodeOwnerPoolTokenRewards(address to) external;
}
