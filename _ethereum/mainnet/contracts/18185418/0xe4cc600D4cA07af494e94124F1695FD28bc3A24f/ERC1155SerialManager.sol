// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract ERC1155SerialManager is Initializable, OwnableUpgradeable {
    // Mapping from tokenId to array of serialNumbers
    mapping(uint256 => uint256[]) public tokenIdToSerials;

    // Mapping from a keccak256 hash of tokenId and serialNumber to owner
    mapping(bytes32 => address) public tokenSerialToOwner;

    function initialize() public initializer {
        __Ownable_init();
    }
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    
    // To generate the same hash in JavaScript using web3.js, you can use the following code:
    // const tokenId = 'yourTokenId';
    // const serialNumber = 'yourSerialNumber';
    // const hash = web3.utils.soliditySha3(tokenId, serialNumber);
    function mint(address to, uint256 tokenId, uint256 serialNumber, bytes32 _hash) public onlyOwner {
        tokenIdToSerials[tokenId].push(serialNumber);
        tokenSerialToOwner[_hash] = to;
        emit TransferSingle(_msgSender(), address(0), to, tokenId, serialNumber);
    }

    // Optimized bulk minting function
    function bulkMint(
        address[] calldata recipients,
        uint256[] calldata tokenIds, 
        uint256[] calldata serialNumbers, 
        bytes32[] calldata hashes
    ) 
        external 
        onlyOwner 
    {
        uint256 length = recipients.length;
        require(
            length == tokenIds.length && 
            length == serialNumbers.length && 
            length == hashes.length,
            "Array lengths must match"
        );

        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 serialNumber = serialNumbers[i];
            address recipient = recipients[i];
            bytes32 _hash = hashes[i];
            mint(recipient, tokenId, serialNumber, _hash);
        }
    }

    function transfer(address to, uint256 tokenId) public  {
        require(tokenIdToSerials[tokenId].length > 0, "Insufficient balance");
        uint256 serialNumber = tokenIdToSerials[tokenId][tokenIdToSerials[tokenId].length - 1];
        tokenIdToSerials[tokenId].pop();
        bytes32 hash = keccak256(abi.encodePacked(tokenId, serialNumber));
        tokenSerialToOwner[hash] = to;
    }

    function burn(uint256 tokenId) public onlyOwner {
        require(tokenIdToSerials[tokenId].length > 0, "Insufficient balance");
        uint256 serialNumber = tokenIdToSerials[tokenId][tokenIdToSerials[tokenId].length - 1];
        tokenIdToSerials[tokenId].pop();
        bytes32 hash = keccak256(abi.encodePacked(tokenId, serialNumber));
        delete tokenSerialToOwner[hash];
    }
}

