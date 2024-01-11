// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC1155Upgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./StringsUpgradeable.sol";
// import "./console.sol";

struct RecipeItem {
  uint256 tokenId;
  uint256 quantity;
}

struct Recipe {
  uint256 cost;
  RecipeItem[] materials;
  RecipeItem[] tools;
}

struct Airdrop {
  uint256[] tokenIds;
  uint256[] amounts;
  address[] wallets;
}

contract MaterialsUpgradeable is
  ERC1155Upgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable,
  AccessControlEnumerableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using StringsUpgradeable for uint256;

  string private _baseMetadataURI;

  mapping(uint256 => Recipe) internal recipes;
  mapping(uint256 => uint256) internal itemIndexesToBlankTokenIds;

  address private _10ktfContractAddress;
  address private _missionRewardContract;

  function initialize(string memory _baseURI) external initializer {
      __Ownable_init();
      __UUPSUpgradeable_init();
      __AccessControlEnumerable_init();
      __ERC1155_init(_baseURI);

      _baseMetadataURI = _baseURI;

      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function supportsInterface(bytes4 interfaceId)
  public
  view
  virtual
  override(AccessControlEnumerableUpgradeable, ERC1155Upgradeable)
  returns (bool)
  {
    return
      interfaceId == type(IERC1155Upgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function version()
  external
  pure
  virtual
  returns (string memory)
  {
    return "1.2.1";
  }

  function setBaseMetadataURI(string memory _newBaseMetadataURI)
      public
      onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setURI(_newBaseMetadataURI);
  }

  function uri(uint256 _id) public view override returns (string memory) {
    return string(abi.encodePacked(_baseMetadataURI, _id.toString()));
  }

  function dropMaterials(
    address[] memory _wallets,
    uint256[] memory _ids,
    uint256[] memory _amounts
  )
  internal
  virtual
  nonReentrant
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    for (uint256 i = 0; i < _wallets.length; i++) {
      _mintBatch(_wallets[i], _ids, _amounts, "");
    }
  }

  function airdropMaterials(Airdrop[] calldata airdrops)
  public
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    for (uint256 i = 0; i < airdrops.length; i++) {
      Airdrop memory airdrop = airdrops[i];
      dropMaterials(airdrop.wallets, airdrop.tokenIds, airdrop.amounts);
    }
  }

  function craftItem(uint256 tokenId, uint256 quantity)
  external
  payable
  nonReentrant
  {
    _craftItem(tokenId, quantity);
  }

  function _craftItem(uint256 tokenId, uint256 quantity)
  internal
  virtual
  {
    address sender = _msgSender();

    require(tokenId >= 0, "Invalid token ID");

    Recipe memory recipe = recipes[tokenId];

    require(recipe.materials.length > 0, "No recipe found for token");
    require(msg.value >= (recipe.cost * quantity), "Insufficient eth sent");

    for (uint256 i = 0; i < recipe.materials.length; i++) {
      RecipeItem memory recipeItem = recipe.materials[i];
      require(balanceOf(sender, recipeItem.tokenId) >= recipeItem.quantity * quantity, "Sender does not have neccessary material(s)");

      _burn(sender, recipeItem.tokenId, recipeItem.quantity * quantity);
    }

    _mint(sender, tokenId, quantity, "");
  }

  function craftItemBatch(
    uint256[] calldata tokenIds,
    uint256[] calldata quantities
  )
  external
  payable
  nonReentrant
  {
    _craftItemBatch(tokenIds, quantities);
  }

  function _craftItemBatch(
    uint256[] calldata tokenIds,
    uint256[] calldata quantities
  )
  internal
  virtual
  {
    require(
      tokenIds.length == quantities.length,
      "length of tokenIds must equal quantities"
    );

    uint256 totalCost = 0;

    for (uint256 j = 0; j < tokenIds.length; j++) {
      uint256 tokenId = tokenIds[j];
      uint256 quantity = quantities[j];

      Recipe memory recipe = recipes[tokenId];
      totalCost = totalCost + recipe.cost * quantity;

      require(msg.value >= totalCost, "Insufficient eth sent");

      _craftItem(tokenId, quantity);
    }
  }

  function _mintReward(
    address account,
    uint256 tokenId,
    uint256 quantity
  )
  internal
  {
    _mint(account, tokenId, quantity, "");
  }

  function mintRewards(
    address account,
    uint256[] calldata tokenIds,
    uint256[] calldata quantities
  )
  external
  nonReentrant
  {
    require(_missionRewardContract != address(0), "Mission reward contract not set yet");
    require(tokenIds.length == quantities.length, "Mismatched length between token ids and quantities");
    require(_msgSender() == _missionRewardContract, "Not allowed to mint rewards");

    for (uint256 i = 0; i < tokenIds.length; i++) {
      _mintReward(account, tokenIds[i], quantities[i]);
    }
  }

  function burnBlank(address buyer, uint256 tokenId)
  external
  nonReentrant
  returns (bool)
  {
    require(msg.sender == _10ktfContractAddress, "Not allowed to call function");
    uint256 itemIndex = (tokenId & 0xFFFF000000000000) >> 48;
    uint256 blankTokenId = itemIndexesToBlankTokenIds[itemIndex];

    require(balanceOf(buyer, blankTokenId) >= 1, "Buyer does not have necessary blank");
    _burn(buyer, blankTokenId, 1);

    return true;
  }

  function set10ktfContractAddress(address contractAddress)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _10ktfContractAddress = contractAddress;
  }

  function get10ktfContractAddress()
  external
  view
  returns (address)
  {
    return _10ktfContractAddress;
  }

  function setMissionRewardsContract(address contractAddress)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _missionRewardContract = contractAddress;
  }

  function getMissionRewardsContract()
  external
  view
  returns (address)
  {
    return _missionRewardContract;
  }

  function setBlankTokenIdsForItemIndexes(
    uint256[] calldata itemIndexes,
    uint256[] calldata blankTokenIds
  )
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(itemIndexes.length == blankTokenIds.length, "Mismatched length between indexes and token ids");

    for (uint16 i = 0; i < itemIndexes.length; i++) {
      itemIndexesToBlankTokenIds[itemIndexes[i]] = blankTokenIds[i];
    }
  }

  function getBlankTokenIdForItemIndex(uint256 itemIndex)
  external
  view
  returns (uint256)
  {
    return itemIndexesToBlankTokenIds[itemIndex];
  }

  function setRecipe(
    uint256 tokenId,
    Recipe calldata recipe
  )
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
      recipes[tokenId] = recipe;
  }

  function removeRecipe(uint256 tokenId)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    delete recipes[tokenId];
  }

  function getRecipe(uint256 tokenId)
  external
  view
  onlyRole(DEFAULT_ADMIN_ROLE)
  returns (Recipe memory)
  {
    return recipes[tokenId];
  }

  function _authorizeUpgrade(address newImplementation)
  internal
  virtual
  override
  onlyRole(DEFAULT_ADMIN_ROLE)
  {}
}
