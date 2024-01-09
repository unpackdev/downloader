// SPDX-License-Identifier: Unlicense

pragma solidity >=0.6.0 <0.8.0;

import "./SafeERC20.sol";
import "./ERC20Burnable.sol";
import "./MultiBridge.sol";
import "./FeeAccrual.sol";
import "./ERC20MintSnapshot.sol";

/**
 * wROOT MainMultiBridge
 *
 * Attributes:
 * - Locks wROOT tokens and supplies
 * - Unlocks wROOT tokens from an authorized member after a cross-chain migration
 * - Powered by Prismnetwork.io
 */
contract MainMultiBridge is MultiBridge, FeeAccrual {
    using SafeERC20 for ERC20MintSnapshot;

    // Gas Units Required for an `unlock`
    uint256 private constant MAIN_UNLOCK_COST = 81574;

    event CrossChainFeeAccrual(uint256 amount);
    event CrossChainBurn(uint256 amount);

    constructor(ERC20MintSnapshot wroot, uint256[] memory chainList)
        public
        MultiBridge(MAIN_UNLOCK_COST, chainList)
        FeeAccrual(wroot)
    {}

    function lock(
        address to,
        uint256 amount,
        uint256 chain
    ) external payable override validFunding() validChain(chain) {
        // Zero Security Assumptions
        uint256 lockAmount = wROOT.balanceOf(address(this));
        wROOT.safeTransferFrom(msg.sender, address(this), amount);
        lockAmount = wROOT.balanceOf(address(this)).sub(lockAmount);

        uint256 id = crossChainTransfer++;

        outwardTransfers[id] = CrossChainTransfer(
            to,
            false,
            safe88(
                tx.gasprice,
                "Multibridge::lock: tx gas price exceeds 32 bits"
            ),
            amount,
            chain
        );

        // Optionally captured by off-chain migrator
        emit CrossChainTransferLocked(msg.sender, id);
    }

    function unlock(
        uint256 satelliteChain,
        uint256 i,
        address to,
        uint256 amount
    ) external override onlyOperator() {
        bytes32 h = keccak256(abi.encode(satelliteChain, i, to, amount));

        uint256 refundGasPrice = inwardTransferFunding[h];
        if (refundGasPrice == PROCESSED) return;
        inwardTransferFunding[h] = PROCESSED;

        wROOT.safeTransfer(to, amount);
        if (refundGasPrice != 0)
            msg.sender.sendValue(refundGasPrice * MAIN_UNLOCK_COST);

        emit CrossChainTransferUnlocked(to, amount, satelliteChain);
    }

    // Fee handling

    function accrueFees(uint224 amount) external onlyOwner() {
        accruedFees.push(
            Fees(
                safe32(
                    block.number,
                    "Multibridge::accrueFees: block number exceeds 32 bits"
                ),
                amount
            )
        );
        emit CrossChainFeeAccrual(amount);
    }

    function collectwROOT(uint256 amount) external onlyOwner() {
        wROOT.safeTransfer(msg.sender, amount);
    }
}
