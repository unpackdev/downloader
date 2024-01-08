// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

/**
 * @title Dungeons contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract LootDungeons is ERC721, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    // Sales
    uint256 public astralPrice = 50000000000000000; // Default: 0.05 ETH
    uint256 public legendaryPrice = 300000000000000000; // Default: 0.3 ETH

    // URI
    string public baseURI;

    // Meta functionality
    mapping(uint256 => uint256) private _dungeonsToRealms;

    // Contracts
    IERC721 lootContract = IERC721(0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7);
    IERC721 realmContract = IERC721(0x7AFe30cB3E53dba6801aa0EA647A0EcEA7cBe18d);

    constructor() ERC721("Dungeons (for Adventurers)", "LootDungeon") {
    }

    function setAstralPrice(uint256 _newPrice) public onlyOwner {
        astralPrice = _newPrice;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    //Private sale minting (reserved for Loot owners)
    function claimWithLoot(uint _lootId) public nonReentrant {
        require(_lootId > 0 && _lootId < 8001, "Token ID invalid");
        require(lootContract.ownerOf(_lootId) == msg.sender, "Not the owner of this Loot");
        _safeMint(msg.sender, _lootId);
    }

    function batchClaimWithLoot(uint[] memory _lootIds) public nonReentrant {        
        for (uint i = 0; i < _lootIds.length; i++) {
            require(_lootIds[i] > 0 && _lootIds[i] < 8001, "Token ID invalid");
            require(lootContract.ownerOf(_lootIds[i]) == msg.sender, "Not the owner of this Loot");
            _safeMint(msg.sender, _lootIds[i]);
        }
    }

    // Astral minting
    function mintAstral(uint _tokenId) public payable nonReentrant {
        require(astralPrice <= msg.value, "Ether value sent is not correct");
        require(_tokenId > 8000 && _tokenId < 10001, "Token ID invalid");

        _safeMint(msg.sender, _tokenId);
    }

    function batchMintAstral(uint[] memory _tokenIds) public payable nonReentrant {
        require((astralPrice * _tokenIds.length) <= msg.value, "Ether value sent is not correct");
        
        for (uint i=0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] > 8000 && _tokenIds[i] < 10001, "Token ID invalid");

            _safeMint(msg.sender, _tokenIds[i]);
        }
    }

    // Legendary minting
    function mintLegendaryDungeon(uint256 _tokenId) public payable nonReentrant {
        require(_tokenId > 10000 && _tokenId <= 10018, "Token ID invalid");
        require(legendaryPrice <= msg.value, "Ether value sent is not correct");
        _safeMint(msg.sender, _tokenId);
    }

    // Bifrost: connects Dungeon to Realm
    // _realmId = 0 means "return to Astral"
    function createBifrostBridge(uint256 _dungeonId, uint256 _realmId) public nonReentrant {
        require(ownerOf(_dungeonId) == msg.sender, "Not an owner");
        if (_realmId > 0) {
            require(realmContract.ownerOf(_realmId) != address(0), "Realm does not exist");
        }

        _dungeonsToRealms[_dungeonId] = _realmId;
    }

    function realmOf(uint256 _dungeonId) public view returns (uint256) {
        return _dungeonsToRealms[_dungeonId];
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(0xE52ae8cf013F152aCE4323837475B0AA4e6387BC).transfer(balance);
    }
}