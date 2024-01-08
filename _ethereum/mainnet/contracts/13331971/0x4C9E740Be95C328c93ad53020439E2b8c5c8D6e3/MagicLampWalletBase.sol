// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./MagicLampWalletStorage.sol";

contract MagicLampWalletBase is MagicLampWalletStorage, Ownable {
    using SafeMath for uint256;

    function _onlyWalletOwner(address host, uint256 id) internal view {
        require(walletFeatureHosted[host], "Unsupported host");
        require(
            IERC721(host).ownerOf(id) == _msgSender(),
            "Only wallet owner can call"
        );
    }

    function _exists(address host, uint256 id) internal view {
        require(walletFeatureHosted[host], "Unsupported host");
        require(IERC721(host).ownerOf(id) != address(0), "NFT does not exist");
    }

    function _unlocked(address host, uint256 id) internal view {
        require(_lockedTimestamps[host][id] <= block.timestamp, "Wallet is locked");
    }

    function _onlyWalletOwnerOrHost(address host, uint256 id) internal view {
        require(walletFeatureHosted[host], "Unsupported host");
        require(
            IERC721(host).ownerOf(id) == _msgSender() || host == _msgSender(),
            "Only wallet owner or host can call"
        );
    }

    /**
     * @dev Puts token(type, address)
     */
    function _putToken(address host, uint256 id, uint8 tokenType, address token) internal {
        Token[] storage tokens = _tokens[host][id];

        uint256 i = 0;
        for (; i < tokens.length && (tokens[i].tokenType != tokenType || tokens[i].tokenAddress != token); i++) {
        }

        if (i == tokens.length) {
            tokens.push(Token({tokenType: tokenType, tokenAddress: token}));
        }
    }

    /**
     * @dev Pops token(type, address)
     */
    function _popToken(address host, uint256 id, uint8 tokenType, address token) internal {
        Token[] storage tokens = _tokens[host][id];

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i].tokenType == tokenType && tokens[i].tokenAddress == token) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                if (tokens.length == 0) {
                    delete _tokens[host][id];
                }
                return;
            }
        }        
        require(false, "Not found token");
    }

    /**
     * @dev Puts a token id
     */
    function _putTokenId(address host, uint256 id, uint8 tokenType, address token, uint256 tokenId) internal {
        if (_erc721ERC1155TokenIds[host][id][token].length == 0) {
            _putToken(host, id, tokenType, token);
        }
        _erc721ERC1155TokenIds[host][id][token].push(tokenId);
    }

    /**
     * @dev Pops a token id
     */
    function _popTokenId(address host, uint256 id, uint8 tokenType, address token, uint256 tokenId) internal {
        uint256[] storage ids = _erc721ERC1155TokenIds[host][id][token];

        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == tokenId) {
                ids[i] = ids[ids.length - 1];
                ids.pop();
                if (ids.length == 0) {
                    delete _erc721ERC1155TokenIds[host][id][token];
                    _popToken(host, id, tokenType, token);
                }
                return;
            }
        }
        require(false, "Not found token id");
    }

    /**
     * @dev Adds token balance
     */
    function _addERC20TokenBalance(address host, uint256 id, address token, uint256 amount) internal {
        if (amount == 0) return;
        if (_erc20TokenBalances[host][id][token] == 0) {
            _putToken(host, id, _TOKEN_TYPE_ERC20, token);
        }
        _erc20TokenBalances[host][id][token] = _erc20TokenBalances[host][id][token].add(amount);
    }

    /**
     * @dev Subs token balance
     */
    function _subERC20TokenBalance(address host, uint256 id, address token, uint256 amount) internal {
        if (amount == 0) return;
        _erc20TokenBalances[host][id][token] = _erc20TokenBalances[host][id][token].sub(amount);
        if (_erc20TokenBalances[host][id][token] == 0) {
            _popToken(host, id, _TOKEN_TYPE_ERC20, token);
        }
    }

    /**
     * @dev Adds ERC1155 token balance
     */
    function _addERC1155TokenBalance(address host, uint256 id, address token, uint256 tokenId, uint256 amount) internal {
        if (amount == 0) return;
        if (_erc1155TokenBalances[host][id][token][tokenId] == 0) {
            _putTokenId(host, id, _TOKEN_TYPE_ERC1155, token, tokenId);
        }
        _erc1155TokenBalances[host][id][token][tokenId] = _erc1155TokenBalances[host][id][token][tokenId].add(amount);
    }

    /**
     * @dev Subs ERC1155 token balance
     */
    function _subERC1155TokenBalance(address host, uint256 id, address token, uint256 tokenId, uint256 amount) internal {
        if (amount == 0) return;
        _erc1155TokenBalances[host][id][token][tokenId] = _erc1155TokenBalances[host][id][token][tokenId].sub(amount);
        if (_erc1155TokenBalances[host][id][token][tokenId] == 0) {
            _popTokenId(host, id, _TOKEN_TYPE_ERC1155, token, tokenId);
        }
    }
}