// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./Initializable.sol";
import "./IBankStorage.sol";
import "./OhUpgradeable.sol";

abstract contract OhBankStorage is Initializable, OhUpgradeable, IBankStorage {
    bytes32 internal constant _UNDERLYING_SLOT = 0x90773825e4bc2bc5b176633f3046da46e88d251c6a1ff0816162f0a2ed8410ce;
    bytes32 internal constant _PAUSED_SLOT = 0x260da1bd0b3277b5df511eb3ee2570300c0d5002c849b8340104d112bb42b5be;

    constructor() {
        assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.bank.underlying")) - 1));
        assert(_PAUSED_SLOT == bytes32(uint256(keccak256("eip1967.bank.paused")) - 1));
    }

    function initializeStorage(address underlying_) internal initializer {
        _setPaused(false);
        _setUnderlying(underlying_);
    }

    /// @notice Pause status for this Bank
    /// @return Boolean for if Bank is paused
    function paused() public view override returns (bool) {
        return getBoolean(_PAUSED_SLOT);
    }

    /// @notice The underlying token that is deposited
    /// @return The underlying token address
    function underlying() public view override returns (address) {
        return getAddress(_UNDERLYING_SLOT);
    }

    function _setPaused(bool paused_) internal {
        setBoolean(_PAUSED_SLOT, paused_);
    }

    function _setUnderlying(address underlying_) internal {
        setAddress(_UNDERLYING_SLOT, underlying_);
    }
}
