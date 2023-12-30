// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./SafeMath.sol";
import "./Address.sol";
import "./EnumerableSet.sol";

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ILotManager.sol";
import "./IHegicPool.sol";

contract HegicPool is IHegicPool, ERC20 {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  uint256 public WITHDRAW_MAX_COOLDOWN = 2 * 7 * 24 * 60 * 60;
  uint256 public WITHDRAW_FEE_PRECISION = 10000;
  uint256 public WITHDRAW_MAX_FEE = 5 * WITHDRAW_FEE_PRECISION;

  IERC20 public constant token = IERC20(0x584bC13c7D411c00c01A62e8019472dE68768430);
  EnumerableSet.AddressSet private protocolTokens;

  address public governance;
  address public pendingGovernance;

  address public manager;
  address public pendingManager;

  ILotManager public lotManager;

  uint256 public minTokenReserves = 100000 * 1e18;
  uint256 public withdrawCooldown = 0;
  uint256 public withdrawFee = 0;

  mapping (address => uint256) public userCooldown;

  constructor() public ERC20("zHEGIC", "zHEGIC") {
    protocolTokens.add(address(token));
    governance = msg.sender;
    manager = msg.sender;
  }

  function isHegicPool() external pure override virtual returns (bool) {
    return true;
  }

  function getToken() external view override virtual returns (address) {
    return address(token);
  }

  function setLotManager(address _lotManager) external onlyGovernance {
    require(ILotManager(_lotManager).isLotManager(), "hegic-pool/invalid-lot-manager");
    lotManager = ILotManager(_lotManager);
    emit LotManagerSet(_lotManager);
  }
  function setMinTokenReserves(uint256 _minTokenReserves) external onlyGovernance {
    minTokenReserves = _minTokenReserves;
    emit MinTokenReservesSet(_minTokenReserves);
  }
  function setWithdrawCooldown(uint256 _withdrawCooldown) external onlyGovernance {
    require(_withdrawCooldown <= WITHDRAW_MAX_COOLDOWN, "hegic-pool/max-withdraw-cooldown");
    withdrawCooldown = _withdrawCooldown;
    emit WithdrawCooldownSet(_withdrawCooldown);
  }
  function setWithdrawFee(uint256 _withdrawFee) external onlyGovernance {
    require(_withdrawFee <= WITHDRAW_MAX_FEE, "hegic-pool/max-withdraw-fee");
    withdrawFee = _withdrawFee;
    emit WithdrawFeeSet(_withdrawFee);
  }

  function depositAll() external returns (uint256 _shares) {
    return deposit(token.balanceOf(msg.sender));
  }

  function deposit(uint256 _amount) public returns (uint256 _shares) {
    userCooldown[msg.sender] = now.add(withdrawCooldown);
    uint256 _pool = totalUnderlying();
    uint256 _before = unusedUnderlyingBalance();
    token.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 _after = unusedUnderlyingBalance();
    _amount = _after.sub(_before); // Additional check for deflationary tokens
    if (totalSupply() == 0) {
      _shares = _amount;
    } else {
      _shares = (_amount.mul(totalSupply())).div(_pool);
    }
    _mint(msg.sender, _shares);
    emit Deposited(msg.sender, _amount, _shares);
  }

  function withdrawAll() external returns (uint256 _underlyingToWithdraw) {
    return withdraw(balanceOf(msg.sender));
  }

  function withdraw(uint256 _shares) public returns (uint256 _underlyingToWithdraw) {
    _underlyingToWithdraw = (totalUnderlying().mul(_shares)).div(totalSupply());
    _burn(msg.sender, _shares);

    uint256 _unusedUnderlyingBalance = unusedUnderlyingBalance();
    if (_underlyingToWithdraw > _unusedUnderlyingBalance) {
      uint256 _missingUnderlying = _underlyingToWithdraw.sub(_unusedUnderlyingBalance);

      require(lotManager.sellLot(), "hegic-pool/error-while-selling-lot");

      uint256 _underlyingAfterLotClosure = unusedUnderlyingBalance();
      uint256 _diff = _underlyingAfterLotClosure.sub(_unusedUnderlyingBalance);

      if (_missingUnderlying > _diff) {
        _underlyingToWithdraw = _unusedUnderlyingBalance.add(_diff);
      }
    }

    uint256 _withdrawFee;
    if (now < userCooldown[msg.sender]) {
      _withdrawFee = _underlyingToWithdraw.mul(withdrawFee).div(WITHDRAW_FEE_PRECISION).div(100);
      _underlyingToWithdraw = _underlyingToWithdraw.sub(_withdrawFee);
      token.safeTransfer(governance, _withdrawFee);
    }

    token.safeTransfer(msg.sender, _underlyingToWithdraw);
    emit Withdrew(msg.sender, _shares, _underlyingToWithdraw, _withdrawFee);
  }

  function claimRewards() public onlyManager returns (uint _rewards) {
    uint256 _before = unusedUnderlyingBalance();
    require(lotManager.claimRewards(), "hegic-pool/error-while-claiming-rewards");
    uint256 _after = unusedUnderlyingBalance();
    _rewards = _after.sub(_before);
    emit RewardsClaimed(_rewards);
  }

  function buyLot() public onlyManager returns (bool) {
    require(unusedUnderlyingBalance() >= minTokenReserves.add(lotManager.lotPrice()), "hegic-pool/not-enough-reserves");
    uint256 availableUnderlying = unusedUnderlyingBalance().sub(minTokenReserves);
    token.approve(address(lotManager), availableUnderlying);
    require(lotManager.buyLot(), "hegic-pool/error-while-buying-lot");
    emit LotBought();
    return true;
  }

  function unusedUnderlyingBalance() public view returns (uint256) {
    return token.balanceOf(address(this));
  }
  function totalUnderlying() public view returns (uint256) {
    if (address(lotManager) == address(0)) return unusedUnderlyingBalance();
    return unusedUnderlyingBalance().add(lotManager.balaceOfUnderlying());
  }
  function getPricePerFullShare() public view returns (uint256) {
    return totalUnderlying().mul(1e18).div(totalSupply());
  }

  function setPendingGovernance(address _pendingGovernance) external onlyGovernance {
    pendingGovernance = _pendingGovernance;
    emit PendingGovernanceSet(_pendingGovernance);
  }
  function acceptGovernance() external onlyPendingGovernance {
    governance = msg.sender;
    emit GovernanceAccepted();
  }

  modifier onlyGovernance {
    require(msg.sender == governance, "hegic-pool/only-governance");
    _;
  }
  modifier onlyPendingGovernance {
    require(msg.sender == pendingGovernance, "hegic-pool/only-pending-governance");
    _;
  }

  function setPendingManager(address _pendingManager) external onlyGovernanceOrManager {
    pendingManager = _pendingManager;
    emit PendingManagerSet(_pendingManager);
  }

  function acceptManager() external onlyPendingManager {
    manager = msg.sender;
    emit ManagerAccepted();
  }

  modifier onlyManager {
    require(msg.sender == manager, "hegic-pool/only-manager");
    _;
  }
  modifier onlyPendingManager {
    require(msg.sender == pendingManager, "hegic-pool/only-pending-manager");
    _;
  }

  modifier onlyGovernanceOrManager {
    require(msg.sender == governance || msg.sender == manager, "hegic-pool/only-governance-or-manager");
    _;
  }

  function collectDust(address _token, uint256 _amount) public onlyGovernance {
    require(!protocolTokens.contains(_token), "hegic-pool/token-is-part-of-protocol");
    if (_token == address(0)) {
      payable(governance).transfer(_amount);
    } else {
      IERC20(_token).transfer(governance, _amount);
    }
    emit CollectedDust(_token, _amount);
  }
}
