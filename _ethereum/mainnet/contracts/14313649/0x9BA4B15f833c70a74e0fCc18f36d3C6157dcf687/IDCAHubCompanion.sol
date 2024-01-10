// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import "./IDCAHub.sol";
import "./IDCAPermissionManager.sol";
import "./IDCAHubSwapCallee.sol";
import "./IWrappedProtocolToken.sol";
import "./ICollectableDust.sol";
import "./IGovernable.sol";
import "./ISharedTypes.sol";

interface IDCAHubCompanionParameters is IGovernable {
  /// @notice Thrown when the given parameters are invalid
  error InvalidTokenApprovalParams();

  /// @notice Emitted when tokens with approval issues are set
  /// @param addresses The addresses of the tokens
  /// @param hasIssue Whether they have issues or not
  event TokenWithApprovalIssuesSet(address[] addresses, bool[] hasIssue);

  /// @notice Returns the DCA Hub's address
  /// @dev This value cannot be modified
  /// @return The DCA Hub contract
  function hub() external view returns (IDCAHub);

  /// @notice Returns the address of the wrapped token
  /// @dev This value cannot be modified
  /// @return The wToken contract
  function wToken() external view returns (IWrappedProtocolToken);

  /// @notice Returns the address used to represent the protocol token (f.e. ETH/MATIC)
  /// @dev This value cannot be modified
  /// @return The protocol token
  // solhint-disable-next-line func-name-mixedcase
  function PROTOCOL_TOKEN() external view returns (address);

  /// @notice Returns the permission manager contract
  /// @return The contract itself
  function permissionManager() external view returns (IDCAPermissionManager);

  /// @notice Returns whether the given address has issues with approvals, like USDT
  /// @param _tokenAddress The address of the token to check
  /// @return Whether it has issues or not
  function tokenHasApprovalIssue(address _tokenAddress) external view returns (bool);

  /// @notice Sets whether specific addresses have issues with approvals, like USDT
  /// @dev Will revert with `InvalidTokenApprovalParams` if the length of the given arrays differ
  /// @param _addresses The addresses of the tokens
  /// @param _hasIssue Wether they have issues or not
  function setTokensWithApprovalIssues(address[] calldata _addresses, bool[] calldata _hasIssue) external;
}

interface IDCAHubCompanionSwapHandler is IDCAHubSwapCallee {
  /// @notice Thrown when the reward is less that the specified minimum
  error RewardNotEnough();

  /// @notice Thrown when the amount to provide is more than the specified maximum
  error ToProvideIsTooMuch();

  /// @notice Thrown when callback is not called by the hub
  error CallbackNotCalledByHub();

  /// @notice Thrown when swap was not initiated by the companion
  error SwapNotInitiatedByCompanion();

  /// @notice Thrown when the callback is executed with an unexpected swap plan
  error UnexpectedSwapPlan();

  /// @notice Thrown when a swap is executed with a DEX that is not supported
  error UnsupportedDex();

  /// @notice Thrown when a call to the given DEX fails
  error CallToDexFailed();

  /// @notice Returns whether the given DEX can be used for swaps for not
  /// @param _dex The address of the DEX to check
  /// @return Whether the given DEX can be used for swaps for not
  function isDexSupported(address _dex) external view returns (bool);

  /// @notice Defines whether a specific DEX will be supported for swaps
  /// @dev Will revert with `ZeroAddress` if the zero address if given
  /// @param _dex The address of the DEX
  /// @param _support Whether the Companion should support swaps with the given DEX
  function defineDexSupport(address _dex, bool _support) external;

  /// @notice Executes a swap for the caller, by sending them the reward, and taking from them the needed tokens
  /// @dev Will revert:
  /// With RewardNotEnough if the minimum output is not met
  /// With ToProvideIsTooMuch if the hub swap requires more than the given maximum input
  /// @param _tokens The tokens involved in the swap
  /// @param _pairsToSwap The pairs to swap
  /// @param _minimumOutput The minimum amount of tokens to receive as part of the swap
  /// @param _maximumInput The maximum amount of tokens to provide as part of the swap
  /// @param _recipient Address that will receive all the tokens from the swap
  /// @param _deadline Deadline when the swap becomes invalid
  /// @return The information about the executed swap
  function swapForCaller(
    address[] calldata _tokens,
    IDCAHub.PairIndexes[] calldata _pairsToSwap,
    uint256[] calldata _minimumOutput,
    uint256[] calldata _maximumInput,
    address _recipient,
    uint256 _deadline
  ) external payable returns (IDCAHub.SwapInfo memory);

  /// @notice Executes a swap with the given DEX, and sends all unspent tokens to the given recipient
  /// @param _dex The DEX that will be used in the swap
  /// @param _tokens The tokens involved in the swap
  /// @param _pairsToSwap The pairs to swap
  /// @param _callsToDex The bytes to send to the DEX to execute swaps
  /// @param _doDexSwapsIncludeTransferToHub Some DEXes support swap & transfer, which would be cheaper in terms of gas
  /// If this feature is used, then the flag should be true
  /// @param _leftoverRecipient Address that will receive all unspent tokens
  /// @param _deadline Deadline when the swap becomes invalid
  /// @return The information about the executed swap
  function swapWithDex(
    address _dex,
    address[] calldata _tokens,
    IDCAHub.PairIndexes[] calldata _pairsToSwap,
    bytes[] calldata _callsToDex,
    bool _doDexSwapsIncludeTransferToHub,
    address _leftoverRecipient,
    uint256 _deadline
  ) external returns (IDCAHub.SwapInfo memory);

  /// @notice Executes a swap with the given DEX and sends all `reward` unspent tokens to the given recipient.
  /// All positive slippage for tokens that need to be returned to the hub is also sent to the hub
  /// @param _dex The DEX that will be used in the swap
  /// @param _tokens The tokens involved in the swap
  /// @param _pairsToSwap The pairs to swap
  /// @param _callsToDex The bytes to send to the DEX to execute swaps
  /// @param _doDexSwapsIncludeTransferToHub Some DEXes support swap & transfer, which would be cheaper in terms of gas
  /// If this feature is used, then the flag should be true
  /// @param _leftoverRecipient Address that will receive `reward` unspent tokens
  /// @param _deadline Deadline when the swap becomes invalid
  /// @return The information about the executed swap
  function swapWithDexAndShareLeftoverWithHub(
    address _dex,
    address[] calldata _tokens,
    IDCAHub.PairIndexes[] calldata _pairsToSwap,
    bytes[] calldata _callsToDex,
    bool _doDexSwapsIncludeTransferToHub,
    address _leftoverRecipient,
    uint256 _deadline
  ) external returns (IDCAHub.SwapInfo memory);
}

interface IDCAHubCompanionWTokenPositionHandler {
  /// @notice Thrown when the user tries to make a deposit where neither or both of the tokens are the protocol token
  error InvalidTokens();

  /// @notice Creates a new position by converting the protocol's base token to its wrapped version
  /// @dev This function will also give all permissions to this contract, so that it can then withdraw/terminate and
  /// convert back to protocol's token. Will revert with InvalidTokens unless only one of the tokens is the protocol token
  /// @param _from The address of the "from" token
  /// @param _to The address of the "to" token
  /// @param _amount How many "from" tokens will be swapped in total
  /// @param _amountOfSwaps How many swaps to execute for this position
  /// @param _swapInterval How frequently the position's swaps should be executed
  /// @param _owner The address of the owner of the position being created
  /// @param _permissions Extra permissions to add to the position. Can be empty
  /// @param _miscellaneous Bytes that will be emitted, and associated with the position. If empty, no event will be emitted
  /// @return The id of the created position
  function depositUsingProtocolToken(
    address _from,
    address _to,
    uint256 _amount,
    uint32 _amountOfSwaps,
    uint32 _swapInterval,
    address _owner,
    IDCAPermissionManager.PermissionSet[] calldata _permissions,
    bytes calldata _miscellaneous
  ) external payable returns (uint256);

  /// @notice Withdraws all swapped tokens from a position to a recipient
  /// @param _positionId The position's id
  /// @param _recipient The address to withdraw swapped tokens to
  /// @return _swapped How much was withdrawn
  function withdrawSwappedUsingProtocolToken(uint256 _positionId, address payable _recipient) external payable returns (uint256 _swapped);

  /// @notice Withdraws all swapped tokens from multiple positions
  /// @param _positionIds A list positions whose 'to' token is the wToken
  /// @param _recipient The address to withdraw swapped tokens to
  /// @return _swapped How much was withdrawn in total
  function withdrawSwappedManyUsingProtocolToken(uint256[] calldata _positionIds, address payable _recipient)
    external
    payable
    returns (uint256 _swapped);

  /// @notice Takes the unswapped balance, adds the new deposited funds and modifies the position so that
  /// it is executed in _newSwaps swaps
  /// @param _positionId The position's id
  /// @param _amount Amount of funds to add to the position
  /// @param _newSwaps The new amount of swaps
  function increasePositionUsingProtocolToken(
    uint256 _positionId,
    uint256 _amount,
    uint32 _newSwaps
  ) external payable;

  /// @notice Withdraws the specified amount from the unswapped balance and modifies the position so that
  /// it is executed in _newSwaps swaps
  /// @param _positionId The position's id
  /// @param _amount Amount of funds to withdraw from the position
  /// @param _newSwaps The new amount of swaps
  /// @param _recipient The address to send tokens to
  function reducePositionUsingProtocolToken(
    uint256 _positionId,
    uint256 _amount,
    uint32 _newSwaps,
    address payable _recipient
  ) external payable;

  /// @notice Terminates the position and sends all unswapped and swapped balance to the specified recipients
  /// @param _positionId The position's id
  /// @param _recipientUnswapped The address to withdraw unswapped tokens to
  /// @param _recipientSwapped The address to withdraw swapped tokens to
  /// @return _unswapped The unswapped balance sent to `_recipientUnswapped`
  /// @return _swapped The swapped balance sent to `_recipientSwapped`
  function terminateUsingProtocolTokenAsFrom(
    uint256 _positionId,
    address payable _recipientUnswapped,
    address _recipientSwapped
  ) external payable returns (uint256 _unswapped, uint256 _swapped);

  /// @notice Terminates the position and sends all unswapped and swapped balance to the specified recipients
  /// @param _positionId The position's id
  /// @param _recipientUnswapped The address to withdraw unswapped tokens to
  /// @param _recipientSwapped The address to withdraw swapped tokens to
  /// @return _unswapped The unswapped balance sent to `_recipientUnswapped`
  /// @return _swapped The swapped balance sent to `_recipientSwapped`
  function terminateUsingProtocolTokenAsTo(
    uint256 _positionId,
    address _recipientUnswapped,
    address payable _recipientSwapped
  ) external payable returns (uint256 _unswapped, uint256 _swapped);

  /// @notice Increases the allowance of wToken to the max, for the DCAHub
  /// @dev Anyone can call this method
  function approveWTokenForHub() external;
}

interface IDCAHubCompanionDustHandler is ICollectableDust {}

interface IDCAHubCompanionLibrariesHandler {
  /// @notice Takes a list of pairs and returns how it would look like to execute a swap for all of them
  /// @dev Please note that this function is very expensive. Ideally, it would be used for off-chain purposes
  /// @param _pairs The pairs to be involved in the swap
  /// @return How executing a swap for all the given pairs would look like
  function getNextSwapInfo(Pair[] calldata _pairs) external view returns (IDCAHub.SwapInfo memory);

  /// @notice Returns how many seconds left until the next swap is available for a list of pairs
  /// @dev Tokens in pairs may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _pairs Pairs to check
  /// @return The amount of seconds until next swap for each of the pairs
  function secondsUntilNextSwap(Pair[] calldata _pairs) external view returns (uint256[] memory);
}

interface IDCAHubCompanionMulticallHandler {
  /// @notice Creates a new position
  /// @dev Meant to be used as part of a multicall
  /// @param _from The address of the "from" token
  /// @param _to The address of the "to" token
  /// @param _amount How many "from" tokens will be swapped in total
  /// @param _amountOfSwaps How many swaps to execute for this position
  /// @param _swapInterval How frequently the position's swaps should be executed
  /// @param _owner The address of the owner of the position being created
  /// @param _miscellaneous Bytes that will be emitted, and associated with the position. If empty, no event will be emitted
  /// @param _transferFromCaller Determines if the funds should be transfered from the caller
  /// @return _positionId The id of the created position
  function depositProxy(
    address _from,
    address _to,
    uint256 _amount,
    uint32 _amountOfSwaps,
    uint32 _swapInterval,
    address _owner,
    IDCAPermissionManager.PermissionSet[] calldata _permissions,
    bytes calldata _miscellaneous,
    bool _transferFromCaller
  ) external payable returns (uint256 _positionId);

  /// @notice Call the hub and withdraws all swapped tokens from a position to a recipient
  /// @dev Meant to be used as part of a multicall
  /// @param _positionId The position's id
  /// @param _recipient The address to withdraw swapped tokens to
  /// @return _swapped How much was withdrawn
  function withdrawSwappedProxy(uint256 _positionId, address _recipient) external payable returns (uint256 _swapped);

  /// @notice Call the hub and withdraws all swapped tokens from multiple positions
  /// @dev Meant to be used as part of a multicall
  /// @param _positions A list positions, grouped by `to` token
  /// @param _recipient The address to withdraw swapped tokens to
  /// @return _withdrawn How much was withdrawn for each token
  function withdrawSwappedManyProxy(IDCAHub.PositionSet[] calldata _positions, address _recipient)
    external
    payable
    returns (uint256[] memory _withdrawn);

  /// @notice Call the hub and takes the unswapped balance, adds the new deposited funds and modifies the position so that
  /// it is executed in _newSwaps swaps
  /// @dev Meant to be used as part of a multicall
  /// @param _positionId The position's id
  /// @param _amount Amount of funds to add to the position
  /// @param _newSwaps The new amount of swaps
  /// @param _transferFromCaller Determines if the funds should be transfered from the caller
  function increasePositionProxy(
    uint256 _positionId,
    uint256 _amount,
    uint32 _newSwaps,
    bool _transferFromCaller
  ) external payable;

  /// @notice Call the hub and withdraws the specified amount from the unswapped balance and modifies the position so that
  /// it is executed in _newSwaps swaps
  /// @dev Meant to be used as part of a multicall
  /// @param _positionId The position's id
  /// @param _amount Amount of funds to withdraw from the position
  /// @param _newSwaps The new amount of swaps
  /// @param _recipient The address to send tokens to
  function reducePositionProxy(
    uint256 _positionId,
    uint256 _amount,
    uint32 _newSwaps,
    address _recipient
  ) external payable;

  /// @notice Calls the hub and terminates the position and sends all unswapped and swapped balance to the specified recipients
  /// @dev Meant to be used as part of a multicall
  /// @param _positionId The position's id
  /// @param _recipientUnswapped The address to withdraw unswapped tokens to
  /// @param _recipientSwapped The address to withdraw swapped tokens to
  /// @return _unswapped The unswapped balance sent to `_recipientUnswapped`
  /// @return _swapped The swapped balance sent to `_recipientSwapped`
  function terminateProxy(
    uint256 _positionId,
    address _recipientUnswapped,
    address _recipientSwapped
  ) external payable returns (uint256 _unswapped, uint256 _swapped);

  /// @notice Calls the permission manager and sets permissions via signature
  /// @param _permissions The permissions to set
  /// @param _tokenId The token's id
  /// @param _deadline The deadline timestamp by which the call must be mined for the approve to work
  /// @param _v Must produce valid secp256k1 signature from the holder along with `r` and `s`
  /// @param _r Must produce valid secp256k1 signature from the holder along with `v` and `s`
  /// @param _s Must produce valid secp256k1 signature from the holder along with `r` and `v`
  function permissionPermitProxy(
    IDCAPermissionManager.PermissionSet[] calldata _permissions,
    uint256 _tokenId,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external payable;
}

interface IDCAHubCompanion is
  IDCAHubCompanionParameters,
  IDCAHubCompanionSwapHandler,
  IDCAHubCompanionWTokenPositionHandler,
  IDCAHubCompanionDustHandler,
  IDCAHubCompanionLibrariesHandler,
  IDCAHubCompanionMulticallHandler
{
  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /// @notice Thrown when a user tries operate on a position that they don't have access to
  error UnauthorizedCaller();
}
