//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ISlothItemV4.sol";
import "./IERC2981.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./RevokableOperatorFiltererUpgradeable.sol";
import "./ERC721AQueryableUpgradeable.sol";

contract SpecialSlothItemV7 is Initializable, ERC721AQueryableUpgradeable, OwnableUpgradeable, ISlothItemV4, IERC2981, RevokableOperatorFiltererUpgradeable {
  error InvalidArguments();

  mapping(uint256 => IItemTypeV2.ItemType) public itemType;
  mapping(uint256 => uint256) public specialType;
  address payable private _royaltyWallet;
  uint256 public royaltyBasis;
  string  public baseURI;
  mapping(uint256 => bool) private combinational;
  address private _slothMintAddr;
  uint256 private _nextPoupelleClothType;
  mapping(uint256 => uint256) public clothType;
  mapping(uint256 => uint256) internal _nextClothType;
  mapping(uint256 => uint256) internal _clothPattern;
  mapping(uint256 => mapping(uint256 => IItemTypeV2.ItemType)) public _clothItemTypeMapping;

  function initialize() initializerERC721A initializer public {
    __ERC721A_init("SpecialSlothItem", "SSI");
    __Ownable_init();
    __RevokableOperatorFilterer_init(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), true);
 
    _royaltyWallet = payable(0x452Ccc6d4a818D461e20837B417227aB70C72B56);
    royaltyBasis = 200; // 2%
  }

  function owner() public view override(OwnableUpgradeable, RevokableOperatorFiltererUpgradeable) returns (address) {
    return super.owner();
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721AUpgradeable, IERC165, IERC721AUpgradeable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  function ownerItemMintClothes(uint256 quantity, uint256 specialTypeNum, uint256 clothTypeNum) external onlyOwner {
    require(quantity > 0, "quantity must be greater than 0");
    uint256 nextTokenId = _nextTokenId();
    _mint(msg.sender, quantity);
    for(uint256 i = 0; i < quantity; i++) {
      itemType[nextTokenId] = IItemTypeV2.ItemType.CLOTHES;
      specialType[nextTokenId] = specialTypeNum;
      clothType[nextTokenId] = clothTypeNum;
      nextTokenId += 1;
    }
  }

  function mintPoupelle(address sender, uint256 quantity) external {
    require(msg.sender == _slothMintAddr, "worng sender");
    require(quantity > 0, "quantity must be greater than 0");
    uint256 nextTokenId = _nextTokenId();
    _mint(sender, quantity);

    uint256 _clothType = _nextPoupelleClothType;
    for(uint256 i = 0; i < quantity; i++) {
      itemType[nextTokenId] = IItemTypeV2.ItemType.CLOTHES;
      specialType[nextTokenId] = 2;
      clothType[nextTokenId] = _clothType;
      nextTokenId += 1;
      _clothType = (_clothType + 1) % 4;
    }
    _nextPoupelleClothType = _clothType;
  }

  function mintCollaboCloth(address sender, uint256 quantity, uint256 _specialType) external {
    require(msg.sender == _slothMintAddr, "worng sender");
    require(quantity > 0, "quantity must be greater than 0");
    uint256 nextTokenId = _nextTokenId();
    _mint(sender, quantity);
    for(uint256 i = 0; i < quantity; i++) {
      itemType[nextTokenId] = IItemTypeV2.ItemType.CLOTHES;
      specialType[nextTokenId] = _specialType;
      clothType[nextTokenId] = _nextClothType[_specialType];
      nextTokenId += 1;
      updateNextClothType(_specialType);
    }
  }

  function ownerMint(uint quantity, uint256 _specialType, uint256 _clothType) external onlyOwner {
    uint256 nextTokenId = _nextTokenId();
    _mint(msg.sender, quantity);
    itemType[nextTokenId] = IItemTypeV2.ItemType.CLOTHES;
    specialType[nextTokenId] = _specialType;
    clothType[nextTokenId] = _clothType;
  }

  function batchTransferToMultipleWallets(address[] calldata tos, uint256[] calldata tokenIds) external onlyOwner {
    uint256 length = tokenIds.length;
    if (tos.length != length) revert("wallets and amounts length mismatch");

    for (uint256 i; i < length; ) {
        uint256 tokenId = tokenIds[i];
        address to = tos[i];
        transferFrom(msg.sender, to, tokenId);
        unchecked {
            ++i;
        }
    }
  }

  function mintSlothCollection(address sender, uint256 quantity, uint8 _clothType, uint256 _specialType) external {
    require(msg.sender == _slothMintAddr, "worng sender");
    _mintSlothCollection(sender, quantity, _clothType, _specialType);
  }
  function _mintSlothCollection(address sender, uint256 quantity, uint8 _clothType, uint256 _specialType) internal {
    require(_clothType < _clothPattern[_specialType], "invalid clothType");
    uint256 nextTokenId = _nextTokenId();
    _mint(sender, quantity);
    for(uint256 i = 0; i < quantity; i++) {
      itemType[nextTokenId] = _clothItemTypeMapping[_specialType][_clothType];
      specialType[nextTokenId] = _specialType;
      clothType[nextTokenId] = _clothType;
      nextTokenId += 1;
    }
  }

  function mintSlothCollectionNovember(address sender, uint256 quantity, uint8 _clothType) external {
    require(msg.sender == _slothMintAddr, "worng sender");
    require(_clothType < 5, "invalid clothType");
    uint256 nextTokenId = _nextTokenId();
    _mint(sender, quantity);
    uint NOVEMBER_SPECIAL_TYPE = 54;
    for(uint256 i = 0; i < quantity; i++) {
      itemType[nextTokenId] = IItemTypeV2.ItemType.BACKGROUND;
      specialType[nextTokenId] = NOVEMBER_SPECIAL_TYPE;
      clothType[nextTokenId] = _clothType;
      nextTokenId += 1;
      updateNextClothType(NOVEMBER_SPECIAL_TYPE);
    }
  }

  function _mintSlothCollectionDecember(address sender, uint256 quantity, uint8 _clothType) internal {
    require(msg.sender == _slothMintAddr, "worng sender");
    require(_clothType < 3, "invalid clothType");
    uint256 nextTokenId = _nextTokenId();
    _mint(sender, quantity);
    uint8 SPECIAL_TYPE = 59;
    for(uint256 i = 0; i < quantity; i++) {
      itemType[nextTokenId] = IItemTypeV2.ItemType.HEAD;
      specialType[nextTokenId] = SPECIAL_TYPE;
      clothType[nextTokenId] = _clothType;
      nextTokenId += 1;
      updateNextClothType(SPECIAL_TYPE);
    }
  }

  function updateNextClothType(uint256 _specialType) internal {  
    if (_clothPattern[_specialType] == 0) {
      return;
    }
    _nextClothType[_specialType] = (_nextClothType[_specialType] + 1) % _clothPattern[_specialType];
    return;
  }

  function setClothPattern(uint256[] calldata specialTypeArray, uint256[] calldata patternArray) external onlyOwner {
    for (uint256 i = 0; i < specialTypeArray.length; i++) {
      _clothPattern[specialTypeArray[i]] = patternArray[i];
    }
  }
  function setCombinational(bool[] memory _combinational, uint256[] calldata _specialType) public onlyOwner {
    for (uint256 i; i < _combinational.length; i++ ) {
        combinational[_specialType[i]] = _combinational[i];
    }
  }
  function setClothItemType(uint256 _specialType, uint256[] calldata clothTypeArray, IItemTypeV2.ItemType[] calldata itemTypeArray) external onlyOwner {
    for (uint256 i = 0; i < clothTypeArray.length; i++) {
      _clothItemTypeMapping[_specialType][clothTypeArray[i]] = itemTypeArray[i];
    }
  }

  function isCombinational(uint256 _specialType) public virtual view returns (bool) {
    return combinational[_specialType];
  }

  function setSlothMintAddr(address addr) external onlyOwner {
    _slothMintAddr = addr;
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

  function getSpecialType(uint256 tokenId) external view returns (uint256) {
    return specialType[tokenId];
  }
  function getItemType(uint256 tokenId) external view returns (IItemTypeV2.ItemType) {
    return itemType[tokenId];
  }
  function getClothType(uint256 tokenId) external view returns (uint256) {
    return clothType[tokenId];
  }
  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }
  function getItemMintCount(address sender) external view returns (uint256) {
    return balanceOf(sender);
  }
  function clothesMint(address sender, uint256 quantity) external {}
  function itemMint(address sender, uint256 quantity) external {}

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

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function numberMinted(address sender) external view returns (uint256) {
    return _numberMinted(sender);
  }
}