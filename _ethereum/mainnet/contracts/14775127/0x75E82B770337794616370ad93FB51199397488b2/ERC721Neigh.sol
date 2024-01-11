// SPDX-License-Identifier: MIT
/// @title: Ric Rac Equestrian Club
/// @author: DropHero LLC

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC2981.sol";
import "./Strings.sol";

error MustMintAtLeastOne();
error MaxTokenSupplyExceeded();
error MaxReserveSupplyExceeded();

contract ERC721Neigh is ERC721A, AccessControlEnumerable, Pausable, Ownable, ERC2981 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint16 public MAX_SUPPLY = 6969;
    uint16 _remainingReserved = 111;

    string _baseURIValue;
    string _preRevealIPFSHash;

    constructor(string memory preRevealIPFSHash_) ERC721A("Ric Rac Equestrian Club", "RREC") {
        _preRevealIPFSHash = preRevealIPFSHash_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
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

    function setBaseURI(string memory newBase) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseURIValue = newBase;
    }

    function preRevealIPFSHash() public view returns (string memory) {
        return _preRevealIPFSHash;
    }

    function setPreRevealIPFSHash(string memory newValue) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _preRevealIPFSHash = newValue;
    }

    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        if (bytes(_baseURIValue).length == 0) {
            return string(abi.encodePacked("ipfs://", _preRevealIPFSHash));
        } else {
            return super.tokenURI(tokenId);
        }
    }

    function remainingReservedSupply() public view returns(uint16) {
        return _remainingReserved;
    }

    function mintTokens(uint16 numberOfTokens, address to) external
        onlyRole(MINTER_ROLE)
        whenNotPaused
    {
        if (numberOfTokens < 1) {
            revert MustMintAtLeastOne();
        }

        if (totalSupply() + numberOfTokens + _remainingReserved > MAX_SUPPLY) {
            revert MaxTokenSupplyExceeded();
        }

        _safeMint(to, numberOfTokens);
    }

    function mintReserved(uint16 numberOfTokens, address to) external
        onlyOwner
        whenNotPaused
    {
        if (numberOfTokens < 1) {
            revert MustMintAtLeastOne();
        }

        if (totalSupply() + numberOfTokens > MAX_SUPPLY) {
            revert MaxTokenSupplyExceeded();
        }

        if (numberOfTokens > _remainingReserved) {
            revert MaxReserveSupplyExceeded();
        }

        _safeMint(to, numberOfTokens);
        _remainingReserved -= numberOfTokens;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setRoyaltiesInfo(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function _startTokenId() internal override view virtual returns (uint256) {
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
