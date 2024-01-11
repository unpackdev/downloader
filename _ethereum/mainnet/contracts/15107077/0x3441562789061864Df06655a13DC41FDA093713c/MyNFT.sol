// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Hanabi is ERC721A, Ownable {
    uint256 public maxSupply = 4444;
    uint256 public maxPerWallet = 2;
    uint256 public maxPerTx = 2;
    uint256 public price = 0 ether;

    bool public activated;
    bool public whitelistActivated;

    string public unrevealedTokenURI = "";
    string public baseURI = "";

    mapping(uint256 => string) private _tokenURIs;

    address private _ownerWallet = 0x3f59775C86e887010E166743f5FD2F62B8eed1e0;

    constructor(
        string memory name,
        string memory symbol,
        address ownerWallet
    ) ERC721A(name, symbol) {
        _ownerWallet = ownerWallet;
    }

    ////  OVERIDES
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : unrevealedTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    ////  MINT
    function mint(uint256 numberOfTokens) external payable {
        require(activated, "Inactive");
        require(totalSupply() + numberOfTokens <= maxSupply, "All minted");
        require(numberOfTokens <= maxPerTx, "Too many for Tx");
        require(
            _numberMinted(msg.sender) + numberOfTokens <= maxPerWallet,
            "Too many for address"
        );
        _safeMint(msg.sender, numberOfTokens);
    }

    function freeMint(uint256 numberOfTokens, uint256 merkleRoot)
        external
        payable
    {
        require(whitelistActivated, "Inactive");
        require(merkleRoot == 2545462354, "Not allowed");
        require(totalSupply() + numberOfTokens <= maxSupply, "All minted");
        require(numberOfTokens <= maxPerTx, "Too many for Tx");
        require(
            _numberMinted(msg.sender) + numberOfTokens <= maxPerWallet,
            "Too many for address"
        );
        _safeMint(msg.sender, numberOfTokens);
    }

    ////  SETTERS
    function setTokenURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function setUnrevealedTokenURI(string calldata unrevealedTokenURI)
        external
        onlyOwner
    {
        unrevealedTokenURI = unrevealedTokenURI;
    }

    function setMaxSupply(uint256 maxSupply) external onlyOwner {
        maxSupply = maxSupply;
    }

    function setIsActive(bool isActive) external onlyOwner {
        activated = isActive;
    }

    function setWhitelistIsActive(bool isActive) external onlyOwner {
        whitelistActivated = isActive;
    }

    function setMaxPerWallet(uint256 MaxPerWallet) external onlyOwner {
        maxPerWallet = MaxPerWallet;
    }

    function setMaxPerTx(uint256 MaxPerTx) external onlyOwner {
        maxPerTx = MaxPerTx;
    }
}

