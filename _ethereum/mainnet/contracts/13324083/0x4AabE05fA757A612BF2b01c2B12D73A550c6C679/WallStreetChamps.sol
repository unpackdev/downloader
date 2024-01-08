// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract WallStreetChamps is ERC721Enumerable, Ownable {
    // USINGS

    using Strings for uint256;

    // VARIABLES

    uint256 public price;
    uint256 public maxSupply;
    uint256 public maxMintAmount;
    string public baseURI;
    string public baseExtension;
    string public champsProvenance;
    bool public isSaleActive;

    // CONSTRUCTOR

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _price,
        uint256 _maxSupply,
        uint256 _maxMintAmount,
        string memory __baseURI,
        string memory _baseExtension,
        string memory _champsProvenance,
        bool _mintForOwner
    ) ERC721(_name, _symbol) {
        price = _price;
        maxSupply = _maxSupply;
        maxMintAmount = _maxMintAmount;
        baseURI = __baseURI;
        baseExtension = _baseExtension;
        champsProvenance = _champsProvenance;

        if (_mintForOwner) {
            mint(msg.sender, maxMintAmount);
        }
    }

    // INTERNAL

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // OWNER-ONLY FUNCTIONS

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) external onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setBaseExtension(string memory _extension) external onlyOwner {
        baseExtension = _extension;
    }

    function setProvenanceHash(string memory _provenanceHash)
        external
        onlyOwner
    {
        champsProvenance = _provenanceHash;
    }

    function flipSaleStatus() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // PUBLIC FUNCTIONS

    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();

        if (msg.sender != owner()) {
            require(isSaleActive, "Not on sale");
        }

        require(_mintAmount > 0, "Mint amount cannot be 0");
        require(
            _mintAmount <= maxMintAmount,
            "Mint amount has exceeded the max mint amount"
        );
        require(
            supply + _mintAmount <= maxSupply,
            "Mint amount has exceeded the max supply"
        );

        if (msg.sender != owner()) {
            require(
                msg.value >= price * _mintAmount,
                "Not enough ether to mint"
            );
        }

        for (uint256 ctr = 0; ctr < _mintAmount; ctr++) {
            _safeMint(_to, supply + ctr);
        }
    }

    function tokensByOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenList = new uint256[](ownerTokenCount);

        for (uint256 ctr = 0; ctr < ownerTokenCount; ctr++) {
            tokenList[ctr] = tokenOfOwnerByIndex(_owner, ctr);
        }

        return tokenList;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }
}
