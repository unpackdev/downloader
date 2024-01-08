// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./LootBox.sol";

/**
 * @title LootBoxFactory
 * LootBoxFactory - the opensea factory contract for CRYPTO Shih Tzus
 */
contract LootBoxFactory is FactoryERC721, Ownable {
  using Strings for string;

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  struct Option {
    uint256 lootBoxOptionId;
    uint256 qty;
  }

  mapping(uint256 => Option) options;
  uint256 optionCount = 0;

  address public proxyRegistryAddress;
  address public nftAddress;
  string public baseURI;

  constructor(
    address _proxyRegistryAddress,
    address _nftAddress,
    string memory _baseURI
  ) {
    proxyRegistryAddress = _proxyRegistryAddress;
    nftAddress = _nftAddress;
    baseURI = _baseURI;

    // 1 standard box
    addOption(1, 1);

    // 3 standard boxes
    addOption(1, 3);

    // 1 premium box
    addOption(2, 1);

    // 3 premium boxes
    addOption(2, 3);

    // 1 gold box
    addOption(3, 1);

    // 3 gold boxes
    addOption(3, 3);

    // fireTransferEvents(address(0), owner());
  }

  function name() external pure override returns (string memory) {
    return "Crypto Shih Tzu Lootbox Factory";
  }

  function symbol() external pure override returns (string memory) {
    return "SLF";
  }

  function supportsFactoryInterface() public pure override returns (bool) {
    return true;
  }

  function numOptions() public view override returns (uint256) {
    return optionCount;
  }

  function transferOwnership(address newOwner) public override onlyOwner {
    address _prevOwner = owner();
    super.transferOwnership(newOwner);
    fireTransferEvents(_prevOwner, newOwner);
  }

  function fireTransferEvents(address _from, address _to) private {
    for (uint256 i = 0; i < optionCount; i++) {
      emit Transfer(_from, _to, i);
    }
  }

  function addOption(uint256 _lootBoxOption, uint256 _qty) public onlyOwner {
    LootBox lootbox = LootBox(nftAddress);

    (uint256 _totalSupply, uint16[4] memory _probabilities) = lootbox.getOption(
      _lootBoxOption
    );

    require(_totalSupply > 0, "Lootbox option supply is empty");

    options[optionCount] = Option(_lootBoxOption, _qty);
    emit Transfer(address(0), owner(), optionCount);

    optionCount++;
  }

  function removeOption(uint256 _option) public onlyOwner {
    delete options[_option];
  }

  function getOption(uint256 _option)
    external
    view
    returns (uint256 _lootBoxOptionId, uint256 _qty)
  {
    return (options[_option].lootBoxOptionId, options[_option].qty);
  }

  function mint(uint256 _optionId, address _toAddress) public override {
    // Must be sent from the owner proxy or owner.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    assert(
      address(proxyRegistry.proxies(owner())) == _msgSender() ||
        owner() == _msgSender()
    );

    require(canMint(_optionId), "Cannot mint");

    Option memory _option = options[_optionId];
    LootBox lootBox = LootBox(nftAddress);

    // mint lootboxes
    for (uint256 i = 0; i < _option.qty; i++) {
      lootBox.mintTo(_toAddress, _option.lootBoxOptionId);
    }
  }

  function tokenURI(uint256 _optionId)
    external
    view
    override
    returns (string memory)
  {
    return string(abi.encodePacked(baseURI, Strings.toString(_optionId)));
  }

  /**
   * Hack to get things to work automatically on OpenSea.
   * Use transferFrom so the frontend doesn't have to worry about different method names.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public {
    mint(_tokenId, _to);
  }

  function canMint(uint256 _optionId) public view override returns (bool) {
    LootBox lootbox = LootBox(nftAddress);

    (uint256 _totalSupply, uint16[4] memory _probabilities) = lootbox.getOption(
      options[_optionId].lootBoxOptionId
    );

    return options[_optionId].qty <= _totalSupply;
  }

  /**
   * Hack to get things to work automatically on OpenSea.
   * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
   */
  function isApprovedForAll(address _owner, address _operator)
    public
    view
    returns (bool)
  {
    if (owner() == _owner && _owner == _operator) {
      return true;
    }

    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (
      owner() == _owner && address(proxyRegistry.proxies(_owner)) == _operator
    ) {
      return true;
    }

    return false;
  }

  /**
   * Hack to get things to work automatically on OpenSea.
   * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
   */
  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return owner();
  }
}
