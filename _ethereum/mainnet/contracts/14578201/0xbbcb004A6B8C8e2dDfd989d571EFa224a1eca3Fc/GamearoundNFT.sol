// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Counters.sol";

// Gamearound Ecosystem Genesis Token
/// @custom:security-contact claudio@gamearound.com
contract GamearoundNFT is ERC721, Pausable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant FUNDS_ROLE = keccak256("FUNDS_ROLE");

    Counters.Counter internal _tokenIdCounter;

    string baseURI = "ipfs://QmWKVwauSTVdAsA4sLMA3cBp274yp4eM6rcerE1XYn5Uzj/";

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(FUNDS_ROLE, msg.sender);
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _newBaseURI;
    }

    function pause(bool _state) public onlyRole(PAUSER_ROLE) {
        if (_state) {
            _pause();
        } else {
            _unpause();
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        virtual
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
