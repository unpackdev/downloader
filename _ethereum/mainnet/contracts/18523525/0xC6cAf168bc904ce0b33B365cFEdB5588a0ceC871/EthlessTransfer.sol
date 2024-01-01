// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./GluwacoinBase.sol";
import "./ERC20Upgradeable.sol";
import "./Validate.sol";
import "./SignerNonce.sol";

contract EthlessTransfer is GluwacoinBase, SignerNonce, ERC20Upgradeable  {
    /**
     * @dev Allow a account to transfer tokens of a account that allow it via ERC191 signature and collect fee
     */
    function transfer(
        address sender,
        address recipient,
        uint256 amount,
        uint256 fee,
        uint256 gluwaNonce,
        bytes calldata sig
    ) external virtual returns (bool success) {
        unchecked {
            _useNonce(sender, gluwaNonce);
            bytes32 hash_ = keccak256(
                abi.encodePacked(
                    _GENERIC_SIG_TRANSFER_DOMAIN,
                    block.chainid,
                    address(this),
                    sender,
                    recipient,
                    amount,
                    fee,
                    gluwaNonce
                )
            );
            Validate._validateSignature(hash_, sender, sig);
            _transfer(sender, _msgSender(), fee);
            _transfer(sender, recipient, amount);
            return true;
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}