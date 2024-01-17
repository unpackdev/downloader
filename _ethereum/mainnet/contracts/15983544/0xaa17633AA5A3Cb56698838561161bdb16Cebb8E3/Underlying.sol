// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// External references
import "./PriceOracle.sol";
import "./CToken.sol";
import "./Errors.sol";

// Internal references
import "./Trust.sol";
import "./FixedMath.sol";
import "./BaseAdapter.sol";

contract UnderlyingOracle is PriceOracle, Trust {
    using FixedMath for uint256;

    /// @notice underlying address -> adapter address
    mapping(address => address) public adapters;

    constructor() Trust(msg.sender) {}

    function setUnderlying(address underlying, address adapter) external requiresTrust {
        adapters[underlying] = adapter;
    }

    function getUnderlyingPrice(CToken cToken) external view override returns (uint256) {
        return _price(address(cToken.underlying()));
    }

    function price(address underlying) external view override returns (uint256) {
        return _price(underlying);
    }

    function _price(address underlying) internal view returns (uint256) {
        address adapter = adapters[address(underlying)];
        if (adapter == address(0)) revert Errors.AdapterNotSet();

        return Adapter(adapter).getUnderlyingPrice();
    }
}
