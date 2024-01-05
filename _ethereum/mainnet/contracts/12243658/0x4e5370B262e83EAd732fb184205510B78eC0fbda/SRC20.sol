// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

import "./TokenMinter.sol";
import "./SRC20Registry.sol";
import "./TransferRules.sol";
import "./Features.sol";

/**
 * @title SRC20 contract
 * @author 0x5W4RM
 * @dev Base SRC20 contract.
 */
contract SRC20 is ERC20, Ownable {
  using SafeMath for uint256;
  using ECDSA for bytes32;

  string public kyaUri;

  uint256 public nav;
  uint256 public maxTotalSupply;

  address public registry;

  TransferRules public transferRules;
  Features public features;

  modifier onlyMinter() {
    require(msg.sender == getMinter(), 'SRC20: Minter is not the caller');
    _;
  }

  modifier onlyTransferRules() {
    require(msg.sender == address(transferRules), 'SRC20: TransferRules is not the caller');
    _;
  }

  modifier enabled(uint8 feature) {
    require(features.isEnabled(feature), 'SRC20: Token feature is not enabled');
    _;
  }

  event TransferRulesUpdated(address transferRrules);
  event KyaUpdated(string kyaUri);
  event NavUpdated(uint256 nav);
  event SupplyMinted(uint256 amount, address account);
  event SupplyBurned(uint256 amount, address account);

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _maxTotalSupply,
    string memory _kyaUri,
    uint256 _netAssetValueUSD,
    uint8 _features,
    address _registry,
    address _minter
  ) ERC20(_name, _symbol) {
    maxTotalSupply = _maxTotalSupply;
    kyaUri = _kyaUri;
    nav = _netAssetValueUSD;

    features = new Features(msg.sender, _features);

    if (features.isEnabled(features.TransferRules())) {
      transferRules = new TransferRules(address(this), msg.sender);
    }

    registry = _registry;
    SRC20Registry(registry).register(address(this), _minter);
  }

  function updateTransferRules(address _transferRules)
    external
    enabled(features.TransferRules())
    onlyOwner
    returns (bool)
  {
    return _updateTransferRules(_transferRules);
  }

  function updateKya(string memory _kyaUri, uint256 _nav) external onlyOwner returns (bool) {
    kyaUri = _kyaUri;
    emit KyaUpdated(_kyaUri);
    if (_nav != 0) {
      nav = _nav;
      emit NavUpdated(_nav);
    }
    return true;
  }

  function updateNav(uint256 _nav) external onlyOwner returns (bool) {
    nav = _nav;
    emit NavUpdated(_nav);
    return true;
  }

  function getMinter() public view returns (address) {
    return SRC20Registry(registry).getMinter(address(this));
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    require(
      features.checkTransfer(msg.sender, recipient),
      'SRC20: Cannot transfer due to disabled feature'
    );

    if (transferRules != TransferRules(0)) {
      require(transferRules.doTransfer(msg.sender, recipient, amount), 'SRC20: Transfer failed');
    } else {
      _transfer(msg.sender, recipient, amount);
    }

    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    require(features.checkTransfer(sender, recipient), 'SRC20: Feature transfer check');

    _approve(sender, msg.sender, allowance(sender, msg.sender).sub(amount));
    if (transferRules != ITransferRules(0)) {
      require(transferRules.doTransfer(sender, recipient, amount), 'SRC20: Transfer failed');
    } else {
      _transfer(sender, recipient, amount);
    }

    return true;
  }

  /**
   * @dev Force transfer tokens from one address to another. This
   * call expects the from address to have enough tokens, all other checks are
   * skipped.
   * Allowed only to token owners. Require 'ForceTransfer' feature enabled.
   *
   * @param sender The address which you want to send tokens from.
   * @param recipient The address to send tokens to.
   * @param amount The amount of tokens to send.
   * @return true on success.
   */
  function forceTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) external enabled(features.ForceTransfer()) onlyOwner returns (bool) {
    _transfer(sender, recipient, amount);
    return true;
  }

  /**
   * @dev This method is intended to be executed by the TransferRules contract when doTransfer is called in transfer
   * and transferFrom methods to check where funds should go.
   *
   * @param sender The address to transfer from.
   * @param recipient The address to send tokens to.
   * @param amount The amount of tokens to send.
   */
  function executeTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) external onlyTransferRules returns (bool) {
    _transfer(sender, recipient, amount);
    return true;
  }

  /**
   * Perform multiple token transfers from the token owner's address.
   * The tokens should already be minted. If this function is to be called by
   * an actor other than the owner (a delegate), the owner has to call approve()
   * first to set up the delegate's allowance.
   *
   * @param _addresses an array of addresses to transfer to
   * @param _amounts an array of amounts
   * @return true on success
   */
  function bulkTransfer(address[] calldata _addresses, uint256[] calldata _amounts)
    external
    onlyOwner
    returns (bool)
  {
    require(_addresses.length == _amounts.length, 'SRC20: Input dataset length mismatch');

    uint256 count = _addresses.length;
    for (uint256 i = 0; i < count; i++) {
      address to = _addresses[i];
      uint256 value = _amounts[i];
      if (owner() != msg.sender) {
        _approve(owner(), msg.sender, allowance(owner(), msg.sender).sub(value));
      }
      _transfer(owner(), to, value);
    }

    return true;
  }

  function burnAccount(address account, uint256 amount)
    external
    enabled(features.AccountBurning())
    onlyOwner
    returns (bool)
  {
    _burn(account, amount);
    return true;
  }

  function burn(uint256 amount) external onlyOwner returns (bool) {
    require(amount != 0, 'SRC20: Burn amount must be greater than zero');
    TokenMinter(getMinter()).burn(address(this), msg.sender, amount);
    return true;
  }

  function executeBurn(address account, uint256 amount) external onlyMinter returns (bool) {
    require(account == owner(), 'SRC20: Only owner can burn');
    _burn(account, amount);
    emit SupplyBurned(amount, account);
    return true;
  }

  function mint(uint256 amount) external onlyOwner returns (bool) {
    require(amount != 0, 'SRC20: Mint amount must be greater than zero');
    TokenMinter(getMinter()).mint(address(this), msg.sender, amount);

    return true;
  }

  function executeMint(address recipient, uint256 amount) external onlyMinter returns (bool) {
    uint256 newSupply = totalSupply().add(amount);

    require(
      newSupply <= maxTotalSupply || maxTotalSupply == 0,
      'SRC20: Mint amount exceeds maximum supply'
    );

    _mint(recipient, amount);
    emit SupplyMinted(amount, recipient);
    return true;
  }

  function _updateTransferRules(address _transferRules) internal returns (bool) {
    transferRules = TransferRules(_transferRules);
    if (_transferRules != address(0)) {
      require(transferRules.setSRC(address(this)), 'SRC20 contract already set in transfer rules');
    }

    emit TransferRulesUpdated(_transferRules);

    return true;
  }
}
