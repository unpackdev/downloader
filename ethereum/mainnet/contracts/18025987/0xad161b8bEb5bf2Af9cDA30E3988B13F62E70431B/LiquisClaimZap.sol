// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ILiqLocker.sol";
import "./IRewardStaking.sol";

/**
 * @title   LiquisClaimZap
 * @author  ConvexFinance -> AuraFinance -> LiquisFinance
 * @notice  Claim zap to bundle various reward claims
 * @dev     Claims from all pools, and locks LIQ if wanted.
 */
contract LiquisClaimZap {
    using SafeERC20 for IERC20;

    address public immutable liq;
    address public immutable liqLit;
    address public immutable liqLitRewards;
    address public immutable liqLocker;

    enum Options {
        ClaimLiqLit, // 1
        ClaimLockedLiq, // 2
        UseAllLiqFunds, // 4
        LockLiq // 8
    }

    /**
     * @param _liq                LIQ token (0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
     * @param _liqLit             liqLIT token (0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7);
     * @param _liqLitRewards      liqLitRewards (0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e);
     * @param _liqLocker          vlLIQ (0xD18140b4B819b895A3dba5442F959fA44994AF50);
     */
    constructor(
        address _liq,
        address _liqLit,
        address _liqLitRewards,
        address _liqLocker
    ) {
        liq = _liq;
        liqLit = _liqLit;
        liqLitRewards = _liqLitRewards;
        liqLocker = _liqLocker;

        _setApprovals();
    }

    function getName() external pure returns (string memory) {
        return "LiquisClaimZap V1.0";
    }

    /**
     * @notice Approve spending of liq -> Locker
     */
    function _setApprovals() internal {
        IERC20(liq).safeApprove(liqLocker, 0);
        IERC20(liq).safeApprove(liqLocker, type(uint256).max);
    }

    /**
     * @notice Use bitmask to check if option flag is set
     */
    function _checkOption(uint256 _mask, uint256 _flag) internal pure returns (bool) {
        return (_mask & (1 << _flag)) != 0;
    }

    /**
     * @notice Claim all the rewards
     * @param rewardContracts        Array of addresses for LP token rewards
     * @param extraRewardContracts   Array of addresses for extra rewards
     * @param tokenRewardContracts   Array of addresses for token rewards e.g vlCvxExtraRewardDistribution
     * @param tokenRewardTokens      Array of token reward addresses to use with tokenRewardContracts
     * @param options                Claim options
     */
    function claimRewards(
        address[] calldata rewardContracts,
        address[] calldata extraRewardContracts,
        address[] calldata tokenRewardContracts,
        address[] calldata tokenRewardTokens,
        uint256 options
    ) external {
        require(tokenRewardContracts.length == tokenRewardTokens.length, "!parity");

        uint256 removeCvxBalance = IERC20(liq).balanceOf(msg.sender);

        // claim from main curve LP pools
        for (uint256 i = 0; i < rewardContracts.length; i++) {
            IRewardStaking(rewardContracts[i]).getReward(msg.sender, true);
        }
        // claim from extra rewards
        for (uint256 i = 0; i < extraRewardContracts.length; i++) {
            IRewardStaking(extraRewardContracts[i]).getReward(msg.sender);
        }
        // claim from multi reward token contract
        for (uint256 i = 0; i < tokenRewardContracts.length; i++) {
            IRewardStaking(tokenRewardContracts[i]).getReward(msg.sender, tokenRewardTokens[i]);
        }

        // reset remove liq balances if we want to also lock funds already in our wallet
        if (_checkOption(options, uint256(Options.UseAllLiqFunds))) {
            removeCvxBalance = 0;
        }

        // claim from liqLit rewards
        if (_checkOption(options, uint256(Options.ClaimLiqLit))) {
            IRewardStaking(liqLitRewards).getReward(msg.sender, true);
        }

        // claim from liqLocker
        if (_checkOption(options, uint256(Options.ClaimLockedLiq))) {
            ILiqLocker(liqLocker).getReward(msg.sender);
        }

        // stake up to given amount of liq
        if (_checkOption(options, uint256(Options.LockLiq))) {
            uint256 cvxBalance = IERC20(liq).balanceOf(msg.sender) - removeCvxBalance;
            if (cvxBalance > 0) {
                IERC20(liq).safeTransferFrom(msg.sender, address(this), cvxBalance);
                ILiqLocker(liqLocker).lock(msg.sender, cvxBalance);
            }
        }
    }
}
