// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Structs.sol";

library SignatureUtils {
    
    /**
     * @dev To hash the transfer data into bytes32 
     * @param _data the transfer data
     * @return hash the hash of transfer data
     */
    function getMessageHash(TransferData memory _data)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    _data.fromToken,
                    _data.toToken,
                    _data.fromAddress,
                    _data.toAddress,
                    _data.amount,
                    _data.internalTxId
                )
            );
    }

    /**
     * @dev To get the eth-signed message of hash
     * @param _messageHash the hash of transfer data
     * @return ethSignedMessage the eth signed message hash
     */
    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    /**
     * @dev To verify the transfer data and transfer signature
     * @param _data the transfer data
     * @param _signature the signature of transfer
     * @return result true/false
     */
    function verify(TransferData memory _data, bytes memory _signature, address _signer)
        internal
        pure
        returns (bool)
    {
        bytes32 messageHash = getMessageHash(_data);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == _signer;
    }

    /**
     * @dev To recover the signer from signature and hash
     * @param _hash the hash of transfer data
     * @param _signature the signature which was signed by the admin
     * @return signer the address of signer
     */
    function recoverSigner(bytes32 _hash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (_signature.length != 65) {
            return (address(0));
        }

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(_hash, v, r, s);
        }
    }
}
// ["0xeDb21A5bAdc10a5233767e6019C1a92AE6D14793", "0x577f0d8EE0e2C570fbC4f1f98beB85A848ef7556", "0xa781bc9ef3dc0d1e13f973264ff49531a1c84577", "0xa781bc9ef3dc0d1e13f973264ff49531a1c84577", 100000000, "62329a1cabac1e4302f4a07f"]