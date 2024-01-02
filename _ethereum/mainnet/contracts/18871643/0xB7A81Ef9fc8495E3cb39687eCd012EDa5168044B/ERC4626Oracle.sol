// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

import "./IERC4626.sol";

/// @title ERC4626Oracle
/// @author Jason (Sturdy) https://github.com/iris112
/// @notice  An oracle for ERC4626 Token
contract ERC4626Oracle {
    uint8 public constant DECIMALS = 18;

    address public immutable TOKEN;
    uint8 public immutable TOKEN_DECIMALS;
    uint256 public immutable PRICE_MIN;

    string public name;

    constructor(
        uint256 _priceMin,
        address _token,
        uint8 _decimals,
        string memory _name
    ) {
        PRICE_MIN = _priceMin;
        TOKEN = _token;
        TOKEN_DECIMALS = _decimals;
        name = _name;
    }

    /// @notice The ```getPrices``` function is intended to return price of ERC4626 token based on the base asset
    /// @return _isBadData is always false, just sync to other oracle interfaces
    /// @return _priceLow is the lower of the prices
    /// @return _priceHigh is the higher of the prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        uint256 rate = IERC4626(TOKEN).convertToShares(10 ** TOKEN_DECIMALS);
        rate = rate * 10 ** DECIMALS / 10 ** TOKEN_DECIMALS;
        _priceHigh = rate > PRICE_MIN ? rate : PRICE_MIN;
        _priceLow = _priceHigh;
    }
}
