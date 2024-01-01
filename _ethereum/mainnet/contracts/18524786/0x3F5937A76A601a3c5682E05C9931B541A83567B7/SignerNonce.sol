// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./ContextUpgradeable.sol";

contract SignerNonce is ContextUpgradeable {
    mapping(bytes32 => bool) private _nonceUsed;

    /**
     * @dev Allow sender to check if the nonce is used.
     */
    function isNonceUsed(uint256 nonce) public view virtual returns (bool) {
        return _isNonceUsed(_nonceSig(_msgSender(), nonce));
    }

    /**
     * @dev Allow sender to check if the nonce is used.
     */
    function revokeSignature(uint256 nonce) external virtual returns (bool) {
        _nonceUsed[_nonceSig(_msgSender(), nonce)] = true;
        return true;
    }

    /**
     * @dev Check whether a nonce is used for a signer.
     */
    function _isNonceUsed(bytes32 nonceSig)
        private
        view
        returns (bool)
    {
        return _nonceUsed[nonceSig];
    }

    /**
     * @dev Create nonce signature.
     */
    function _nonceSig(address signer, uint256 nonce)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(signer, nonce));
    }

    /**
     * @dev Register a nonce for a signer.
     */
    function _useNonce(address signer, uint256 nonce) internal {
        bytes32 nonceSig = _nonceSig(signer, nonce);
        require(!_isNonceUsed(nonceSig), "SignerNonce: Invalid Nonce");
        _nonceUsed[nonceSig] = true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
