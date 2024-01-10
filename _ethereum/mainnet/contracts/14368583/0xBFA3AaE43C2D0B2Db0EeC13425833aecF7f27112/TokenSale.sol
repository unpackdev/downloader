// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;
import "./TruthereumToken.sol";
import "./Owned.sol";

contract TokenSale is Owned {

    // Variables
    address public tokenAddress = address(0); // address of the token itself
    address public saleAddress; // address where the tokens are stored
    address public unsoldAddress; // address to send any unsold tokens to
    address payable public beneficiary; // address to receive ETH contributions
    uint256 public tokensForSale;
    uint256 public tokensPerETH;

    TruthereumToken token;

    // Events
    event SaleContribution(address _contributor, uint256 _amount, uint256 _return);

    // Modifiers
    modifier saleActive() {
        require(isActive() == true, 'ERROR: There is currently no active sale');
        _;
    }

    modifier saleNotActive() {
        require(isActive() == false, 'ERROR: There is currently an active sale');
        _;
    }

    constructor(
        address _saleAddress,
        address _unsoldAddress,
        address payable _beneficiary,
        uint256 _tokensForSale,
        uint256 _tokensPerETH,
        uint256 _decimals
    ) {
        saleAddress = _saleAddress;
        unsoldAddress = _unsoldAddress;
        beneficiary = _beneficiary;
        tokensForSale = safeMul(_tokensForSale, (10 ** _decimals));
        tokensPerETH = _tokensPerETH;
    }

    /**
        Checks if pre-start conditions are met for the sale
    */
    function isStartable() isValidAddress(tokenAddress) public view virtual returns (bool) {
        return true;
    }

    /**
        Checks if the sale is active
    */
    function isActive() public view virtual returns (bool) {
        if (tokenAddress == address(0)) {
            return false;
        }
        if (availableForSale() <= 0) {
            return false;
        }
        return true;
    }

    /**
        Returns the total amount of tokens still available in this sale
    */
    function availableForSale() public view returns (uint256) {
        return token.allowance(saleAddress, address(this));
    }

    /**
        Sets the token variable, this can only be done once
    */
    function setToken(address _tokenAddress) isValidAddress(_tokenAddress) ownerRestricted public {
        require(tokenAddress == address(0), 'ERROR: The tokenAddress must be 0x0');
        tokenAddress = _tokenAddress;
        token = TruthereumToken(_tokenAddress);
    }

    /**
        Sets the address to receive the ETH contributions
    */
    function setBeneficiary(address payable _beneficiary) isValidAddress(_beneficiary) ownerRestricted public {
        beneficiary = _beneficiary;
    }

    /**
        Ends the token sale and no longer allows for contributions
    */
    function endSale() ownerRestricted public {
        token.endTokenSale();
    }

    /**
        Handles ETH contributions and validates the address before further processing
    */
    function handleETHContribution(address _to) public payable saleActive isValidAddress(_to) returns (uint256) {
        return handleContribution(_to);
    }

    /**
        Transfers the ETH to the beneficiary and transfers the amount of tokens in return
    */
    function handleContribution(address _to) isNotAddress(_to, token.publicAddress()) private returns (uint256) {
        uint256 tokens = getTotalTokensForETH(msg.value);
        require(availableForSale() > tokens, 'ERROR: There are not enough tokens available to cover the contribution');
        beneficiary.transfer(msg.value);
        token.transferFrom(token.publicAddress(), _to, tokens);
        token.addToAllocation(tokens);
        emit SaleContribution(_to, msg.value, tokens);
        return tokens;
    }

    /**
        Returns the equivalent value of tokens for the ETH provided 
    */
    function getTotalTokensForETH(uint256 _eth) public view virtual returns (uint256) {
        return safeMul(_eth, tokensPerETH);
    }

    /**
        The entry point to purchase tokens
    */
    receive() payable external {
        handleETHContribution(msg.sender);
    }
}