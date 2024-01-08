// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./WithLimitedSupplyUpgradeable.sol";
import "./IRandomlyAssignedUpgradeable.sol";
import "./OwnableUpgradeable.sol";

/// @author 1001.digital
/// @title Randomly assign tokenIDs from a given set of tokens.
contract RandomlyAssignedUpgradeable is
    WithLimitedSupplyUpgradeable,
    IRandomlyAssignedUpgradeable,
    OwnableUpgradeable
{
    // Used for random index assignment
    mapping(uint256 => uint256) private tokenMatrix;

    // The initial token ID
    uint256 private startFrom;

    // The lastTokenId
    uint256 public lastTokenId;

    function initialize(uint256 _maxSupply, uint256 _startFrom)
        public
        initializer
    {
        __RandomlyAssigned_init(_maxSupply, _startFrom);
    }

    // @param _maxSupply how many tokens this collection should hold
    // @param _startFrom the tokenID with which to start counting
    function __RandomlyAssigned_init(uint256 _maxSupply, uint256 _startFrom)
        internal
        initializer
    {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __WithLimitedSupply_init_unchained(_maxSupply);
        __RandomlyAssigned_init_unchain(_startFrom);
    }

    function __RandomlyAssigned_init_unchain(uint256 _startFrom)
        internal
        initializer
    {
        startFrom = _startFrom;
    }

    /// Get the next token ID
    /// @dev Randomly gets a new token ID and keeps track of the ones that are still available.
    /// @return the next token ID
    function _nextToken()
        internal
        override
        ensureAvailability
        returns (uint256)
    {
        uint256 maxIndex = maxSupply() - tokenCount();
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.coinbase,
                    block.difficulty,
                    block.gaslimit,
                    block.timestamp
                )
            )
        ) % maxIndex;

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

        // Increment counts
        super._nextToken();

        return value + startFrom;
    }

    function nextTokenId() public override onlyOwner returns (uint256) {
        uint256 tokenId = _nextToken();
        lastTokenId = tokenId;
        emit TokenIdCreated(tokenId);
        return tokenId;
    }

    function getMaxSupply() public view override returns (uint256) {
        return maxSupply();
    }
}
