// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/* Make contract verifiable when creating new NFT, and when refunding to a specific user */
contract PaymentVerifiable {
    function getMessageHash(
        address buyer_,
        address nftAddress_,
        uint256[] memory tokenId_,
        uint256 price_
    ) public pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(buyer_, nftAddress_, tokenId_, price_));
    }

    function getEthSignedMessageHash(bytes32 messageHash_)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash_
                )
            );
    }

    function verify(
        bytes memory signature_,
        address buyer_,
        address nftAddress_,
        uint256[] memory tokenId_,
        uint256 price_
    ) public pure returns (address) {
        bytes32 messageHash = getMessageHash(
            buyer_,
            nftAddress_,
            tokenId_,
            price_
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature_);

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}
