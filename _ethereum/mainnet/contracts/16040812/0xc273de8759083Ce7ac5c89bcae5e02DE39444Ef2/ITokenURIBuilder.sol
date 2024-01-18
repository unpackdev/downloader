// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConditionalTokenLibrary.sol";

interface ITokenURIBuilder {
    function tokenURI(
        ConditionalTokenLibrary.Condition memory _condition,
        ConditionalTokenLibrary.Collection memory _collection,
        ConditionalTokenLibrary.Position memory _position,
        uint256 _positionId,
        uint256 _decimals
    ) external view returns (string memory);
}
