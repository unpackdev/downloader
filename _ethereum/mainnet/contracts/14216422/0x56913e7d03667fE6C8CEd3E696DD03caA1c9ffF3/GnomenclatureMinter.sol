// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IGnomenclatureToken.sol";

contract GnomenclatureMinter is Ownable, ReentrancyGuard {

    // ======== Supply =========
    uint256 public constant MAX_MINTS_PER_TX = 20;
    uint256 public maxMintsPerAddress;
    uint256 public maxTokens;

    // ======== Cost =========
    uint256 public constant TOKEN_COST = 0.02 ether;

    // ======== Sale status =========
    bool public saleIsActive = false;
    uint256 public publicSaleStart; // Public sale start (20 mints per tx, max 200 mints per address)

    // ======== Claim Tracking =========
    mapping(address => uint256) private addressToMintCount;

    // ======== External Storage Contract =========
    IGnomenclatureToken public token;

    // ======== Constructor =========
    constructor(address nftAddress,
                uint256 publicSaleStartTimestamp,
                uint256 tokenSupply,
                uint256 maxMintsAddress) {
        token = IGnomenclatureToken(nftAddress);
        publicSaleStart = publicSaleStartTimestamp;
        maxTokens = tokenSupply;
        maxMintsPerAddress = maxMintsAddress;
    }

    // ======== Claim / Minting =========
    function mintPublic(uint amount) public payable nonReentrant {
        uint256 supply = token.tokenCount();

        require(saleIsActive, "Sale must be active to claim!");

        require(block.timestamp >= publicSaleStart, "Sale not started!");

        require(amount <= MAX_MINTS_PER_TX, "Exceeds max mint per tx!");

        require(addressToMintCount[msg.sender] + amount <= maxMintsPerAddress, "Exceeded wallet mint limit!");

        require(supply + amount <= maxTokens, "Exceeds max token supply!");

        require(msg.value >= TOKEN_COST * amount, "Invalid ETH value sent!");

        token.mint(amount, msg.sender);

        addressToMintCount[msg.sender] += amount;
    }

    function reserveTeamTokens(address _to, uint256 _reserveAmount) public onlyOwner {
        uint256 supply = token.tokenCount();
        require(supply + _reserveAmount <= maxTokens, "Exceeds max token supply!");
        token.mint(_reserveAmount, _to);
    }

    // ======== Max Minting =========
    function setMaxMintPerAddress(uint _max) public onlyOwner {
        maxMintsPerAddress = _max;
    }

    // ======== Utilities =========
    function mintCount(address _address) external view returns (uint) {
        return addressToMintCount[_address];
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
