//SPDX-License-Identifier: MIT

// @title:  BONANZA BEARS
// @desc:   THE BONANZA BEARS COLLECTION
// @dev:    https://twitter.com/bonanzabears
// @url:    https://www.bonanzabears.com/

pragma solidity ^0.8.6;
import "./Ownable.sol";
import "./ERC721.sol";

contract BonanzaBears is ERC721, Ownable {

     // ======== Token Counter =========
    uint256 private tokenSupply;

    // ======== Mint Information =========
    uint private currentMintPrice;

    // ======== Token URI Mapping =========
    mapping (uint256 => string) private _tokenURIs;

    constructor() ERC721("Bonanza Bears", "BB") {
        // ======== Set initial mint price =========
        currentMintPrice = 0.00001 ether;
    }

    // ======== Get tokenSupply =========
    function totalSupply() public view returns (uint256) {
        return tokenSupply;
    }

    // ======== Get currentMintPrice =========
    function getMintPrice() public view returns (uint256) {
        return currentMintPrice;
    }

    // ======== Get token URI =========
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    // ======== Public minting function =========
    function mintToken() external payable {
        uint256 supply = totalSupply();
        require(msg.value >= currentMintPrice, "Not enough eth sent");

        _safeMint(msg.sender, supply + 1);   
        tokenSupply++;
        // ======== Double the mint price =========
        currentMintPrice = currentMintPrice * 2;
    }

    // ======== Set token id =========
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");

        // ======== Metadata can only be set once =========
        require(bytes(_tokenURIs[tokenId]).length == 0, "Metadata has already been set");
        _tokenURIs[tokenId] = _tokenURI;
    }

    // ======== Withdraw =========
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdraw failed");
    }
}