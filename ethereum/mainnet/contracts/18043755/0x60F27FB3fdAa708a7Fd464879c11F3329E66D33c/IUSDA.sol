// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IRoles.sol";

import "./IERC20Metadata.sol";

/// @title USDA Interface
/// @notice extends IERC20Metadata
interface IUSDA is IERC20Metadata, IRoles {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

  // @notice Emitted when a deposit is made
  // @param _from The address which made the deposit
  // @param _value The value deposited

  event Deposit(address indexed _from, uint256 _value);

  // @notice Emitted when a withdraw is made
  // @param _from The address which made the withdraw
  // @param _value The value withdrawn

  event Withdraw(address indexed _from, uint256 _value);

  // @notice Emitted when a mint is made
  // @param _to The address which made the mint
  // @param _value The value minted

  event Mint(address _to, uint256 _value);

  // @notice Emitted when a burn is made
  // @param _from The address which made the burn
  // @param _value The value burned

  event Burn(address _from, uint256 _value);

  // @notice Emitted when a donation is made
  // @param _from The address which made the donation
  // @param _value The value of the donation
  // @param _totalSupply The new total supply

  event Donation(address indexed _from, uint256 _value, uint256 _totalSupply);

  // @notice Emitted when the owner recovers dust
  // @param _receiver The address which made the recover
  // @param _amount The value recovered

  event RecoveredDust(address indexed _receiver, uint256 _amount);

  // @notice Emitted when the owner sets a pauser
  // @param _pauser The new pauser address

  event PauserSet(address indexed _pauser);

  // @notice Emitted when a sUSD transfer is made from the vaultController
  // @param _target The receiver of the transfer
  // @param _susdAmount The amount sent

  event VaultControllerTransfer(address _target, uint256 _susdAmount);

  // @notice Emitted when the owner adds a new vaultController giving special roles
  // @param _vaultController The address of the vault controller

  event VaultControllerAdded(address indexed _vaultController);

  // @notice Emitted when the owner removes a vaultController removing special roles
  // @param _vaultController The address of the vault controller

  event VaultControllerRemoved(address indexed _vaultController);

  // @notice Emitted when the owner removes a vaultController from the list
  // @param _vaultController The address of the vault controller

  event VaultControllerRemovedFromList(address indexed _vaultController);

  /*///////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

  /// @notice Thrown when trying to deposit zero amount
  error USDA_ZeroAmount();

  /// @notice Thrown when trying to withdraw more than the balance
  error USDA_InsufficientFunds();

  /// @notice Thrown when trying to withdraw all but the reserve amount is 0
  error USDA_EmptyReserve();

  /// @notice Thrown when _msgSender is not the pauser of the contract
  error USDA_OnlyPauser();

  /// @notice Thrown when vault controller is trying to burn more than the balance
  error USDA_NotEnoughBalance();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

  /// @notice Returns sUSD contract (reserve)
  /// @return _sUSD The sUSD contract
  function sUSD() external view returns (IERC20 _sUSD);

  /// @notice Returns the reserve ratio
  /// @return _reserveRatio The reserve ratio
  function reserveRatio() external view returns (uint192 _reserveRatio);

  /// @notice Returns the reserve amount
  /// @return _reserveAmount The reserve amount
  function reserveAmount() external view returns (uint256 _reserveAmount);

  /// @notice The address of the pauser
  function pauser() external view returns (address _pauser);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Deposit sUSD to mint USDA
  /// @dev Caller should obtain 1 USDA for each sUSD
  /// the calculations for deposit mimic the calculations done by mint in the ampleforth contract, simply with the susd transfer
  /// 'fragments' are the units that we see, so 1000 fragments == 1000 USDA
  /// 'gons' are the internal accounting unit, used to keep scale.
  /// We use the variable _gonsPerFragment in order to convert between the two
  /// try dimensional analysis when doing the math in order to verify units are correct
  /// @param _susdAmount The amount of sUSD to deposit
  function deposit(uint256 _susdAmount) external;

  /// @notice Deposits sUSD to mint USDA and transfer to a different address
  /// @param _susdAmount The amount of sUSD to deposit
  /// @param _target The address to receive the USDA tokens
  function depositTo(uint256 _susdAmount, address _target) external;

  /// @notice Withdraw sUSD by burning USDA
  /// @dev The caller should obtain 1 sUSD for every 1 USDA
  /// @param _susdAmount The amount of sUSD to withdraw
  function withdraw(uint256 _susdAmount) external;

  /// @notice Withdraw sUSD to a specific address by burning USDA from the caller
  /// @dev The _target address should obtain 1 sUSD for every 1 USDA burned from the caller
  /// @param _susdAmount amount of sUSD to withdraw
  /// @param _target address to receive the sUSD
  function withdrawTo(uint256 _susdAmount, address _target) external;

  /// @notice Withdraw sUSD by burning USDA
  /// @dev The caller should obtain 1 sUSD for every 1 USDA
  /// @dev This function is effectively just withdraw, but we calculate the amount for the sender
  /// @param _susdWithdrawn The amount os sUSD withdrawn
  function withdrawAll() external returns (uint256 _susdWithdrawn);

  /// @notice Withdraw sUSD by burning USDA
  /// @dev This function is effectively just withdraw, but we calculate the amount for the _target
  /// @param _target should obtain 1 sUSD for every 1 USDA burned from caller
  /// @param _susdWithdrawn The amount os sUSD withdrawn
  function withdrawAllTo(address _target) external returns (uint256 _susdWithdrawn);

  /// @notice Donates susd to the protocol reserve
  /// @param _susdAmount The amount of sUSD to donate
  function donate(uint256 _susdAmount) external;

  /// @notice Recovers accidentally sent sUSD to this contract
  /// @param _to The receiver of the dust
  function recoverDust(address _to) external;

  /// @notice Sets the pauser for both USDA and VaultController
  /// @dev The pauser is a separate role from the owner
  function setPauser(address _pauser) external;

  /// @notice Pause contract
  /// @dev Can only be called by the pauser
  function pause() external;

  /// @notice Unpause contract, pauser only
  /// @dev Can only be called by the pauser
  function unpause() external;

  /// @notice Admin function to mint USDA
  /// @param _susdAmount The amount of USDA to mint, denominated in sUSD
  function mint(uint256 _susdAmount) external;

  /// @notice Admin function to burn USDA
  /// @param _susdAmount The amount of USDA to burn, denominated in sUSD
  function burn(uint256 _susdAmount) external;

  /// @notice Function for the vaultController to burn
  /// @param _target The address to burn the USDA from
  /// @param _amount The amount of USDA to burn
  function vaultControllerBurn(address _target, uint256 _amount) external;

  /// @notice Function for the vaultController to mint
  /// @param _target The address to mint the USDA to
  /// @param _amount The amount of USDA to mint
  function vaultControllerMint(address _target, uint256 _amount) external;

  /// @notice Allows VaultController to send sUSD from the reserve
  /// @param _target The address to receive the sUSD from reserve
  /// @param _susdAmount The amount of sUSD to send
  function vaultControllerTransfer(address _target, uint256 _susdAmount) external;

  /// @notice Function for the vaultController to scale all USDA balances
  /// @param _amount The amount of USDA (e18) to donate
  function vaultControllerDonate(uint256 _amount) external;

  /// @notice Adds a new vault controller
  /// @param _vaultController The new vault controller to add
  function addVaultController(address _vaultController) external;

  /// @notice Removes a vault controller
  /// @param _vaultController The vault controller to remove
  function removeVaultController(address _vaultController) external;

  /// @notice Removes a vault controller from the loop list
  /// @param _vaultController The vault controller to remove
  function removeVaultControllerFromList(address _vaultController) external;
}
