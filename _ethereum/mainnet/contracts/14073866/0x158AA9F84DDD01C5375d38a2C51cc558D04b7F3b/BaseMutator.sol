// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the aura.lol authors
// Author David Huber (@cxkoda)

pragma solidity >=0.8.0 <0.9.0;

import "./AuraLol.sol";

contract BaseMutator {
    AuraLol internal callback;

    constructor(AuraLol callback_) {
        callback = callback_;
    }

    function _setTokenData(uint256 tokenId, TokenData memory tokenData)
        internal
    {
        callback.setTokenData(tokenId, tokenData);
    }

    function _getTokenData(uint256 tokenId)
        internal
        view
        returns (TokenData memory)
    {
        return callback.getTokenData(tokenId);
    }
}
