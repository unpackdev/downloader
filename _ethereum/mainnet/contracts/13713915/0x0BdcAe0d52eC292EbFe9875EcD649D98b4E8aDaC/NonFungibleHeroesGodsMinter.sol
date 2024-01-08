// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./INonFungibleHeroesGodsToken.sol";

contract NonFungibleHeroesGodsMinter is Ownable, ReentrancyGuard {

    // ======== Supply =========
    uint256 public constant MAX_MINTS_PER_TX = 20;
    uint256 public maxMintsPerAddress;
    uint256 public maxGods;

    // ======== Cost =========
    uint256 public constant GOD_COST = 0.06666 ether;

    // ======== Sale status =========
    bool public saleIsActive = false;
    uint256 public preSaleStart; // When the whitelist claiming/minting starts
    uint256 public communitySaleStart; // When the free Gods claiming/minting starts
    uint256 public publicSaleStart; // Public sale start (20 mints per tx, max 200 mints per address)

    // ======== Claim Tracking =========
    mapping(address => uint256) private addressToMintCount;
    mapping(address => uint256) private addressToClaimableGods;
    mapping(address => uint256) private saleWhitelist;

    // ======== External Storage Contract =========
    INonFungibleHeroesGodsToken public godsToken;

    // ======== Constructor =========
    constructor(address nonFungibleHeroesAddress,
                uint256 preSaleStartTimestamp,
                uint256 communitySaleStartTimestamp,
                uint256 publicSaleStartTimestamp,
                uint256 godSupply,
                uint256 maxMintsAddress) {
        godsToken = INonFungibleHeroesGodsToken(nonFungibleHeroesAddress);
        preSaleStart = preSaleStartTimestamp;
        communitySaleStart = communitySaleStartTimestamp;
        publicSaleStart = publicSaleStartTimestamp;
        maxGods = godSupply;
        maxMintsPerAddress = maxMintsAddress;
    }

    // ======== Claim / Minting =========
    function mintCommunity(uint amount) external nonReentrant {
        require(saleIsActive, "Sale must be active to claim!");
        require(block.timestamp >= communitySaleStart && block.timestamp < publicSaleStart, "Community sale not active!");
        require(amount > 0, "Enter valid amount to claim");
        require(amount <= addressToClaimableGods[msg.sender], "Invalid hero amount!");
        require(amount <= MAX_MINTS_PER_TX, "Exceeds max mint per tx!");

        godsToken.mint(amount, msg.sender);
        addressToClaimableGods[msg.sender] -= amount;
    }

    function mintPublic(uint amount) public payable nonReentrant {
        uint256 supply = godsToken.totalSupply();
        require(saleIsActive, "Sale must be active to claim!");
        require(block.timestamp >= preSaleStart, "Sale not started!");
        require(amount <= MAX_MINTS_PER_TX, "Exceeds max mint per tx!");
        require(addressToMintCount[msg.sender] + amount <= maxMintsPerAddress, "Exceeded wallet mint limit!");

        // Whitelist period
        if (block.timestamp < publicSaleStart) {
            require(saleWhitelist[msg.sender] > 0, "Must be on the sale whitelist");
        }

        require(supply + amount <= maxGods, "Exceeds max hero supply!");
        require(msg.value >= GOD_COST * amount, "Invalid ETH value sent!");

        godsToken.mint(amount, msg.sender);

        addressToMintCount[msg.sender] += amount;
        
        if (block.timestamp < publicSaleStart) {
            saleWhitelist[msg.sender] -= amount;
        }
    }

    function reserveTeamTokens(address _to, uint256 _reserveAmount) public onlyOwner {
        uint256 supply = godsToken.totalSupply();
        require(supply + _reserveAmount <= maxGods, "Exceeds max hero supply!");
        godsToken.mint(_reserveAmount, _to);
    }

    // ======== Snapshot / Whitelisting
    function snapshot(address[] memory _addresses, uint[] memory _godsToClaim) external onlyOwner {
        require(_addresses.length == _godsToClaim.length, "Invalid snapshot data");
        for (uint i = 0; i < _addresses.length; i++) {
            addressToClaimableGods[_addresses[i]] = _godsToClaim[i];
        }
    }

    function addWhitelisted(address[] memory _addresses, uint[] memory _godsToClaim) external onlyOwner {
        require(_addresses.length == _godsToClaim.length, "Invalid whitelist data");
        for (uint256 i = 0; i < _addresses.length; i++) {
            saleWhitelist[_addresses[i]] = _godsToClaim[i];
        }
    }

    // ======== Max Minting =========
    function setMaxMintPerAddress(uint _max) public onlyOwner {
        maxMintsPerAddress = _max;
    }

    // ======== Utilities =========
    function remainingWhitelistGodsForClaim(address _address) external view returns (uint) {
        return saleWhitelist[_address];
    }

    function remainingGodsForClaim(address _address) external view returns (uint) {
        return addressToClaimableGods[_address];
    }

    function mintCount(address _address) external view returns (uint) {
        return addressToMintCount[_address];
    }

    function isPreSaleActive() external view returns (bool) {
        return block.timestamp >= preSaleStart && block.timestamp < publicSaleStart && saleIsActive;
    }

    function isCommunitySaleActive() external view returns (bool) {
        return block.timestamp >= communitySaleStart && block.timestamp < publicSaleStart && saleIsActive;
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
