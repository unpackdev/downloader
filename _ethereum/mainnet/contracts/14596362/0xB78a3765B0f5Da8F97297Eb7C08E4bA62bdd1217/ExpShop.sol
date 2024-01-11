// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract ExpShop is Ownable {
    // verification
    using ECDSA for bytes32;
    address private _signer = 0xBc9eebF48B2B8B54f57d6c56F41882424d632EA7;
    mapping(bytes32 => bool) private _usedKey;

    event Claimed(address indexed from, bytes32 indexed key, address contractAddress, uint tokenId);

    function claim(bytes32 _key, bytes calldata _signature, uint _timestamp, address _contractAddress, uint _tokenId) external {
        require(IERC721(_contractAddress).isApprovedForAll(owner(), address(this)), "Token is not approved");
        require(!_usedKey[_key], "Key has been used");
        require(block.timestamp < _timestamp, "Expired claim time");
        require(keccak256(abi.encode(msg.sender, "shop", _contractAddress, _tokenId, _timestamp, _key)).toEthSignedMessageHash().recover(_signature) == _signer, "Invalid signature");
        _usedKey[_key] = true;
        IERC721(_contractAddress).transferFrom(owner(), msg.sender, _tokenId);
        emit Claimed(msg.sender, _key, _contractAddress, _tokenId);
    }

    function setSignerAddress(address _address) external onlyOwner {
        _signer = _address;
    }
}