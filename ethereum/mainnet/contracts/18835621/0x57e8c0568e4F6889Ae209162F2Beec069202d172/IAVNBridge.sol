// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IAVNBridge {
  event LogGrowthDenied(uint32 indexed period);
  event LogGrowthDelayUpdated(uint256 indexed oldDelaySeconds, uint256 indexed newDelaySeconds);
  event LogAuthorsEnabled(bool indexed state);
  event LogLiftingEnabled(bool indexed state);
  event LogLoweringEnabled(bool indexed state);
  event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

  event LogAuthorAdded(address indexed t1Address, bytes32 indexed t2PubKey, uint32 indexed t2TxId);
  event LogAuthorRemoved(address indexed t1Address, bytes32 indexed t2PubKey, uint32 indexed t2TxId);
  event LogRootPublished(bytes32 indexed rootHash, uint32 indexed t2TxId);
  event LogGrowthTriggered(uint256 amount, uint32 indexed period, uint32 indexed t2TxId);

  event LogLifted(address indexed token, bytes32 indexed t2PubKey, uint256 amount);
  event LogLegacyLowered(address indexed token, address indexed t1Address, bytes32 indexed t2PubKey, uint256 amount);
  event LogLowerClaimed(uint32 indexed lowerId);
  event LogGrowth(uint256 indexed amount, uint32 indexed period);

  // Owner only
  function setCoreOwner() external;
  function denyGrowth(uint32 period) external;
  function setGrowthDelay(uint256 delaySeconds) external;
  function toggleAuthors(bool state) external;
  function toggleLifting(bool state) external;
  function toggleLowering(bool state) external;

  // Authors only
  function addAuthor(bytes calldata t1PubKey, bytes32 t2PubKey, uint256 expiry, uint32 t2TxId, bytes calldata confirmations) external;
  function removeAuthor(bytes32 t2PubKey, bytes calldata t1PubKey, uint256 expiry, uint32 t2TxId, bytes calldata confirmations) external;
  function publishRoot(bytes32 rootHash, uint256 expiry, uint32 t2TxId, bytes calldata confirmations) external;
  function triggerGrowth(uint128 rewards, uint128 avgStaked, uint32 period, uint256 expiry, uint32 t2TxId, bytes calldata confirmations) external;

  // Public
  function releaseGrowth(uint32 period) external;
  function lift(address token, bytes calldata t2PubKey, uint256 amount) external;
  function liftETH(bytes calldata t2PubKey) external payable;
  function legacyLower(bytes calldata leaf, bytes32[] calldata merklePath) external;
  function claimLower(bytes calldata proof) external;
  function checkLower(bytes calldata proof) external view returns (address token, uint256 amount, address recipient, uint32 lowerId, uint256 confirmationsRequired, uint256 confirmationsProvided, bool proofIsValid, bool lowerIsClaimed);
  function confirmTransaction(bytes32 leafHash, bytes32[] calldata merklePath) external view returns (bool);
  function corroborate(uint32 t2TxId, uint256 expiry) external view returns (int8);
}
