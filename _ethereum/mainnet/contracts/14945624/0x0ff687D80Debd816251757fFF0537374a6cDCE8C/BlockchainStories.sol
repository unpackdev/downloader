// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract BlockchainStories is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => bool) public updatedAfterMint;
    mapping(uint256 => string) public tokenToMsg;
    mapping(uint256 => uint256) public tokenToTimestamp;
    mapping(uint256 => uint256) public tokenToOwnerWealth;

    uint256 public minFee = 0.005 ether;


    constructor() ERC721("BlockchainStories", "BSR") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://blockchainstories.xyz/api/nft/";
    }

    function updateFee(uint256 newFee) public onlyOwner {
        minFee = newFee;
    }

    function payToMint(address recipient, string memory metadataURI, string memory message
    ) public payable returns (uint256) {
        require (msg.value >= minFee, 'Not enough funds');
        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _mint(recipient, newItemId);
        _setTokenURI(newItemId, metadataURI);
        tokenToMsg[newItemId] = message;
        tokenToTimestamp[newItemId] = block.timestamp;
        tokenToOwnerWealth[newItemId] = recipient.balance;
        updatedAfterMint[newItemId] = false;

        return newItemId;
    }

    function updateMsg(uint256 tokenId, string memory newMsg) public payable{
        require(ownerOf(tokenId)==msg.sender, 'You are not the owner');
        updatedAfterMint[tokenId] = true;
        tokenToMsg[tokenId] = newMsg;
    }

    function changedAfterMint(uint256 tokenId) public view returns (bool){
        return (updatedAfterMint[tokenId]);
    }
    function tokenMsg(uint256 tokenId) public view returns (string memory){
        return (tokenToMsg[tokenId]);
    }
    function tokenTimestamp(uint256 tokenId) public view returns (uint256){
        return (tokenToTimestamp[tokenId]);
    }
    function tokenOwnerWealth(uint256 tokenId) public view returns (uint256){
        return (tokenToOwnerWealth[tokenId]);
    }
    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }


    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}