//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./OpenSeaGasFreeListing.sol";
import "./AdminMintUpgradable.sol";
import "./WhitelistUpgradable.sol";
import "./BalanceLimitUpgradable.sol";
import "./UriManagerUpgradable.sol";
import "./RoyaltiesUpgradable.sol";
import "./PriceUpgradable.sol";
import "./CustomPaymentSplitterUpgradeable.sol";

contract FlareMCOrigin is
  Initializable,
  ERC1155Upgradeable,
  OwnableUpgradeable,
  AdminMintUpgradable,
  WhitelistUpgradable,
  BalanceLimitUpgradable,
  UriManagerUpgradable,
  RoyaltiesUpgradable,
  PriceUpgradable,
  CustomPaymentSplitterUpgradeable
{
  uint256 public whitelistReserved;
  uint256 public publicReserved;
  uint256 public totalSupply;
  string public name;
  string public symbol;

  function initialize(
    bytes32 whitelistMerkleTreeRoot_,
    address receiver_,
    address[] memory shareholders_,
    uint256[] memory shares_
  ) public initializer {
    name = 'FlareMC-Origin';
    symbol = 'FLARE';

    __ERC1155_init('');
    __Ownable_init();
    __AdminMint_init();
    __Whitelist_init_unchained();
    __BalanceLimit_init_unchained();
    __UriManager_init_unchained(
      'https://ipfs.io/ipfs/QmSAEKMwKURfiEQdmUMup48vo4sdusQzWiPTBvnWB7nApy/',
      '.json'
    );
    __Royalties_init_unchained(receiver_, 750);
    __Price_init_unchained();
    __CustomPaymentSplitter_init(shareholders_, shares_);
    updateMerkleTreeRoot(uint8(Stage.Whitelist), whitelistMerkleTreeRoot_);
    updateBalanceLimit(uint8(Stage.Whitelist), 2);
    updateBalanceLimit(uint8(Stage.Public), 2);
    setPrice(uint8(Stage.Whitelist), 0.049 ether);
    setPrice(uint8(Stage.Public), 0.069 ether);

    whitelistReserved = 2500;
    publicReserved = 2500;

    _callMint(receiver_, 1);
  }

  enum Stage {
    Disabled,
    Whitelist,
    Public
  }

  Stage public stage;

  function isApprovedForAll(address owner_, address operator_)
    public
    view
    virtual
    override(ERC1155Upgradeable)
    returns (bool)
  {
    return
      super.isApprovedForAll(owner_, operator_) ||
      OpenSeaGasFreeListing.isApprovedForAll(owner_, operator_);
  }

  function whitelistMint(uint256 amount_, bytes32[] calldata proof_)
    external
    payable
    onlyWhitelisted(uint8(Stage.Whitelist), msg.sender, proof_)
  {
    require(stage == Stage.Public, 'Whitelist sale not enabled');
    require(
      whitelistReserved - amount_ >= 0,
      'Not enough reserved for whitelist'
    );
    uint8 _stage = uint8(Stage.Whitelist);
    _increaseBalance(_stage, msg.sender, amount_);
    whitelistReserved -= amount_;
    _callMint(msg.sender, amount_);
    _handlePayment(amount_ * price(_stage));
  }

  function publicMint(uint256 amount_) external payable {
    require(stage == Stage.Public, 'Public sale not enabled');
    require(publicReserved - amount_ >= 0, 'Not enough reserved for public');
    uint8 _stage = uint8(Stage.Public);
    _increaseBalance(_stage, msg.sender, amount_);
    publicReserved -= amount_;
    _callMint(msg.sender, amount_);
    _handlePayment(amount_ * price(_stage));
  }

  function setStage(Stage stage_) external onlyAdmin {
    stage = stage_;
  }

  function _callMint(address account_, uint256 amount_) internal {
    require(amount_ > 0, 'Must be greater than zero');
    require(tx.origin == msg.sender, 'No bots');
    totalSupply += amount_;
    _mint(account_, 1, amount_, '');
  }

  function _adminMint(address account_, uint256 amount_) internal override {
    _callMint(account_, amount_);
  }

  function uri(uint256 tokenId)
    public
    view
    override(ERC1155Upgradeable)
    returns (string memory)
  {
    return _buildUri(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(RoyaltiesUpgradable, ERC1155Upgradeable)
    returns (bool)
  {
    return
      RoyaltiesUpgradable.supportsInterface(interfaceId) ||
      ERC1155Upgradeable.supportsInterface(interfaceId);
  }

  function setWhitelistReserve(uint256 whitelistReserved_) external onlyAdmin {
    whitelistReserved = whitelistReserved_;
  }

  function setPublicReserve(uint256 publicReserved_) external onlyAdmin {
    publicReserved = publicReserved_;
  }

  function carryOverWhitelistReservedToPublic() external onlyAdmin {
    uint256 current = whitelistReserved;
    whitelistReserved = 0;
    publicReserved += current;
  }
}
