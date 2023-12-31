// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";

import "./IWrappedERC20.sol";

/// @title A custom ERC20 contract used in the bridge
contract WrappedERC20 is IWrappedERC20, ERC20Upgradeable {

    address internal _bridge;
    uint8 internal _decimals;
    string internal _tokenName;
    string internal _tokenSymbol;  
    
    /// @dev Checks if the caller is the bridge contract
    modifier onlyBridge {
        require(msg.sender == _bridge, "Token: caller is not a bridge!");
        _;
    }

    /// @dev Creates an "empty" template token that will be cloned in the future

    /// @dev Upgrades an "empty" template. Initializes internal variables. 
    /// @param name_ The name of the token
    /// @param symbol_ The symbol of the token
    /// @param decimals_ Number of decimals of the token
    /// @param bridge_ The address of the bridge of the tokens 
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address bridge_
    ) external initializer {
        require(bytes(name_).length > 0, "ERC20: initial token name can not be empty!");
        require(bytes(symbol_).length > 0, "ERC20: initial token symbol can not be empty!");
        require(decimals_ > 0, "ERC20: initial decimals can not be zero!");
        require(bridge_ != address(0), "ERC20: initial bridge address can not be a zero address!");
        _decimals = decimals_;
        _bridge = bridge_;
        _tokenName = name_;
        _tokenSymbol = symbol_;
    }

    /// @notice Returns the name of the token
    /// @return The name of the token
    function name() public view override(ERC20Upgradeable, IWrappedERC20) returns(string memory) {
        return _tokenName;
    }

    /// @notice Returns the symbol of the token
    /// @return The symbol of the token
    function symbol() public view override(ERC20Upgradeable, IWrappedERC20) returns(string memory) {
        return _tokenSymbol;
    }

    /// @notice Returns number of decimals of the token
    /// @return The number of decimals of the token
    function decimals() public view override(ERC20Upgradeable, IWrappedERC20) returns(uint8) {
        return _decimals;
    }

    /// @notice Creates tokens and assigns them to account, increasing the total supply.
    /// @param to The receiver of tokens
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) external onlyBridge {
        _mint(to, amount);
        emit Mint(to, amount);
    }

    /// @notice Returns the address of the bridge
    /// @return The address of the bridge
    function bridge() external view returns(address) {
        return _bridge;
    }
    
    /// @notice Destroys tokens from account, reducing the total supply.
    /// @param from The address holding the tokens
    /// @param amount The amount of tokens to burn
    function burn(address from, uint256 amount) external onlyBridge {
        _burn(from, amount);
        emit Burn(from, amount);
    }
}
