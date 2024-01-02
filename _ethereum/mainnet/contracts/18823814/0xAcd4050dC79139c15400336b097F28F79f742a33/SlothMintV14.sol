// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ISlothV3.sol";
import "./ISlothItemV4.sol";
import "./ISpecialSlothItemV4.sol";
import "./ISlothMintV4.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract SlothMintV14 is Initializable, OwnableUpgradeable, ISlothMintV4 {
    address private _slothAddr;
    address private _slothItemAddr;
    address private _specialSlothItemAddr;
    address private _piementAddress;
    bool public publicSale;
    mapping(uint256 => bool) public forSaleCollabo;
    mapping(uint256 => uint256) public collaboSaleEndTimes;
    mapping(uint256 => uint256) public collaboSalePricePatterns;
    uint256 public collectionSize;
    uint256 public itemCollectionSize;
    uint256 public clothesSize;
    uint256 public itemSize;
    uint256 public currentItemCount;
    uint256 public currentClothesCount;
    mapping(uint256 => uint256) public collaboItemSizes;
    mapping(uint256 => uint256) public currentCollaboItemCounts;

    address private _treasuryAddress;
    uint256 private _MINT_WITH_CLOTHES_PRICE;
    uint256 private _MINT_WITH_COLLABO_PRICE;
    uint256 private _MINT_WITH_COLLABO_PRICE2;
    uint256 private _MINT_COLLABO_PRICE;
    uint256 private _MINT_COLLABO_PRICE2;
    address private _lightSlothAddr;
    uint256 private _MINT_SLOTH_COLLECTION_PRICE;
    uint256 private _MINT_SLOTH_BODY_PRICE;
    uint256 private _MINT_SLOTH_CLOTHES_PRICE;
    mapping(uint256 => uint256) private specialTypeSaleEndTime;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 newCollectionSize, uint256 newItemCollectionSize, uint256 newClothesSize, uint256 newItemSize, uint256 newCurrentClothesCount, uint256 newCurrentItemCount) initializer public {
        __Ownable_init();
        collectionSize = newCollectionSize;
        itemCollectionSize = newItemCollectionSize;
        clothesSize = newClothesSize;
        itemSize = newItemSize;
        currentClothesCount = newCurrentClothesCount;
        currentItemCount = newCurrentItemCount;

        _treasuryAddress = payable(0x452Ccc6d4a818D461e20837B417227aB70C72B56);
        _MINT_WITH_CLOTHES_PRICE = 0.021 ether;
        _MINT_WITH_COLLABO_PRICE = 0.03 ether;
        _MINT_WITH_COLLABO_PRICE2 = 0.04 ether;
        _MINT_COLLABO_PRICE = 0.01 ether;
        _MINT_COLLABO_PRICE2 = 0.02 ether;
    }

    function setSlothAddr(address newSlothAddr) external onlyOwner {
        _slothAddr = newSlothAddr;
    }
    function setSlothItemAddr(address newSlothItemAddr) external onlyOwner {
        _slothItemAddr = newSlothItemAddr;
    }
    function setSpecialSlothItemAddr(address newSpecialSlothItemAddr) external onlyOwner {
        _specialSlothItemAddr = newSpecialSlothItemAddr;
    }
    function setPiementAddress(address newPiementAddress) external onlyOwner {
        _piementAddress = newPiementAddress;
    }
    function setLightSlothAddr(address newLightSlothAddr) external onlyOwner {
        _lightSlothAddr = newLightSlothAddr;
    }
    function setSlothCollectionPrice(uint256 newPrice) external onlyOwner {
        _MINT_SLOTH_COLLECTION_PRICE = newPrice;
    }
    function setSlothBodyPrice(uint256 newPrice) external onlyOwner {
        _MINT_SLOTH_BODY_PRICE = newPrice;
    }
    function setSlothClothesPrice(uint256 newPrice) external onlyOwner {
        _MINT_SLOTH_CLOTHES_PRICE = newPrice;
    }

    function itemPrice(uint256 quantity) internal pure returns(uint256) {
        uint256 price = 0;
        if (quantity == 1) {
          price = 20;
        } else if (quantity == 2) {
          price = 39;
        } else if (quantity == 3) {
          price = 56;
        } else if (quantity == 4) {
          price = 72;
        } else if (quantity == 5) {
          price = 88;
        } else if (quantity == 6) {
          price = 100;
        } else if (quantity == 7) {
          price = 115 ;
        } else if (quantity == 8) {
          price = 125 ;
        } else if (quantity == 9) {
          price = 135;
        } else {
          price = 15 * quantity;
        }
        return price * 1 ether / 1000;
    }

    function publicMintBody(uint8 quantity) payable public {
        require(publicSale, "inactive");
        require(ISlothV3(_slothAddr).totalSupply() + quantity <= collectionSize, "exceeds collection size");
        require(msg.value == _MINT_SLOTH_BODY_PRICE * quantity, "wrong price");

        _mintBody(quantity, msg.sender);
        emit mintBody(quantity, false);
    }
    function _mintBody(uint8 quantity, address sender) internal {
        ISlothV3(_slothAddr).mint(sender, quantity);
    }
    function publicMintBodyForPiement(address transferAddress, uint8 quantity) payable external {
        require(publicSale, "inactive");
        require(ISlothV3(_slothAddr).totalSupply() + quantity <= collectionSize, "exceeds collection size");
        require(msg.value == _MINT_SLOTH_BODY_PRICE * quantity, "wrong price");
        require(msg.sender == _piementAddress, "wrong address");

        ISlothV3(_slothAddr).mint(transferAddress, quantity);
        emit mintBody(quantity, true);
    }

    function publicMintClothes(uint8 quantity) payable external {
        require(publicSale, "inactive");
        require(currentClothesCount + quantity <= clothesSize, "exceeds clothes size");
        require(msg.value == _MINT_SLOTH_CLOTHES_PRICE * quantity, "wrong price");

        ISlothItemV4(_slothItemAddr).clothesMint(msg.sender, quantity);
        currentClothesCount += quantity;
        emit mintClothes(quantity, false);
    }
    function publicMintClothesForPiement(address transferAddress, uint8 quantity) payable external {
        require(publicSale, "inactive");
        require(currentClothesCount + quantity <= clothesSize, "exceeds clothes size");
        require(msg.value == _MINT_SLOTH_CLOTHES_PRICE * quantity, "wrong price");
        require(msg.sender == _piementAddress, "wrong address");

        ISlothItemV4(_slothItemAddr).clothesMint(transferAddress, quantity);
        currentClothesCount += quantity;
        emit mintClothes(quantity, true);
    }

    function publicItemMint(uint8 quantity) payable external {
        require(publicSale, "inactive");
        require(msg.value == itemPrice(quantity), "wrong price");
        require(ISlothItemV4(_slothItemAddr).totalSupply() + quantity <= itemCollectionSize, "exceeds item collection size");

        _itemMint(quantity, msg.sender);
        emit mintItem(quantity, false);
    }
    function publicItemMintForPiement(address transferAddress, uint8 quantity) payable external {
        require(publicSale, "inactive");
        require(msg.value == itemPrice(quantity), "wrong price");
        require(ISlothItemV4(_slothItemAddr).totalSupply() + quantity <= itemCollectionSize, "exceeds item collection size");
        require(msg.sender == _piementAddress, "wrong address");

        _itemMint(quantity, transferAddress);
        emit mintItem(quantity, true);
    }

    function _itemMint(uint256 quantity, address to) private {
        require(currentItemCount + quantity <= itemSize, "exceeds item size");

        ISlothItemV4(_slothItemAddr).itemMint(to, quantity);
        currentItemCount += quantity;
    }

    function _publicMint(uint8 quantity, address to) private {
        require(publicSale, "inactive");
        require(ISlothV3(_slothAddr).totalSupply() + quantity <= collectionSize, "exceeds collection size");
        require(currentClothesCount + quantity <= clothesSize, "exceeds clothes size");

        ISlothV3(_slothAddr).mint(to, quantity);
        ISlothItemV4(_slothItemAddr).clothesMint(to, quantity);
        currentClothesCount += quantity;
    }

    function _isSaleEnded(uint256 specialType) internal view returns (bool) {
        if (collaboSaleEndTimes[specialType] == 0) {
          return false;
        }
        return block.timestamp >= collaboSaleEndTimes[specialType];
    }

    function publicMintSlothCollectionNovember(uint256 quantity, uint8 clothType) payable public {
        require(quantity > 0, "quantity must be greater than 0");
        require(forSaleCollabo[54], "inactive collabo");
        require(clothType < 5, "invalid clothType");
        require(msg.value == (_MINT_SLOTH_COLLECTION_PRICE * quantity), "wrong price");
        _mintSlothCollectionNovember(msg.sender, quantity, clothType);
        emit mintSlothCollection(quantity, 54, clothType, false);
    }
    function publicMintSlothCollectionNovemberAll(uint256 setQuantity) payable public {
        require(forSaleCollabo[54], "inactive collabo");
        require(setQuantity > 0, "quantity must be greater than 0");
        require(msg.value == (_MINT_SLOTH_COLLECTION_PRICE * setQuantity * 5), "wrong price");
        for (uint8 clothType = 0; clothType < 5; clothType++) {
          _mintSlothCollectionNovember(msg.sender, setQuantity, clothType);
          emit mintSlothCollection(setQuantity, 54, clothType, false);
        }
    }
    function publicMintSlothCollectionNovemberForPiement(address transferAddress, uint256 quantity, uint8 clothType) payable public {
        require(msg.sender == _piementAddress, "worng address");
        require(quantity > 0, "quantity must be greater than 0");
        require(forSaleCollabo[54], "inactive collabo");
        require(clothType < 5, "invalid clothType");
        require(msg.value == (_MINT_SLOTH_COLLECTION_PRICE * quantity), "wrong price");
        _mintSlothCollectionNovember(transferAddress, quantity, clothType);
        emit mintSlothCollection(quantity, 54, clothType, true);
    }
    function publicMintSlothCollectionNovemberAllForPiement(address transferAddress, uint256 setQuantity) payable public {
        require(forSaleCollabo[54], "inactive collabo");
        require(setQuantity > 0, "quantity must be greater than 0");
        require(msg.sender == _piementAddress, "worng address");
        require(msg.value == (_MINT_SLOTH_COLLECTION_PRICE * setQuantity * 5), "wrong price");
        for (uint8 clothType = 0; clothType < 5; clothType++) {
          _mintSlothCollectionNovember(transferAddress, setQuantity, clothType);
          emit mintSlothCollection(setQuantity, 54, clothType, true);
        }
    }
    function _mintSlothCollectionNovember(address transferAddress, uint256 quantity, uint8 clothType) internal {
        ISpecialSlothItemV4(_specialSlothItemAddr).mintSlothCollectionNovember(transferAddress, quantity, clothType);
    }

    function publicMintSlothCollectionDecemberAll(uint256 setQuantity) payable public {
        require(forSaleCollabo[59], "inactive collabo");
        require(setQuantity > 0, "quantity must be greater than 0");
        require(msg.value == (0.02 ether * setQuantity), "wrong price");
        for (uint8 clothType = 0; clothType < 3; clothType++) {
          _mintSlothCollection(msg.sender, setQuantity, clothType, 59);
          emit mintSlothCollection(setQuantity, 59, clothType, false);
        }
    }
    function publicMintSlothCollectionDecember(uint256 quantity, uint8 clothType) payable public {
        require(forSaleCollabo[59], "inactive collabo");
        require(quantity > 0, "quantity must be greater than 0");
        require(msg.value == (_MINT_SLOTH_COLLECTION_PRICE * quantity), "wrong price");
        _mintSlothCollection(msg.sender, quantity, clothType, 59);
        emit mintSlothCollection(quantity, 59, clothType, false);
    }
    function publicMintSlothCollectionDecemberAllForPiement(address transferAddress, uint256 setQuantity) payable public {
        require(forSaleCollabo[59], "inactive collabo");
        require(setQuantity > 0, "quantity must be greater than 0");
        require(msg.sender == _piementAddress, "worng address");
        require(msg.value == (0.02 ether * setQuantity), "wrong price");
        for (uint8 clothType = 0; clothType < 3; clothType++) {
          _mintSlothCollection(transferAddress, setQuantity, clothType, 59);
          emit mintSlothCollection(setQuantity, 59, clothType, true);
        }
    }
    function _mintSlothCollection(address transferAddress, uint256 quantity, uint8 clothType, uint8 specialType) internal {
        ISpecialSlothItemV4(_specialSlothItemAddr).mintSlothCollection(transferAddress, quantity, clothType, specialType);
    }

    function checkAllowCollaboMint(uint8 quantity, uint256 specialType) internal view {
        require(forSaleCollabo[specialType], "inactive collabo");
        require(!_isSaleEnded(specialType), "ended");
        require(currentCollaboItemCounts[specialType] + quantity <= collaboItemSizes[specialType], "collabo sold out");
    }

    function collaboMintValue(uint8 quantity, uint256 specialType) internal view returns (uint256) {
        if (collaboSalePricePatterns[specialType] == 1) {
          return _MINT_COLLABO_PRICE2 * quantity;
        }
        return _MINT_COLLABO_PRICE * quantity;
    }

    function bodyWithCollaboMintValue(uint8 quantity, uint256 specialType) internal view returns (uint256) {
        if (collaboSalePricePatterns[specialType] == 1) {
          return _MINT_COLLABO_PRICE2 * quantity + _MINT_SLOTH_BODY_PRICE * quantity;
        }
        return _MINT_COLLABO_PRICE * quantity + _MINT_SLOTH_BODY_PRICE * quantity;
    }
    function bodyAndClothWithCollaboMintValue(uint8 quantity, uint256 specialType) internal view returns (uint256) {
        if (collaboSalePricePatterns[specialType] == 1) {
          return _MINT_WITH_COLLABO_PRICE2 * quantity;
        }
        return _MINT_WITH_COLLABO_PRICE * quantity;
    }

    function mintCollaboWithBody(uint8 quantity, uint256 specialType) internal {
        checkAllowCollaboMint(quantity, specialType);
        require(msg.value ==  bodyWithCollaboMintValue(quantity, specialType), "wrong price");

        _mintBody(quantity, msg.sender);
        ISpecialSlothItemV4(_specialSlothItemAddr).mintCollaboCloth(msg.sender, quantity, specialType);
        currentCollaboItemCounts[specialType] += quantity;
    }

    function mintCollaboCloth(uint8 quantity, uint256 specialType) internal {
        checkAllowCollaboMint(quantity, specialType);
        require(msg.value ==  collaboMintValue(quantity, specialType), "wrong price");
        ISpecialSlothItemV4(_specialSlothItemAddr).mintCollaboCloth(msg.sender, quantity, specialType);
        currentCollaboItemCounts[specialType] += quantity;
    }

    function publicMintBodyWithCollabo(uint256 specialType, uint8 quantity) payable external {
        mintCollaboWithBody(quantity, specialType);
        emit mintWithClothAndCollabo(quantity, specialType, false);
    }
    function publicMintBodyWithCollaboForPiement(address transferAddress, uint256 specialType) payable external {
        checkAllowCollaboMint(1, specialType);
        require(msg.value ==  bodyWithCollaboMintValue(1, specialType), "wrong price");
        require(msg.sender == _piementAddress, "worng address");

        _mintBody(1, transferAddress);
        ISpecialSlothItemV4(_specialSlothItemAddr).mintCollaboCloth(transferAddress, 1, specialType);
        currentCollaboItemCounts[specialType] += 1;
        emit mintWithClothAndCollabo(1, specialType, true);
    }
    function publicMintWithClothesAndCollaboForPiement(address transferAddress, uint256 specialType) payable external {
        checkAllowCollaboMint(1, specialType);
        require(ISlothItemV4(_slothItemAddr).totalSupply() + 1 <= itemCollectionSize, "exceeds item collection size");
        require(currentClothesCount + 1 <= clothesSize, "exceeds clothes size");
        require(msg.value ==  bodyAndClothWithCollaboMintValue(1, specialType), "wrong price");
        if (msg.sender == owner()) {
          _publicMint(1, transferAddress);
          ISpecialSlothItemV4(_specialSlothItemAddr).mintCollaboCloth(transferAddress, 1, specialType);
          currentCollaboItemCounts[specialType] += 1;
          return;
        }
        require(msg.sender == _piementAddress, "worng address");
        _publicMint(1, transferAddress);
        ISpecialSlothItemV4(_specialSlothItemAddr).mintCollaboCloth(transferAddress, 1, specialType);
        currentCollaboItemCounts[specialType] += 1;
        emit mintWithClothAndCollabo(1, specialType, true);
    }
    function publicMintWithClothesAndCollabo(uint256 specialType, uint8 quantity) payable external {
        checkAllowCollaboMint(quantity, specialType);
        require(msg.value ==  bodyAndClothWithCollaboMintValue(quantity, specialType), "wrong price");
        _publicMint(quantity, msg.sender);
        ISpecialSlothItemV4(_specialSlothItemAddr).mintCollaboCloth(msg.sender, quantity, specialType);
        currentCollaboItemCounts[specialType] += 1;
        emit mintWithClothAndCollabo(quantity, specialType, false);
    }
    function publicMintOnlyCollabo(uint256 specialType, uint8 quantity) payable external {
        mintCollaboCloth(quantity, specialType);
        emit mintCollabo(quantity, specialType);
    }

    function setPublicSale(bool newPublicSale) external onlyOwner {
        publicSale = newPublicSale;
    }
    function setSaleCollabo(uint256[] calldata specialTypeArray, bool[] calldata newSaleCollaboArray) external onlyOwner {
        for (uint256 i = 0; i < specialTypeArray.length; i++) {
          forSaleCollabo[specialTypeArray[i]] = newSaleCollaboArray[i];
        }
    }
    function setCollaboItemSizes(uint256[] calldata specialTypeArray, uint256[] calldata itemSizeArray) external onlyOwner {
        for (uint256 i = 0; i < specialTypeArray.length; i++) {
          collaboItemSizes[specialTypeArray[i]] = itemSizeArray[i];
        }
    }
    function setCollaboSaleEndTimes(uint256[] calldata specialTypeArray, uint256[] calldata endTimeArray) external onlyOwner {
        for (uint256 i = 0; i < specialTypeArray.length; i++) {
          collaboSaleEndTimes[specialTypeArray[i]] = endTimeArray[i];
        }
    }
    function setCollaboSalePricePatterns(uint256[] calldata specialTypeArray, uint256[] calldata pricePatternArray) external onlyOwner {
        for (uint256 i = 0; i < specialTypeArray.length; i++) {
          collaboSalePricePatterns[specialTypeArray[i]] = pricePatternArray[i];
        }
    }
    function setCurrentCollaboItemCount(uint256[] calldata specialTypeArray, uint256[] calldata itemCountArray) external onlyOwner {
        for (uint256 i = 0; i < specialTypeArray.length; i++) {
          currentCollaboItemCounts[specialTypeArray[i]] = itemCountArray[i];
        }
    }
    function setSecialTypeSaleEndTime(uint256[] calldata specialTypeArray, uint256[] calldata endTimeArray) external onlyOwner {
        for (uint256 i = 0; i < specialTypeArray.length; i++) {
          specialTypeSaleEndTime[specialTypeArray[i]] = endTimeArray[i];
        }
    }

    function withdraw() external onlyOwner {
        (bool sent,) = _treasuryAddress.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function ownerMint(uint8 quantity, uint256 itemQuantity) external onlyOwner {
        require(ISlothItemV4(_slothItemAddr).totalSupply() + (quantity + itemQuantity) <= itemCollectionSize, "exceeds item collection size");

        if (quantity > 0) {
          _publicMint(quantity, msg.sender);
        }
        if (itemQuantity > 0) {
          _itemMint(itemQuantity, msg.sender);
        }
    }
}