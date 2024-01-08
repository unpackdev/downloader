// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Burnable.sol";

abstract contract AbstractSignature is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    struct ColorMetaData {
        bytes color;
        uint decimal;
    }

    bytes constant _alphabet = "0123456789abcdef";

    uint16 constant _canvasSize = 960;
    uint8 constant _gridCount = 6;
    uint16 constant  _gridSize = 160;

    string constant _svgPrefix = "<svg viewBox=\\\"0 0 960 960\\\" style=\\\"max-width:100vmin;max-height:100vmin;\\\" xmlns=\\\"http://www.w3.org/2000/svg\\\">";
    string constant _svgSuffix = "</svg>";

    uint16 private _maxSupply;
    uint256 private _mintPriceWei;
    uint256 private _mintPriceSingleWei;

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => uint256) _tokenIdMap;

    string[3] _styles;
    string[6] _gridPos;
    string[6] _gridCentrePos;

    string private _description;
    string private _collectionUrl;

    constructor(string memory name_, string memory collectionUrl_, string memory description_, string memory key_) ERC721(name_, key_) {
        _description = description_;
        _collectionUrl = collectionUrl_;

        _maxSupply = 9999;
        _mintPriceWei = 50_000_000_000_000_000;
        _mintPriceSingleWei = 20_000_000_000_000_000;

        _gridPos[0] = "0";
        _gridPos[1] = "160";
        _gridPos[2] = "320";
        _gridPos[3] = "480";
        _gridPos[4] = "640";
        _gridPos[5] = "800";

        _gridCentrePos[0] = "80";
        _gridCentrePos[1] = "240";
        _gridCentrePos[2] = "400";
        _gridCentrePos[3] = "560";
        _gridCentrePos[4] = "720";
        _gridCentrePos[5] = "880";
    }

    function initialConfig() external view returns(uint256[4] memory) {
        uint256[4] memory result;
        result[0] = _maxSupply;
        result[1] = ERC721Enumerable.totalSupply();
        result[2] = _mintPriceWei;
        result[3] = _mintPriceSingleWei;
        return result;
    }

    function userConfig() external view returns(uint8[] memory, uint256[] memory) {
        uint256 tokenPrefix = uint256(uint160(msg.sender)) << 4;

        uint8[] memory _minted;
        uint256[] memory _owned;

        uint256[] memory tokenIds = new uint256[](3);
        uint256[] memory minted = new uint256[](3);
        uint8 mintedCount = 0;
        for (uint8 i=0;i<3;i++) {
            tokenIds[i] = tokenPrefix + i + 1;
            minted[i] = _tokenIdMap[tokenIds[i]];
            if (minted[i] > 0) {
                mintedCount = mintedCount + 1;
            }
        }

        if (mintedCount > 0) {
            uint8 index = 0;
            _minted = new uint8[](mintedCount);
            for (uint8 i=0;i<3;i++) {
                if (minted[i] > 0) {
                    _minted[index] = i + 1;
                    index = index + 1;
                }
            }
        }

        uint256 ownerCount = ERC721.balanceOf(msg.sender);
        if (ownerCount > 0) {
            _owned = new uint256[](ownerCount);
            for (uint i=0;i<ownerCount;i++) {
                _owned[i] = tokenOfOwnerByIndex(msg.sender, i);
            }
        }

        return (_minted, _owned);
    }

    function updateMaxSupply(uint16 maxSupply) external onlyOwner {
        require(maxSupply >= ERC721Enumerable.totalSupply(), "Can't reduce supply below total supply");
        require(maxSupply < _maxSupply, "Can't increase supply");
        _maxSupply = maxSupply;
    }

    function updateMintPriceWei(uint256 priceWei) external onlyOwner {
        _mintPriceWei = priceWei;
    }

    function updateMintPriceSingleWei(uint256 priceSingleWei) external onlyOwner {
        _mintPriceSingleWei = priceSingleWei;
    }

    function claim(address to) external onlyOwner {
        _mintInternal(to);
    }

    function mint() external payable {
        require(msg.value >= _mintPriceWei, "Must send at least mintPriceWei");
        _mintInternal(msg.sender);
        _pay(_mintPriceWei);
    }

    function _mintInternal(address to) private {
        require(to != address(0), "Can't mint for zero address");
        require(_tokenIdCounter.current() + 3 <= _maxSupply, string(abi.encodePacked("ERC721: Series already minted")));

        uint256 tokenPrefix = uint256(uint160(to)) << 4;

        for (uint i=1;i<=3;i++) {
            require(!_exists(tokenPrefix + i), "One or more requested tokens already minted!");
        }

        for (uint i=1;i<=3;i++) {
            uint256 tokenId = tokenPrefix + i;
            _safeMint(to, tokenId);
            _tokenIdCounter.increment();
            _tokenIdMap[tokenId] = _tokenIdCounter.current();
        }
    }

    function mintSingle(uint256 styleId) external payable {
        address to = msg.sender;
        require(to != address(0), "Can't mint for zero address");
        require(msg.value >= _mintPriceSingleWei, "Must send at least mintPriceSingleWei");
        require(_tokenIdCounter.current() < _maxSupply, string(abi.encodePacked("ERC721: Series already minted")));

        uint256 tokenId = (uint256(uint160(to)) << 4) + styleId;
        require(!_exists(tokenId), "Token already minted!");

        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
        _tokenIdMap[tokenId] = _tokenIdCounter.current();

        _pay(_mintPriceSingleWei);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        require(_exists(tokenId), "ERC721: missing token!");
        uint256 styleId = tokenId & 0xF;
        uint256 mintAddress = tokenId >> 4;
        ColorMetaData[] memory colors = _addressToColors(mintAddress);
        string memory image = _draw(styleId, colors);
        string memory id = _uintToString(_tokenIdMap[tokenId]);
        return string(abi.encodePacked("data:application/json;utf8,{\"name\": \"", ERC721.name(), " #", id, "\", \"description\": \"" , _description, "\", \"attributes\": [{\"trait_type\": \"Style\", \"value\": \"", _styles[styleId-1], "\"}], \"image_data\": \"", image, "\", \"external_url\": \"https://obsolete.design/art/collection/", _collectionUrl, "/gallery/", _uintToString(tokenId), "\", \"background_color\": \"110011\"}"));
    }

    function _draw(uint256 /* styleId */, ColorMetaData[] memory /* colors */) internal view virtual returns(string memory) {
        return "";
    }

    function _pay(uint256 amount) internal {
        if (msg.value > 0) {
            uint256 refund = msg.value - amount;

            if (refund > 0) {
                payable(msg.sender).transfer(refund);
            }

            payable(owner()).transfer(amount);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        delete _tokenIdMap[tokenId];
    }


    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    function _addressToColors(uint256 _addr) internal pure returns(ColorMetaData[] memory) {
        ColorMetaData[] memory colors = new ColorMetaData[](36);

        for (uint i = 0; i < 36; i++) {
            colors[i] = ColorMetaData({color: new bytes(6), decimal: 0});
        }

        uint256 mask = 0xf;
        for (uint i = 0; i < 40; i++) {
            uint256 index = (_addr >> (4 * (39 - i))) & mask;
            bytes1 hexChar = _alphabet[index];

            for (uint j = 0; j < 6; j++) {
                if (i >= j && i < (36 + j)) {
                    ColorMetaData memory cmd = colors[i - j];
                    cmd.color[j] = hexChar;
                    cmd.decimal = cmd.decimal + (index << 4 * (5 - j));
                }
            }
        }
        colors[35].color[5] = colors[0].color[0];
        return colors;
    }

    function _uintToString(uint v) internal pure returns(string memory) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        if (v == 0) {
            return "0";
        }

        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1];
        }
        return string(s);
    }
}
