//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// Imports
import "./IERC20.sol";

// Errors
error LynxVault__NotWhitelisted();
error LynxVault__NotOwner();
error LynxVault__ProperChannels();
error LynxVault__InvalidAddress();

/**
 * @title Vault for Lynx
 * @author Semi Invader
 * @notice This contract is the vault for Lynx Tokens used in other contracts.
 */
contract LynxVault {
    //------------------------
    // Variables
    //------------------------

    mapping(address => bool) public whitelisted;
    address public owner;
    IERC20 public lynx;

    //------------------------
    // Events
    //------------------------

    event SetWhitelist(address indexed _address, bool status);
    event Withdraw(address indexed _address, uint amount);

    //------------------------
    // Modifiers
    //------------------------

    modifier onlyWhitelisted() {
        if (whitelisted[msg.sender]) _;
        else revert LynxVault__NotWhitelisted();
    }

    modifier onlyOwner() {
        if (msg.sender == owner) _;
        else revert LynxVault__NotOwner();
    }

    //------------------------
    // Constructor
    //------------------------
    constructor(address _lynx) {
        whitelisted[msg.sender] = true;
        owner = msg.sender;
        lynx = IERC20(_lynx);
    }

    //----------------------------
    // External/Public functions
    //----------------------------

    /**
     * @notice Sets the whitelist status for an address
     * @param _address Address to set the whitelist status for
     * @param status the status to set the whitelist to
     */
    function setWhitelistStatus(
        address _address,
        bool status
    ) external onlyOwner {
        if (_address == address(0)) revert LynxVault__InvalidAddress();
        whitelisted[_address] = status;
        emit SetWhitelist(_address, status);
    }

    /**
     * @notice Sets the whitelist status for multiple Addresses
     * @param _addresses Addresses to set the whitelist status for
     * @param status the status value set
     */
    function addMultipleWhitelist(
        address[] calldata _addresses,
        bool status
    ) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            if (_addresses[i] == address(0)) revert LynxVault__InvalidAddress();
            whitelisted[_addresses[i]] = status;
            emit SetWhitelist(_addresses[i], status);
        }
    }

    function withdraw(uint amount) external onlyWhitelisted {
        lynx.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function withdrawTo(
        address _address,
        uint amount
    ) external onlyWhitelisted {
        if (_address == address(0)) revert LynxVault__InvalidAddress();
        lynx.transfer(_address, amount);
        emit Withdraw(_address, amount);
    }

    function recoverERC20(address _otherToken) external onlyOwner {
        if (_otherToken == address(lynx)) revert LynxVault__ProperChannels();
        IERC20 otherToken = IERC20(_otherToken);
        otherToken.transfer(msg.sender, otherToken.balanceOf(address(this)));
    }
}
