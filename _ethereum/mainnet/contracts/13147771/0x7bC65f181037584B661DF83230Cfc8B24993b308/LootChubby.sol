// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Tradable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface ILoot {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract LootChubby is ERC721Tradable, ReentrancyGuard {
    uint256 constant PREMINT = 10;
    uint256 constant MAX_LOOT_ID = 8000;
    uint256 constant LOOT_RESERVED = 3000;
    uint256 constant MINT_PRICE = 20000000000000000; // 0.02 ether
    uint256 constant MAX_SUPPLY = 10000;

    uint256 public totalClaimed;
    address public lootAddress;
    bool public isPreminted;

    mapping(uint256 => bool) claimedToken;

    constructor(address lootAddress_, address proxyRegistryAddress_)
        ERC721Tradable("LootChubby", "CHUBBY", proxyRegistryAddress_)
    {
        lootAddress = lootAddress_;
        _currentTokenId = LOOT_RESERVED + PREMINT;
    }

    function baseTokenURI() public pure override returns (string memory) {
        return "ipfs://QmVRUcnhZhyk1osRyKBRZeXXDkqEYqrxqcoYD52yzVaW1V/";
    }

    function claim(uint256 tokenId) public nonReentrant returns (uint256) {
        require(totalClaimed < LOOT_RESERVED, "claims no longer available");

        require(tokenId > 0 && tokenId <= MAX_LOOT_ID, "invalid token id");

        ILoot loot = ILoot(lootAddress);
        require(loot.ownerOf(tokenId) == _msgSender(), "not owner");

        require(!claimedToken[tokenId], "token already claimed");

        uint256 newTokenId = totalClaimed + 1;
        _mint(_msgSender(), newTokenId);

        claimedToken[tokenId] = true;
        totalClaimed++;

        return newTokenId;
    }

    function mint() public payable nonReentrant returns (uint256) {
        require(totalSupply() < MAX_SUPPLY, "minting period finished");
        require(msg.value >= MINT_PRICE, "minting costs 0.02 ether");

        uint256 newTokenId = _getNextTokenId();
        _mint(_msgSender(), newTokenId);
        _incrementTokenId();

        return newTokenId;
    }

    function premint() public onlyOwner {
        require(totalSupply() < MAX_SUPPLY, "minting period finished");
        require(!isPreminted, "premint not available");

        for (uint256 i = 1; i <= PREMINT; i++) {
            uint256 newTokenId = LOOT_RESERVED + i;
            _mint(_msgSender(), newTokenId);
        }

        isPreminted = true;
    }

    function withdraw() public onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    // function setTotalClaimed(uint256 i) public onlyOwner {
    //     totalClaimed = i;
    // }
}
