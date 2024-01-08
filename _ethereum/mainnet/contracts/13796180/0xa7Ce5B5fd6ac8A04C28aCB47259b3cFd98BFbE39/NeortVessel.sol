//SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Strings.sol";

interface iNeortVessel {

    function maxMintableTokenId() external view returns (uint256);

    function remainingAmountForPromotion() external view returns (uint256);

    function remainingAmountForSale() external view returns (uint256);

    function isOnSale() external view returns (bool);

    function mintedSalesTokenIdList(
        uint256 offset,
        uint256 limit
    ) external view returns (uint256[] memory);

    function buy(uint256 tokenId) external payable;

    function buyBundle(uint256[] memory tokenIdList) external payable;

    // functions for admin

    function setOnSale(bool _isOnSale) external;

    function updateBaseURI(string calldata newBaseURI) external;

    function freezeMetadata() external;

    function mintForPromotion(
        address to,
        uint256 amount
    ) external;

    function updateMaxMintableTokenId(uint256 _maxMintableTokenId) external;

    function withdrawETH() external;
}

contract NeortVessel is iNeortVessel, ERC721, ReentrancyGuard, Ownable {

    using Strings for uint256;

    uint256 public constant PRICE = 0.05 ether;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_RESERVE_TOKEN_ID = 199;
    uint256 private _maxMintableTokenId = 2999;
    uint256 private _nextReservedTokenId = 0;
    uint256 private _remainingAmountForPromotion = 200;
    uint256 private _remainingAmountForSale = 9800;
    uint256[] private _mintedTokenIdList;
    address payable private _recipient;
    bool private _isOnSale;
    bool private _isMetadataFroze;
    string private __baseURI;

    constructor(
        string memory baseURI,
        address payable __recipient
    )
    ERC721("NEORT Vessel", "NV")
    {
        require(__recipient != address(0), "NeortVessel: Invalid address");
        _recipient = __recipient;
        __baseURI = baseURI;
    }

    function maxMintableTokenId() external override view returns (uint256) {
        return _maxMintableTokenId;
    }

    function remainingAmountForPromotion() external override view returns (uint256) {
        return _remainingAmountForPromotion;
    }

    function remainingAmountForSale() external override view returns (uint256) {
        return _remainingAmountForSale;
    }

    function isOnSale() external view override returns (bool) {
        return _isOnSale;
    }

    function mintedSalesTokenIdList(
        uint256 offset,
        uint256 limit
    ) external override view returns (uint256[] memory) {

        uint256 minted = _mintedTokenIdList.length;

        if (minted == 0) {
            return _mintedTokenIdList;
        }
        if (minted < offset) {
            return new uint256[](0);
        }

        uint256 length = limit;
        if (minted < offset + limit) {
            length = minted - offset;
        }
        uint256[] memory list = new uint256[](length);
        for (uint256 i = offset; i < offset + limit; i++) {
            if (_mintedTokenIdList.length <= i) {
                break;
            }
            list[i - offset] = _mintedTokenIdList[i];
        }

        return list;
    }

    function _baseURI() internal override view virtual returns (string memory) {
        return __baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "NeortVessel: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function buy(uint256 tokenId) external override nonReentrant payable {
        require(_isOnSale, "NeortVessel: Not on sale");
        require(msg.value == PRICE, "NeortVessel: Invalid value");
        require(MAX_RESERVE_TOKEN_ID < tokenId, "NeortVessel: Reserved id");
        require(tokenId <= _maxMintableTokenId, "NeortVessel: Non-mintable token id");

        _mintedTokenIdList.push(tokenId);
        _remainingAmountForSale--;
        _safeMint(_msgSender(), tokenId);
    }

    function buyBundle(uint256[] memory tokenIdList) external override nonReentrant payable {
        uint256 count = tokenIdList.length;
        require(_isOnSale, "NeortVessel: Not on sale");
        require(msg.value == PRICE * count, "NeortVessel: Invalid value");
        _remainingAmountForSale -= count;

        for (uint256 i; i < count; i++) {
            require(MAX_RESERVE_TOKEN_ID < tokenIdList[i], "NeortVessel: Reserved id");
            require(tokenIdList[i] <= _maxMintableTokenId, "NeortVessel: Non-mintable token id");

            _mintedTokenIdList.push(tokenIdList[i]);
            _safeMint(_msgSender(), tokenIdList[i]);
        }
    }

    function setOnSale(bool __isOnSale) external override onlyOwner {
        _isOnSale = __isOnSale;
    }

    function updateBaseURI(string calldata newBaseURI) external override onlyOwner {
        require(!_isMetadataFroze, "NeortVessel: Metadata is froze");
        __baseURI = newBaseURI;
    }

    function freezeMetadata() external override onlyOwner {
        require(!_isMetadataFroze, "NeortVessel: Already froze");
        _isMetadataFroze = true;
    }

    function mintForPromotion(
        address to,
        uint256 amount
    ) external override onlyOwner {
        _remainingAmountForPromotion -= amount;

        for (uint256 i = _nextReservedTokenId; i < _nextReservedTokenId + amount; i++) {
            _safeMint(to, i);
        }

        _nextReservedTokenId += amount;
    }

    function updateMaxMintableTokenId(uint256 __maxMintableTokenId) external override onlyOwner {
        require(__maxMintableTokenId < MAX_SUPPLY, "NeortVessel: Invalid id");
        _maxMintableTokenId = __maxMintableTokenId;
    }

    function withdrawETH() external override onlyOwner {
        Address.sendValue(_recipient, address(this).balance);
    }

}
