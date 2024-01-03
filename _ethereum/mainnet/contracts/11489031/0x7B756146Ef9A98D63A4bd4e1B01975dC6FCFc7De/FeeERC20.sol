// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

import "./IFeeController.sol";
import "./IFeeSplitter.sol";

contract FeeERC20 is ERC20, Ownable {
  using SafeMath for uint256;

  address public governance;

  address public feeController;

  address public feeSplitter;

  address public lockedLiquidityEvent;

  /// @dev Maximum supply of TDAO
  uint256 public constant MAX_SUPPLY = 5000e18;

  bool private _setupComplete;

  modifier onlyGovernance() {
    require(governance == msg.sender, 'FeeERC20: Caller is not governance.');
    _;
  }

  constructor(string memory _name, string memory _symbol)
    public
    ERC20(_name, _symbol)
  {}

  // @notice Allows governance to set a new treasury address
  // @param _treasury New treasury address to be set
  function setTreasuryVault(address _treasuryVault) external onlyGovernance {
    IFeeSplitter(feeSplitter).setTreasuryVault(_treasuryVault);
  }

  // @notice Sets the percentage of the fee that goes to TRIG holders
  // @param _trigFee It can be between 5000 (50%) and 9000 (90%)
  function setTrigFee(uint256 _trigFee) external onlyGovernance {
    IFeeSplitter(feeSplitter).setTrigFee(_trigFee);
  }

  // @notice Sets the percentage of the fee that goes to the keeper
  // @param _keeperFee Must be below 10 (0.1%)
  function setKeeperFee(uint256 _keeperFee) external onlyGovernance {
    IFeeSplitter(feeSplitter).setKeeperFee(_keeperFee);
  }

  // @notice Sets the percentage of the transfer that will be charged as fee
  // @param _fee It can be between 10 (0.1%) and 1000 (10%)
  function setFee(uint256 _fee) external onlyGovernance {
    IFeeController(feeController).setFee(_fee);
  }

  // @notice Sets addresse that will not be charged fee while sending TDAO
  // @param _address Address of the account that can send TDAO without fees
  // @param _noFee True for no fees
  function editNoFeeList(address _address, bool _noFee)
    external
    onlyGovernance
  {
    IFeeController(feeController).editNoFeeList(_address, _noFee);
  }

  // @notice Sets addresse that will be blocked from sending or receiving TDAO
  // @param _address Address of the account that will be blocked
  // @param _block True if the address should be blocked
  function editBlockList(address _address, bool _block)
    external
    onlyGovernance
  {
    IFeeController(feeController).editBlockList(_address, _block);
  }

  function setLockedLiquidityEvent(address _lockedLiquidityEvent)
    external
    onlyOwner
  {
    require(lockedLiquidityEvent == address(0), 'FeeERC20: LLE already set.');
    lockedLiquidityEvent = _lockedLiquidityEvent;
  }

  function setDependencies(
    address _feeController,
    address _feeSplitter,
    address _governance
  ) external onlyOwner {
    feeController = _feeController;
    feeSplitter = _feeSplitter;
    governance = _governance;
    _mint(lockedLiquidityEvent, MAX_SUPPLY);
    renounceOwnership();
    _setupComplete = true;
  }

  function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    _transferWithFee(_msgSender(), recipient, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transferWithFee(sender, recipient, amount);
    uint256 _allowance = allowance(sender, _msgSender());
    uint256 _remaining =
      _allowance.sub(amount, 'FeeERC20: transfer amount exceeds allowance');
    _approve(sender, _msgSender(), _remaining);
    return true;
  }

  function _transferWithFee(
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    require(_setupComplete, 'FeeERC20: Must set up dependencies.');

    (uint256 amountMinusFee, uint256 fee) =
      IFeeController(feeController).applyFee(sender, recipient, amount);

    require(
      amountMinusFee.add(fee) == amount,
      'FeeERC20: Fee plus transfer amount should be equal to total amount'
    );

    _transfer(sender, recipient, amountMinusFee);

    if (fee != 0) {
      _transfer(sender, feeSplitter, fee);
    }
  }
}
