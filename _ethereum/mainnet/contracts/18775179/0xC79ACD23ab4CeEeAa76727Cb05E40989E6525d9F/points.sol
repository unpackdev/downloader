// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./ERC20.sol";
import "./Ownable.sol";

contract POINTS is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 1000000000;
    uint256 public constant MINT_INCREMENT = 100; 
    uint256 public constant PRICE_PER_HUNDRED_TOKENS = 0.0001 ether;

    constructor(address initialOwner)
        ERC20("POINTS", "POINTS")
        Ownable(initialOwner)
    {
        _mint(initialOwner, 1000000);
    }

    /**
     * @notice Mints new tokens in increments of 100, with a cost of 0.0001 ETH per 100 tokens.
     * @dev Mints `numberOfHundreds` * 100 tokens to the sender's address. Requires the sender to send ETH equal to `numberOfHundreds` * 0.0001.
     * @param numberOfHundreds The number of hundreds of tokens to mint.
     */
    function mint(uint256 numberOfHundreds) public payable {
        uint256 tokensToMint = numberOfHundreds * MINT_INCREMENT;
        uint256 requiredPayment = numberOfHundreds * PRICE_PER_HUNDRED_TOKENS;

        require(msg.value >= requiredPayment, "Insufficient ETH sent");
        require(totalSupply() + tokensToMint <= MAX_SUPPLY, "Max supply exceeded");

        _mint(msg.sender, tokensToMint);
        
        if (msg.value > requiredPayment) {
            payable(msg.sender).transfer(msg.value - requiredPayment);
        }
    }

    /**
     * @notice Allows the contract owner to airdrop tokens to a specified address.
     * @param to The address to receive the airdropped tokens.
     * @param amount The amount of tokens to airdrop.
     */
    function airdrop(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");
        _mint(to, amount);
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}