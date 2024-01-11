// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./OndoRegistryClient.sol";
import "./Multicall.sol";
import "./IPairVault.sol";
import "./IRollover.sol";
import "./ISingleAssetVault.sol";
import "./ISAStrategy.sol";
import "./OndoLibrary.sol";

contract SingleAssetVault is Multicall, ISingleAssetVault {
  using SafeERC20 for IERC20;

  uint256 public constant MULTIPLIER_DENOMINATOR = 2**100;

  IERC20 public immutable override asset;

  mapping(address => bool) public isStrategy;

  uint256 public totalFundAmount;
  uint256 public totalActivePoolAmount;
  uint256 public totalPassivePoolAmount;

  PoolData[] public pools;
  Action[] public actions; // calculate token balance based on this action order

  mapping(address => UserDeposit[]) internal userDeposits;
  mapping(address => uint256) internal fromDepositIndex; // calculate token balance from this deposit index

  bool public withdrawEnabled;

  /**
   * @dev Setup contract dependencies here
   * @param _asset single asset
   * @param _registry Pointer to Registry
   */
  constructor(address _asset, address _registry) OndoRegistryClient(_registry) {
    require(_asset != address(0), "Invalid asset");
    asset = IERC20(_asset);
  }

  function setStrategy(address _strategy, bool _flag)
    external
    isAuthorized(OLib.GUARDIAN_ROLE)
    nonReentrant
  {
    isStrategy[_strategy] = _flag;
  }

  function setWithdrawEnabled(bool _withdrawEnabled)
    external
    isAuthorized(OLib.GUARDIAN_ROLE)
  {
    withdrawEnabled = _withdrawEnabled;
  }

  function deposit(uint256 _amount) external nonReentrant {
    require(_amount > 0, "zero amount");
    asset.safeTransferFrom(msg.sender, address(this), _amount);

    totalFundAmount += _amount;
    userDeposits[msg.sender].push(
      UserDeposit({amount: _amount, firstActionId: actions.length})
    );

    emit Deposit(msg.sender, _amount, pools.length);
  }

  function withdraw(uint256 _amount, address _to)
    external
    whenNotPaused
    nonReentrant
  {
    require(_amount > 0, "zero amount");
    require(withdrawEnabled, "withdraw disabled");
    (
      uint256 activeInvestAmount,
      uint256 passiveInvestAmount,
      uint256 remainAmount
    ) = tokenBalances(msg.sender);
    require(activeInvestAmount + passiveInvestAmount == 0, "invested!");
    require(remainAmount >= _amount, "insufficient balance");

    fromDepositIndex[msg.sender] = userDeposits[msg.sender].length;
    if (remainAmount > _amount) {
      userDeposits[msg.sender].push(
        UserDeposit({
          amount: remainAmount - _amount,
          firstActionId: actions.length
        })
      );
    }

    totalFundAmount -= _amount;
    asset.safeTransfer(_to, _amount);

    emit Withdraw(msg.sender, _amount, _to);
  }

  function massUpdateUserBalance(address _user) external {
    (
      uint256 activeInvestAmount,
      uint256 passiveInvestAmount,
      uint256 remainAmount
    ) = tokenBalances(msg.sender);
    require(activeInvestAmount + passiveInvestAmount == 0, "invested!");

    fromDepositIndex[msg.sender] = userDeposits[msg.sender].length;
    if (remainAmount > 0) {
      userDeposits[msg.sender].push(
        UserDeposit({amount: remainAmount, firstActionId: actions.length})
      );
    }

    emit MassUpdateUserBalance(_user);
  }

  function invest(
    address _strategy,
    uint256 _amount,
    bool _isPassive,
    bytes memory _data
  ) external whenNotPaused isAuthorized(OLib.STRATEGIST_ROLE) nonReentrant {
    require(isStrategy[_strategy], "invalid strategy");

    if (_isPassive) {
      pools.push(
        PoolData({
          isPassive: true,
          investAmount: _amount,
          strategy: _strategy,
          strategist: msg.sender,
          depositMultiplier: 0,
          redemptionMultiplier: 0,
          redeemed: false
        })
      );
      totalPassivePoolAmount += _amount;
    } else {
      pools.push(
        PoolData({
          isPassive: false,
          investAmount: _amount,
          strategy: _strategy,
          strategist: msg.sender,
          depositMultiplier: OLib.safeMulDiv(
            _amount,
            MULTIPLIER_DENOMINATOR,
            (totalFundAmount + totalPassivePoolAmount)
          ),
          redemptionMultiplier: MULTIPLIER_DENOMINATOR,
          redeemed: false
        })
      );
      actions.push(
        Action({actionType: ActionType.Invest, poolId: pools.length - 1})
      );
      totalActivePoolAmount += _amount;
    }

    totalFundAmount -= _amount;

    uint256 poolId = pools.length - 1;
    asset.safeApprove(_strategy, _amount);
    ISAStrategy(_strategy).invest(poolId, _amount, _data);

    emit Invest(poolId, msg.sender, _strategy, _amount, _data);
  }

  function redeem(uint256 _poolId, bytes memory _data)
    external
    whenNotPaused
    nonReentrant
  {
    PoolData storage pool = pools[_poolId];
    require(
      msg.sender == pool.strategist ||
        registry.authorized(OLib.GUARDIAN_ROLE, msg.sender),
      "Unauthorized"
    );
    require(!pool.redeemed, "Already redeemed");

    (bool pendingAdditionalWithdraw, uint256 redeemAmount) =
      ISAStrategy(pool.strategy).redeem(_poolId, _data);

    if (pendingAdditionalWithdraw) {
      return;
    }

    pool.redeemed = true;
    pool.redemptionMultiplier = OLib.safeMulDiv(
      redeemAmount,
      MULTIPLIER_DENOMINATOR,
      pool.investAmount
    );

    if (pool.isPassive) {
      pool.depositMultiplier = OLib.safeMulDiv(
        pool.investAmount,
        MULTIPLIER_DENOMINATOR,
        (totalFundAmount + totalPassivePoolAmount)
      );

      actions.push(Action({actionType: ActionType.Invest, poolId: _poolId}));
      totalPassivePoolAmount -= pool.investAmount;
    } else {
      totalActivePoolAmount -= pool.investAmount;
    }

    actions.push(Action({actionType: ActionType.Redeem, poolId: _poolId}));
    totalFundAmount += redeemAmount;

    emit Redeem(_poolId, msg.sender, redeemAmount, _data);
  }

  function tokenBalance(address _user) external view returns (uint256 amount) {
    (
      uint256 activeInvestAmount,
      uint256 passiveInvestAmount,
      uint256 remainAmount
    ) = tokenBalances(_user);

    return activeInvestAmount + passiveInvestAmount + remainAmount;
  }

  function tokenBalances(address _user)
    public
    view
    returns (
      uint256 activeInvestAmount,
      uint256 passiveInvestAmount,
      uint256 remainAmount
    )
  {
    uint256 depositLength = userDeposits[_user].length;
    uint256 depositIndex = fromDepositIndex[_user];
    if (depositLength == depositIndex) {
      return (0, 0, 0);
    }

    UserDeposit[] storage deposits = userDeposits[_user];

    uint256 currentActionId = deposits[depositIndex].firstActionId;
    uint256[] memory userPoolDeposits = new uint256[](pools.length); // this is to reduce the memory size
    while (depositIndex < depositLength || currentActionId < actions.length) {
      if (
        depositIndex < depositLength &&
        currentActionId == deposits[depositIndex].firstActionId
      ) {
        remainAmount += deposits[depositIndex].amount;
        depositIndex++;
        continue;
      }

      // always: currentActionId < deposits[depositIndex].actionId
      Action memory action = actions[currentActionId];
      PoolData memory pool = pools[action.poolId];
      if (action.actionType == ActionType.Invest) {
        userPoolDeposits[action.poolId] = OLib.safeMulDiv(
          remainAmount,
          pool.depositMultiplier,
          MULTIPLIER_DENOMINATOR
        );
        remainAmount -= userPoolDeposits[action.poolId];
        activeInvestAmount += userPoolDeposits[action.poolId];
      } else if (userPoolDeposits[action.poolId] > 0) {
        uint256 redeemAmount =
          OLib.safeMulDiv(
            userPoolDeposits[action.poolId],
            pool.redemptionMultiplier,
            MULTIPLIER_DENOMINATOR
          );
        remainAmount += redeemAmount;
        activeInvestAmount -= userPoolDeposits[action.poolId];
      }
      currentActionId++;
    }

    if (totalPassivePoolAmount != 0) {
      passiveInvestAmount = OLib.safeMulDiv(
        remainAmount,
        totalPassivePoolAmount,
        (totalFundAmount + totalPassivePoolAmount)
      );
      remainAmount -= passiveInvestAmount;
    }
  }
}
