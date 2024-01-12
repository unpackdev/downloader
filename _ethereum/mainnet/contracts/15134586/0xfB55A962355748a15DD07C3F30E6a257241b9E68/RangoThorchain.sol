// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./BaseContract.sol";
import "./IThorchainRouter.sol";
import "./IRangoThorchain.sol";

/// @title A contract to handle interactions with Thorchain Router contract on evm chains.
/// @author Thinking Particle
/// @notice This contract directly interacts with thorchain router.
/// @dev This contract checks for basic validation and also checks that provided thorchain router is whitelisted. Also emits swap events.
contract RangoThorchain is IRangoThorchain, BaseContract {
    /// @notice emiited to notify that a swap to thorchain has been initiated by rango and provides the parameters used for the swap.
    /// @param vault The vault address of Thorchain. This cannot be hardcoded because Thorchain rotates vaults.
    /// @param token The token contract address (if token is native, should be 0x0000000000000000000000000000000000000000)
    /// @param amount The amount of token to be swapped. It should be positive and if token is native, msg.value should be bigger than amount.
    /// @param memo The transaction memo used by Thorchain which contains the thorchain swap data. More info: https://dev.thorchain.org/thorchain-dev/memos
    /// @param expiration The expiration block number. If the tx is included after this block, it will be reverted.
    event ThorchainTxInitiated(address vault, address token, uint amount, string memo, uint expiration);

    receive() external payable { }

    // @inheritdoc IRangoThorchain
    function swapInToThorchain(
        address token,
        uint amount,
        address tcRouter,
        address tcVault,
        string calldata thorchainMemo,
        uint expiration
    ) external payable whenNotPaused nonReentrant {
        BaseContractStorage storage baseStorage = getBaseContractStorage();
        require(baseStorage.whitelistContracts[tcRouter], "given thorchain router not whitelisted");
        require(amount > 0, "Requested amount should be positive");
        if (token == NULL_ADDRESS) {
            require(msg.value >= amount, "zero input while fromToken is native");
        } else {
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
            approve(token, tcRouter, amount);
        }

        IThorchainRouter(tcRouter).depositWithExpiry{value : msg.value}(
            payable(tcVault), // address payable vault,
            token, // address asset,
            amount, // uint amount,
            thorchainMemo, // string calldata memo,
            expiration  // uint expiration) external payable;
        );
        emit ThorchainTxInitiated(tcVault, token, amount, thorchainMemo, expiration);
    }

}