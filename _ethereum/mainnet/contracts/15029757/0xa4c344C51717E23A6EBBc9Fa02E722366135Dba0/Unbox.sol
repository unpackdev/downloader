// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract Unbox is Ownable, ERC721A, ReentrancyGuard {  
    using Strings for uint256;

    string public _baseURIextended = "";

    bool public pauseMint = true;

    uint256 public constant MAX_NFT_SUPPLY = 300;
        
    constructor() ERC721A("Unbox", "$UNBOX") {
    }

    function mintNFTForOwner(uint256 _amount) public onlyOwner {
        require(!pauseMint, "Paused!");
        require(totalSupply() <= MAX_NFT_SUPPLY, "Sale has already ended");

        _safeMint(msg.sender, _amount);
    }

    function withdraw() public onlyOwner() {
        uint balance = address(this).balance;
        address payable ownerAddress = payable(msg.sender);
        ownerAddress.transfer(balance);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(_baseURIextended).length > 0 ? string(abi.encodePacked(_baseURIextended, tokenId.toString(), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function pause() public onlyOwner {
        pauseMint = true;
    }

    function unPause() public onlyOwner {
        pauseMint = false;
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}