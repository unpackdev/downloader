// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Operatable.sol";

abstract contract ERC721TokenPausable is ERC721, Operatable {
    using Address for address;
    using Roles for Roles.Role;
    Roles.Role private tokenPauser;

    event TokenPauserAdded(address indexed account);
    event TokenPauserRemoved(address indexed account);

    event TokenPaused(uint256 indexed tokenId);
    event TokenUnpaused(uint256 indexed tokenId);

    event SetDefaultTokenPaused(bool defaultTokenPaused);

    // tokenId => bool
    mapping(uint256 => bool) private _tokenPaused;

    bool defaultTokenPaused = false;

    constructor() {
        tokenPauser.add(msg.sender);
    }

    modifier onlyTokenPauser() {
        require(
            isTokenPauser(msg.sender),
            "Only token pauser can call this method"
        );
        _;
    }

    modifier whenNotTokenPaused(uint256 _tokenId) {
        // tokenPauser can do if tokenPaused
        if (!isTokenPauser(msg.sender)) {
            require(!isTokenPaused(_tokenId), "TokenPausable: paused");
        }
        _;
    }

    modifier whenTokenPaused(uint256 _tokenId) {
        require(isTokenPaused(_tokenId), "TokenPausable: not paused");
        _;
    }
    
    function setDefaultTokenPaused(bool _defaultTokenPaused) public onlyOperator {
        defaultTokenPaused = _defaultTokenPaused;
        emit SetDefaultTokenPaused(_defaultTokenPaused);
    }
    
    function isDefaultTokenPaused() public view returns (bool) {
        return defaultTokenPaused;
    }

    function pauseToken(uint256 _tokenId) public onlyTokenPauser() {
        require(!isTokenPaused(_tokenId), "Token is already paused");
        _pauseToken(_tokenId);
    }

    function _pauseToken(uint256 _tokenId) internal {
        _tokenPaused[_tokenId] = true;
        emit TokenPaused(_tokenId);
    }

    function unpauseToken(uint256 _tokenId) public onlyTokenPauser() {
        require(isTokenPaused(_tokenId), "Token is not paused");
        _unpauseToken(_tokenId);
    }

    function _unpauseToken(uint256 _tokenId) internal {
        _tokenPaused[_tokenId] = false;
        emit TokenUnpaused(_tokenId);
    }

    function isTokenPaused(uint256 _tokenId) public view returns (bool) {
        return _tokenPaused[_tokenId];
    }

    function isTokenPauser(address account) public view returns (bool) {
        return tokenPauser.has(account);
    }

    function addTokenPauser(address account) public onlyOperator() {
        require(account.isContract(), "TokenPauser must be contract");
        tokenPauser.add(account);
        emit TokenPauserAdded(account);
    }

    function removeTokenPauser(address account) public onlyOperator() {
        tokenPauser.remove(account);
        emit TokenPauserRemoved(account);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override whenNotPaused() whenNotTokenPaused(tokenId) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
