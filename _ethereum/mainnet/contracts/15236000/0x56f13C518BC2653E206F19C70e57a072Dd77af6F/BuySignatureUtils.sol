// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// Signature Verification

contract BuySignatureUtils {
    function getBuyMessageHash(
        string memory _uuid,
        address _to,
        uint256 _quantity,
        address _payer,
        uint256 _userType
    ) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_uuid, _to, _quantity, _payer, _userType));
    }


    // Verify signature function
    function verifyBuySignature(
        address _signer,
        string memory _uuid,
        address _to,
        uint256 _quantity,
        address _payer,
        uint256 _userType,
        bytes memory _signature
    ) public pure returns (bool) {
        bytes32 messageHash = getBuyMessageHash(_uuid, _to, _quantity, _payer, _userType);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(ethSignedMessageHash, v, r, s) == _signer;
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
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );

    }
}
