// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Auth.sol";

// import "./console.sol";

contract BoosterBox is Ownable, ERC721A, Auth {
    string private _name;
    string private _symbol;
    string private _tokenMetadataRoot;
    string private _contractMetadataRoot;
    uint256 private _maxSupply;

    bool private _mintsPaused;
    bool private _burnsPaused;
    bool private _transfersPaused;

    uint16 public constant ROLE_MINT = 1 << 0;
    uint16 public constant ROLE_BURN = 1 << 1;
    uint16 public constant ROLE_REFRESH_METADATA = 1 << 2;
    uint16 public constant ROLE_SET_PAUSED = 1 << 3;
    uint16 public constant ROLE_ADMIN =
        ROLE_MINT | ROLE_BURN | ROLE_REFRESH_METADATA | ROLE_SET_PAUSED;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory tokenMetadataRoot_,
        string memory contractMetadataRoot_,
        uint256 maxSupply_
    ) ERC721A(name_, symbol_) {
        // Set metadata
        setMetadata(name_, symbol_, tokenMetadataRoot_, contractMetadataRoot_);

        // Give the deployer (owner) full permissions
        setRole(msg.sender, ROLE_ADMIN);

        // Set max supply.
        _maxSupply = maxSupply_;
    }

    function setMetadata(
        string memory name_,
        string memory symbol_,
        string memory tokenMetadataRoot_,
        string memory contractMetadataRoot_
    ) public onlyOwner {
        _name = name_;
        _symbol = symbol_;
        _tokenMetadataRoot = tokenMetadataRoot_;
        _contractMetadataRoot = contractMetadataRoot_;
    }

    function setPaused(
        bool mints,
        bool burns,
        bool transfers
    ) public requireRole(ROLE_SET_PAUSED) {
        _mintsPaused = mints;
        _burnsPaused = burns;
        _transfersPaused = transfers;
    }

    function isPaused() public view returns (bool, bool, bool) {
        return (_mintsPaused, _burnsPaused, _transfersPaused);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 2 ** 32;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenMetadataRoot;
    }

    function contractURI() public view returns (string memory) {
        return _contractMetadataRoot;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function mint(address to, uint256 quantity) public requireRole(ROLE_MINT) {
        require(
            quantity + _totalMinted() <= _maxSupply,
            "Quantity exceeds max supply."
        );

        _safeMint(to, quantity);
    }

    function burn(address from, uint256 id) public requireRole(ROLE_BURN) {
        require(ownerOf(id) == from, "Address doesn't own token.");

        _burn(id);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256,
        uint256
    ) internal view override {
        if (from == address(0)) {
            require(!_mintsPaused, "Mints are paused.");
        }

        if (to == address(0)) {
            require(!_burnsPaused, "Burns are paused.");
        }

        if (from != address(0) && to != address(0)) {
            require(!_transfersPaused, "Transfers are paused.");
        }
    }

    function setRole(address operator, uint16 mask) public onlyOwner {
        _setRole(operator, mask);
    }

    function hasRole(address operator, uint16 role) public view returns (bool) {
        return _hasRole(operator, role);
    }

    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    function updateMetadata(
        uint256 id
    ) public requireRole(ROLE_REFRESH_METADATA) {
        emit MetadataUpdate(id);
    }

    function updateMetadataRange(
        uint256 from,
        uint256 to
    ) public requireRole(ROLE_REFRESH_METADATA) {
        emit BatchMetadataUpdate(from, to);
    }

    function updateAllMetadata() public requireRole(ROLE_REFRESH_METADATA) {
        emit BatchMetadataUpdate(0, type(uint256).max);
    }
}
