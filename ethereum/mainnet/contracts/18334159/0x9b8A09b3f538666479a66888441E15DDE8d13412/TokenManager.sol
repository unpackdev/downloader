/*
 * Capital DEX
 *
 * Copyright ©️ 2023 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2023 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./AccessControl.sol";
import "./Context.sol";
import "./ERC165Checker.sol";

interface ITokenManager {
    enum TokenStatus { NotSupported, Active, Paused }

    event TokenAdded(IERC20 token);
    event TokenRemoved(IERC20 token);
    event TokenPaused(IERC20 token);
    event TokenUnpaused(IERC20 token);

    error TokenAlreadySupported(IERC20 token);
    error TokenNotSupported(IERC20 token);

    error TokenNotActive(IERC20 token);
    error TokenNotPaused(IERC20 token);
    
    error AddressDoesNotSupportIERC20(address token);

    function addToken(IERC20 token, bool paused, bool force) external;
    function removeToken(IERC20 token) external;
    function setTokenPause(IERC20 token, bool pause) external;
    function tokenStatus(IERC20 token) external view returns(TokenStatus);
    function isTokenSupported(IERC20 token) external view returns(bool);
    function isTokenPaused(IERC20 token) external view returns(bool);
}

contract TokenManager is ITokenManager, Context, AccessControl {
    using ERC165Checker for address;

    bytes32 public immutable tokenManagerRole;

    mapping(IERC20 => TokenStatus) public supportedTokens;

    modifier OnlySupportedToken(IERC20 token) {
        ensureTokenSupported(token);
        _;
    }

    modifier OnlyActiveToken(IERC20 token) {
        ensureTokenActive(token);
        _;
    }

    modifier OnlyPausedToken(IERC20 token) {
        ensureTokenPaused(token);
        _;
    }

    constructor(address admin, bytes32 managerRole) {
        tokenManagerRole = managerRole;
        AccessControl._grantRole(AccessControl.DEFAULT_ADMIN_ROLE, admin);
    }

    function addToken(IERC20 token, bool paused, bool force) external AccessControl.onlyRole(tokenManagerRole) {
        if(!address(token).supportsInterface(type(IERC20).interfaceId) && !force) {
            revert AddressDoesNotSupportIERC20(address(token));
        }

        if(isTokenSupported(token)) {
            revert TokenAlreadySupported(token);
        }

        if(paused){
            supportedTokens[token] = TokenStatus.Paused;
        } else {
            supportedTokens[token] = TokenStatus.Active;
        }

        emit TokenAdded(token);
    }

    function removeToken(IERC20 token) external AccessControl.onlyRole(tokenManagerRole) OnlySupportedToken(token) {
        supportedTokens[token] = TokenStatus.NotSupported;

        emit TokenRemoved(token);
    }

    function setTokenPause(IERC20 token, bool pause) external AccessControl.onlyRole(tokenManagerRole) OnlySupportedToken(token) {
        if(pause) {
            _pauseToken(token);
        } else {
            _unpauseToken(token);
        }
    }

    function isTokenSupported(IERC20 token) public view returns(bool) {
        return supportedTokens[token] != TokenStatus.NotSupported;
    }

    function isTokenPaused(IERC20 token) public view returns(bool) {
        return supportedTokens[token] == TokenStatus.Paused;
    }

    function isTokenActive(IERC20 token) public view returns(bool) {
        return supportedTokens[token] == TokenStatus.Active;
    }

    function tokenStatus(IERC20 token) public view returns(TokenStatus) {
        return supportedTokens[token];
    }

    function ensureTokenSupported(IERC20 token) internal view {
        if(!isTokenSupported(token)) {
            revert TokenNotSupported(token);
        }
    }

    function ensureTokenActive(IERC20 token) internal view {
        if(!isTokenActive(token)) {
            revert TokenNotActive(token);
        }
    }

    function ensureTokenPaused(IERC20 token) internal view {
        if(!isTokenPaused(token)) {
            revert TokenNotPaused(token);
        }
    }

    function _pauseToken(IERC20 token) private OnlyActiveToken(token) {
        supportedTokens[token] = TokenStatus.Paused;
        emit TokenPaused(token);
    }

    function _unpauseToken(IERC20 token) private OnlyPausedToken(token) {
        supportedTokens[token] = TokenStatus.Active;
        emit TokenUnpaused(token);
    }
}