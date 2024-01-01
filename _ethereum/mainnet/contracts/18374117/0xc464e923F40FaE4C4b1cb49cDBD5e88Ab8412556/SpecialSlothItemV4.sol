//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ISlothItemV3.sol";
import "./IERC2981.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./RevokableOperatorFiltererUpgradeable.sol";
import "./ERC721AQueryableUpgradeable.sol";

contract SpecialSlothItemV4 is Initializable, ERC721AQueryableUpgradeable, OwnableUpgradeable, ISlothItemV3, IERC2981, RevokableOperatorFiltererUpgradeable {
  error InvalidArguments();

  mapping(uint256 => IItemType.ItemType) public itemType;
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
      itemType[nextTokenId] = IItemType.ItemType.CLOTHES;
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
      itemType[nextTokenId] = IItemType.ItemType.CLOTHES;
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
      itemType[nextTokenId] = IItemType.ItemType.CLOTHES;
      specialType[nextTokenId] = _specialType;
      clothType[nextTokenId] = _nextClothType[_specialType];
      nextTokenId += 1;
      updateNextClothType(_specialType);
    }
  }

  function ownerMint(uint quantity, uint256 _specialType, uint256 _clothType) external onlyOwner {
    uint256 nextTokenId = _nextTokenId();
    _mint(msg.sender, quantity);
    itemType[nextTokenId] = IItemType.ItemType.CLOTHES;
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

  function setClothPattern(uint256[] calldata specialTypeArray, uint256[] calldata patternArray) external onlyOwner {
    for (uint256 i = 0; i < specialTypeArray.length; i++) {
      _clothPattern[specialTypeArray[i]] = patternArray[i];
    }
  }

  function mintHalloweenJiangshiSet(address sender, uint256 quantity) external {
    require(msg.sender == _slothMintAddr, "worng sender");
    require(quantity > 0, "quantity must be greater than 0");
    uint256 nextTokenId = _nextTokenId();

    uint256 ITEM_TYPE_PATTERN = 2;
    _mint(sender, quantity * ITEM_TYPE_PATTERN);

    uint HALLOWEEN_CLOTH_SPECIAL_TYPE = 39;
    uint JIANGSHI_CLOTH_TYPE = 1;
    for (uint i = 0; i < quantity; i++) {
      itemType[nextTokenId] = IItemType.ItemType.CLOTHES;
      specialType[nextTokenId] = HALLOWEEN_CLOTH_SPECIAL_TYPE; 
      clothType[nextTokenId] = JIANGSHI_CLOTH_TYPE;
      nextTokenId += 1;

      itemType[nextTokenId] = IItemType.ItemType.HEAD;
      specialType[nextTokenId] = HALLOWEEN_CLOTH_SPECIAL_TYPE; 
      clothType[nextTokenId] = JIANGSHI_CLOTH_TYPE;
      nextTokenId += 1;
    }
  }
  function mintHalloweenJacKOLanternSet(address sender, uint256 quantity) external {
    require(msg.sender == _slothMintAddr, "worng sender");
    require(quantity > 0, "quantity must be greater than 0");
    uint256 nextTokenId = _nextTokenId();

    uint256 ITEM_TYPE_PATTERN = 3;
    _mint(sender, quantity * ITEM_TYPE_PATTERN);

    uint HALLOWEEN_CLOTH_SPECIAL_TYPE = 39;
    uint JACKOLANTERN_CLOTH_TYPE = 2;
    for (uint i = 0; i < quantity; i++) {
      itemType[nextTokenId] = IItemType.ItemType.CLOTHES;
      specialType[nextTokenId] = HALLOWEEN_CLOTH_SPECIAL_TYPE; 
      clothType[nextTokenId] = JACKOLANTERN_CLOTH_TYPE;
      nextTokenId += 1;

      itemType[nextTokenId] = IItemType.ItemType.HEAD;
      specialType[nextTokenId] = HALLOWEEN_CLOTH_SPECIAL_TYPE; 
      clothType[nextTokenId] = JACKOLANTERN_CLOTH_TYPE;
      nextTokenId += 1;

      itemType[nextTokenId] = IItemType.ItemType.HAND;
      specialType[nextTokenId] = HALLOWEEN_CLOTH_SPECIAL_TYPE; 
      clothType[nextTokenId] = JACKOLANTERN_CLOTH_TYPE;
      nextTokenId += 1;
    }
  }

  function mintHalloweenGhostSet(address sender, uint256 quantity) external {
    require(msg.sender == _slothMintAddr, "worng sender");
    require(quantity > 0, "quantity must be greater than 0");
    uint256 nextTokenId = _nextTokenId();

    uint256 ITEM_TYPE_PATTERN = 2;
    _mint(sender, quantity * ITEM_TYPE_PATTERN);

    uint HALLOWEEN_CLOTH_SPECIAL_TYPE = 39;
    uint GHOST_CLOTH_TYPE = 3;
    for (uint i = 0; i < quantity; i++) {
      itemType[nextTokenId] = IItemType.ItemType.CLOTHES;
      specialType[nextTokenId] = HALLOWEEN_CLOTH_SPECIAL_TYPE; 
      clothType[nextTokenId] = GHOST_CLOTH_TYPE;
      nextTokenId += 1;

      itemType[nextTokenId] = IItemType.ItemType.HAND;
      specialType[nextTokenId] = HALLOWEEN_CLOTH_SPECIAL_TYPE; 
      clothType[nextTokenId] = GHOST_CLOTH_TYPE;
      nextTokenId += 1;
    }
  }


  function updateNextClothType(uint256 _specialType) internal {  
    if (_clothPattern[_specialType] == 0) {
      return;
    }
    _nextClothType[_specialType] = (_nextClothType[_specialType] + 1) % _clothPattern[_specialType];
    return;
  }

  function setCombinational(bool[] memory _combinational, uint256[] calldata _specialType) public onlyOwner {
    for (uint256 i; i < _combinational.length; i++ ) {
        combinational[_specialType[i]] = _combinational[i];
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
  function getItemType(uint256 tokenId) external view returns (IItemType.ItemType) {
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