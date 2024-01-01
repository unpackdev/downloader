//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ISlothItemV3.sol";
import "./IEquipment.sol";
import "./ISlothEquipment.sol";
import "./ISlothV2.sol";
import "./IERC2981.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721AQueryableUpgradeable.sol";

contract LightSlothV4 is Initializable, ERC721AQueryableUpgradeable, OwnableUpgradeable, ISloth, IERC2981 {
  string public baseURI;
  mapping(uint256 => mapping(uint256 => IEquipment.Equipment)) public items;
  mapping(uint256 => uint256) private _lastSetAt;
  address private _slothAddr;
  address private _slothEquipmentAddr;

  uint8 private constant _ITEM_NUM = 5;
  address payable private _royaltyWallet;
  uint256 public royaltyBasis;
  uint256 public disableTransferPeriod;
  bool public onMint;
  uint256 public maxPerAddressDuringMint;
  address private _slothItemAddr;
  address private _specialSlothItemAddr;

  function initialize() initializerERC721A initializer public {
    __ERC721A_init("LightSloth", "LST");
    __Ownable_init();

    _royaltyWallet = payable(0x452Ccc6d4a818D461e20837B417227aB70C72B56);
    royaltyBasis = 200; // 2%
    disableTransferPeriod = 1 days;
  }

  function owner() public view override(OwnableUpgradeable) returns (address) {
    return super.owner();
  }

  function checkHaveItem(address wallet) internal view returns (bool) {
    return ISlothItemV3(_slothItemAddr).balanceOf(wallet) > 0 || ISlothItemV3(_specialSlothItemAddr).balanceOf(wallet) > 0;
  }

  function mint(address sender, uint8 quantity) external {
    require(onMint, "inactive");
    require(_numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "wrong num");
    require(checkHaveItem(sender), "no item");
    _mint(sender, quantity);
  }

  function numberMinted(address sender) external view returns (uint256) {
    return _numberMinted(sender);
  }

  function setDisableTransferPeriod(uint256 newDisableTransferPeriod) external onlyOwner {
    disableTransferPeriod = newDisableTransferPeriod;
  }

  function setSlothAddr(address newSlothAddr) external onlyOwner {
    _slothAddr = newSlothAddr;
  }

  function setSlothEquipmentAddr(address newSlothEquipmentAddr) external onlyOwner {
    _slothEquipmentAddr = newSlothEquipmentAddr;
  }

  function setSlothItemAddr(address newSlothItemAddr) external onlyOwner {
    _slothItemAddr = newSlothItemAddr;
  }

  function setSpecialSlothItemAddr(address newSpecialSlothItemAddr) external onlyOwner {
    _specialSlothItemAddr = newSpecialSlothItemAddr;
  }

  function getEquipments(uint256 tokenId) public view returns (IEquipment.Equipment[_ITEM_NUM] memory) {
    IEquipment.Equipment[_ITEM_NUM] memory equipments;
    for (uint8 i = 0; i < _ITEM_NUM; i++) {
      equipments[i] = items[uint256(ISlothItem.ItemType(i))][tokenId];
    }
    return equipments;
  }

  function setItem(uint256 _tokenId, IEquipment.EquipmentTargetItem memory _targetItem, ISlothItem.ItemType _targetItemType, address sender) external returns (address) {
    ISlothEquipment slothEquipment = ISlothEquipment(_slothEquipmentAddr);
    address itemContractAddr = slothEquipment.getTargetItemContractAddress(_targetItem.itemMintType);
    IEquipment.Equipment memory _equipment = items[uint256(_targetItemType)][_tokenId];

    if (_targetItem.itemTokenId == 0) {
      if (_equipment.itemId != 0 && _equipment.itemAddr != address(0)) {
        ISloth(_slothAddr).receiveItem(sender, _equipment.itemAddr, _equipment.itemId);
      }
      items[uint256(_targetItemType)][_tokenId] = IEquipment.Equipment(0, address(0));
      return address(0);
    }

    if (_equipment.itemId == _targetItem.itemTokenId && _equipment.itemAddr == itemContractAddr) {
      return itemContractAddr;
    }

    // transfer old item to sender
    if (_equipment.itemId != 0 && _equipment.itemAddr != address(0)) {
      ISloth(_slothAddr).receiveItem(sender, _equipment.itemAddr, _equipment.itemId);
    }
    // receive new item to contract
    ISloth(_slothAddr).sendItem(sender, itemContractAddr, _targetItem.itemTokenId);
    items[uint256(_targetItemType)][_tokenId] = IEquipment.Equipment(_targetItem.itemTokenId, itemContractAddr);
    return itemContractAddr;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function setOnMint(bool newOnMint) external onlyOwner {
    onMint = newOnMint;
  }

  function setMaxPerAddressDuringMint(uint256 newNum) external onlyOwner {
    maxPerAddressDuringMint = newNum;
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721AUpgradeable, IERC165, IERC721AUpgradeable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC165-royaltyInfo}.
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    require(_exists(tokenId), "Nonexistent token");
    return (payable(_royaltyWallet), uint((salePrice * royaltyBasis)/10000));
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function _beforeTokenTransfers(
      address from,
      address to,
      uint256 startTokenId,
      uint256 quantity
  ) internal virtual override {
    for (uint256 i = 0; i < quantity; i++) {
      uint256 tokenId = startTokenId + i;
      require(block.timestamp - _lastSetAt[tokenId] > disableTransferPeriod, "ineligible transfer");
    }
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
  }

  function exists(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  function receiveItem(address tokenOwner, address itemContractAddress, uint256 itemTokenId) external {}
  function sendItem(address tokenOwner, address itemContractAddress, uint256 itemTokenId) external {}
}