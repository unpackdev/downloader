// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Signatures {
    bytes private constant _PREFIX = "\x19Ethereum Signed Message:\n32";

    function recoverAddressBulk(
        uint256 tokenId,
        string[] memory _tokenURIs,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address) {
        bytes32 h = keccak256(abi.encode(this, tokenId, _tokenURIs));
        address _address = ecrecover(h, v, r, s);

        return _address;
    }

    function recoverAddress(
        uint256 tokenId,
        string memory _tokenURI,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address) {
        bytes32 h = keccak256(abi.encode(this, tokenId, _tokenURI));
        address _address = ecrecover(h, v, r, s);

        return _address;
    }

    /**
     * @dev Personal: recovers the address from a personal sign from the user
     */
    function recoverPersonalAddressBulk(
        uint256 tokenId,
        string[] memory _tokenURIs,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address) {
        bytes32 h = keccak256(abi.encode(this, tokenId, _tokenURIs));
        bytes32 prefixedHash = keccak256(abi.encodePacked(_PREFIX, h));
        address _address = ecrecover(prefixedHash, v, r, s);

        return _address;
    }

    function recoverPersonalAddress(
        uint256 tokenId,
        string memory _tokenURI,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address) {
        bytes32 h = keccak256(abi.encode(this, tokenId, _tokenURI));
        bytes32 prefixedHash = keccak256(abi.encodePacked(_PREFIX, h));
        return ecrecover(prefixedHash, v, r, s);
    }

    function recoverPersonal(
        bytes memory input,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        bytes32 h = keccak256(input);
        bytes32 prefixedHash = keccak256(abi.encodePacked(_PREFIX, h));
        return ecrecover(prefixedHash, v, r, s);
    }
}
