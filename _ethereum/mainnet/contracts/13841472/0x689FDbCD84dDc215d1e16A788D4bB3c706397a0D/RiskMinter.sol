// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IRiskToken.sol";

contract RiskMinter is Ownable, ReentrancyGuard {

    // ======== Supply =========
    uint256 public constant MAX_MINTS_PER_TX = 20;
    uint256 public maxMintsPerAddress;
    uint256 public maxTokens;

    // ======== Cost =========
    uint256 public constant TOKEN_COST = 0.07 ether;

    // ======== Sale status =========
    bool public saleIsActive = false;
    uint256 public preSaleStart; // When the whitelist claiming/minting starts
    uint256 public publicSaleStart; // Public sale start (20 mints per tx, max 200 mints per address)

    // ======== Claim Tracking =========
    mapping(address => uint256) private addressToMintCount;
    mapping(address => uint256) private saleWhitelist;

    // ======== External Storage Contract =========
    IRiskToken public riskToken;

    // ======== Constructor =========
    constructor(address riskNftAddress,
                uint256 preSaleStartTimestamp,
                uint256 publicSaleStartTimestamp,
                uint256 riskTokenSupply,
                uint256 maxMintsAddress) {
        riskToken = IRiskToken(riskNftAddress);
        preSaleStart = preSaleStartTimestamp;
        publicSaleStart = publicSaleStartTimestamp;
        maxTokens = riskTokenSupply;
        maxMintsPerAddress = maxMintsAddress;
    }

    // ======== Claim / Minting =========
    function mintPublic(uint amount) public payable nonReentrant {
        uint256 supply = riskToken.tokenCount();
        require(saleIsActive, "Sale must be active to claim!");
        require(block.timestamp >= preSaleStart, "Sale not started!");
        require(amount <= MAX_MINTS_PER_TX, "Exceeds max mint per tx!");
        require(addressToMintCount[msg.sender] + amount <= maxMintsPerAddress, "Exceeded wallet mint limit!");

        // Whitelist period
        if (block.timestamp < publicSaleStart) {
            require(saleWhitelist[msg.sender] > 0, "Must be on the sale whitelist");
        }

        require(supply + amount <= maxTokens, "Exceeds max hero supply!");
        require(msg.value >= TOKEN_COST * amount, "Invalid ETH value sent!");

        riskToken.mint(amount, msg.sender);

        addressToMintCount[msg.sender] += amount;
        
        if (block.timestamp < publicSaleStart) {
            saleWhitelist[msg.sender] -= amount;
        }
    }

    function reserveTeamTokens(address _to, uint256 _reserveAmount) public onlyOwner {
        uint256 supply = riskToken.tokenCount();
        require(supply + _reserveAmount <= maxTokens, "Exceeds max hero supply!");
        riskToken.mint(_reserveAmount, _to);
    }

    // ========  Whitelisting 
    function addWhitelisted(address[] memory _addresses, uint[] memory _tokensToClaim) external onlyOwner {
        require(_addresses.length == _tokensToClaim.length, "Invalid whitelist data");
        for (uint256 i = 0; i < _addresses.length; i++) {
            saleWhitelist[_addresses[i]] = _tokensToClaim[i];
        }
    }

    // ======== Max Minting =========
    function setMaxMintPerAddress(uint _max) public onlyOwner {
        maxMintsPerAddress = _max;
    }

    // ======== Utilities =========
    function remainingWhitelistTokensForClaim(address _address) external view returns (uint) {
        return saleWhitelist[_address];
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
