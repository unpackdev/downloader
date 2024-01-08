pragma solidity 0.7.3;

import "./MathUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./IStrategy.sol";
import "./IVault.sol";
import "./IStorage.sol";
import "./IController.sol";
import "./IUpgradeSource.sol";
import "./ControllableInit.sol";
import "./VaultStorage.sol";
import "./IUniswapV2Router02.sol";
import "./console.sol";

contract OneRingVault is ERC20Upgradeable, IUpgradeSource, ControllableInit, VaultStorage {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using AddressUpgradeable for address;
  using SafeMathUpgradeable for uint256;

  event Withdraw(address indexed beneficiary, uint256 amount);
  event Deposit(address indexed beneficiary, uint256 amount);
  event Invest(uint256 amount);

  constructor() public {}

  function initializeVault(
    address _storage,
    address _underlying
  ) public initializer {
    __ERC20_init(
      "One Ring USD",
      "OUSD"
    );
    _setupDecimals(ERC20Upgradeable(_underlying).decimals());

    ControllableInit.initialize(
      _storage
    );

    console.log("storage main underlying: ", IStorage(_storage).mainUnderlying());
    console.log("_underlying: ", _underlying);

    require(IStorage(_storage).mainUnderlying() == _underlying, "Underlying mismatch");

    uint256 underlyingUnit = 10 ** uint256(ERC20Upgradeable(address(_underlying)).decimals());
    uint256 implementationDelay = 12 hours;
    uint256 strategyChangeDelay = 12 hours;
    VaultStorage.initialize(
      _underlying,
      underlyingUnit,
      implementationDelay,
      strategyChangeDelay
    );
  }

  function strategy() public view returns(address) {
    return _strategy();
  }

  function underlying() public view returns(address) {
    return _underlying();
  }

  function underlyingUnit() public view returns(uint256) {
    return _underlyingUnit();
  }

  function nextImplementation() public view returns(address) {
    return _nextImplementation();
  }

  function nextImplementationTimestamp() public view returns(uint256) {
    return _nextImplementationTimestamp();
  }

  function nextImplementationDelay() public view returns(uint256) {
    return _nextImplementationDelay();
  }

  modifier whenStrategyDefined() {
    require(address(strategy()) != address(0), "Strategy must be defined");
    _;
  }

  function setStrategy(address _strategy) public onlyControllerOrGovernance {
    require(_strategy != address(0), "new _strategy cannot be empty");
    require(IStrategy(_strategy).vault() == address(this), "the strategy does not belong to this vault");

    if (address(strategy()) != address(0)) {
      withdrawAll();
    }
    _setStrategy(_strategy);
    IERC20Upgradeable(underlying()).safeApprove(address(strategy()), 0);
    IERC20Upgradeable(underlying()).safeApprove(address(strategy()), uint256(~0));
  }

  // Only smart contracts will be affected by this modifier
  modifier defense() {
    require(
      (msg.sender == tx.origin) ||                // If it is a normal user and not smart contract,
                                                  // then the requirement will pass
      !IController(controller()).greyList(msg.sender), // If it is a smart contract, then
      "This smart contract has been grey listed"  // make sure that it is not on our greyList.
    );
    _;
  }

  function doHardWork() whenStrategyDefined onlyControllerOrGovernance external {
    invest();
    IStrategy(strategy()).doHardWork();
  }

  function underlyingBalanceInVault() view public returns (uint256) {
    return IERC20Upgradeable(underlying()).balanceOf(address(this));
  }
  
  function underlyingBalanceWithInvestment() view public returns (uint256) {
    if (address(strategy()) == address(0)) {
      // initial state, when not set
      return underlyingBalanceInVault();
    }
    return underlyingBalanceInVault().add(IStrategy(strategy()).investedUnderlyingBalance());
  }

  function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256) {
    if (totalSupply() == 0) {
      return 0;
    }
    return underlyingBalanceWithInvestment()
        .mul(balanceOf(holder))
        .div(totalSupply());
  }

  function getPricePerFullShare() public view returns (uint256) {
    return totalSupply() == 0
        ? underlyingUnit()
        : underlyingUnit().mul(underlyingBalanceWithInvestment()).div(totalSupply());
  }
  
  function rebalance() external onlyControllerOrGovernance {
    withdrawAll();
    invest();
  }
  
  function invest() internal whenStrategyDefined {
    uint256 availableAmount = underlyingBalanceInVault();
    if (availableAmount > 0) {
      IERC20Upgradeable(underlying()).safeTransfer(address(strategy()), availableAmount);
      emit Invest(availableAmount);
    }
  }
  
  function deposit(uint256 amount, address token) external defense {
    _deposit(amount, token, msg.sender, msg.sender);
  }
  
  function depositFor(uint256 amount, address token, address holder) public defense {
    _deposit(amount, token, msg.sender, holder);
  }

  function withdrawAll() public onlyControllerOrGovernance whenStrategyDefined {
    IStrategy(strategy()).withdrawAllToVault();
  }

  function withdraw(uint256 numberOfShares, address _underlying) external {
    require(totalSupply() > 0, "Vault has no shares");
    require(numberOfShares > 0, "numberOfShares must be greater than 0");
    uint256 totalSupply = totalSupply();
    _burn(msg.sender, numberOfShares);

    uint256 underlyingAmountToWithdraw = underlyingBalanceWithInvestment()
        .mul(numberOfShares)
        .div(totalSupply);
    if (underlyingAmountToWithdraw > underlyingBalanceInVault()) {
      // withdraw everything from the strategy to accurately check the share value
      if (numberOfShares == totalSupply) {
        IStrategy(strategy()).withdrawAllToVault();
      } else {
        uint256 missing = underlyingAmountToWithdraw.sub(underlyingBalanceInVault());
        IStrategy(strategy()).withdrawToVault(missing);
      }
      // recalculate to improve accuracy
      underlyingAmountToWithdraw = MathUpgradeable.min(underlyingBalanceWithInvestment()
          .mul(numberOfShares)
          .div(totalSupply), underlyingBalanceInVault());
    }

    uint256 _withdrawAmount = 0;
    uint256[] memory amounts;

    address routerAddress = IStorage(_storage()).routerAddress();

    IERC20Upgradeable(underlying()).safeApprove(routerAddress, 0);
    IERC20Upgradeable(underlying()).safeApprove(routerAddress, underlyingAmountToWithdraw);

    address[] memory path = new address[](2);
    path[0] = underlying();
    path[1] = _underlying;

    if (_underlying != underlying()) {
      amounts = IUniswapV2Router02(routerAddress).swapExactTokensForTokens(
        underlyingAmountToWithdraw,
        0,
        path,
        address(this),
        block.timestamp.add(60)
      );
      _withdrawAmount = amounts[1];
    } else {
      _withdrawAmount = underlyingAmountToWithdraw;
    }

    IERC20Upgradeable(underlying()).safeTransfer(msg.sender, _withdrawAmount);

    // update the withdrawal amount for the holder
    emit Withdraw(msg.sender, _withdrawAmount);
  }

  function _deposit(uint256 amount, address _underlying, address sender, address beneficiary) internal {
    require(amount > 0, "Cannot deposit 0");
    require(beneficiary != address(0), "holder must be defined");
    require(IStorage(_storage()).underlyingEnabled(_underlying), "Underlying token is not enabled");

    console.log("\n\n=== Vault _deposit function ===");
    console.log("amount: ", amount);
    console.log("beneficiary: ", beneficiary);

    IERC20Upgradeable(underlying()).safeTransferFrom(sender, address(this), amount);

    uint256 _depositAmount = 0;
    uint256[] memory amounts;

    address routerAddress = IStorage(_storage()).routerAddress();

    IERC20Upgradeable(_underlying).safeApprove(routerAddress, 0);
    IERC20Upgradeable(_underlying).safeApprove(routerAddress, amount);

    address[] memory path = new address[](2);
    path[0] = _underlying;
    path[1] = underlying();

    if (_underlying != underlying()) {
      amounts = IUniswapV2Router02(routerAddress).swapExactTokensForTokens(
        amount,
        0,
        path,
        address(this),
        block.timestamp
      );
      _depositAmount = amounts[1];
    } else {
      _depositAmount = amount;
    }

    console.log("_depositAmount: ", _depositAmount);

    uint256 toMint = totalSupply() == 0
        ? _depositAmount
        : _depositAmount.mul(totalSupply()).div(underlyingBalanceWithInvestment());
    _mint(beneficiary, toMint);

    console.log("toMint: ", toMint);

    // update the contribution amount for the beneficiary
    emit Deposit(beneficiary, _depositAmount);
  }

  function scheduleUpgrade(address impl) public onlyGovernance {
    _setNextImplementation(impl);
    _setNextImplementationTimestamp(block.timestamp.add(nextImplementationDelay()));
  }
  
  function shouldUpgrade() external view override returns (bool, address) {
    return (
      nextImplementationTimestamp() != 0
        && block.timestamp > nextImplementationTimestamp()
        && nextImplementation() != address(0),
      nextImplementation()
    );
  }

  function finalizeUpgrade() external override onlyGovernance {
    _setNextImplementation(address(0));
    _setNextImplementationTimestamp(0);
  }
}
