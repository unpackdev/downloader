// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: DirtyPanties
/// @author: devcryptodude
/// @twitter: https://twitter.com/dirtypantiesnft

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

import "./ERC721a.sol";

contract DirtyPanties is ReentrancyGuard, ERC721A, Ownable{

    using Strings for uint256;

    uint256 public maxRewardsPanties = 300;
    uint256 public RewardsPantiesClaim;

    uint256 public mintPrice = 0 ether;
    uint256 constant public maxPanties = 6969;

    /* royalties */
    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;

    bool public MintActivated; 

    string private _prefixURI;

    event Activate();
    event SetPrefixURI(string prefixURI);

    constructor()  ERC721A("DirtyPanties NFT","DPNFT",30,6969) {
       _royaltyRecipient = payable(msg.sender);
       _royaltyBps = 750;
       _prefixURI = "https://api.dirtypanties.xyz/metadatafree/";
    }

    function updateRoyalties(address payable recipient, uint256 bps) external onlyOwner {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

   function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return  interfaceId == type(IERC721Receiver).interfaceId || ERC721A.supportsInterface(interfaceId) || interfaceId == this.royaltyInfo.selector ;
    }


    function _mintPanties(address recipient, uint256 value) private {
        _safeMint(recipient, value);
    }

    function changeMintPrice(uint256 _mintPrice) external onlyOwner{
        mintPrice = _mintPrice;
    }

    function enableRedemption(bool _MintActivated) external onlyOwner {
        MintActivated = _MintActivated;
        emit Activate();
    }


    function setPrefixURI(string calldata uri) external onlyOwner {
        _prefixURI = uri;

        emit SetPrefixURI(_prefixURI);
    }

     function TeamMint(
        uint256 value,
        address recipient
    ) public nonReentrant onlyOwner{

        require(MintActivated, "Inactive");
        require(value > 0 && value <= 30, "Bad value");
        require(totalSupply() + value <= maxPanties, "Too many Claimed");

        RewardsPantiesClaim += value;

        require(RewardsPantiesClaim <= maxRewardsPanties , "TC" );

        _mintPanties(recipient, value);
    }

 
    function publicMint(uint256 value) public payable nonReentrant{

        require(msg.sender == tx.origin, "ONLY EOA");

        require(MintActivated , "Redemption inactive");
        require(value > 0 && value <= 3 &&  msg.value ==  (value * mintPrice), "Invalid eth sent");
        require(totalSupply() - RewardsPantiesClaim + value <= maxPanties - maxRewardsPanties , "Too many Claimed");

        _mintPanties(msg.sender, value);
    }


    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        require(_exists(tokenId), "ERC721A: URI query for nonexistent token");
        return string(abi.encodePacked(_prefixURI, tokenId.toString()));
    }


    function withdraw() external onlyOwner{
       uint balance = address(this).balance;
       require(balance > 0, "BB");
       (bool success, ) = payable(msg.sender).call{value: balance}("");
       require(success, "ETH failed");
    }


    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }


}
