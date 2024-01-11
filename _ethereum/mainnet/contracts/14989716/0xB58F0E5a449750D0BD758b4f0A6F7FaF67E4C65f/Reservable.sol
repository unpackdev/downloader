// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "./Revealable.sol";

/// @title Reserveable
/// @author Chain Labs
/// @notice Module that adds functionality of reserving tokens from sale. Reserved tokens cannot be bought.
/// @dev Reserves tokens from token ID 1, mints them on demand
contract Reserveable is Revealable {
    //------------------------------------------------------//
    //
    //  Storage
    //
    //------------------------------------------------------//

    /// @notice total reserved tokends
    /// @dev total reserved tokens, it can be updated by owner until first buy (presale or main sale)
    /// @return reservedTokens the return variables of a contract’s function state variable
    uint256 public reservedTokens;

    /// @notice next token ID that will be minted from reserved tokens
    /// @dev next token ID counter for minting from reserved tokens
    /// @return reserveTokenCounter the return variables of a contract’s function state variable
    uint256 public reserveTokenCounter;

    //------------------------------------------------------//
    //
    //  Owner only functions
    //
    //------------------------------------------------------//

    /// @notice set reserved tokens
    /// @dev only owner can set reserved tokens state
    /// @param _reserveTokens number of tokens to be reserved
    function reserveTokens(uint256 _reserveTokens) external onlyOwner {
        _setReserveTokens(_reserveTokens);
    }

    /// @notice set reserved tokens
    /// @dev internal method to set reserved tokens state
    /// @param _reserveTokens number of tokens to be reserved
    function _setReserveTokens(uint256 _reserveTokens) internal {
        require(tokensCount == 0, "RS:001");
        require(
            _reserveTokens + presaleReservedTokens <= maximumTokens,
            "RS:002"
        );
        reservedTokens = _reserveTokens;
        startingTokenIndex = _reserveTokens;
    }

    /// @notice transfer reserve tokens to list of receivers
    /// @dev mints tokens from reserved tokens to the receivers
    /// @param _receivers array of addresses that will receive token in sequential order
    function transferReservedTokens(address[] memory _receivers)
        external
        onlyOwner
    {
        uint256 currentTokenId = reserveTokenCounter;
        require(currentTokenId + _receivers.length <= reservedTokens, "RS:003");
        reserveTokenCounter += _receivers.length;
        for (uint256 i; i < _receivers.length; i++) {
            _safeMint(_receivers[i], currentTokenId + 1 + i);
        }
    }
}
