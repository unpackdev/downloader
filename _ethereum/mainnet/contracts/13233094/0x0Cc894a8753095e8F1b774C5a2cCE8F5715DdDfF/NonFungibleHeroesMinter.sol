// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./INonFungibleHeroesToken.sol";

contract NonFungibleHeroesMinter is Ownable, ReentrancyGuard {

    // ======== Supply =========
    uint256 public constant MAX_MINTS_PER_TX = 20;
    uint256 public constant WHITELIST_MAX_MINTS = 3;
    uint256 public maxMintsPerAddress;
    uint256 public reservedHeroes;
    uint256 public maxHeroes;

    // ======== Cost =========
    uint256 public constant HERO_COST = 0.08888 ether;

    // ======== Sale status =========
    bool public saleIsActive = false;
    uint256 public preSaleStart; // When the community + whitelist claiming/minting starts
    uint256 public publicSaleStart; // Public sale start (20 mints per tx, max 200 mints per address)

    // ======== Claim Tracking =========
    mapping(address => uint256) private addressToMintCount;
    mapping(address => uint256) private addressToClaimableHeroes;
    mapping(address => bool) private saleWhitelist;

    // ======== External Storage Contract =========
    INonFungibleHeroesToken public heroesToken;

    // ======== Constructor =========
    constructor(address nonFungibleHeroesAddress,
                uint256 preSaleStartTimestamp,
                uint256 publicSaleStartTimestamp,
                uint256 heroSupply,
                uint256 reserveSupply,
                uint256 maxMintsAddress) {
        heroesToken = INonFungibleHeroesToken(nonFungibleHeroesAddress);
        preSaleStart = preSaleStartTimestamp;
        publicSaleStart = publicSaleStartTimestamp;
        maxHeroes = heroSupply;
        reservedHeroes = reserveSupply;
        maxMintsPerAddress = maxMintsAddress;
    }

    // ======== Claim / Minting =========
    function mintCommunity(uint amount) external nonReentrant {
        require(saleIsActive, "Sale must be active to claim!");
        require(block.timestamp >= preSaleStart && block.timestamp < publicSaleStart, "Presale not active!");
        require(amount > 0, "Enter valid amount to claim");
        require(amount <= addressToClaimableHeroes[msg.sender], "Invalid hero amount!");
        require(amount <= MAX_MINTS_PER_TX, "Exceeds max mint per tx!");

        heroesToken.mint(amount, msg.sender);
        addressToClaimableHeroes[msg.sender] -= amount;
    }

    function mintPublic(uint amount) public payable nonReentrant {
        uint256 supply = heroesToken.totalSupply();
        require(saleIsActive, "Sale must be active to claim!");
        require(block.timestamp >= preSaleStart, "Sale not started!");
        require(amount <= MAX_MINTS_PER_TX, "Exceeds max mint per tx!");
        require(addressToMintCount[msg.sender] + amount <= maxMintsPerAddress, "Exceeded wallet mint limit!");

        // Whitelist period
        if (block.timestamp < publicSaleStart) {
            require(saleWhitelist[msg.sender], "Must be on the sale whitelist");
            uint256 remainingMints = WHITELIST_MAX_MINTS - addressToMintCount[msg.sender];
            require(amount <= remainingMints, "You can mint max 3 during whitelist sale");
        }

        require(supply + amount <= maxHeroes - reservedHeroes, "Exceeds max hero supply!");
        require(msg.value >= HERO_COST * amount, "Invalid Eth value sent!");

        heroesToken.mint(amount, msg.sender);
        addressToMintCount[msg.sender] += amount;
    }

    function reserveTeamTokens(address _to, uint256 _reserveAmount) public onlyOwner {        
        require(_reserveAmount <= reservedHeroes, "Not enough reserves");

        heroesToken.mint(_reserveAmount, _to);
        reservedHeroes = reservedHeroes - _reserveAmount;
    }

    // ======== Snapshot / Whitelisting
    function snapshot(address[] memory _addresses, uint[] memory _heroesToClaim) external onlyOwner {
        require(_addresses.length == _heroesToClaim.length, "Invalid snapshot data");
        for (uint i = 0; i < _addresses.length; i++) {
            addressToClaimableHeroes[_addresses[i]] = _heroesToClaim[i];
        }
    }

    function addWhitelisted(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            saleWhitelist[_addresses[i]] = true;
        }
    }

    function removeWhitelisted(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            saleWhitelist[_addresses[i]] = false;
        }
    }

    // ======== Max Minting =========
    function setMaxMintPerAddress(uint _max) public onlyOwner {
        maxMintsPerAddress = _max;
    }

    // ======== Utilities =========
    function isWhitelisted(address _address) external view returns (bool) {
        return saleWhitelist[_address];
    }

    function remainingHeroesForClaim(address _address) external view returns (uint) {
        return addressToClaimableHeroes[_address];
    }

    function mintCount(address _address) external view returns (uint) {
        return addressToMintCount[_address];
    }

    function isPreSaleActive() external view returns (bool) {
        return block.timestamp >= preSaleStart && block.timestamp < publicSaleStart && saleIsActive;
    }

    function isPublicSaleActive() external view returns (bool) {
        return block.timestamp >= publicSaleStart && saleIsActive;
    }

    // ======== State management =========
    function flipSaleStatus() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // ======== Withdraw =========
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }
}
