// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the aura.lol authors
// Author David Huber (@cxkoda)

pragma solidity >=0.8.0 <0.9.0;

import "./BaseMutator.sol";
import "./Ownable.sol";

contract GodMutator is Ownable, BaseMutator {
    constructor(AuraLol callback, address newOwner) BaseMutator(callback) {
        transferOwnership(newOwner);
    }

    function setTokenData(uint256 tokenId, TokenData memory tokenData)
        external
        onlyOwner
    {
        _setTokenData(tokenId, tokenData);
    }

    function incrementGeneration(uint256 tokenId) external onlyOwner {
        TokenData memory data = _getTokenData(tokenId);
        data.generation++;
        _setTokenData(tokenId, data);
    }

    function setGeneration(uint256 tokenId, uint96 generation)
        external
        onlyOwner
    {
        TokenData memory data = _getTokenData(tokenId);
        data.generation = generation;
        _setTokenData(tokenId, data);
    }
}
