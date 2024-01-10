// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./AccessControl.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

/**
 * @title ManagedPool
 * @dev The DAOracle Network relies on decentralized risk pools. This is a
 * simple implementation of a staking pool which wraps a single arbitrary token
 * and provides a mechanism for recouping losses incurred by the deployer of
 * the underlying. Pool ownership is represented as ERC20 tokens that can be
 * freely used as the holder sees fit. Holders of pool shares may make claims
 * proportional to their stake on the underlying token balance of the pool. Any
 * rewards or penalties applied to the pool will thus impact all holders.
 */
abstract contract ManagedPool is AccessControl, ERC20 {
  using SafeERC20 for IERC20;

  bytes32 public immutable MANAGER = keccak256("MANAGER");

  /// @dev The token being staked in this pool
  IERC20 public stakedToken;

  /**
   * @dev The mint/burn fee config. Fees must be scaled by 10**18 (1e18 = 100%)
   * Formula: fee = tokens * mintOrBurnFee / 1e18
   * Example: 1000 DAI deposit * (0.1 * 10**18) / 10**18 = 100 DAI fee
   */
  uint256 public mintFee;
  uint256 public burnFee;
  address public feePayee;

  event Created(address pool, IERC20 underlying);
  event FeesChanged(uint256 mintFee, uint256 burnFee, address payee);
  event Fee(uint256 feeAmount);

  event Deposit(
    address indexed depositor,
    uint256 underlyingAmount,
    uint256 tokensMinted
  );

  event Payout(
    address indexed beneficiary,
    uint256 underlyingAmount,
    uint256 tokensBurned
  );

  /**
   * @dev Mint pool shares for a given stake amount
   * @param _stakeAmount The amount of underlying to stake
   * @return shares The number of pool shares minted
   */
  function mint(uint256 _stakeAmount) external returns (uint256 shares) {
    require(
      stakedToken.allowance(msg.sender, address(this)) >= _stakeAmount,
      "mint: insufficient allowance"
    );

    // Grab the pre-deposit balance and shares for comparison
    uint256 oldBalance = stakedToken.balanceOf(address(this));
    uint256 oldShares = totalSupply();

    // Pull user's tokens into the pool
    stakedToken.safeTransferFrom(msg.sender, address(this), _stakeAmount);

    // Calculate the fee for minting
    uint256 fee = (_stakeAmount * mintFee) / 1e18;
    if (fee != 0) {
      stakedToken.safeTransfer(feePayee, fee);
      _stakeAmount -= fee;
      emit Fee(fee);
    }

    // Calculate the pool shares for the new deposit
    if (oldShares != 0) {
      // shares = stake * oldShares / oldBalance
      shares = (_stakeAmount * oldShares) / oldBalance;
    } else {
      // if no shares exist, just assign 1,000 shares (it's arbitrary)
      shares = 10**3;
    }

    // Transfer shares to caller
    _mint(msg.sender, shares);
    emit Deposit(msg.sender, _stakeAmount, shares);
  }

  /**
   * @dev Burn some pool shares and claim the underlying tokens
   * @param _shareAmount The number of shares to burn
   * @return tokens The number of underlying tokens returned
   */
  function burn(uint256 _shareAmount) external returns (uint256 tokens) {
    require(balanceOf(msg.sender) >= _shareAmount, "burn: insufficient shares");

    // TODO: Extract
    // Calculate the user's share of the underlying balance
    uint256 balance = stakedToken.balanceOf(address(this));
    tokens = (_shareAmount * balance) / totalSupply();

    // Burn the caller's shares before anything else
    _burn(msg.sender, _shareAmount);

    // Calculate the fee for burning
    uint256 fee = getBurnFee(tokens);
    if (fee != 0) {
      tokens -= fee;
      stakedToken.safeTransfer(feePayee, fee);
      emit Fee(fee);
    }

    // Transfer underlying tokens back to caller
    stakedToken.safeTransfer(msg.sender, tokens);
    emit Payout(msg.sender, tokens, _shareAmount);
  }

  /**
   * @dev Calculate the minting fee
   * @param _amount The number of tokens being staked
   * @return fee The calculated fee value
   */
  function getMintFee(uint256 _amount) public view returns (uint256 fee) {
    fee = (_amount * mintFee) / 1e18;
  }

  /**
   * @dev Calculate the burning fee
   * @param _amount The number of pool tokens being burned
   * @return fee The calculated fee value
   */
  function getBurnFee(uint256 _amount) public view returns (uint256 fee) {
    fee = (_amount * burnFee) / 1e18;
  }

  /**
   * @dev Update fee configuration
   * @param _mintFee The new minting fee
   * @param _burnFee The new burning fee
   * @param _feePayee The new payee
   */
  function setFees(
    uint256 _mintFee,
    uint256 _burnFee,
    address _feePayee
  ) external onlyRole(MANAGER) {
    mintFee = _mintFee;
    burnFee = _burnFee;
    feePayee = _feePayee;
    emit FeesChanged(_mintFee, _burnFee, _feePayee);
  }
}
