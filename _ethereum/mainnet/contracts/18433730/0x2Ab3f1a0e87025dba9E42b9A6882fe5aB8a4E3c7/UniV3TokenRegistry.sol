// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Clones.sol";
import "./SafeERC20.sol";

import "./INonfungiblePositionManager.sol";
import "./ISwapRouter.sol";

import "./UniV3Token.sol";
import "./UniV3MEVProtection.sol";

contract UniV3TokenRegistry {
    using SafeERC20 for IERC20;

    INonfungiblePositionManager public immutable positionManager;
    UniV3Token public immutable singleton;
    uint256 public numberOfTokens = 1;

    // returns registry id of token by its address
    mapping(address => uint256) private _ids;
    mapping(uint256 => UniV3Token) private _tokenById;

    constructor(
        INonfungiblePositionManager positionManager_,
        ISwapRouter router_,
        UniV3MEVProtection mevProtection,
        bytes32 proxyContractBytecodeHash_
    ) {
        positionManager = positionManager_;
        singleton = new UniV3Token(
            positionManager_,
            router_,
            UniV3TokenRegistry(address(this)),
            mevProtection,
            proxyContractBytecodeHash_
        );
    }

    function idByToken(address token) external view returns (uint256 tokenId) {
        return _ids[token];
    }

    function tokenById(uint256 tokenId) external view returns (address token) {
        return address(_tokenById[tokenId]);
    }

    function createToken(UniV3Token.InitParams memory params) external returns (uint256 currentTokenId, address token) {
        currentTokenId = numberOfTokens++;
        UniV3Token uniV3Token = UniV3Token(Clones.cloneDeterministic(address(singleton), bytes32(currentTokenId)));
        token = address(uniV3Token);
        positionManager.transferFrom(positionManager.ownerOf(params.positionId), token, params.positionId);

        uniV3Token.initialize(params);
        _ids[token] = currentTokenId;
        _tokenById[currentTokenId] = uniV3Token;
    }
}
