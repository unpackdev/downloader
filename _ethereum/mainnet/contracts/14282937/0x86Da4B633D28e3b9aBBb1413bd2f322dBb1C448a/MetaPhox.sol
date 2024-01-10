// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract MetaPhox is ERC721Enumerable, Ownable {
    using Strings for uint256;

    bool public _isSaleActive = false;
    bool public _revealed = false;

    // Constants
    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public mintPrice = 0.08 ether;
    uint256 public maxBalance = 3;
    uint256 public maxMint = 3;

    string baseURI = "";
    string public notRevealedUri = "ipfs://QmYbwn1L56pTktr6LujGYwFUSxZvCnPbU7CyPgVtTcbW3i";
    string public baseExtension = ".json";

    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721("MetaPhox", "MetaPhox"){}

    function mint(uint256 tokenQuantity) public payable {
        require(
            totalSupply() + tokenQuantity <= MAX_SUPPLY,
            "ExceedMax"
        );
        require(_isSaleActive, "NotStart");
        require(
            balanceOf(msg.sender) + tokenQuantity <= maxBalance,
            "ExceedBalance"
        );
        require(
            tokenQuantity * mintPrice <= msg.value,
            "NotEnoughETH"
        );
        require(tokenQuantity <= maxMint, "ExceedAmount");

        _mint(tokenQuantity);
    }

    function _mint(uint256 tokenQuantity) internal {
        for (uint256 i = 0; i < tokenQuantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId),"NotExist");
        if (_revealed == false) {
            return notRevealedUri;
        }
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base,'/', tokenId.toString(), baseExtension));
    }


    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    //if something wrong ,solve it
    function setTokenURI(string memory uri,uint256 tokenId) external onlyOwner{
         _tokenURIs[tokenId] = uri;
    }

    //only owner
    function flipSaleActive() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    function flipReveal() public onlyOwner {
        _revealed = !_revealed;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }

    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }
}