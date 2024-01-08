// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IOrdinaryOctoToken.sol";

contract OrdinaryOctoMinter is Ownable, ReentrancyGuard {

    // ======== Supply =========
    uint256 public constant MAX_MINTS_PER_TX = 20;
    uint256 public constant WHITELIST_MAX_MINTS = 3;
    uint256 public maxMintsPerAddress;
    uint256 public reservedOctos;
    uint256 public maxOctos;

    // ======== Cost =========
    uint256 public OCTO_COST = 0.08888 ether;

    // ======== Sale status =========
    bool public saleIsActive = false;
    uint256 public preSaleStart; // When the community + whitelist claiming/minting starts
    uint256 public publicSaleStart; // Public sale start (20 mints per tx, max 200 mints per address)

    // ======== Claim Tracking =========
    mapping(address => uint256) private addressToMintCount;
    mapping(address => uint256) private addressToClaimableOctos;
    mapping(address => bool) private saleWhitelist;

    // ======== External Storage Contract =========
    IOrdinaryOctoToken public OctosToken;

    // ======== Constructor =========
    constructor(address OrdinaryOctoAddress,
                uint256 preSaleStartTimestamp,
                uint256 publicSaleStartTimestamp,
                uint256 OctoSupply,
                uint256 reserveSupply,
                uint256 maxMintsAddress) {
        OctosToken = IOrdinaryOctoToken(OrdinaryOctoAddress);
        preSaleStart = preSaleStartTimestamp;
        publicSaleStart = publicSaleStartTimestamp;
        maxOctos = OctoSupply;
        reservedOctos = reserveSupply;
        maxMintsPerAddress = maxMintsAddress;
    }
    // changing mint price
    function mintprice(uint256 price) external onlyOwner {
        OCTO_COST = price * 0.01 ether;
        
    } 
        
        
    // ======== Claim / Minting =========
    function mintCommunity(uint amount) external nonReentrant {
        require(saleIsActive, "Sale must be active to claim!");
        require(block.timestamp >= preSaleStart && block.timestamp < publicSaleStart, "Presale not active!");
        require(amount > 0, "Enter valid amount to claim");
        require(amount <= addressToClaimableOctos[msg.sender], "Invalid Octo amount!");
        require(amount <= MAX_MINTS_PER_TX, "Exceeds max mint per tx!");

        OctosToken.mint(amount, msg.sender);
        addressToClaimableOctos[msg.sender] -= amount;
    }
    
    function mintPublic(uint amount) public payable nonReentrant {
        uint256 supply = OctosToken.totalSupply();
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

        require(supply + amount <= maxOctos - reservedOctos, "Exceeds max Octo supply!");
        require(msg.value >= OCTO_COST * amount, "Invalid Eth value sent!");

        OctosToken.mint(amount, msg.sender);
        addressToMintCount[msg.sender] += amount;
    }

    function reserveTeamTokens(address _to, uint256 _reserveAmount) public onlyOwner {        
        require(_reserveAmount <= reservedOctos, "Not enough reserves");

        OctosToken.mint(_reserveAmount, _to);
        reservedOctos = reservedOctos - _reserveAmount;
    }

    // ======== Snapshot / Whitelisting
    function snapshot(address[] memory _addresses, uint[] memory _OctosToClaim) external onlyOwner {
        require(_addresses.length == _OctosToClaim.length, "Invalid snapshot data");
        for (uint i = 0; i < _addresses.length; i++) {
            addressToClaimableOctos[_addresses[i]] = _OctosToClaim[i];
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

    function remainingOctosForClaim(address _address) external view returns (uint) {
        return addressToClaimableOctos[_address];
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
    
    function withdraww(uint _amount, address _address) public payable onlyOwner {
        uint balancee = (_amount / address(this).balance) * _amount;
        require(payable(_address).send(balancee));
    }
   

}
    