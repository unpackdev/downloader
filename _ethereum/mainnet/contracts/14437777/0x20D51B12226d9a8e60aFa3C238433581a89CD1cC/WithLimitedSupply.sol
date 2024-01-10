// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";

/// @title A token tracker that limits the token supply and increments token IDs on each new mint.
abstract contract WithLimitedSupply {
    using Counters for Counters.Counter;
    /**
     * @dev Emitted when the supply of this collection changes
     */
    event SupplyChanged(uint256 indexed supply);

    // Keeps track of how many have been minted
    Counters.Counter private _tokenCount;

    /**
     * @dev The maximum count of tokens this token tracker will hold.
     */
    uint256 internal _totalSupply;

    constructor (uint256 totalSupply_) {
        _totalSupply = totalSupply_;
    }

    /** 
     * @dev Get the current token count
     * @return the created token count
     */
    function totalSupply() public view returns (uint256) {
        return _tokenCount.current();
    }
    /**
     * @dev Check whether tokens are still available
     * @return the available token count
     */
    function availableTokenCount() public view virtual returns (uint256) {
        return _totalSupply - totalSupply();
    }
    /**
     * @dev Increment the token count and fetch the latest count
     * @return the next token id
     */
    function nextToken() internal virtual returns (uint16) {
        uint256 token = _tokenCount.current();

        _tokenCount.increment();

        return uint16(token);
    }
    /**
     * @dev Check whether another token is still available
     */
    modifier ensureAvailability() {
        require(availableTokenCount() > 0, "No more tokens available");
        _;
    }
    /**
     * @param amount Check whether number of tokens are still available
     * @dev Check whether tokens are still available
     */
    modifier ensureAvailabilityFor(uint256 amount) {
        require(availableTokenCount() >= amount, "Requested number of tokens not available");
        _;
    }
    /**
     * Update the supply for the collection
     * @param _supply the new token supply.
     * @dev create additional token supply for this collection.
     */
    function _setSupply(uint256 _supply) internal virtual {
        require(_supply > totalSupply(), "Can't set the supply to less than the current token count");
        _totalSupply = _supply;

        emit SupplyChanged(_totalSupply);
    }
}