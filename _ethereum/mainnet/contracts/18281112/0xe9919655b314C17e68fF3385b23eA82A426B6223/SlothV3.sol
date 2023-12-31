//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ISlothV2.sol";
import "./ISlothItem.sol";
import "./IEquipment.sol";
import "./IERC2981.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./RevokableOperatorFiltererUpgradeable.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./ISlothEquipment.sol";

contract SlothV3 is Initializable, ERC721AQueryableUpgradeable, OwnableUpgradeable, ISloth, IERC2981, RevokableOperatorFiltererUpgradeable {
  string public baseURI;

  mapping(uint256 => mapping(uint256 => IEquipment.Equipment)) public items;
  mapping(uint256 => uint256) private _lastSetAt;

  address private _slothItemAddr;
  address private _slothMintAddr;

  bool private _itemAvailable;
  uint8 private constant _ITEM_NUM = 5;
  address payable private _royaltyWallet;
  uint256 public royaltyBasis;
  uint256 public disableTransferPeriod;
  address private _slothEquipmentAddr;
  mapping(address => bool) private _allowContractAddrs;

  function initialize() initializerERC721A initializer public {
    __ERC721A_init("Sloth", "SLT");
    __Ownable_init();
    __RevokableOperatorFilterer_init(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), true);

    _royaltyWallet = payable(0x452Ccc6d4a818D461e20837B417227aB70C72B56);
    royaltyBasis = 200; // 2%
    disableTransferPeriod = 1 days;
  }

  function owner() public view override(OwnableUpgradeable, RevokableOperatorFiltererUpgradeable) returns (address) {
    return super.owner();
  }

  function setItemAddr(address newItemAddr) external onlyOwner {
    _slothItemAddr = newItemAddr;
  }

  function setSlothMintAddr(address newSlothMintAddr) external onlyOwner {
    _slothMintAddr = newSlothMintAddr;
  }

  function setSlothEquipmentAddr(address newSlothEquipmentAddr) external onlyOwner {
    _slothEquipmentAddr = newSlothEquipmentAddr;
  }

  function setDisableTransferPeriod(uint256 newDisableTransferPeriod) external onlyOwner {
    disableTransferPeriod = newDisableTransferPeriod;
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
        ISlothItem(_equipment.itemAddr).transferFrom(address(this), sender, _equipment.itemId);
      }
      items[uint256(_targetItemType)][_tokenId] = IEquipment.Equipment(0, address(0));
      return address(0);
    }

    if (_equipment.itemId == _targetItem.itemTokenId && _equipment.itemAddr == itemContractAddr) {
      return itemContractAddr;
    }

    // transfer old item to sender
    if (_equipment.itemId != 0 && _equipment.itemAddr != address(0)) {
      ISlothItem(_equipment.itemAddr).transferFrom(address(this), sender, _equipment.itemId);
    }
    // receive new item to contract
    ISlothItem(itemContractAddr).transferFrom(sender, address(this), _targetItem.itemTokenId);
    items[uint256(_targetItemType)][_tokenId] = IEquipment.Equipment(_targetItem.itemTokenId, itemContractAddr);
    return itemContractAddr;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function setAllowContractAddr(address contractAddr, bool allow) external onlyOwner {
    _allowContractAddrs[contractAddr] = allow;
  }

  function mint(address sender, uint8 quantity) external {
    require(msg.sender == _slothMintAddr, "not slothMintAddr");

    _mint(sender, quantity);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function numberMinted(address sender) external view returns (uint256) {
    return _numberMinted(sender);
  }

  function setApprovalForAll(address operator, bool approved) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      override(ERC721AUpgradeable, IERC721AUpgradeable)
      onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
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

  function receiveItem(address tokenOwner, address itemContractAddress, uint256 itemTokenId) external {
    require(_allowContractAddrs[msg.sender], "forbidden");
    ISlothItem(itemContractAddress).transferFrom(address(this), tokenOwner, itemTokenId);
  }
  function sendItem(address tokenOwner, address itemContractAddress, uint256 itemTokenId) external {
    require(_allowContractAddrs[msg.sender], "forbidden");
    ISlothItem(itemContractAddress).transferFrom(tokenOwner, address(this), itemTokenId);
  }
}