// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ECDSA.sol";

// Signature Verification
/// @title RedKite Whitelists - Implement off-chain whitelist and on-chain verification
/// @author CuongTran <cuong.tran@sotatek.com>

contract Signature {
    // Using Openzeppelin ECDSA cryptography library
    address public signer;

    function setSigner(address _signer) external virtual {
        signer = _signer;
    }

    function getMessageHash(
        uint256 _poolId,
        address _user,
        uint256[] memory _ids,
        uint256[] memory _prices,
        uint256[] memory _tiers
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _poolId,
                    _user,
                    _ids,
                    _prices,
                    _tiers
                )
            );
    }

    function getBoostCardsMessageHash(
        uint256 _poolId,
        address _user,
        uint256 _ids,
        uint256 _prices,
        uint256 _tiers,
        uint256 _boostId
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _poolId,
                    _user,
                    _ids,
                    _prices,
                    _tiers,
                    _boostId
                )
            );
    }

    // Verify signature function
    function _verifyStakeCardsSignature(
        bytes32 _msgHash,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(_msgHash);

        return getSignerAddress(ethSignedMessageHash, signature) == signer;
    }

    function getSignerAddress(bytes32 _messageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        return ECDSA.recover(_messageHash, _signature);
    }

    // Split signature to r, s, v
    function splitSignature(bytes memory _signature)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_signature.length == 65, "invalid signature length");

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(_messageHash);
    }
}
