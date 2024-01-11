// SPDX-License-Identifier: MIT
// Creators: Toffysoft

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ERC721A.sol";

error QuantityToMintTooHigh();
error MaxSupplyExceeded();
error InsufficientFunds();
error TheCallerIsAnotherContract();

contract CatzCrewz is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_CATZ = 99;

    string private hiddenURI = "";

    mapping(uint256 => string) private revealURI;

    constructor(string memory newHiddenURI) ERC721A("CatzCrewz", "CATZ") {
        setHiddenURI(newHiddenURI);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    modifier mintCompliance(uint256 quantity) {
        if (totalSupply() + quantity > MAX_CATZ) revert MaxSupplyExceeded();
        _;
    }

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert TheCallerIsAnotherContract();
        _;
    }

    function ownerMint(uint256 quantity)
        public
        onlyOwner
        callerIsUser
        nonReentrant
        mintCompliance(quantity)
    {
        _safeMint(owner(), quantity, "");
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory _uri = revealURI[tokenId];
        return
            bytes(_uri).length != 0
                ? _uri
                : string(abi.encodePacked(hiddenURI, tokenId.toString()));
    }

    function setReavealURI(uint256 tokenId, string memory _URI)
        public
        onlyOwner
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        revealURI[tokenId] = _URI;
    }

    function setHiddenURI(string memory newHiddenURI) public onlyOwner {
        hiddenURI = newHiddenURI;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
