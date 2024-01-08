// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CountersUpgradeable.sol";
import "./Initializable.sol";

/// @author 1001.digital
/// @title A token tracker that limits the token supply and increments token IDs on each new mint.
abstract contract WithLimitedSupplyUpgradeable is Initializable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Keeps track of how many we have minted
    CountersUpgradeable.Counter private _tokenCount;

    /// @dev The maximum count of tokens this token tracker will hold.
    uint256 private _maxSupply;

    // @param maxSupply_ how many tokens this collection should hold
    function __WithLimitedSupply_init(uint256 maxSupply_) internal initializer {
        __WithLimitedSupply_init_unchained(maxSupply_);
    }

    function __WithLimitedSupply_init_unchained(uint256 maxSupply_)
        internal
        initializer
    {
        _maxSupply = maxSupply_;
    }

    /// @dev Get the max Supply
    /// @return the maximum token count
    function maxSupply() internal view returns (uint256) {
        return _maxSupply;
    }

    /// @dev Get the current token count
    /// @return the created token count
    function tokenCount() public view returns (uint256) {
        return _tokenCount.current();
    }

    /// @dev Check whether tokens are still available
    /// @return the available token count
    function availableTokenCount() public view returns (uint256) {
        return _maxSupply - tokenCount();
    }

    /// @dev Increment the token count and fetch the latest count
    /// @return the next token id
    function _nextToken()
        internal
        virtual
        ensureAvailability
        returns (uint256)
    {
        uint256 token = _tokenCount.current();

        _tokenCount.increment();

        return token;
    }

    /// @dev Check whether another token is still available
    modifier ensureAvailability() {
        require(availableTokenCount() > 0, "No more tokens available");
        _;
    }

    /// @param amount Check whether number of tokens are still available
    /// @dev Check whether tokens are still available
    modifier ensureAvailabilityFor(uint256 amount) {
        require(
            availableTokenCount() >= amount,
            "Requested number of tokens not available"
        );
        _;
    }
}
