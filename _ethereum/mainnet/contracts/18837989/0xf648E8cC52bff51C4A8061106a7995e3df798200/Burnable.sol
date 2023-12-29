// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./GluwacoinBase.sol";
import "./ERC20Upgradeable.sol";
import "./Validate.sol";
import "./SignerNonce.sol";

contract Burnable is GluwacoinBase, SignerNonce, ERC20Upgradeable {
    event Burn(address indexed account, uint256 indexed amount);

    /**
     * @dev Allow a account to burn tokens of a account that allow it via ERC191 signature and collect fee
     */
    function burn(
        address burner,
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        bytes calldata sig
    ) external virtual returns (bool success) {
        unchecked {
            _useNonce(burner, nonce);
            bytes32 hash_ = keccak256(
                abi.encodePacked(
                    _GENERIC_SIG_BURN_DOMAIN,
                    block.chainid,
                    address(this),
                    burner,
                    amount,
                    fee,
                    nonce
                )
            );
            Validate._validateSignature(hash_, burner, sig);
            if (fee > 0) _transfer(burner, _msgSender(), fee);
        }
        return _executeBurn(burner, amount - fee);
    }

    function burn(uint256 amount) external returns (bool) {
        return _executeBurn(_msgSender(), amount);
    }

    function _executeBurn(
        address burner,
        uint256 amount
    ) private returns (bool) {
        _burn(burner, amount);
        emit Burn(burner, amount);
        return true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
