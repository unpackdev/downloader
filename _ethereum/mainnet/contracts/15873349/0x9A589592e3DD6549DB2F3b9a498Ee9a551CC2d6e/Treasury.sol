// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ITreasury.sol";

interface IERC20Mintable is IERC20 {
  function mint(address to, uint256 amount) external;
}

/// @title Treasury
/// @author Bluejay Core Team
/// @notice The Treasury controls the minting of BLU tokens as well as withdrawal of assets.
/// Allowance to mint BLU tokens and withdraw other tokens are controlled by accounts with manager role.
/// @dev This contract can be upgraded to support additional features.
contract Treasury is
  Initializable,
  AccessControlUpgradeable,
  UUPSUpgradeable,
  ITreasury
{
  using SafeERC20 for IERC20;

  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  /// @notice Contract address of the BLU Token
  IERC20Mintable public BLU;

  /// @notice Mapping of address to their BLU minting limit
  mapping(address => uint256) public mintLimit;

  /// @notice Mapping of address to their BLU minted
  mapping(address => uint256) public mintedAmount;

  /// @notice Mapping of assets and their spender address to their asset withdrawal limit
  /// @dev Access using withdrawalLimit[asset][spender]
  mapping(address => mapping(address => uint256)) public withdrawalLimit;

  /// @notice Mapping of assets and their spender address to their asset withdrawn total
  /// @dev Access using withdrawnAmount[asset][spender]
  mapping(address => mapping(address => uint256)) public withdrawnAmount;

  /// @notice Initializer for the contract
  /// @param _BLU Address of the BLU token
  function initialize(address _BLU) public initializer {
    __AccessControl_init();
    __UUPSUpgradeable_init();

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    BLU = IERC20Mintable(_BLU);
  }

  /// @notice Mint BLU tokens to an address. Minter must have sufficient mint limit.
  /// @param to Address to receive the BLU token
  /// @param amount Amount of BLU tokens to mint, in WAD
  function mint(address to, uint256 amount) public override {
    mintedAmount[msg.sender] += amount;
    require(
      mintedAmount[msg.sender] <= mintLimit[msg.sender],
      "Mint limit exceeded"
    );
    BLU.mint(to, amount);
    emit Mint(to, amount);
  }

  /// @notice Withdraw any assets from the Treasury. Withdrawer must have sufficient withdrawal limit.
  /// @param token Address of asset to withdraw
  /// @param to Address to receive the token
  /// @param amount Amount of assets to withdraw
  function withdraw(
    address token,
    address to,
    uint256 amount
  ) public override {
    withdrawnAmount[token][msg.sender] += amount;
    require(
      withdrawnAmount[token][msg.sender] <= withdrawalLimit[token][msg.sender],
      "Withdrawal limit exceeded"
    );
    IERC20(token).safeTransfer(to, amount);
    emit Withdraw(token, to, amount);
  }

  /// @notice Increase the BLU token mint limit for an address. Caller must have manager role.
  /// @param minter Address to increase the mint limit for
  /// @param amount Amount of BLU tokens to increase the mint limit by
  function increaseMintLimit(address minter, uint256 amount)
    public
    override
    onlyRole(MANAGER_ROLE)
  {
    mintLimit[minter] += amount;
    emit MintLimitUpdate(minter, mintLimit[minter]);
  }

  /// @notice Decrease the BLU token mint limit for an address. Caller must have manager role.
  /// @param minter Address to decrease the mint limit for
  /// @param amount Amount of BLU tokens to decrease the mint limit by
  function decreaseMintLimit(address minter, uint256 amount)
    public
    override
    onlyRole(MANAGER_ROLE)
  {
    mintLimit[minter] -= amount;
    if (mintLimit[minter] < mintedAmount[minter]) {
      mintLimit[minter] = mintedAmount[minter];
    }
    emit MintLimitUpdate(minter, mintLimit[minter]);
  }

  /// @notice Increase the asset withdrawal limit for an address. Caller must have manager role.
  /// @param asset Address of the asset
  /// @param spender Address to increase the withdrawal limit for
  /// @param amount Amount of assets to increase the withdrawal limit by
  function increaseWithdrawalLimit(
    address asset,
    address spender,
    uint256 amount
  ) public override onlyRole(MANAGER_ROLE) {
    withdrawalLimit[asset][spender] += amount;
    emit WithdrawLimitUpdate(asset, spender, withdrawalLimit[asset][spender]);
  }

  /// @notice Decrease the asset withdrawal limit for an address. Caller must have manager role.
  /// @param asset Address of the asset
  /// @param spender Address to decrease the withdrawal limit for
  /// @param amount Amount of assets to decrease the withdrawal limit by
  function decreaseWithdrawalLimit(
    address asset,
    address spender,
    uint256 amount
  ) public override onlyRole(MANAGER_ROLE) {
    withdrawalLimit[asset][spender] -= amount;
    if (withdrawalLimit[asset][spender] < withdrawnAmount[asset][spender]) {
      withdrawalLimit[asset][spender] = withdrawnAmount[asset][spender];
    }
    emit WithdrawLimitUpdate(asset, spender, withdrawalLimit[asset][spender]);
  }

  /// @notice Internal function to check that upgrader of contract has UPGRADER_ROLE
  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyRole(UPGRADER_ROLE)
  {}
}
