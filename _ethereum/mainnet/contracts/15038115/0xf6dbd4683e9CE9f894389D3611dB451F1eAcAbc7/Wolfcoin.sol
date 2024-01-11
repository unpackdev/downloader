//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

contract Wolfcoin is ERC20, Ownable {
    // Libaries —————————————————————————————————————————————————————
    using SafeMath for uint256;

    // Events ———————————————————————————————————————————————————————
    event WillClaim(address indexed claimant, uint256 amount);
    event DidClaim(address indexed claimant, uint256 amount);

    // Constants ————————————————————————————————————————————————————
    // Aggregate supply in wei.
    uint256 private constant AGGREGATE_SUPPLY = 1_337_069_420_000e18;
    // Allocate 80% of the supply to the market.
    uint256 private constant MARKET_SUPPLY = 1_069_655_536_000e18;
    // Date when airdrop is completed and remaining airdrop supply is burned.
    uint256 private constant MINIMUM_BALANCE = 0.25 ether; 
    // 1e16 represents 0.01% reduction after each subsequent claim.
    uint256 private constant CLAIM_REDUCTION = 1e16; 
    // 1e20 represents dividing by 100 as a percentage.
    uint256 private constant CLAIM_DIVISOR = 1e20;

    // Airdrop state ————————————————————————————————————————————————
    // List of addresses that have previously claimed the airdrop.
    mapping(address => bool) private claimed;
    // Represents the state of the airdrop (in/active).
    bool private isAirdropActive;
    // Allocate the remaining 20% supply to the airdrop.
    uint256 public airdropSupply = AGGREGATE_SUPPLY - MARKET_SUPPLY;
    // 1e18 represents 1% as the starting claim percentage.
    uint256 public claimRatio = 1e18;

    constructor(address marketSupplyOwnerAddress) ERC20("Wolfcoin", "WOLF") {
        _mint(marketSupplyOwnerAddress, MARKET_SUPPLY);
        _mint(address(this), airdropSupply);
        isAirdropActive = true;
    }

    // [α] To preventing underflow the order of operation matters `uint256.mul(MULTIPLE).div(DIVISOR)`.
    function claimAirdrop() public returns (uint256) {
        require(isAirdropActive, "Wolfcoin: Claim is inactive.");
        require(airdropSupply > 0, "Wolfcoin: Airdrop supply gone.");
        require(msg.sender.balance >= MINIMUM_BALANCE, "Wolfcoin: Balance too low.");
        require(!claimed[msg.sender], "Wolfcoin: Already claimed.");
        claimed[msg.sender] = true;

        // Transfer claim amount to caller.
        uint256 claimAmount = airdropSupply.mul(claimRatio).div(CLAIM_DIVISOR); // α
        emit WillClaim(msg.sender, claimAmount);
        _transfer(address(this), msg.sender, claimAmount);
        emit DidClaim(msg.sender, claimAmount);

        // Update claim permillages for next caller.
        claimRatio -= claimRatio.mul(CLAIM_REDUCTION).div(CLAIM_DIVISOR); // α
        airdropSupply -= claimAmount;

        return claimAmount;
    }

    function burnRemainingAirdrop() public onlyOwner {
        require(isAirdropActive, "Wolfcoin: Claim is active.");
        _transfer(address(this), address(0), balanceOf(address(this)));
    }

    function deactivateAirdrop() public onlyOwner {
        isAirdropActive = false;
    }
}
