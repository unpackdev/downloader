// SPDX-License-Identifier: MIT
/// @title: HDL Genesis Token
/// @author: DropHero LLC

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC2981.sol";
import "./Strings.sol";

error MustMintAtLeastOne();
error MaxTokenSupplyExceeded();

contract HDLGenesisToken is
    ERC721A,
    ERC721ABurnable,
    AccessControlEnumerable,
    Pausable,
    Ownable,
    ERC2981
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint16 public MAX_SUPPLY = 1000;

    string _baseURIValue;
    string _preRevealIPFSHash;

    constructor(string memory preRevealIPFSHash_, address projectWallet)
        ERC721A("The Deity", "DEITY")
    {
        _preRevealIPFSHash = preRevealIPFSHash_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setDefaultRoyalty(projectWallet, 1000);
        _safeMint(projectWallet, 50);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory newBase)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseURIValue = newBase;
    }

    function preRevealIPFSHash() public view returns (string memory) {
        return _preRevealIPFSHash;
    }

    function setPreRevealIPFSHash(string memory newValue)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _preRevealIPFSHash = newValue;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (bytes(_baseURIValue).length == 0) {
            return string(abi.encodePacked("ipfs://", _preRevealIPFSHash));
        } else {
            return super.tokenURI(tokenId);
        }
    }

    function mintTokens(uint16 numberOfTokens, address to)
        external
        onlyRole(MINTER_ROLE)
        whenNotPaused
    {
        if (numberOfTokens < 1) {
            revert MustMintAtLeastOne();
        }

        if (totalSupply() + numberOfTokens > MAX_SUPPLY) {
            revert MaxTokenSupplyExceeded();
        }

        _safeMint(to, numberOfTokens);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setRoyaltiesInfo(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControlEnumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
