// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./ECDSAUpgradeable.sol";
import "./ExtendedERC20.sol";
import "./Validate.sol";
import "./GluwacoinModels.sol";

/**
 * @dev Extension of {ERC20} that allows users to escrow a transfer. When the fund is reserved, the sender designates
 * an `executor` of the `reserve`. The `executor` can `release` the fund to the pre-defined `recipient` and collect
 * a `fee`. If the `reserve` gets expired without getting executed, the `sender` or the `executor` can `reclaim`
 * the fund back to the `sender`.
 */
contract ERC20Transfer is ExtendedERC20 {
    using ECDSAUpgradeable for bytes32;

    function __ERC20Transfer_init() internal onlyInitializing {
        __ERC20Transfer_init_unchained();
    }

    function __ERC20Transfer_init_unchained() internal onlyInitializing {}

    function transfer(
        address sender,
        address recipient,
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        bytes memory sig
    ) public returns (bool success) {
        _useNonce(sender, GluwacoinModels.SigDomain.Transfer, nonce); // 3 = Transfer
        uint256 totalAmount;
        unchecked {
            totalAmount = amount + fee;
        }
        _beforeTokenTransfer(sender, recipient, totalAmount);
        bytes32 hash = keccak256(
            abi.encodePacked(
                GluwacoinModels.SigDomain.Transfer,
                chainId(),
                address(this),
                sender,
                recipient,
                amount,
                fee,
                nonce
            )
        );
        Validate.validateSignature(hash, sender, sig);

        _collect(sender, fee, msg.sender);
        _transfer(sender, recipient, amount);

        return true;
    }

    uint256[50] private __gap;
}
