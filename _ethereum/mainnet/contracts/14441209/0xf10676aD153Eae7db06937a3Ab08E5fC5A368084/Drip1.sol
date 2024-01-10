// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";

contract Drip1 is ERC721, ERC721Enumerable, Pausable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint256 public mintPrice = 2000000000000000;
    uint256 public presales;
    uint256 public sale;
    uint256 public MAX_PRESALE = 5;
    uint256 public MAX_SALE = 5;
    uint256 public redeemTime;
    mapping(uint256 => address) public redeemed;

    constructor() ERC721("MyToken", "MTK") {
        redeemTime = 1647340592;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://mainnet-sample-assets.s3.eu-west-2.amazonaws.com/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function presale(address to) external onlyOwner {
        unchecked {
            presales += 1;
        }
        require(presales <= MAX_PRESALE, "Presale supply exceeded");
        require(totalSupply() <= (MAX_PRESALE + MAX_SALE), "Purchase: Max supply reached");
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    function mintNFT() payable external nonReentrant whenNotPaused{
        unchecked {
            sale += 1;
        }
        require(sale <= MAX_SALE, "sale supply exceeded");
        require(totalSupply() <= (MAX_PRESALE + MAX_SALE), "Purchase: Max supply reached");
        require(msg.value == mintPrice, "Purchase: Incorrect payment");
        (bool sent, ) = owner().call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
    }

    function redeem(uint256 tokenId) external whenNotPaused{
        require(ownerOf(tokenId) == msg.sender, "Not the current owner of token");
        require(redeemed[tokenId] == address(0), "Token redeemed");
        require(block.timestamp>=redeemTime, "Redeem time is yet to begin");
        redeemed[tokenId] = msg.sender;
    }

    function getIdsOwnedUnRedeemed(address user) public view returns(uint256[] memory) {    
    uint256 numTokens = balanceOf(user);
    uint256[] memory uriList = new uint256[](numTokens);
    for (uint256 i; i < numTokens; i++) {
        uint256 tok  = tokenOfOwnerByIndex(user, i);
        if(redeemed[tok]==address(0)){
            uriList[i] = tok;
        }
    }
    return(uriList);
    }

    function updateRedeemTime(uint256 _time) external onlyOwner {
        redeemTime = _time;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}