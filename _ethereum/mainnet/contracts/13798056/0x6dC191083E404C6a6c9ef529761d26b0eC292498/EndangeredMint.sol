// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./ERC721MetadataEnumerable.sol";
import "./Strings.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension and the Enumerable extension, designed for the Endangered Mints NFT project.
 */
contract EndangeredMint is ERC721MetadataEnumerable {
    using Strings for uint256;

    address private _conservation;

    uint256 private _conservationOpen;
    uint256 private _conservationClose;
    uint256 private _conservationLock;
    uint256 private _conserved;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 startTime_,
        address conservation_
    ) ERC721MetadataEnumerable(name_, symbol_, baseURI_) {
        _conservationOpen = startTime_;
        _conservationClose = _conservationOpen + 1 weeks;
        // First release has a 3 week window for reward distribution and metadata updates
        _conservationLock = _conservationClose + 3 weeks;
        _conservation = conservation_;
        _conserved = 0;

        /* Mint Founder's Edition Mints */
        for (uint8 i = 0; i < 5; i++) {
            _safeMintInternal(_conservation, "");
        }

        /* Mint reserved community Mints */
        for (uint8 i = 0; i < 5; i++) {
            _safeMintInternal(_conservation, "");
        }
    }

    modifier conservationOwner() {
        require(_conservation == msg.sender, "Only the conservation owner can perform maintenance");
        _;
    }

    function safeMint(address to) public payable virtual {
        safeMint(to, "");
    }
    
    function safeMint(address to, bytes memory _data) public payable virtual {
        _requireMintable();
        _purchase();
        _safeMintInternal(to, _data);
    }

    function mint(address to) public payable virtual {
        _requireMintable();
        _purchase();
        uint256 tokenId = ERC721MetadataEnumerable.totalSupply() + 1;
        ERC721MetadataEnumerable._mint(to, tokenId);
        _conserved += 1;
    }

    function conservationOpen() external view virtual returns(uint256) {
        return _conservationOpen;
    }

    function conservationClose() external view virtual returns(uint256) {
        return _conservationClose;
    }

    function conservationLock() external view virtual returns(uint256) {
        return _conservationLock;
    }

    function _safeMintInternal(address to, bytes memory _data) internal virtual {
        uint256 tokenId = ERC721MetadataEnumerable.totalSupply() + 1;
        ERC721MetadataEnumerable._safeMint(to, tokenId, _data);
        _conserved += 1;
    }

    function _requireMintable() internal view virtual {
        require(_conserved < 1000, "All endangered mints have been conserved");
        require(block.timestamp >= _conservationOpen, "Minting has not yet started");
        require(block.timestamp < _conservationClose, "Minting is no longer possible, sale has ended");
    }

    function _purchase() internal virtual {
        require(msg.value == 0.25 ether, "Payment amount must equal 0.25 Ether");
        (bool paid, ) = _conservation.call{value: msg.value}("");
        require(paid, "Unable to send payment, recipient may have reverted");
    }

    function conservationists() public view virtual returns (address[] memory) {
        address[] memory addrs = new address[](_conserved);
        for (uint256 i = 1; i <= _conserved; i++) {
            addrs[i - 1] = ownerOf(i);
        }
        return addrs;
    }

    function conserved() public view virtual returns (uint256) {
        return _conserved;
    }

    function allConservedBy(address conservationist) public view virtual returns (uint256[] memory) {
        uint256 balance = balanceOf(conservationist);
        uint256[] memory tokens = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(conservationist, i);
        }
        return tokens;
    }

    function setConservationURI(string memory mintURI) public virtual conservationOwner {
        require(block.timestamp < _conservationLock, "Cannot update URI, maintenance window is closed");
        ERC721MetadataEnumerable._setTokenURI(mintURI);
    }

    function mintExclusive(address[] memory owners) public virtual conservationOwner {
        require(block.timestamp < _conservationLock, "Cannot mint exclusive, maintenance window is closed");
        uint256 exclusive = ERC721MetadataEnumerable.totalSupply() - _conserved;
        uint256 startingTokenId = ERC721MetadataEnumerable.totalSupply() + 1;
        // In the extremely improbable event that every mint is used for an exclusive, add 11 to take into
        // account the Ruby mints that provide an exclusive without being paired
        require((exclusive + owners.length) <= _conserved + 11, "Cannot mint an excess number of exclusives");

        for (uint256 i = 0; i < owners.length; i++) {
            ERC721MetadataEnumerable._safeMint(owners[i], startingTokenId + i, "");
        }
    }
}
