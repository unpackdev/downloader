// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";


contract MagicalGirlsV2 is ERC721A, Ownable {
    uint256 public MAX_SUPPLY = 4444;
    uint256 public MAX_PER_WALLET = 20;
    uint256 public MAX_PER_TX = 20;
    uint256 public _price = 0 ether;

    bool public activated;

    string public baseURI = "";

    mapping(uint256 => string) private _tokenURIs;

    address private _ownerWallet = 0x338597e4a4702D55715f81F34Ad71a33797C9e82;

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
        return string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    ////  MINT
    function mint(uint256 numberOfTokens) external payable {
        require(activated, "Inactive");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "All minted");
        require(numberOfTokens <= MAX_PER_TX, "Too many for Tx");
        require(
            _numberMinted(msg.sender) + numberOfTokens <= MAX_PER_WALLET,
            "Too many for address"
        );
        _safeMint(msg.sender, numberOfTokens);
    }

    ////  SETTERS
    function setTokenURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        MAX_SUPPLY = _maxSupply;
    }

    function setIsActive(bool _isActive) external onlyOwner {
        activated = _isActive;
    }
}
