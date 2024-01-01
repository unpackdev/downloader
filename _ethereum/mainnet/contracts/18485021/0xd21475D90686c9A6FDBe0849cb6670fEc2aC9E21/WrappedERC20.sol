// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./Ownable.sol";

/// @title Wrapped ERC20
/// @notice Represents a token on another chain
/// @dev Can be minted and burned only by the bridge
contract WrappedERC20 is ERC20, Ownable {
    mapping(address => bool) public authorizedBridges;
    uint8 private immutable _tokenDecimals;

    /// @param _bridge responsible for minting and burning the wrapped token
    /// @param _name wrapped token name
    /// @param _symbol wrapped token symbol
    /// @param _decimals number of decimals of the original token
    constructor(
        address _bridge,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol) {
        require(_bridge != address(0), "WrappedERC20: invalid bridge");

        authorizedBridges[_bridge] = true;
        _tokenDecimals = _decimals;
    }

    modifier onlyBridge() {
        require(
            authorizedBridges[msg.sender],
            "WrappedERC20: caller is not a bridge"
        );
        _;
    }

    /// @notice Set authorized bridges to mint wrapped token
    function setAuthorizedBridge(
        address _bridge,
        bool _authorized
    ) external onlyOwner {
        authorizedBridges[_bridge] = _authorized;
    }

    /// @notice Number of decimal places used to represent the token's smallest unit
    /// @dev Overrides the default value of 18
    /// @return number of decimal places
    function decimals() public view virtual override returns (uint8) {
        return _tokenDecimals;
    }

    /// @notice Creates `amount` tokens and assigns them to `account`, increasing the total supply
    /// @dev called only by the bridge
    function mint(address _to, uint _amount) external virtual onlyBridge {
        _mint(_to, _amount);
    }

    /// @notice Destroys `amount` tokens from `account`, reducing the total supply
    /// @dev Called only by the bridge
    function burn(address _from, uint _amount) external virtual onlyBridge {
        _burn(_from, _amount);
    }
}
