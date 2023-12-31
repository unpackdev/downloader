// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC165.sol";
import "./Ownable.sol";

import "./IBridgeTokenManager.sol";
import "./Errors.sol";
import "./RToken.sol";

contract BridgeTokenManager is ERC165, Ownable, IBridgeTokenManager {
    uint256 private immutable _chainId;

    mapping(bytes32 => bytes32) private _keychain;
    mapping(bytes32 => RToken.Token) private _tokens;
    mapping(bytes32 => uint256) private _limits;

    constructor() {
        uint256 chainId_;
        assembly {
            chainId_ := chainid()
        }
        _chainId = chainId_;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IBridgeTokenManager).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev This should be responsible to set of a local token limit of entrance for the bridge to any direction
     * @param tokenAddr address of token
     * @param amt amount of the limit
     */
    function setLimit(
        address tokenAddr,
        uint256 amt
    ) external override onlyOwner {
        _limits[_createLimitKey(tokenAddr)] = amt;
        emit LimitUpdated(tokenAddr, amt);
    }

    function limits(
        address tokenAddr
    ) external view override returns (uint256) {
        return _limits[_createLimitKey(tokenAddr)];
    }

    /**
     * @dev This should be responsible to get token mapping for current chain
     * @param sourceAddr address of source token
     * @param sourceChainId chain id of token on origin
     * @param targetChainId chain id of token on target
     */
    function getLocal(
        address sourceAddr,
        uint256 sourceChainId,
        uint256 targetChainId
    ) public view override returns (RToken.Token memory token) {
        bytes32 tokenKey = _keychain[
            _createLinkKey(sourceAddr, sourceChainId, targetChainId)
        ];
        if (tokenKey == 0) {
            return token;
        }
        bytes32 sourceKey;
        if (_chainId != targetChainId) {
            sourceKey = tokenKey;
        } else {
            sourceKey = _keychain[tokenKey];
        }
        token = _tokens[sourceKey];
    }

    /**
     * @dev This should be responsible to remove tokens connection between chains
     * @param targetAddr address of target token
     * @param targetChainId chain id of target
     */
    function revoke(
        address targetAddr,
        uint256 targetChainId
    ) external override onlyOwner {
        bytes32 sourceKey = _keychain[
            _createLinkKey(targetAddr, targetChainId, _chainId)
        ];
        require(sourceKey != 0, Errors.B_ENTITY_NOT_EXIST);

        bytes32 targetKey = _keychain[sourceKey];
        require(targetKey != 0, Errors.B_ENTITY_NOT_EXIST);

        delete _keychain[sourceKey];
        delete _keychain[targetKey];

        RToken.Token memory sourceToken = _tokens[sourceKey];
        RToken.Token memory targetToken = _tokens[targetKey];

        delete _tokens[sourceKey];
        delete _tokens[targetKey];

        emit TokenRemoved(sourceToken.addr, sourceToken.chainId);
        emit TokenRemoved(targetToken.addr, targetToken.chainId);
    }

    /**
     * @dev This should be responsible to connect tokens between chains
     * @param sourceToken source token to create a link connection
     * @param targetToken target token to create a link connection
     */
    function issue(
        RToken.Token calldata sourceToken,
        RToken.Token calldata targetToken
    ) external override onlyOwner {
        require(sourceToken.chainId == _chainId, Errors.M_ONLY_EXTERNAL);
        require(targetToken.chainId != _chainId, Errors.M_SAME_CHAIN);
        require(sourceToken.exist, Errors.B_ENTITY_NOT_EXIST);
        require(targetToken.exist, Errors.B_ENTITY_NOT_EXIST);

        bytes32 sourceKey = _createLinkKey(
            targetToken.addr,
            targetToken.chainId,
            sourceToken.chainId
        );
        require(_keychain[sourceKey] == 0, Errors.M_SOURCE_EXIST);

        bytes32 targetKey = _createLinkKey(
            sourceToken.addr,
            sourceToken.chainId,
            targetToken.chainId
        );
        require(_keychain[targetKey] == 0, Errors.M_TARGET_EXIST);

        // linking
        _keychain[sourceKey] = targetKey;
        _keychain[targetKey] = sourceKey;
        _tokens[sourceKey] = sourceToken;
        _tokens[targetKey] = targetToken;

        emit TokenAdded(sourceToken.addr, sourceToken.chainId);
        emit TokenAdded(targetToken.addr, targetToken.chainId);
    }

    function _createLinkKey(
        address sourceAddr,
        uint256 sourceChainId,
        uint256 targetChainId
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(sourceAddr, sourceChainId, targetChainId)
            );
    }

    function _createLimitKey(address addr) private view returns (bytes32) {
        return keccak256(abi.encodePacked(addr, _chainId));
    }
}
