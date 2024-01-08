// SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

import "./ERC20.sol";
import "./ILPT.sol";

/// @title Liquidity Pool Token
/// @notice Receipt Tokens for supplying USDC into the Liquidity Pool
/// @dev This is a plain ERC20 and implements the interface that exposes actions into the Liquidity Pool
contract LPT is ILPT, ERC20 {
    address public liquidityPool;

    /// @notice LPT ERC20 constructor
    /// @dev This token is expected to be shown with 6 decimals
    /// @param _name (string) LPT name
    /// @param _symbol (string) LPT Symbol
    /// @param _liquidityPool (address) Liquidity Pool's address
    constructor(
        string memory _name,
        string memory _symbol,
        address _liquidityPool
    ) ERC20(_name, _symbol) {
        require(_liquidityPool != address(0));
        _setupDecimals(6);
        liquidityPool = _liquidityPool;
    }

    /// @dev Helps to perform actions meant to be executed by the Liquidity Pool itself
    modifier onlyLiquidityPool() {
        require(msg.sender == liquidityPool, "You are not allowed to perform this action");
        _;
    }

    /// @notice Mints LPT in exchange for lender's USDC supplied into the Liquidity Pool
    /// @param _recipient (address) Lender's address to send the LPTs
    /// @param _amount (uint256) LPT amount to be minted
    /// @return  (bool) indicates a successful operation
    function mint(address _recipient, uint256 _amount) external override onlyLiquidityPool returns (bool) {
        _mint(_recipient, _amount);
        return true;
    }

    /// @notice Burns LPT as indicated
    /// @param _sender (address) Lender's address account to burn LPT from
    /// @param _amount (uint256) LPT amount to be burned
    /// @return  (bool) indicates a successful operation
    function burnFrom(address _sender, uint256 _amount) external override onlyLiquidityPool returns (bool) {
        _burn(_sender, _amount);
        return true;
    }
}
