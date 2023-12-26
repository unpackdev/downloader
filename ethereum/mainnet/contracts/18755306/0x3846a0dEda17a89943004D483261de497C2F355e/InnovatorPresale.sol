// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./AccessControl.sol";

// Presale contract
contract PresaleContract is AccessControl {

    // Token contract will be created by presale contract
    PresaleToken Token;

    // Generated token address
    address public tokenAddress;
    address payable deployer;

    // Presale data
    bool saleActive;

    uint256 public cycle;
    uint256 public priceMultiplier;
    uint256 public totalTokensSold;
    uint256 public tokensLeft;
    uint256 public tokenCycle;
    uint256 public tokenPrice;

    // Initiate constructor data
    constructor () 
    {
        Token = new PresaleToken (address(this));
        tokenAddress = address(Token);
        deployer = payable(msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        saleActive = true;
        cycle = 50000;
        tokenCycle = 0;
        priceMultiplier = 0.000001 ether;
        tokensLeft = 4_000_000 * 1e18;
        tokenPrice = 0.000025 ether;
    }

    // Function to return new tokenPrice
    function calcNewTokenPrice (uint256 tokenAmount) view public returns (uint256) {

        // Calc cycles
        uint256 fullCyclesCompleted = (tokenCycle + tokenAmount) / cycle;
        uint256 newTokenPrice = tokenPrice;

        // Add priceMultiplier for each completed cycle
        for (uint256 i = 0; i < fullCyclesCompleted; i++) {
            newTokenPrice += priceMultiplier;
        }

        // Return new tokenPrice value
        return newTokenPrice;
    }

    // Function to return new tokenCycle amount
    function calcNewTokenCycle (uint256 tokenAmount) view public returns (uint256) {
        // Return new tokenCycle value
        return (tokenCycle + tokenAmount) % cycle;
    }

    // Calc total price on buy
    function calcTotalPrice(uint256 tokenAmount) public view returns (uint256) {

        // Calculate the new value of tokenCycle
        uint256 newTokenCycle = (tokenCycle + tokenAmount) % cycle;

        // Calculate the number of full cycles completed
        uint256 fullCyclesCompleted = (tokenCycle + tokenAmount) / cycle;

        // Calculate the total price
        uint256 totalPrice = 0;

        // Update tokenPrice for completed cycles
        uint256 currentTokenPrice = tokenPrice;
        for (uint256 i = 0; i < fullCyclesCompleted; i++) {
            currentTokenPrice += priceMultiplier;

            // Calculate price for tokens in a completed cycle
            totalPrice += cycle * currentTokenPrice;
        }

        // Calculate price for any remaining tokens in the last cycle
        uint256 remainingTokens = 0;

        if (newTokenCycle >= tokenCycle) {
            remainingTokens = newTokenCycle - tokenCycle;
        } else {
            // If the first cycle exceeds 10, calculate remaining tokens based on the initial tokenCycle
            remainingTokens = cycle - tokenCycle;
        }

        if (remainingTokens > 0) {
             totalPrice += remainingTokens * currentTokenPrice;
        }

        // Return totalprice
        return totalPrice;
    }

    // Purchase function
    function purchaseTokens (uint256 tokenAmount) public payable {

        // Gather total price
        uint256 totalPrice = calcTotalPrice(tokenAmount);

        // Msg.value check
        require (msg.value >= totalPrice, "Not enough ETH");

        // Mint tokens
        Token.mint(msg.sender, tokenAmount * 1e18);

        // Send ETH to deployer
        deployer.transfer(totalPrice);

        // Update tokenPrice
        tokenPrice = calcNewTokenPrice(tokenAmount);

        // Update tokenCycle
        tokenCycle = calcNewTokenCycle(tokenAmount);

        // Refund excess ETH
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        // Update total sold and tokens left
        totalTokensSold += tokenAmount * 1e18;
        tokensLeft -= tokenAmount * 1e18;
    }

    // Function to (de)activate presale
    function setSaleStatus (bool status) external onlyRole (DEFAULT_ADMIN_ROLE) {
        saleActive = status;
    }

    // Function to clear stuck ETH in the contract
    function clearETH () external onlyRole (DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Function to clear stuck ETH in the token contract for whatever reason
    function clearETH_tokenContract () external onlyRole (DEFAULT_ADMIN_ROLE) {
        address receiver = msg.sender;
        Token.clearETH(receiver);
    }

    // Function to clear ERC20's stuck in the token contract for whatever reason
    function clearERC20_tokenContract (address erc20Address) external onlyRole (DEFAULT_ADMIN_ROLE) {
        address receiver = msg.sender;
        Token.clearStuckTokens(erc20Address, receiver);
    }
}

// Presale Innovator Token
contract PresaleToken is ERC20, AccessControl {

    // MINTER_ROLE
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Presale contract
    address private presaleContract;

    // Initiate constructor data
    constructor (address minter)
        ERC20 ("Innovator Presale Token", "P-INOV8")
    {
        _grantRole (MINTER_ROLE, minter);
        presaleContract = msg.sender;
    }

    // Only presale contract
    modifier onlyPresaleContract() {
        require (msg.sender == presaleContract, "You are not the presale contract");
        _;
    }

    // Mint function, only for the presale contract
    function mint (address to, uint256 amount) public onlyRole (MINTER_ROLE) {
        _mint(to, amount);
    }

    // Function to withdraw third party ERC20's or stables that got stuck here for whatever reason
    function clearStuckTokens (address tokenAddress, address receiver) external onlyPresaleContract {
        IERC20(tokenAddress).transfer(address(receiver), balanceOf(address(this)));
    }
 
    // Function to clear stuck ETH in the contract
    function clearETH (address receiver) external onlyPresaleContract {
        payable(receiver).transfer(balanceOf(address(this)));
    } 
}