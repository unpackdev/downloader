// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./helpers.sol";

import "./events.sol";

/// @title WithdrawalsModule
/// @dev Actions are executable by allowed rebalancers only
contract WithdrawalsModule is Helpers, Events {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /***********************************|
    |              ERRORS               |
    |__________________________________*/
    error WithdrawalsModule__VaultUnsafeAfterWithdraw();
    error WithdrawalsModule__InvalidERC721Transfer();
    error WithdrawalsModule__ERC721NotTransferred();
    error WithdrawalsModule__NoETHTransferred();

    /***********************************|
    |          WITHDRAWALS CORE         |
    |__________________________________*/

    /// @notice withdraws `stethAmount_` of stETH from protocol at `fromProtocolId_` and
    /// queues ETH withdrawal request for `stethAmount_` stETH at Lido WithdrawalQueue
    /// @dev more details in event logged by Lido contract WithdrawalQueue event "WithdrawalRequested"
    /// @param stethAmount_ amount to withdraw (Always in stETH).
    /// @param fromProtocolId_ Id of the protocol to withdraw stETH from. leverage ratio must be safe after request.
    /// Set to 0 to skip withdrawing from a protocol (recommended to do all in one tx to avoid risk of someone withdrawing)
    /// if set to 0, enough stETH to cover `stethAmount_` must already be in vault contract
    /// @return requestId_ Lido withdrawal request id
    function queueEthWithdrawal(
        uint256 stethAmount_,
        uint8 fromProtocolId_
    ) external nonReentrant onlyRebalancer returns (uint256 requestId_) {
        if (fromProtocolId_ == 4) {
            revert Helpers__EulerDisabled();
        }

        uint256 nftBalanceBefore_ = LIDO_WITHDRAWAL_QUEUE.balanceOf(address(this));

        if (fromProtocolId_ > 0) {
            bool isFromStETHBasedProtocol_ = fromProtocolId_ == 1 ||
                fromProtocolId_ == 5;

            // Getting wstETH values for protocols supporting wstETH.
            uint256 fromWithdrawAmount_ = isFromStETHBasedProtocol_
                ? stethAmount_
                : WSTETH_CONTRACT.getWstETHByStETH(stethAmount_);

            string[] memory targets_ = new string[](
                isFromStETHBasedProtocol_ ? 2 : 3
            );
            bytes[] memory calldatas_ = new bytes[](
                isFromStETHBasedProtocol_ ? 2 : 3
            );

            if (fromProtocolId_ == 1) {
                // stETH based protocol
                targets_[0] = "AAVE-V2-A";
                calldatas_[0] = abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    STETH_ADDRESS,
                    fromWithdrawAmount_, // stETH amount
                    0,
                    0
                );
            } else if (fromProtocolId_ == 2) {
                // wstETH based protocol
                targets_[0] = "AAVE-V3-A";
                calldatas_[0] = abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    WSTETH_ADDRESS,
                    fromWithdrawAmount_, // stETH amount converted to wstETH.
                    0,
                    0
                );
            } else if (fromProtocolId_ == 3) {
                // wstETH based protocol
                targets_[0] = "COMPOUND-V3-A";
                calldatas_[0] = abi.encodeWithSignature(
                    "withdraw(address,address,uint256,uint256,uint256)",
                    COMP_ETH_MARKET_ADDRESS,
                    WSTETH_ADDRESS,
                    fromWithdrawAmount_, // stETH amount converted to wstETH.
                    0,
                    0
                );
            } else if (fromProtocolId_ == 5) {
                // stETH based protocol
                targets_[0] = "MORPHO-AAVE-V2-A";
                calldatas_[0] = abi.encodeWithSignature(
                    "withdraw(address,address,uint256,uint256,uint256)",
                    STETH_ADDRESS,
                    A_STETH_ADDRESS,
                    fromWithdrawAmount_, // stETH amount
                    0,
                    0
                );
            } else if (fromProtocolId_ == 6) {
                // wstETH based protocol
                targets_[0] = "MORPHO-AAVE-V3-A";
                calldatas_[0] = abi.encodeWithSignature(
                    "withdrawCollateral(address,uint256,uint256,uint256)",
                    WSTETH_ADDRESS,
                    fromWithdrawAmount_, // stETH amount converted to wstETH.
                    0,
                    0
                );
            } else if (fromProtocolId_ == 7) {
                // wstETH based protocol
                targets_[0] = "SPARK-A";
                calldatas_[0] = abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    WSTETH_ADDRESS,
                    fromWithdrawAmount_, // stETH amount converted to wstETH.
                    0,
                    0
                );
            }

            // convert wstETH to stETH if necessary
            if (isFromStETHBasedProtocol_ == false) {
                targets_[1] = "WSTETH-A";
                calldatas_[1] = abi.encodeWithSignature(
                    "withdraw(uint256,uint256,uint256)",
                    type(uint256).max, // Converting all the withdrawn amount
                    0,
                    0
                );
            }

            // Using max amount to withdraw stETH from DSA to vault
            targets_[isFromStETHBasedProtocol_ ? 1 : 2] = "BASIC-A";
            calldatas_[isFromStETHBasedProtocol_ ? 1 : 2] = abi
                .encodeWithSignature(
                    "withdraw(address,uint256,address,uint256,uint256)",
                    STETH_ADDRESS,
                    type(uint256).max,
                    address(this),
                    0,
                    0
                );

            vaultDSA.cast(targets_, calldatas_, address(this));

            // Make sure protocol ratio is still below max risk ratio
            if (
                getProtocolRatio(fromProtocolId_) >
                maxRiskRatio[fromProtocolId_]
            ) {
                revert WithdrawalsModule__VaultUnsafeAfterWithdraw();
            }
        }

        // Approve stETH amount to Lido withdrawal queue
        IERC20Upgradeable(STETH_ADDRESS).safeApprove(
            address(LIDO_WITHDRAWAL_QUEUE),
            stethAmount_
        );

        // Request withdrawal at Lido withdrawal queue
        uint256[] memory amounts_ = new uint256[](1);
        amounts_[0] = stethAmount_;

        // Vault will always be the owner of request IDs
        uint256[] memory requestIds_ = LIDO_WITHDRAWAL_QUEUE.requestWithdrawals(
            amounts_,
            address(this) // Vault will receive the confirmatory NFT
        );

        requestId_ = requestIds_[0];

        uint256 nftBalanceAfter_ = LIDO_WITHDRAWAL_QUEUE.balanceOf(address(this));

        if (nftBalanceAfter_ != (nftBalanceBefore_ + 1)) {
            revert WithdrawalsModule__ERC721NotTransferred();
        }

        // Update queued stETH amount
        queuedWithdrawStEth += stethAmount_;

        // Log withdrawal queued
        emit LogQueueEthWithdrawal(stethAmount_, requestId_, fromProtocolId_);
    }

    /// @notice accept ERC721 token transfers ONLY from LIDO_WITHDRAWAL_QUEUE
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public returns (bytes4) {
        if (msg.sender == address(LIDO_WITHDRAWAL_QUEUE)) {
            return this.onERC721Received.selector;
        }

        revert WithdrawalsModule__InvalidERC721Transfer();
    }

    /// @notice claims ETH for queued Lido withdraw request and repays the debt at `toProtocolId_`
    /// @dev more details in event logged by Lido contract WithdrawalQueue event "WithdrawClaimed" (e.g. amount of ETH claimed)
    /// @param requestId_ Id of request at Lido. Can be found with `getEthWithdrawalRequests()`
    /// @param toProtocolId_ Id of the protocol to repay claimed ETH to (as WETH). Protocol ID should be sent as '0' to skip repaying.
    function claimEthWithdrawal(
        uint256 requestId_,
        uint8 toProtocolId_
    ) external nonReentrant onlyRebalancer {
        // Get amount of original stETH locked (and spent) for request
        uint256[] memory requestIds_ = new uint256[](1);
        requestIds_[0] = requestId_;

        ILidoWithdrawalQueue.WithdrawalRequestStatus[]
            memory requestStatuses_ = LIDO_WITHDRAWAL_QUEUE.getWithdrawalStatus(
                requestIds_
            );

        // Check ETH balance before claim
        uint256 balanceBefore_ = address(this).balance;

        // No checks needed, Lido will fail if requestId is not claimable or invalid
        LIDO_WITHDRAWAL_QUEUE.claimWithdrawal(requestId_);

        // Check ETH balance after claim.
        uint256 balanceAfter_ = address(this).balance;

        // We can't check the exact ETH recieved as the amount can vary due to slashing and penalties.
        // https://github.com/lidofinance/lido-dao/blob/master/contracts/0.8.9/WithdrawalQueueBase.sol#L154
        if (balanceAfter_ <= balanceBefore_) {
            revert WithdrawalsModule__NoETHTransferred();
        }

        // Convert all ETH received to WETH
        IWeth(WETH_ADDRESS).deposit{value: address(this).balance}();

        // Repay the debt at toProtocolId_
        if (toProtocolId_ > 0) {
            _paybackDebt(toProtocolId_);
        }

        // Update queued stETH amount
        queuedWithdrawStEth -= requestStatuses_[0].amountOfStETH;

        // Log withdrawal claimed
        emit LogClaimEthWithdrawal(
            requestStatuses_[0].amountOfStETH,
            requestId_,
            toProtocolId_
        );
    }

    /// @notice Internal function to repay claimed amounts to a protocol
    /// @param toProtocolId_ Id of the protocol to repay claimed ETH to (as WETH)
    function _paybackDebt(uint8 toProtocolId_) internal {
        if (toProtocolId_ == 4) {
            revert Helpers__EulerDisabled();
        }

        string[] memory targets_ = new string[](1);
        bytes[] memory calldatas_ = new bytes[](1);

        uint256 wethBalanceToPayback_ = TokenInterface(WETH_ADDRESS).balanceOf(
            address(this)
        );

        // Deposit all WETH to DSA
        IWeth(WETH_ADDRESS).transfer(address(vaultDSA), wethBalanceToPayback_);

        // repay max WETH at `toProtocolId_`
        if (toProtocolId_ == 1) {
            targets_[0] = "AAVE-V2-A";
            calldatas_[0] = abi.encodeWithSignature(
                "payback(address,uint256,uint256,uint256,uint256)",
                WETH_ADDRESS,
                type(uint256).max,
                2,
                0,
                0
            );
        } else if (toProtocolId_ == 2) {
            targets_[0] = "AAVE-V3-A";
            calldatas_[0] = abi.encodeWithSignature(
                "payback(address,uint256,uint256,uint256,uint256)",
                WETH_ADDRESS,
                type(uint256).max,
                2,
                0,
                0
            );
        } else if (toProtocolId_ == 3) {
            targets_[0] = "COMPOUND-V3-A";
            calldatas_[0] = abi.encodeWithSignature(
                "payback(address,address,uint256,uint256,uint256)",
                COMP_ETH_MARKET_ADDRESS,
                WETH_ADDRESS,
                type(uint256).max,
                0,
                0
            );
        } else if (toProtocolId_ == 5) {
            targets_[0] = "MORPHO-AAVE-V2-A";
            calldatas_[0] = abi.encodeWithSignature(
                "payback(address,address,uint256,uint256,uint256)",
                WETH_ADDRESS,
                A_WETH_ADDRESS,
                type(uint256).max,
                0,
                0
            );
        } else if (toProtocolId_ == 6) {
            targets_[0] = "MORPHO-AAVE-V3-A";
            calldatas_[0] = abi.encodeWithSignature(
                "payback(address,uint256,uint256,uint256)",
                WETH_ADDRESS,
                type(uint256).max,
                0,
                0
            );
        } else if (toProtocolId_ == 7) {
            targets_[0] = "SPARK-A";
            calldatas_[0] = abi.encodeWithSignature(
                "payback(address,uint256,uint256,uint256,uint256)",
                WETH_ADDRESS,
                type(uint256).max,
                2,
                0,
                0
            );
        }

        // Protocol ratio can only be better after repay, no need to check max risk ratio
        vaultDSA.cast(targets_, calldatas_, address(this));

        // Log WETH payback
        emit LogWethPayback(wethBalanceToPayback_, toProtocolId_);
    }

    /// @notice Transfers WETH from vault to DSA and repays debt at `toProtocolId_`
    /// @param toProtocolId_ Id of the protocol to repay claimed ETH to (as WETH)
    function paybackDebt(
        uint8 toProtocolId_
    ) external nonReentrant onlyRebalancer {
        _paybackDebt(toProtocolId_);
    }
}
