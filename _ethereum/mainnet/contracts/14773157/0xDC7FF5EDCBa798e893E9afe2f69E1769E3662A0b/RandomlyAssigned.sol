// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./Counters.sol";

/// @author 1001.digital
/// @title Randomly assign tokenIDs from a given set of tokens.
/// @notice adopted for own needs from https://github.com/1001-digital/erc721-extensions/blob/main/contracts/RandomlyAssigned.sol
abstract contract RandomlyAssigned {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Used for random index assignment
    mapping(uint256 => uint256) private tokenMatrix;

    // The max token supply
    uint256 private maxSupply;

    /// Instantiate the contract
    /// @param _maxSupply how many tokens this collection will hold
    constructor(uint256 _maxSupply) {
        maxSupply = _maxSupply;
    }

    /// Get the next token ID
    /// @dev Randomly gets a new token ID and keeps track of the ones that are still available.
    /// @return the next token ID
    function nextTokenId() internal ensureAvailability returns (uint256) {
        uint256 maxIndex = availableTokenCount();
        uint256 random = _getRandomInt(0, maxIndex);

        uint256 value = 0;
        if (tokenMatrix[random] == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = random;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = tokenMatrix[random];
        }

        // If the last available tokenID is still unused...
        if (tokenMatrix[maxIndex - 1] == 0) {
            // ...store that ID in the current matrix position.
            tokenMatrix[random] = maxIndex - 1;
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            tokenMatrix[random] = tokenMatrix[maxIndex - 1];
        }

        _tokenIdCounter.increment();

        return value;
    }

    function _getRandomInt(uint256 _min, uint256 _max) internal view returns (uint256) {
        uint256 maxIndex = _max - _min;
        uint256 random = uint256(
            keccak256(abi.encodePacked(msg.sender, block.coinbase, block.difficulty, block.gaslimit, block.timestamp))
        ) % maxIndex;

        return _min + random;
    }

    modifier ensureAvailability() {
        require(availableTokenCount() > 0, "Error: No more tokens available");
        _;
    }

    modifier ensureAvailabilityFor(uint256 _numTokens) {
        require(availableTokenCount() >= _numTokens, "Error: No more tokens available");
        _;
    }

    function availableTokenCount() public view returns (uint256) {
        return maxSupply - _tokenIdCounter.current();
    }
}
