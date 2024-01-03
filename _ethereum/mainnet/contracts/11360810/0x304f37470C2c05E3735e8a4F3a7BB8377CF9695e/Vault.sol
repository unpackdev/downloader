// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Address.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./IBundle.sol";
import "./IController.sol";
import "./IVault.sol";
import "./IUpgradeSource.sol";
import "./ControllableInit.sol";
import "./VaultStorage.sol";

contract Vault is ERC20UpgradeSafe, IVault, IUpgradeSource, ControllableInit, VaultStorage {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  event Withdraw(address indexed beneficiary, uint256 amount);
  event Deposit(address indexed beneficiary, uint256 amount);
  event BundleChanged(address newBundle, address oldBundle);

  // the function is named differently to not cause inheritance clash in truffle and allows tests
  function initializeVault(address _storage,
    address _underlying
  ) public initializer {

    ERC20UpgradeSafe.__ERC20_init(
      string(abi.encodePacked("MUD_", ERC20UpgradeSafe(_underlying).symbol())),
      string(abi.encodePacked("m", ERC20UpgradeSafe(_underlying).symbol()))
    );
    ControllableInit.initializeController(
      _storage
    );

    uint256 underlyingUnit = 10 ** uint256(ERC20UpgradeSafe(address(_underlying)).decimals());
    
    VaultStorage.initializeVaultStorage(
      _underlying,
      underlyingUnit
    );
  }

  function bundle() public override view returns(address) {
    return _bundle();
  }

  function underlying() public override view returns(address) {
    return _underlying();
  }

  function underlyingUnit() public view returns(uint256) {
    return _underlyingUnit();
  }


  modifier whenBundleDefined() {
    require(address(bundle()) != address(0), "Bundle must be defined");
    _;
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

  /*
  * Returns the cash balance across all users in this contract.
  */
  function underlyingBalanceInVault() view public override returns (uint256) {
    if (address(bundle()) == address(0)) {
      // initial state, when not set
      return 0;
    }

    return IBundle(bundle()).underlyingBalanceInBundle();
  }

  /* Returns the current underlying (e.g., DAI's) balance together with
   * the invested amount (if DAI is invested elsewhere by the bundle).
  */
  function underlyingBalanceWithInvestment() public override view returns (uint256) {
    if (address(bundle()) == address(0)) {
      // initial state, when not set
      return 0;
    }
    return IBundle(bundle()).underlyingBalanceWithInvestment();
  }

  function getPricePerFullShare() public override view returns (uint256) {
    return totalSupply() == 0
        ? underlyingUnit()
        : underlyingUnit().mul(underlyingBalanceWithInvestment()).div(totalSupply());
  }

  /* get the user's share (in underlying)
  */
  function underlyingBalanceWithInvestmentForHolder(address holder) view external override returns (uint256) {
    if (totalSupply() == 0) {
      return 0;
    }
    return underlyingBalanceWithInvestment()
        .mul(balanceOf(holder))
        .div(totalSupply());
  }

  function setBundle(address _bundle) public override onlyControllerOrGovernance {
    require(_bundle != address(0), "new _bundle cannot be empty");
    require(IBundle(_bundle).getUnderlying() == address(underlying()), "Vault underlying must match Bundle underlying");
    require(IBundle(_bundle).getVault() == address(this), "the bundle does not belong to this vault");

    emit BundleChanged(_bundle, bundle());
    if (address(_bundle) != address(bundle())) {
      if (address(bundle()) != address(0)) { // if the original bundle (no underscore) is defined
        IERC20(underlying()).safeApprove(address(bundle()), 0);
        // IBundle(bundle()).withdrawAllToVault();
      }
      _setBundle(_bundle);
      IERC20(underlying()).safeApprove(address(bundle()), 0);
      IERC20(underlying()).safeApprove(address(bundle()), uint256(~0));
    }
  }

  // function addBundle(address _bundle, uint256 riskScore) public override onlyControllerOrGovernance {
  //   require(_bundle != address(0), "new _bundle cannot be empty");
  //   require(IBundle(_bundle).getUnderlying() == address(underlying), "Vault underlying must match Bundle underlying");
  //   require(IBundle(_bundle).getVault() == address(this), "the bundle does not belong to this vault");

  //   bundleStruct[_bundle].riskScore = riskScore;
  //   bundleStruct[_bundle].isActive = true;
  //   bundleList.push(_bundle);

  //   underlying.safeApprove(_bundle, 0);
  //   underlying.safeApprove(_bundle, uint256(~0));
  // }

  // function removeBundle(address _bundle) public override onlyControllerOrGovernance {
  //   require(_bundle != address(0), "_bundle cannot be empty");
  //   require(bundles[_bundle], "Bundle not part of the vault");

  //   bundle = IBundle(_bundle)
  //   underlying.safeApprove(address(bundle), 0);
  //   // bundle.withdrawAllToVault();
  //   }
  // }

  function doHardWork() whenBundleDefined onlyControllerOrGovernance external override {
    IBundle(bundle()).doHardWork();
  }

  /*
  * Allows for depositing the underlying asset in exchange for shares.
  * Approval is assumed.
  */
  function deposit(uint256 amount) external override defense {
    _deposit(amount, msg.sender, msg.sender);
  }

  /*
  * Allows for depositing the underlying asset in exchange for shares
  * assigned to the holder.
  * This facilitates depositing for someone else (using DepositHelper)
  */
  function depositFor(uint256 amount, address holder) public override defense {
    _deposit(amount, msg.sender, holder);
  }

  function withdraw(uint256 numberOfShares) external override {
    require(totalSupply() > 0, "Vault has no shares");
    require(numberOfShares > 0, "numberOfShares must be greater than 0");
    
    uint256 totalSupply = totalSupply();
    _burn(msg.sender, numberOfShares);

    uint256 underlyingAmountToWithdraw = underlyingBalanceWithInvestment()
        .mul(numberOfShares)
        .div(totalSupply);

    uint256 underlyingAmountWithdrawn = IBundle(bundle()).withdraw(underlyingAmountToWithdraw, msg.sender);
    
    emit Withdraw(msg.sender, underlyingAmountWithdrawn);
  }

  function _deposit(uint256 amount, address sender, address beneficiary) internal {
    require(amount > 0, "Cannot deposit 0");
    require(beneficiary != address(0), "holder must be defined");
    require(address(bundle()) != address(0), "bundle not defined");
    require(IBundle(bundle()).depositArbCheck(), "Too much arb");

    uint256 toMint = totalSupply() == 0
        ? amount
        : amount.mul(totalSupply()).div(underlyingBalanceWithInvestment());
    _mint(beneficiary, toMint);

    IERC20(underlying()).safeTransferFrom(sender, address(bundle()), amount);

    emit Deposit(beneficiary, amount);
  }

  function shouldUpgrade() external override view returns (bool, address) {
    return (
      true,
      address(bundle())
    );
  }

  function finalizeUpgrade() external override onlyGovernance {
  }
}
