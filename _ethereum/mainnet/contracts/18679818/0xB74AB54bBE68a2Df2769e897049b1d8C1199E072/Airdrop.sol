// SPDX-FileCopyrightText: 2023 Stake Together Labs <legal@staketogether.org>
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MerkleProof.sol";
import "./Address.sol";

import "./IAirdrop.sol";
import "./IRouter.sol";
import "./IStakeTogether.sol";

/// @title Airdrop Contract for StakeTogether Protocol
/// @notice This contract manages the Airdrop functionality for the StakeTogether protocol, providing methods to set and claim rewards.
/// @custom:security-contact security@staketogether.org
contract Airdrop is
  Initializable,
  PausableUpgradeable,
  AccessControlUpgradeable,
  UUPSUpgradeable,
  ReentrancyGuardUpgradeable,
  IAirdrop
{
  bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE'); // Role allowing an account to perform upgrade operations.
  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE'); // Role allowing an account to perform administrative operations.
  uint256 public version; // The version of the contract.

  IRouter public router; // The reference to the Router contract for routing related operations.
  IStakeTogether public stakeTogether; // The reference to the StakeTogether contract for staking related operations.

  mapping(uint256 => bytes32) public merkleRoots; // Stores the merkle roots for block number. This is used for claims verification.
  mapping(uint256 => mapping(uint256 => uint256)) private claimBitMap; // A nested mapping where the first key is the block and the second key is the user's index.

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @notice Initializes the contract with initial settings.
  function initialize() external initializer {
    __Pausable_init();
    __ReentrancyGuard_init();
    __AccessControl_init();
    __UUPSUpgradeable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

    version = 1;
  }

  /// @notice Pauses all contract functionalities.
  /// @dev Only callable by the admin role.
  function pause() external onlyRole(ADMIN_ROLE) {
    _pause();
  }

  /// @notice Unpauses all contract functionalities.
  /// @dev Only callable by the admin role.
  function unpause() external onlyRole(ADMIN_ROLE) {
    _unpause();
  }

  /// @notice Internal function to authorize an upgrade.
  /// @dev Only callable by the upgrader role.
  /// @param _newImplementation Address of the new contract implementation.
  function _authorizeUpgrade(address _newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

  /// @notice Transfers any extra amount of ETH in the contract to the StakeTogether fee address.
  /// @dev Only callable by the admin role.
  receive() external payable {
    emit ReceiveEther(msg.value);
  }

  /// @notice Transfers any extra amount of ETH in the contract to the StakeTogether fee address.
  /// @dev Only callable by the admin role.
  function transferExtraAmount() external whenNotPaused nonReentrant onlyRole(ADMIN_ROLE) {
    uint256 extraAmount = address(this).balance;
    if (extraAmount <= 0) revert NoExtraAmountAvailable();
    address stakeTogetherFee = stakeTogether.getFeeAddress(IStakeTogether.FeeRole.StakeTogether);
    Address.sendValue(payable(stakeTogetherFee), extraAmount);
  }

  /// @notice Sets the StakeTogether contract address.
  /// @param _stakeTogether The address of the StakeTogether contract.
  /// @dev Only callable by the admin role.
  function setStakeTogether(address _stakeTogether) external onlyRole(ADMIN_ROLE) {
    if (address(stakeTogether) != address(0)) revert StakeTogetherAlreadySet();
    if (_stakeTogether == address(0)) revert ZeroAddress();
    stakeTogether = IStakeTogether(payable(_stakeTogether));
    emit SetStakeTogether(_stakeTogether);
  }

  /// @notice Sets the Router contract address.
  /// @param _router The address of the router.
  /// @dev Only callable by the admin role.
  function setRouter(address _router) external onlyRole(ADMIN_ROLE) {
    if (address(router) != address(0)) revert RouterAlreadySet();
    if (_router == address(0)) revert ZeroAddress();
    router = IRouter(payable(_router));
    emit SetRouter(_router);
  }

  /**************
   ** AIRDROPS **
   **************/

  /// @notice Adds a new Merkle root for a given blockNumber.
  /// @param _reportBlock The block number.
  /// @param _root The Merkle root.
  /// @dev Only callable by the router.
  function addMerkleRoot(uint256 _reportBlock, bytes32 _root) external whenNotPaused {
    if (msg.sender != address(router)) revert OnlyRouter();
    if (merkleRoots[_reportBlock] != bytes32(0)) revert MerkleRootAlreadySetForBlock();
    merkleRoots[_reportBlock] = _root;
    emit AddMerkleRoot(_reportBlock, _root);
  }

  /// @notice Claims a reward for a specific block number.
  /// @param _reportBlock The block report number.
  /// @param _index The index in the Merkle tree.
  /// @param _account The address claiming the reward.
  /// @param _sharesAmount The amount of shares to claim.
  /// @param merkleProof The Merkle proof required to claim the reward.
  /// @dev Verifies the Merkle proof and transfers the reward shares.
  function claim(
    uint256 _reportBlock,
    uint256 _index,
    address _account,
    uint256 _sharesAmount,
    bytes32[] calldata merkleProof
  ) external nonReentrant whenNotPaused {
    if (stakeTogether.isListedInAntiFraud(_account)) revert ListedInAntiFraud();
    if (isClaimed(_reportBlock, _index)) revert AlreadyClaimed();
    if (merkleRoots[_reportBlock] == bytes32(0)) revert MerkleRootNotSet();
    if (_account == address(0)) revert ZeroAddress();
    if (_sharesAmount == 0) revert ZeroAmount();

    bytes32 leaf = keccak256(
      bytes.concat(keccak256(abi.encode(_index, _reportBlock, _account, _sharesAmount)))
    );
    if (!MerkleProof.verify(merkleProof, merkleRoots[_reportBlock], leaf)) revert InvalidProof();

    _setClaimed(_reportBlock, _index);

    stakeTogether.claimAirdrop(_account, _sharesAmount);

    emit Claim(_reportBlock, _index, _account, _sharesAmount, merkleProof);
  }

  /// @notice Marks a reward as claimed for a specific index and block number.
  /// @param _blockNumber The block report number.
  /// @param _index The index in the Merkle tree.
  /// @dev This function is private and is used internally to update the claim status.
  function _setClaimed(uint256 _blockNumber, uint256 _index) private {
    uint256 claimedWordIndex = _index / 256;
    uint256 claimedBitIndex = _index % 256;
    claimBitMap[_blockNumber][claimedWordIndex] =
      claimBitMap[_blockNumber][claimedWordIndex] |
      (1 << claimedBitIndex);
  }

  /// @notice Checks if a reward has been claimed for a specific index and block number.
  /// @param _blockNumber The block number.
  /// @param _index The index in the Merkle tree.
  /// @return Returns true if the reward has been claimed, false otherwise.
  function isClaimed(uint256 _blockNumber, uint256 _index) public view returns (bool) {
    uint256 claimedWordIndex = _index / 256;
    uint256 claimedBitIndex = _index % 256;
    uint256 claimedWord = claimBitMap[_blockNumber][claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }
}
