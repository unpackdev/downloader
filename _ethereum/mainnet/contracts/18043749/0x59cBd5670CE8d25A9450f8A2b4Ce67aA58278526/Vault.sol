// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IUSDA.sol";
import "./IVault.sol";
import "./IVaultController.sol";
import "./IAMPHClaimer.sol";
import "./IBooster.sol";
import "./IBaseRewardPool.sol";
import "./IVirtualBalanceRewardPool.sol";

import "./Context.sol";
import "./ICVX.sol";
import "./SafeERC20.sol";

/// @notice Vault contract, our implementation of maker-vault like vault
/// @dev Major differences:
/// 1. multi-collateral
/// 2. generate interest in USDA
contract Vault is IVault, Context {
  using SafeERC20 for IERC20;

  /// @dev The CVX token
  ICVX public immutable CVX;

  /// @dev The CRV token
  IERC20 public immutable CRV;

  /// @dev The vault controller
  IVaultController public immutable CONTROLLER;

  /// @dev Metadata of vault, aka the id & the minter's address
  VaultInfo public vaultInfo;

  /// @dev This is the unscaled liability of the vault.
  /// The number is meaningless on its own, and must be combined with the factor taken from
  /// the vaultController in order to find the true liabilitiy
  uint256 public baseLiability;

  /// @dev Keeps track of the accounting of the collateral deposited
  mapping(address => uint256) public balances;

  /// @dev Keeps track of the current rewards contract for each staked token
  mapping(address => IBaseRewardPool) public rewardsContracts;

  /// @dev Keeps track of the current poolId for each staked token
  mapping(address => uint256) public currentPoolIds;

  /// @notice Checks if _msgSender is the controller of the vault
  modifier onlyVaultController() {
    if (_msgSender() != address(CONTROLLER)) revert Vault_NotVaultController();
    _;
  }

  /// @notice Checks if _msgSender is the minter of the vault
  modifier onlyMinter() {
    if (_msgSender() != vaultInfo.minter) revert Vault_NotMinter();
    _;
  }

  /// @dev Must be called by VaultController, else it will not be registered as a vault in system
  /// @param _id Unique id of the vault, ever increasing and tracked by VaultController
  /// @param _minter Address of the person who created this vault
  /// @param _controllerAddress Address of the VaultController
  /// @param _cvx Address of CVX token
  /// @param _crv Address of CRV token
  constructor(uint96 _id, address _minter, address _controllerAddress, IERC20 _cvx, IERC20 _crv) {
    vaultInfo = VaultInfo(_id, _minter);
    CONTROLLER = IVaultController(_controllerAddress);
    CVX = ICVX(address(_cvx));
    CRV = _crv;
  }

  /// @notice Returns the minter of the vault
  /// @return _minter The address of minter
  function minter() external view override returns (address _minter) {
    _minter = vaultInfo.minter;
  }

  /// @notice Returns the id of the vault
  /// @return _id The id of the vault
  function id() external view override returns (uint96 _id) {
    _id = vaultInfo.id;
  }

  /// @notice Used to deposit a token to the vault
  /// @dev    Deposits and stakes on convex if token is of type CurveLPStakedOnConvex
  /// @param _token The address of the token to deposit
  /// @param _amount The amount of the token to deposit
  function depositERC20(address _token, uint256 _amount) external override onlyMinter {
    if (CONTROLLER.tokenId(_token) == 0) revert Vault_TokenNotRegistered();
    if (_amount == 0) revert Vault_AmountZero();

    IERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);
    uint256 _poolId = CONTROLLER.tokenPoolId(_token);
    uint256 _currentPoolId = currentPoolIds[_token];
    if (_poolId != _currentPoolId) {
      _migrateCrvLPCollateral(_token, _poolId, _currentPoolId, _amount);
    } else {
      if (_poolId != 0) {
        IBooster _booster = CONTROLLER.BOOSTER();
        _depositAndStakeOnConvex(_token, _booster, _amount, _poolId);
      }
    }

    balances[_token] += _amount;
    CONTROLLER.modifyTotalDeposited(vaultInfo.id, _amount, _token, true);
    emit Deposit(_token, _amount);
  }

  /// @notice Withdraws an erc20 token from the vault
  /// @dev    This can only be called by the minter
  ///         The withdraw will be denied if ones vault would become insolvent
  ///         If the withdraw token is of CurveLPStakedOnConvex then unstake and withdraw directly to user
  /// @param _tokenAddress The address of erc20 token
  /// @param _amount The amount of erc20 token to withdraw
  function withdrawERC20(address _tokenAddress, uint256 _amount) external override onlyMinter {
    if (CONTROLLER.tokenId(_tokenAddress) == 0) revert Vault_TokenNotRegistered();

    // calculate interest before withdrawing to make sure the vault is solvent
    CONTROLLER.calculateInterest();

    if (currentPoolIds[_tokenAddress] != 0) _withdrawAndUnwrap(rewardsContracts[_tokenAddress], _amount);
    // reduce balance
    balances[_tokenAddress] -= _amount;
    // check if the account is solvent
    if (!CONTROLLER.checkVault(vaultInfo.id)) revert Vault_OverWithdrawal();
    // transfer the token to the owner
    IERC20(_tokenAddress).safeTransfer(_msgSender(), _amount);
    // modify total deposited
    CONTROLLER.modifyTotalDeposited(vaultInfo.id, _amount, _tokenAddress, false);
    emit Withdraw(_tokenAddress, _amount);
  }

  /// @notice Let's the user manually migrate their crvLP to the newest pool set by governance
  /// @dev    This can be called if the convex pool didn't exist when the token was registered
  ///         and was later updated or if the convex pool changed
  /// @param _tokenAddress The address of erc20 crvLP token
  function migrateCrvLPCollateral(address _tokenAddress) external override onlyMinter {
    uint256 _poolId = CONTROLLER.tokenPoolId(_tokenAddress);
    uint256 _vaultPoolId = currentPoolIds[_tokenAddress];
    _migrateCrvLPCollateral(_tokenAddress, _poolId, _vaultPoolId, 0);
    emit Migrated(_tokenAddress, balances[_tokenAddress]);
  }

  /// @notice Migrates the crvLP to the newest pool set by governance
  /// @param _tokenAddress The address of erc20 crvLP token
  /// @param _poolId The latest convex poolId set by governance
  /// @param _vaultPoolId The current poolId where the tokens are staked, 0 if not staked
  /// @param _extraBalance Extra balance to also be migrated
  function _migrateCrvLPCollateral(
    address _tokenAddress,
    uint256 _poolId,
    uint256 _vaultPoolId,
    uint256 _extraBalance
  ) internal {
    if (_poolId == _vaultPoolId) revert Vault_TokenAlreadyMigrated();
    uint256 _tokenBalance = balances[_tokenAddress];

    if (_poolId == 0 || _vaultPoolId != 0 && _tokenBalance > 0) {
      // In here we withdraw in full!
      _withdrawAndUnwrap(rewardsContracts[_tokenAddress], _tokenBalance);
    }

    if (_poolId != 0) {
      // In here we deposit to the new one
      _depositAndStakeOnConvex(_tokenAddress, CONTROLLER.BOOSTER(), _tokenBalance + _extraBalance, _poolId);
    }

    currentPoolIds[_tokenAddress] = _poolId;
    rewardsContracts[_tokenAddress] = CONTROLLER.tokenCrvRewardsContract(_tokenAddress);
  }

  /// @notice Returns true when user can manually migrate their token balance
  /// @param _token The address of the token to check
  /// @return _canMigrate Returns true if the token can be migrated manually
  function canMigrate(address _token) external view override returns (bool _canMigrate) {
    uint256 _controllerPoolId = CONTROLLER.tokenPoolId(_token);
    if (balances[_token] != 0 && currentPoolIds[_token] != _controllerPoolId) _canMigrate = true;
  }

  /// @notice Claims available rewards from multiple tokens
  /// @dev    Transfers a percentage of the crv and cvx rewards to claim AMPH tokens
  /// @param _tokenAddresses The addresses of the erc20 tokens
  /// @param _claimExtraRewards True if it should claim the extra rewards from convex
  function claimRewards(address[] memory _tokenAddresses, bool _claimExtraRewards) external override onlyMinter {
    uint256 _totalCrvReward;
    uint256 _totalCvxReward;

    for (uint256 _i; _i < _tokenAddresses.length;) {
      IVaultController.CollateralInfo memory _collateralInfo = CONTROLLER.tokenCollateralInfo(_tokenAddresses[_i]);
      if (_collateralInfo.tokenId == 0) revert Vault_TokenNotRegistered();
      IBaseRewardPool _rewardsContract = rewardsContracts[_tokenAddresses[_i]];
      if (address(_rewardsContract) == address(0)) revert Vault_TokenNotStaked();

      // Claim the CRV reward
      _rewardsContract.getReward(address(this), false);

      if (_claimExtraRewards) {
        // Loop and claim all virtual rewards
        uint256 _extraRewards = _rewardsContract.extraRewardsLength();
        for (uint256 _j; _j < _extraRewards;) {
          _claimExtraReward(_rewardsContract, _j);
          unchecked {
            ++_j;
          }
        }
      }
      unchecked {
        ++_i;
      }
    }
    _totalCrvReward = (CRV.balanceOf(address(this)) - balances[address(CRV)]);
    _totalCvxReward = (CVX.balanceOf(address(this)) - balances[address(CVX)]);

    _swapRewardsForAmphAndSendToMinter(_totalCrvReward, _totalCvxReward);
  }

  /// @notice Used to claim rewards from past baseRewardContract
  /// @param _baseRewardContract The base reward contract to claim from
  /// @param _claimMainReward True to claim the base rewards also (CRV and CVX)
  /// @param _extraIndexesToClaim Indexes to claim the extra rewards
  function claimPreviousRewards(
    IBaseRewardPool _baseRewardContract,
    bool _claimMainReward,
    uint256[] memory _extraIndexesToClaim
  ) external onlyMinter {
    if (!CONTROLLER.baseRewardContracts(address(_baseRewardContract))) revert Vault_InvalidBaseRewardContract();

    if (_claimMainReward) {
      _baseRewardContract.getReward(address(this), false);
      uint256 _totalCrvReward = (CRV.balanceOf(address(this)) - balances[address(CRV)]);
      uint256 _totalCvxReward = (CVX.balanceOf(address(this)) - balances[address(CVX)]);
      _swapRewardsForAmphAndSendToMinter(_totalCrvReward, _totalCvxReward);
    }

    for (uint256 _i; _i < _extraIndexesToClaim.length;) {
      _claimExtraReward(_baseRewardContract, _extraIndexesToClaim[_i]);
      unchecked {
        ++_i;
      }
    }
  }

  /// @notice Returns an array of tokens and amounts available for claim
  /// @param _tokenAddress The address of erc20 token
  /// @param _claimExtraRewards True if it should claim the extra rewards from convex
  /// @return _rewards The array of tokens and amount available for claim
  function claimableRewards(
    address _tokenAddress,
    bool _claimExtraRewards
  ) external view override returns (Reward[] memory _rewards) {
    if (CONTROLLER.tokenId(_tokenAddress) == 0) revert Vault_TokenNotRegistered();

    IBaseRewardPool _rewardsContract = rewardsContracts[_tokenAddress];
    if (address(_rewardsContract) == address(0)) revert Vault_TokenNotStaked();

    IAMPHClaimer _amphClaimer = CONTROLLER.claimerContract();

    uint256 _rewardsAmount = (_claimExtraRewards) ? _rewardsContract.extraRewardsLength() : 0;

    uint256 _crvBalanceDiff = CRV.balanceOf(address(this)) - balances[address(CRV)];
    uint256 _crvEarned = _rewardsContract.earned(address(this));
    uint256 _crvReward = _crvEarned + _crvBalanceDiff;

    uint256 _cvxBalanceDiff = CVX.balanceOf(address(this)) - balances[address(CVX)];
    uint256 _cvxReward = _calculateExpectedCVXReward(_crvEarned, _rewardsContract.operator()) + _cvxBalanceDiff;

    // +3 for CRV, CVX and AMPH
    _rewards = new Reward[](_rewardsAmount+3);
    _rewards[0] = Reward(CRV, _crvReward);
    _rewards[1] = Reward(CVX, _cvxReward);

    uint256 _i;
    for (_i; _i < _rewardsAmount;) {
      IVirtualBalanceRewardPool _virtualReward = _rewardsContract.extraRewards(_i);
      IERC20 _rewardToken = _virtualReward.rewardToken();

      uint256 _rewardTokenBalanceDiff = _rewardToken.balanceOf(address(this)) - balances[address(_rewardToken)];
      uint256 _earnedReward = _virtualReward.earned(address(this)) + _rewardTokenBalanceDiff;
      _rewards[_i + 2] = Reward(_rewardToken, _earnedReward);

      unchecked {
        ++_i;
      }
    }

    uint256 _takenCVX;
    uint256 _takenCRV;
    uint256 _claimableAmph;
    // if claimer is not set, nothing will happen (and variables are already in zero)
    if (address(_amphClaimer) != address(0)) {
      // claimer is set, proceed
      (_takenCVX, _takenCRV, _claimableAmph) = _amphClaimer.claimable(address(this), this.id(), _cvxReward, _crvReward);
      _rewards[_i + 2] = Reward(_amphClaimer.AMPH(), _claimableAmph);
    }

    _rewards[0].amount = _crvReward - _takenCRV;
    if (_cvxReward > 0) _rewards[1].amount = _cvxReward - _takenCVX;
  }

  /// @notice Function used by the VaultController to transfer tokens
  /// @dev Callable by the VaultController only
  /// @param _token The token to transfer
  /// @param _to The address to send the tokens to
  /// @param _amount The amount of tokens to move
  function controllerTransfer(address _token, address _to, uint256 _amount) external override onlyVaultController {
    balances[_token] -= _amount;
    IERC20(_token).safeTransfer(_to, _amount);
  }

  /// @notice Function used by the VaultController to withdraw from convex
  /// @dev Callable by the VaultController only
  /// @param _tokenAddress The token address to withdraw from the rewards contract
  /// @param _amount The amount of tokens to withdraw
  function controllerWithdrawAndUnwrap(address _tokenAddress, uint256 _amount) external override onlyVaultController {
    _withdrawAndUnwrap(rewardsContracts[_tokenAddress], _amount);
  }

  /// @notice Function used by the VaultController to reduce a vault's liability
  /// @dev Callable by the VaultController only
  /// @param _increase True to increase, false to decrease
  /// @param _baseAmount The change in base liability
  /// @return _newLiability The new liability
  function modifyLiability(
    bool _increase,
    uint256 _baseAmount
  ) external override onlyVaultController returns (uint256 _newLiability) {
    if (_increase) {
      baseLiability += _baseAmount;
    } else {
      // require statement only valid for repayment
      if (baseLiability < _baseAmount) revert Vault_RepayTooMuch();
      baseLiability -= _baseAmount;
    }
    _newLiability = baseLiability;
  }

  /// @dev Internal function for depositing and staking on convex
  function _depositAndStakeOnConvex(address _token, IBooster _booster, uint256 _amount, uint256 _poolId) internal {
    IERC20(_token).safeIncreaseAllowance(address(_booster), _amount);
    if (!_booster.deposit(_poolId, _amount, true)) revert Vault_DepositAndStakeOnConvexFailed();
  }

  /// @dev Internal function for withdrawing and unstaking from convex
  function _withdrawAndUnwrap(IBaseRewardPool _rewardPool, uint256 _amount) internal {
    if (!_rewardPool.withdrawAndUnwrap(_amount, false)) revert Vault_WithdrawAndUnstakeOnConvexFailed();
  }

  /// @notice Used to calculate the expected CVX reward for a given CRV amount
  /// @dev This is copied from the CVX mint function
  /// @param _crv The amount of CRV to calculate the CVX reward for
  /// @param _operator The operator of the rewards contract
  /// @return _cvxAmount The amount of CVX to get
  function _calculateExpectedCVXReward(uint256 _crv, address _operator) internal view returns (uint256 _cvxAmount) {
    // In case the operator is changed from CVX, the rewards are 0
    if (CVX.operator() != _operator) return 0;

    uint256 _supply = CVX.totalSupply();
    uint256 _totalCliffs = CVX.totalCliffs();

    //use current supply to gauge cliff
    //this will cause a bit of overflow into the next cliff range
    //but should be within reasonable levels.
    //requires a max supply check though
    uint256 _cliff = _supply / CVX.reductionPerCliff();
    //mint if below total cliffs
    if (_cliff < _totalCliffs) {
      //for reduction% take inverse of current cliff
      uint256 _reduction = _totalCliffs - _cliff;
      //reduce
      _cvxAmount = (_crv * _reduction) / _totalCliffs;

      //supply cap check
      uint256 _amtTillMax = CVX.maxSupply() - _supply;
      if (_cvxAmount > _amtTillMax) _cvxAmount = _amtTillMax;
    }
  }

  /// @notice Used to claim an extra reward in a base reward contract
  /// @param _rewardsContract The base reward contract
  /// @param _index The index of the extra reward to claim
  function _claimExtraReward(IBaseRewardPool _rewardsContract, uint256 _index) internal {
    IVirtualBalanceRewardPool _virtualReward = _rewardsContract.extraRewards(_index);
    IERC20 _rewardToken = _virtualReward.rewardToken();
    _virtualReward.getReward();
    uint256 _earnedReward = _rewardToken.balanceOf(address(this)) - balances[address(_rewardToken)];
    if (_earnedReward != 0) {
      _rewardToken.safeTransfer(_msgSender(), _earnedReward);
      emit ClaimedReward(address(_rewardToken), _earnedReward);
    }
  }

  /// @notice Changes a percentage of the total CRV and CVX to AMPH and sends everything to the caller
  /// @param _totalCrvReward The total CRV reward claimed
  /// @param _totalCvxReward The total CVX reward claimed
  function _swapRewardsForAmphAndSendToMinter(uint256 _totalCrvReward, uint256 _totalCvxReward) internal {
    if (_totalCrvReward > 0) {
      IAMPHClaimer _amphClaimer = CONTROLLER.claimerContract();
      if (address(_amphClaimer) != address(0)) {
        // Approve amounts for it to be taken
        (uint256 _takenCVX, uint256 _takenCRV, uint256 _claimableAmph) =
          _amphClaimer.claimable(address(this), this.id(), _totalCvxReward, _totalCrvReward);
        if (_claimableAmph != 0) {
          CRV.safeIncreaseAllowance(address(_amphClaimer), _takenCRV);
          IERC20(CVX).safeIncreaseAllowance(address(_amphClaimer), _takenCVX);

          // Claim AMPH tokens depending on how much CRV and CVX was claimed
          _amphClaimer.claimAmph(this.id(), _totalCvxReward, _totalCrvReward, _msgSender());

          _totalCvxReward -= _takenCVX;
          _totalCrvReward -= _takenCRV;
        }
      }

      if (_totalCvxReward > 0) IERC20(CVX).safeTransfer(_msgSender(), _totalCvxReward);
      if (_totalCrvReward > 0) CRV.safeTransfer(_msgSender(), _totalCrvReward);

      emit ClaimedReward(address(CRV), _totalCrvReward);
      emit ClaimedReward(address(CVX), _totalCvxReward);
    }
  }
}
