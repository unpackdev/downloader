// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./SafeERC20.sol";

import "./LendingPool.sol";

import "./PoolFactory.sol";
import "./TrancheVault.sol";

library PoolTransfers {
    function lenderEnableRollOver(
        LendingPool lendingPool,
        bool principal,
        bool rewards,
        bool platformTokens,
        address lender
    ) external {
        PoolFactory poolFactory = PoolFactory(lendingPool.poolFactoryAddress());
        uint256 lockedPlatformTokens;
        uint256 trancheCount = lendingPool.tranchesCount();
        for (uint8 trancheId; trancheId < trancheCount; trancheId++) {
            (uint256 staked, , , ) = lendingPool.s_trancheRewardables(trancheId, lender);
            TrancheVault vault = TrancheVault(lendingPool.trancheVaultAddresses(trancheId));
            (, uint256 locked, , ) = lendingPool.s_trancheRewardables(trancheId, lender);
            lockedPlatformTokens += locked;
            vault.approveRollover(lender, staked);
        }

        address[4] memory futureLenders = poolFactory.nextLenders();
        for (uint256 i = 0; i < futureLenders.length; i++) {
            SafeERC20.safeApprove(
                IERC20(lendingPool.platformTokenContractAddress()),
                futureLenders[i],
                0
            );
            // approve transfer of platform tokens
            SafeERC20.safeApprove(
                IERC20(lendingPool.platformTokenContractAddress()),
                futureLenders[i],
                lockedPlatformTokens
            );

            SafeERC20.safeApprove(
                IERC20(lendingPool.stableCoinContractAddress()),
                futureLenders[i],
                0
            );
            // approve transfer of the stablecoin contract
            SafeERC20.safeApprove(
                IERC20(lendingPool.stableCoinContractAddress()), // asume tranches.asset() == stablecoin address
                futureLenders[i],
                2 ** 256 - 1 // infinity approve because we don't know how much interest will need to be accounted for
            );
        }
    }

    function executeRollover(
        LendingPool lendingPool,
        address deadLendingPoolAddr,
        address[] memory deadTrancheAddrs,
        uint256 lenderStartIndex,
        uint256 lenderEndIndex
    ) external {
        uint256 tranchesCount = lendingPool.tranchesCount();
        require(tranchesCount == deadTrancheAddrs.length, "tranche array mismatch");
        require(
            keccak256(deadLendingPoolAddr.code) == keccak256(address(this).code),
            "rollover incampatible due to version mismatch"
        ); // upgrades to the next contract need to be set before users are allowed to rollover in the current contract
        // should do a check to ensure there aren't more than n protocols running in parallel, if this is true, the protocol will revert for reasons unknown to future devs
        LendingPool deadpool = LendingPool(deadLendingPoolAddr);
        for (uint256 i = lenderStartIndex; i <= lenderEndIndex; i++) {
            address lender = deadpool.lendersAt(i);
            LendingPool.RollOverSetting memory settings = LendingPool(deadLendingPoolAddr).lenderRollOverSettings(lender);
            if (!settings.enabled) {
                continue;
            }

            for (uint8 trancheId; trancheId < tranchesCount; trancheId++) {
                TrancheVault vault = TrancheVault(lendingPool.trancheVaultAddresses(trancheId));
                uint256 rewards = settings.rewards ? deadpool.lenderRewardsByTrancheRedeemable(lender, trancheId) : 0;
                // lenderRewardsByTrancheRedeemable will revert if the lender has previously withdrawn
                // transfer rewards from dead lender to dead tranche
                SafeERC20.safeTransferFrom(
                    IERC20(lendingPool.stableCoinContractAddress()),
                    deadLendingPoolAddr,
                    deadTrancheAddrs[trancheId],
                    rewards
                );

                vault.rollover(lender, deadTrancheAddrs[trancheId], rewards);
            }

            // ask deadpool to move platform token into this new contract
            IERC20 platoken = IERC20(lendingPool.platformTokenContractAddress());
            uint256 platokens = platoken.allowance(deadLendingPoolAddr, address(this));
            SafeERC20.safeTransferFrom(platoken, deadLendingPoolAddr, address(this), platokens);
        }
    }
}
