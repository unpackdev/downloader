pragma solidity 0.7.3;

import "./MathUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./IStrategy.sol";
import "./IVault.sol";
import "./IController.sol";
import "./IUpgradeSource.sol";
import "./ControllableInit.sol";
import "./VaultStorage.sol";

contract OnxAlphaVault is ERC20Upgradeable, ControllableInit, VaultStorage {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using AddressUpgradeable for address;
  using SafeMathUpgradeable for uint256;

  event Withdraw(address indexed beneficiary, uint256 amount);
  event Deposit(address indexed beneficiary, uint256 amount);
  event Invest(uint256 amount);

  constructor() public {}

  function initialize(
    address _storage,
    address _underlying
  ) public initializer {
    __ERC20_init(
      string(abi.encodePacked("alpha_", ERC20Upgradeable(_underlying).symbol())),
      string(abi.encodePacked("alpha", ERC20Upgradeable(_underlying).symbol()))
    );
    _setupDecimals(ERC20Upgradeable(_underlying).decimals());

    ControllableInit.initializeControllableInit(
      _storage
    );

    uint256 underlyingUnit = 10 ** uint256(ERC20Upgradeable(address(_underlying)).decimals());
    VaultStorage.initializeVaultStorage(
      _underlying,
      underlyingUnit
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

  modifier whenStrategyDefined() {
    require(address(strategy()) != address(0), "undefined strategy");
    _;
  }

  function setStrategy(address _strategy) public onlyControllerOrGovernance {
    require(_strategy != address(0), "empty strategy");
    require(IStrategy(_strategy).underlying() == address(underlying()), "underlying not match");
    require(IStrategy(_strategy).vault() == address(this), "strategy vault not match");

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
      "grey listed"  // make sure that it is not on our greyList.
    );
    _;
  }

  function stakeOnsenFarm() whenStrategyDefined onlyControllerOrGovernance external {
    invest();
    IStrategy(strategy()).stakeOnsenFarm();
  }

  function stakeSushiBar() whenStrategyDefined onlyControllerOrGovernance external {
    IStrategy(strategy()).stakeSushiBar();
  }

  function stakeOnxFarm() whenStrategyDefined onlyControllerOrGovernance external {
    IStrategy(strategy()).stakeOnxFarm();
  }

  function stakeOnx() whenStrategyDefined onlyControllerOrGovernance external {
    IStrategy(strategy()).stakeOnx();
  }

  function doHardWork() whenStrategyDefined public {
    invest();
    IStrategy(strategy()).stakeOnsenFarm();
    IStrategy(strategy()).stakeSushiBar();
    IStrategy(strategy()).stakeOnxFarm();
    IStrategy(strategy()).stakeOnx();
  }

  function doHardWorkXSushi() whenStrategyDefined public {
    invest();
    IStrategy(strategy()).stakeOnsenFarm();
    IStrategy(strategy()).stakeSushiBar();
  }

  function doHardWorkSOnx() whenStrategyDefined public {
    IStrategy(strategy()).stakeOnxFarm();
    IStrategy(strategy()).stakeOnx();
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
  
  function deposit(uint256 amount) external defense {
    _deposit(amount, msg.sender, msg.sender);
  }
  
  function depositFor(uint256 amount, address holder) public defense {
    _deposit(amount, msg.sender, holder);
  }

  function withdrawAll() public onlyControllerOrGovernance whenStrategyDefined {
    IStrategy(strategy()).withdrawAllToVault();
  }

  function withdraw(uint256 numberOfShares) external {
    require(totalSupply() > 0, "no shares");

    // doHardWork at every withdraw
    if (address(strategy()) != address(0)) {
      doHardWork();
    }
    
    IStrategy(strategy()).updateAccPerShare(msg.sender);
    IStrategy(strategy()).withdrawReward(msg.sender);

    if (numberOfShares > 0) {
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

      // Send withdrawal fee
      if (address(strategy()) != address(0)) {
        uint256 feeAmount = underlyingAmountToWithdraw.mul(10).div(10000);
        IERC20Upgradeable(underlying()).safeTransfer(IStrategy(strategy()).treasury(), feeAmount);
        underlyingAmountToWithdraw = underlyingAmountToWithdraw.sub(feeAmount);
      }

      IERC20Upgradeable(underlying()).safeTransfer(msg.sender, underlyingAmountToWithdraw);

      // update the withdrawal amount for the holder
      emit Withdraw(msg.sender, underlyingAmountToWithdraw);
    }

    IStrategy(strategy()).updateUserRewardDebts(msg.sender);
  }

  function _deposit(uint256 amount, address sender, address beneficiary) internal {
    require(beneficiary != address(0), "holder undefined");
    
    IStrategy(strategy()).updateAccPerShare(beneficiary);
    IStrategy(strategy()).withdrawReward(beneficiary);

    if (amount > 0) {
      uint256 toMint = totalSupply() == 0
          ? amount
          : amount.mul(totalSupply()).div(underlyingBalanceWithInvestment());
      _mint(beneficiary, toMint);

      IERC20Upgradeable(underlying()).safeTransferFrom(sender, address(this), amount);

      // update the contribution amount for the beneficiary
      emit Deposit(beneficiary, amount);
    }

    IStrategy(strategy()).updateUserRewardDebts(beneficiary);
  }
}
