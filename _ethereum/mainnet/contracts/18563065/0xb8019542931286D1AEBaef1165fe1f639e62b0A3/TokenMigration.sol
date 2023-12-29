pragma solidity ^0.8.19;

import "./ERC20Burnable.sol";
import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract TokenMigration is Ownable, ReentrancyGuard {

    ERC20Burnable public oldToken; // Address of source token contract
    IERC20Metadata public newToken; // Address of destination token contract

    address public burnAddress; 
    address public bridgeContractaddress; // Address holding the tokens
    uint256 public bridgeTokenHoldings; // Amount of tokens holding
    uint256 public oldTokenTotalSupply; // Point in time of the totalSupply at the deployment time 
    uint256 public totalConvertedTokens; // Total number of tokens converted so far
    bool public isBurnAllowed; // Is the token contract support the burn functionality by the token holder
    bool public paused; // To enable or disable the oprations

    // Events
    event TokenConverted(address indexed tokenHolder, uint256 amount);
    event WithdrawToken(address indexed owner, uint256 amount);
    event UpdatePause(address indexed operator, bool operation);

    // Modifiers
    modifier whenNotPaused() {
        require(paused == false, "Operations paused");
        _;
    }

    // Check the balance in the bridge is not changed
    modifier checkBridgeHolding() {
        require( address(bridgeContractaddress) == address(0) || 
                (oldToken.balanceOf(bridgeContractaddress) == bridgeTokenHoldings), "Change in bridge balance");
        _;
    }

    // Check the total supply of the Old Tokens
    modifier checkTotalSupply() {

        uint256 currentTotalSupply = oldToken.totalSupply();
        if(isBurnAllowed) {
            currentTotalSupply = currentTotalSupply + totalConvertedTokens;
        }

        require( currentTotalSupply <= oldTokenTotalSupply, "Change in total supply");
        _;
    }

    /**
    * @dev Constructor takes both old and new token addrress and compares the decimals
    * 
    */
    constructor(address _oldToken, address _newToken, address _burnAddress, uint256 _oldTokenTotalSupply, bool _isBurnAllowed)
    {
        // Set the token contracts
        oldToken = ERC20Burnable(_oldToken);
        newToken = IERC20Metadata(_newToken);

        // Enable the operations by default
        paused = false; // Explicitly not required as the default value is false. For readability setting it.

        // old token total supply
        oldTokenTotalSupply = _oldTokenTotalSupply;

        // to determine whether the old token contract support burn functionality
        isBurnAllowed = _isBurnAllowed;

        // Burn address in case if the burn is not allowed
        burnAddress = _burnAddress;
        
        // Check for the equal decimals
        require(oldToken.decimals() == newToken.decimals(), "Invalid token addresses");

    }

    /**
    * @dev To convert the tokens from one token to another token on Ethereumnetwork. 
    * The tokens which needs to be convereted will be burned on the host network.
    * And the new tokens will be transferred to the user.
    */
    function convertToken(uint256 amount) external whenNotPaused checkBridgeHolding checkTotalSupply nonReentrant {

        // Check for zero amount
        require(amount != 0, "Invalid amount");

        // Check for the Balance
        require(oldToken.balanceOf(msg.sender) >= amount, "Not enough balance");
        
        // Check for the token balance in the contract
        require(newToken.balanceOf(address(this)) >= amount, "Not enough balance");

        // Update the converted tokens
        totalConvertedTokens = totalConvertedTokens + amount;

        // Burn the tokens on behalf of the Wallet or Transfer to the burn address
        if(isBurnAllowed) {
            oldToken.burnFrom(msg.sender, amount);
        }
        else {
            // Transfer to the User Wallet 
            require(oldToken.transferFrom(msg.sender, burnAddress, amount), "Unable to transfer to burn address");
        }

        // Transfer to the User Wallet
        require(newToken.transfer(msg.sender, amount), "Unable to convert");

        emit TokenConverted(msg.sender, amount);

    }

    /**
    * @dev Function to Pause/UnPause the conversions. To pause the operations set it to true
    */
    function setPause(bool pauseOperations) external onlyOwner 
    {
        paused = pauseOperations;

        emit UpdatePause(msg.sender, pauseOperations);
    }

    /**
    * @dev Function to set the bridge holdings.
    */
    function updateBridgeDetails(address _tokenHolder, uint256 _amount, uint256 _oldTokenTotalSupply) external onlyOwner 
    {
        bridgeContractaddress = _tokenHolder;
        bridgeTokenHoldings = _amount;
        oldTokenTotalSupply = _oldTokenTotalSupply;
    }

    /**
    * @dev Function to withdraw additional tokens from the contract
    */
    function withdrawToken(uint256 amount) external onlyOwner
    {

        // Check if contract is having required balance 
        require(newToken.balanceOf(address(this)) >= amount, "Not enough balance in the contract");
        require(newToken.transfer(msg.sender, amount), "Unable to transfer token");

        emit WithdrawToken(msg.sender, amount);
        
    }

}