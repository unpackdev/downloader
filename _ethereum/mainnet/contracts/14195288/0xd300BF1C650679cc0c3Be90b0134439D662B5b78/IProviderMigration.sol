pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./Provider.sol";

interface IProviderMigration {
  /// @notice To set the address for teh Urus V2 contract
  /// @param urusV2Address  The updated address
  event SetUrusV2Address(address urusV2Address);

  /// @notice To set the address for the Provider V2 contract
  /// @param providerV2Address  The updated address
  event SetProviderV2Address(address providerV2Address);

  /// @notice The event emitted when tokens are added into the migration contract
  /// @param user  The user who added tokens
  /// @param amount  The amount of tokens
  event TokensAdded(address indexed user, uint256 amount);

  /// @notice The emitted event when the new LP tokens are created and the admin calls the distributeTokens function with the given array of arguments.
  /// @notice Emitting the array of arguments instead of each one to reduce gas, this will reduce our ability to index and filter events but an external script will resolve this.
  /// @param migrateArgs  The user who added tokens
  event TokensDistributed(Provider.MigrateArgs[] migrateArgs);

  /// @notice Emitted event when the LP tokens held by the contract are burnt by Uniswap and the underlying collateral is returned
  event ClosePositions();

  /// @notice Emitted event when the new LP position is created
  event NewPositionCreated(address newPairAddress, uint256 newTokenTotal);

  /// @notice For setting the address for the URUS V2 token
  /// @param _UrusToken_V2  The Urus V2 token
  function setUrusV2Token(IERC20 _UrusToken_V2) external;

  /// @notice For setting the address for the Provider V2 contract
  /// @param _ProviderContract  The Provider V2 contract
  function setProviderV2(Provider _ProviderContract) external;

  /// @notice For returning all the user's who have added tokens to the migration contract
  /// @return Users  All the users
  function getUsers() external view returns (address[] memory);

  /// @notice Allows a user to add tokens into the migration contract
  /// @param _amount  The amount to add to the contract
  /// @return Status  If the operation was successful
  function addTokens(uint256 _amount) external returns (bool);

  /// @notice Allows the deployer to withdraw all ETH from the contract
  function withdrawETH() external;

  /// @notice Allows the deployer to withdraw the total of a specific token that is held by the contract
  /// @param Token  The token to withdraw amounts for
  function withdraw(IERC20 Token) external;

  /// @notice This is to be called after the LP positions held by the contract have been closed. This will take the same amount of ETH returned from the original position and with the new URUS V2 tokens it will create a new position of the same value.
  function createNewPosition() external;

  /// @notice For returning the percentage of the total amount that is claimable by the user
  /// @param user  The user to return the percentage for
  function returnUsersLPShare(address user)
    external
    view
    returns (uint256 share);

  /// @notice For returning the amount claimable by the user in the new URUS V2 position
  /// @param user  The user to return the amount for
  function returnUsersLPTokenAmount(address user)
    external
    view
    returns (uint256 amount);

  /// @notice This is to be called once the new position has been created and it needs to be distributed amount users. This function also calls for a bonusMultiplier to be passed in for each user. This is the additional bonus the user will receive once they're migrated to Provider V2
  /// @param migrateArgs  All the migration arguments for the users
  function distributeTokens(Provider.MigrateArgs[] memory migrateArgs) external;

  /// @notice This is to be called when enough liquidity is locked up in the contract, all the LP tokens held by the contract will be burnt through the Uniswap remove liquidity function
  /// @param status Whether the operation was successful
  function closePositions() external returns (bool status);
}
