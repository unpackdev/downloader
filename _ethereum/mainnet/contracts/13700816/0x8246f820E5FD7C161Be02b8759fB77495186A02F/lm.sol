// contracts/lowkeyMonkey.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract lowkeyMonkey is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    Counters.Counter private _adminTokenIds;

    uint256 public tokenPrice = 70000000000000000;   // .07 ETH

    uint256 public preSaleTokenCap = 15; // maximum number of token user can buy in a presale

    uint256 public releaseTimeSpan = 3 days;  // release after 3 days or 72 hours

    bool public saleOn = false;
    bool public preSaleOn = true;

    mapping(address => bool) public whitelisted;

    mapping(uint256 => uint256) public tokenMintedTimestamps;

    string private _metadataURI = "https://ipfs.io/ipfs/QmfBvHkqZtoRNNuVGquzVREDUrz6E4XZtH3WeymxtocPac/";

    string private _reveal_url = "https://ipfs.io/ipfs/QmNmaobB1KJW8figzJeLRMEzV1s31FyTxQBFVifYzptJ6N";

    constructor(string memory _name, string memory _symbol, uint256 _tokenPrice) ERC721(_name, _symbol) {
        tokenPrice = _tokenPrice;
    }

    event ToggleSale(bool saleOn, bool preSaleOn);

    /**
    * @dev This Function allows admin to award 50 tokens
    */
    function awardItem(address player) public onlyOwner returns (uint256)
    {
        require(_adminTokenIds.current() < 50, "lowkeyMonkey: Admin can not mint more than 50 tokens.");

        _adminTokenIds.increment();

        uint256 newItemId = _adminTokenIds.current();
        _mint(player, newItemId);
        tokenMintedTimestamps[newItemId] = block.timestamp;
        return newItemId;
    }

    /**
    * @dev This Function allows normal users to mint tokens
    */
    function buy(uint quantity) public payable {
        if (preSaleOn && !saleOn) {
            require(balanceOf(msg.sender).add(quantity) <= preSaleTokenCap, "lowkeyMonkey: presale token cap reached.");
        }else{
            require(saleOn, "lowkeyMonkey: sale is off.");
        }
        require(quantity <= 20, "lowkeyMonkey: Can not buy more than 20 tokens.");
        require(msg.value == tokenPrice.mul(quantity), "lowkeyMonkey: Supplied amount is not correct.");
        require(!preSaleOn || whitelisted[msg.sender], "lowkeyMonkey: private sale is on or user is not whitelisted.");

        for (uint256 i = 0; i < quantity; i++) {
            _tokenIds.increment();

            uint256 newItemId = _tokenIds.current().add(50);
            _mint(msg.sender, newItemId);
            tokenMintedTimestamps[newItemId] = block.timestamp;
        }

    }

    /**
    * @dev This Function update preSaleTokenCap
    */
    function updatePreSaleTokenCap(uint256 newPreSaleTokenCap) public onlyOwner {
        preSaleTokenCap = newPreSaleTokenCap;
        emit ToggleSale(saleOn, preSaleOn);
    }

    /**
    * @dev This Function toggle between presale and normal sale
    */
    function toggleSale() public onlyOwner {
        saleOn = !saleOn;
        emit ToggleSale(saleOn, preSaleOn);
    }

    /**
    * @dev This Function toggle between presale and normal sale
    */
    function togglePreSale() public onlyOwner {
        preSaleOn = !preSaleOn;
        emit ToggleSale(saleOn, preSaleOn);
    }

    /**
    * @dev This Function allows admin to change token price
    */
    function updatePrice(uint256 newPrice) public onlyOwner {
        tokenPrice = newPrice;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _metadataURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (block.timestamp > (tokenMintedTimestamps[tokenId]).add(releaseTimeSpan)) {
            string memory baseURI = _metadataURI;
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
        } else {
            return _reveal_url;
        }
    }

    function registerWhitelist(address[] memory users) public onlyOwner {
        for( uint i = 0 ; i < users.length ; i++ ) {
            whitelisted[users[i]] = true;
        }
    }

    function deregisterWhitelist(address[] memory users) public onlyOwner {
        for( uint i = 0 ; i < users.length ; i++ ) {
            whitelisted[users[i]] = false;
        }
    }
}
