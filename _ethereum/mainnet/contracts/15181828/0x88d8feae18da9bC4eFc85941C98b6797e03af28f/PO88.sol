// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./ERC721.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract PO88 is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public constant maxSupply = 10000;
    bool public revealed;

    string private baseUri = "ipfs://";
    string private baseExtension = ".json";

    mapping(uint256 => uint256) public tokensMapType;
    mapping(uint256 => string) public mapURIs;

    event MintedMap(address minter, uint256 amount, uint256 maptype);

    constructor(string[] memory initMapUris) ERC721("Pieces of 88", "Po88") {
        for (uint256 i = 0; i < initMapUris.length; i++) {
            mapURIs[i] = initMapUris[i];
        }
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA");
        _;
    }

    function calculatePrice(uint256 amount, uint256 mapType)
        public
        pure
        returns (uint256)
    {
        require(mapType == 0 || mapType == 1 || mapType == 2, "wrong option");
        if (mapType == 0) {
            // Tortuga
            return (amount * 0.01 ether);
        } else if (mapType == 1) {
            // Hispanola
            return (amount * 0.02 ether);
        } else if (mapType == 2) {
            // Cartagena
            return (amount * 0.03 ether);
        }
    }

    function mintMap(uint256 amount, uint256 mapType) external payable onlyEOA {
        require(amount > 0, "Incorrect amount");
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        require(
            msg.value >= calculatePrice(amount, mapType),
            "Incorrect Price sent"
        );
        require(mapType >= 0 && mapType < 3, "wrong mapType");

        _mintToken(msg.sender, amount, mapType);
    }

    function _mintToken(
        address to,
        uint256 amount,
        uint256 mapType
    ) private {
        uint256 id;
        for (uint256 i = 0; i < amount; i++) {
            _tokenIds.increment();
            id = _tokenIds.current();
            tokensMapType[id] = mapType;
            _mint(to, id);
            emit MintedMap(msg.sender, amount, mapType);
        }
    }

    function setBaseExtension(string memory newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = newBaseExtension;
    }

    function setBaseUri(string memory newBaseUri) external onlyOwner {
        baseUri = newBaseUri;
    }

    function setMapURIs(uint256 maptype, string memory newMapURI)
        external
        onlyOwner
    {
        mapURIs[maptype] = newMapURI;
    }

    function setRevealed(bool newRevealed) external onlyOwner {
        revealed = newRevealed;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory _tokenURI = "Token with that ID does not exist.";
        if (_exists(tokenId)) {
            if (revealed) {
                _tokenURI = string(
                    abi.encodePacked(baseUri, tokenId.toString(), baseExtension)
                );
            } else {
                _tokenURI = string(
                    abi.encodePacked(
                        mapURIs[tokensMapType[tokenId]],
                        tokenId.toString(),
                        baseExtension
                    )
                );
            }
        }
        return _tokenURI;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function withdrawBalance() external onlyOwner {
        (bool s, ) = payable(owner()).call{value: address(this).balance}("");
        require(s, "tx failed");
    }
}
