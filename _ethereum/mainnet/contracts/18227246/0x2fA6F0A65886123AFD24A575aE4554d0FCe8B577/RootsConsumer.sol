// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ChainlinkClient.sol";

import "./IRootsConsumer.sol";
import "./DataWarehouse.sol";
import "./Strings.sol";
import "./HexStringConverter.sol";
import "./OwnableWithGuardian.sol";
import "./Rescuable.sol";
import "./GovernanceV3Ethereum.sol";
import "./AaveV3Ethereum.sol";
import "./AaveSafetyModule.sol";

/**
 * @title RootsConsumer
 * @author BGD Labs
 * @notice Consumer contract to request transaction calldata off-chain to register roots for
 *         the voting tokens.
 */
contract RootsConsumer is IRootsConsumer, ChainlinkClient, OwnableWithGuardian, Rescuable {
  using Chainlink for Chainlink.Request;

  /// @inheritdoc IRootsConsumer
  address public immutable DATA_WAREHOUSE;

  error OnlyRobotKeeper();

  uint256 private _fee;
  bytes32 private _jobId;
  string private _apiUrl;
  address private _robotKeeper;

  /**
   * @notice Initialize the link token, target oracle, jobId, fee and data warehouse contract to submit roots
   * @dev The oracle address must be an Operator contract for multiword response
   * @param chainlinkToken address of the chainlink token
   * @param chainlinkOperator address of the chainlink node operator
   * @param newGuardian address of the roots consumer guardian
   * @param jobId The jobId used by the operator oracle
   * @param fee The fee to pay to the node operator for the request
   * @param dataWarehouse address of the data warehouse contract
   */
  constructor(
    address chainlinkToken,
    address chainlinkOperator,
    address newGuardian,
    bytes32 jobId,
    uint256 fee,
    address dataWarehouse,
    string memory apiUrl
  ) {
    _jobId = jobId;
    _fee = fee;
    _apiUrl = apiUrl;
    DATA_WAREHOUSE = dataWarehouse;
    setChainlinkToken(chainlinkToken);
    setChainlinkOracle(chainlinkOperator);
    _updateGuardian(newGuardian);
  }

  /// @dev Reverts if called by any account other than the robot keeper.
  modifier onlyRobotKeeper() {
    if (_robotKeeper != msg.sender) revert OnlyRobotKeeper();
    _;
  }

  /// @inheritdoc IRootsConsumer
  function requestSubmitRoots(bytes32 blockHash) external onlyRobotKeeper {
    Chainlink.Request memory request = buildChainlinkRequest(
      _jobId,
      address(this),
      this.fulfillRegisterRoots.selector
    );
    string memory requestUrl = string(
      abi.encodePacked(_apiUrl, HexStringConverter.toHexString(blockHash))
    );

    request.add('get', requestUrl);
    request.add('path', 'data');
    sendOperatorRequest(request, _fee);
    emit OperatorRequestSent(blockHash, requestUrl, _fee);
  }

  /// @inheritdoc IRootsConsumer
  function fulfillRegisterRoots(
    bytes32 requestId,
    bytes calldata response
  ) external recordChainlinkFulfillment(requestId) {
    (
      bytes32 blockHash,
      bytes memory blockHeaderRLP,
      bytes memory accountStateProofRLPAave,
      bytes memory accountStateProofRLPaAave,
      bytes memory accountStateProofRLPstkAave,
      bytes memory accountStateProofRLPGovernance,
      bytes32 slot,
      bytes memory storageProof
    ) = abi.decode(response, (bytes32, bytes, bytes, bytes, bytes, bytes, bytes32, bytes));

    IDataWarehouse(DATA_WAREHOUSE).processStorageRoot(
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      blockHash,
      blockHeaderRLP,
      accountStateProofRLPAave
    );
    IDataWarehouse(DATA_WAREHOUSE).processStorageRoot(
      AaveV3EthereumAssets.AAVE_A_TOKEN,
      blockHash,
      blockHeaderRLP,
      accountStateProofRLPaAave
    );
    IDataWarehouse(DATA_WAREHOUSE).processStorageRoot(
      AaveSafetyModule.STK_AAVE,
      blockHash,
      blockHeaderRLP,
      accountStateProofRLPstkAave
    );
    IDataWarehouse(DATA_WAREHOUSE).processStorageRoot(
      address(GovernanceV3Ethereum.GOVERNANCE),
      blockHash,
      blockHeaderRLP,
      accountStateProofRLPGovernance
    );

    IDataWarehouse(DATA_WAREHOUSE).processStorageSlot(
      AaveSafetyModule.STK_AAVE,
      blockHash,
      slot,
      storageProof
    );

    emit RootsRegisteredFulfilled(requestId, blockHash);
  }

  /// @inheritdoc IRootsConsumer
  function setFee(uint256 fee) external onlyOwnerOrGuardian {
    _fee = fee;
    emit FeeSet(fee);
  }

  /// @inheritdoc IRootsConsumer
  function setJobId(bytes32 jobId) external onlyOwnerOrGuardian {
    _jobId = jobId;
    emit JobIdSet(jobId);
  }

  /// @inheritdoc IRootsConsumer
  function setApiUrl(string memory apiUrl) external onlyOwnerOrGuardian {
    _apiUrl = apiUrl;
    emit ApiUrlSet(apiUrl);
  }

  /// @inheritdoc IRootsConsumer
  function setOperator(address chainlinkOperator) external onlyOwnerOrGuardian {
    setChainlinkOracle(chainlinkOperator);
    emit OperatorSet(chainlinkOperator);
  }

  /// @inheritdoc IRootsConsumer
  function setRobotKeeper(address robotKeeper) external onlyOwnerOrGuardian {
    _robotKeeper = robotKeeper;
    emit RobotKeeperSet(robotKeeper);
  }

  /// @inheritdoc IRootsConsumer
  function getFee() external view returns (uint256) {
    return _fee;
  }

  /// @inheritdoc IRootsConsumer
  function getJobId() external view returns (bytes32) {
    return _jobId;
  }

  /// @inheritdoc IRootsConsumer
  function getApiUrl() external view returns (string memory) {
    return _apiUrl;
  }

  /// @inheritdoc IRootsConsumer
  function getRobotKeeper() external view returns (address) {
    return _robotKeeper;
  }

  /// @inheritdoc IRescuable
  function whoCanRescue() public view virtual override returns (address) {
    return owner();
  }
}
