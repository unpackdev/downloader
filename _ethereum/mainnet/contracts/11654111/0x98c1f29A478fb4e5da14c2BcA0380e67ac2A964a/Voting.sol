// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./FixedPoint.sol";
import "./Testable.sol";
import "./FinderInterface.sol";
import "./OracleInterface.sol";
import "./OracleAncillaryInterface.sol";
import "./VotingInterface.sol";
import "./VotingAncillaryInterface.sol";
import "./IdentifierWhitelistInterface.sol";
import "./Registry.sol";
import "./ResultComputation.sol";
import "./VoteTiming.sol";
import "./VotingToken.sol";
import "./Constants.sol";

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

contract Voting is
  Testable,
  Ownable,
  OracleInterface,
  OracleAncillaryInterface,
  VotingInterface,
  VotingAncillaryInterface
{
  using FixedPoint for FixedPoint.Unsigned;
  using SafeMath for uint256;
  using VoteTiming for VoteTiming.Data;
  using ResultComputation for ResultComputation.Data;

  struct PriceRequest {
    bytes32 identifier;
    uint256 time;
    mapping(uint256 => VoteInstance) voteInstances;
    uint256 lastVotingRound;
    uint256 index;
    bytes ancillaryData;
  }

  struct VoteInstance {
    mapping(address => VoteSubmission) voteSubmissions;
    ResultComputation.Data resultComputation;
  }

  struct VoteSubmission {
    bytes32 commit;
    bytes32 revealHash;
  }

  struct Round {
    uint256 snapshotId;
    FixedPoint.Unsigned inflationRate;
    FixedPoint.Unsigned gatPercentage;
    uint256 rewardsExpirationTime;
  }

  enum RequestStatus {NotRequested, Active, Resolved, Future}

  struct RequestState {
    RequestStatus status;
    uint256 lastVotingRound;
  }

  mapping(uint256 => Round) public rounds;

  mapping(bytes32 => PriceRequest) private priceRequests;

  bytes32[] internal pendingPriceRequests;

  VoteTiming.Data public voteTiming;

  FixedPoint.Unsigned public gatPercentage;

  FixedPoint.Unsigned public inflationRate;

  uint256 public rewardsExpirationTimeout;

  VotingToken public votingToken;

  FinderInterface private finder;

  address public migratedAddress;

  uint256 private constant UINT_MAX = ~uint256(0);

  uint256 public constant ancillaryBytesLimit = 8192;

  bytes32 public snapshotMessageHash =
    ECDSA.toEthSignedMessageHash(keccak256(bytes('Sign For Snapshot')));

  event VoteCommitted(
    address indexed voter,
    uint256 indexed roundId,
    bytes32 indexed identifier,
    uint256 time,
    bytes ancillaryData
  );

  event EncryptedVote(
    address indexed voter,
    uint256 indexed roundId,
    bytes32 indexed identifier,
    uint256 time,
    bytes ancillaryData,
    bytes encryptedVote
  );

  event VoteRevealed(
    address indexed voter,
    uint256 indexed roundId,
    bytes32 indexed identifier,
    uint256 time,
    int256 price,
    bytes ancillaryData,
    uint256 numTokens
  );

  event RewardsRetrieved(
    address indexed voter,
    uint256 indexed roundId,
    bytes32 indexed identifier,
    uint256 time,
    bytes ancillaryData,
    uint256 numTokens
  );

  event PriceRequestAdded(
    uint256 indexed roundId,
    bytes32 indexed identifier,
    uint256 time
  );

  event PriceResolved(
    uint256 indexed roundId,
    bytes32 indexed identifier,
    uint256 time,
    int256 price,
    bytes ancillaryData
  );

  constructor(
    uint256 _phaseLength,
    FixedPoint.Unsigned memory _gatPercentage,
    FixedPoint.Unsigned memory _inflationRate,
    uint256 _rewardsExpirationTimeout,
    address _votingToken,
    address _finder,
    address _timerAddress
  ) public Testable(_timerAddress) {
    voteTiming.init(_phaseLength);
    require(
      _gatPercentage.isLessThanOrEqual(1),
      'GAT percentage must be <= 100%'
    );
    gatPercentage = _gatPercentage;
    inflationRate = _inflationRate;
    votingToken = VotingToken(_votingToken);
    finder = FinderInterface(_finder);
    rewardsExpirationTimeout = _rewardsExpirationTimeout;
  }

  modifier onlyRegisteredContract() {
    if (migratedAddress != address(0)) {
      require(msg.sender == migratedAddress, 'Caller must be migrated address');
    } else {
      Registry registry =
        Registry(finder.getImplementationAddress(OracleInterfaces.Registry));
      require(
        registry.isContractRegistered(msg.sender),
        'Called must be registered'
      );
    }
    _;
  }

  modifier onlyIfNotMigrated() {
    require(migratedAddress == address(0), 'Only call this if not migrated');
    _;
  }

  function requestPrice(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData
  ) public override onlyRegisteredContract() {
    uint256 blockTime = getCurrentTime();
    require(time <= blockTime, 'Can only request in past');
    require(
      _getIdentifierWhitelist().isIdentifierSupported(identifier),
      'Unsupported identifier request'
    );
    require(
      ancillaryData.length <= ancillaryBytesLimit,
      'Invalid ancillary data'
    );

    bytes32 priceRequestId =
      _encodePriceRequest(identifier, time, ancillaryData);
    PriceRequest storage priceRequest = priceRequests[priceRequestId];
    uint256 currentRoundId = voteTiming.computeCurrentRoundId(blockTime);

    RequestStatus requestStatus =
      _getRequestStatus(priceRequest, currentRoundId);

    if (requestStatus == RequestStatus.NotRequested) {
      uint256 nextRoundId = currentRoundId.add(1);

      priceRequests[priceRequestId] = PriceRequest({
        identifier: identifier,
        time: time,
        lastVotingRound: nextRoundId,
        index: pendingPriceRequests.length,
        ancillaryData: ancillaryData
      });
      pendingPriceRequests.push(priceRequestId);
      emit PriceRequestAdded(nextRoundId, identifier, time);
    }
  }

  function requestPrice(bytes32 identifier, uint256 time) public override {
    requestPrice(identifier, time, '');
  }

  /**
   * @notice Whether the price for `identifier` and `time` is available.
   * @dev Time must be in the past and the identifier must be supported.
   * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
   * @param time unix timestamp of for the price request.
   * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
   * @return _hasPrice bool if the DVM has resolved to a price for the given identifier and timestamp.
   */
  function hasPrice(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData
  ) public view override onlyRegisteredContract() returns (bool) {
    (bool _hasPrice, , ) = _getPriceOrError(identifier, time, ancillaryData);
    return _hasPrice;
  }

  // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
  function hasPrice(bytes32 identifier, uint256 time)
    public
    view
    override
    returns (bool)
  {
    return hasPrice(identifier, time, '');
  }

  /**
   * @notice Gets the price for `identifier` and `time` if it has already been requested and resolved.
   * @dev If the price is not available, the method reverts.
   * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
   * @param time unix timestamp of for the price request.
   * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
   * @return int256 representing the resolved price for the given identifier and timestamp.
   */
  function getPrice(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData
  ) public view override onlyRegisteredContract() returns (int256) {
    (bool _hasPrice, int256 price, string memory message) =
      _getPriceOrError(identifier, time, ancillaryData);

    // If the price wasn't available, revert with the provided message.
    require(_hasPrice, message);
    return price;
  }

  // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
  function getPrice(bytes32 identifier, uint256 time)
    public
    view
    override
    returns (int256)
  {
    return getPrice(identifier, time, '');
  }

  /**
   * @notice Gets the status of a list of price requests, identified by their identifier and time.
   * @dev If the status for a particular request is NotRequested, the lastVotingRound will always be 0.
   * @param requests array of type PendingRequest which includes an identifier and timestamp for each request.
   * @return requestStates a list, in the same order as the input list, giving the status of each of the specified price requests.
   */
  function getPriceRequestStatuses(PendingRequestAncillary[] memory requests)
    public
    view
    returns (RequestState[] memory)
  {
    RequestState[] memory requestStates = new RequestState[](requests.length);
    uint256 currentRoundId = voteTiming.computeCurrentRoundId(getCurrentTime());
    for (uint256 i = 0; i < requests.length; i++) {
      PriceRequest storage priceRequest =
        _getPriceRequest(
          requests[i].identifier,
          requests[i].time,
          requests[i].ancillaryData
        );

      RequestStatus status = _getRequestStatus(priceRequest, currentRoundId);

      // If it's an active request, its true lastVotingRound is the current one, even if it hasn't been updated.
      if (status == RequestStatus.Active) {
        requestStates[i].lastVotingRound = currentRoundId;
      } else {
        requestStates[i].lastVotingRound = priceRequest.lastVotingRound;
      }
      requestStates[i].status = status;
    }
    return requestStates;
  }

  // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
  function getPriceRequestStatuses(PendingRequest[] memory requests)
    public
    view
    returns (RequestState[] memory)
  {
    PendingRequestAncillary[] memory requestsAncillary =
      new PendingRequestAncillary[](requests.length);

    for (uint256 i = 0; i < requests.length; i++) {
      requestsAncillary[i].identifier = requests[i].identifier;
      requestsAncillary[i].time = requests[i].time;
      requestsAncillary[i].ancillaryData = '';
    }
    return getPriceRequestStatuses(requestsAncillary);
  }

  /****************************************
   *            VOTING FUNCTIONS          *
   ****************************************/

  /**
   * @notice Commit a vote for a price request for `identifier` at `time`.
   * @dev `identifier`, `time` must correspond to a price request that's currently in the commit phase.
   * Commits can be changed.
   * @dev Since transaction data is public, the salt will be revealed with the vote. While this is the system’s expected behavior,
   * voters should never reuse salts. If someone else is able to guess the voted price and knows that a salt will be reused, then
   * they can determine the vote pre-reveal.
   * @param identifier uniquely identifies the committed vote. EG BTC/USD price pair.
   * @param time unix timestamp of the price being voted on.
   * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
   * @param hash keccak256 hash of the `price`, `salt`, voter `address`, `time`, current `roundId`, and `identifier`.
   */
  function commitVote(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData,
    bytes32 hash
  ) public override onlyIfNotMigrated() {
    require(hash != bytes32(0), 'Invalid provided hash');

    uint256 blockTime = getCurrentTime();
    require(
      voteTiming.computeCurrentPhase(blockTime) ==
        VotingAncillaryInterface.Phase.Commit,
      'Cannot commit in reveal phase'
    );

    uint256 currentRoundId = voteTiming.computeCurrentRoundId(blockTime);

    PriceRequest storage priceRequest =
      _getPriceRequest(identifier, time, ancillaryData);
    require(
      _getRequestStatus(priceRequest, currentRoundId) == RequestStatus.Active,
      'Cannot commit inactive request'
    );

    priceRequest.lastVotingRound = currentRoundId;
    VoteInstance storage voteInstance =
      priceRequest.voteInstances[currentRoundId];
    voteInstance.voteSubmissions[msg.sender].commit = hash;

    emit VoteCommitted(
      msg.sender,
      currentRoundId,
      identifier,
      time,
      ancillaryData
    );
  }

  function commitVote(
    bytes32 identifier,
    uint256 time,
    bytes32 hash
  ) public override onlyIfNotMigrated() {
    commitVote(identifier, time, '', hash);
  }

  /**
   * @notice Snapshot the current round's token balances and lock in the inflation rate and GAT.
   * @dev This function can be called multiple times, but only the first call per round into this function or `revealVote`
   * will create the round snapshot. Any later calls will be a no-op. Will revert unless called during reveal period.
   * @param signature  signature required to prove caller is an EOA to prevent flash loans from being included in the
   * snapshot.
   */
  function snapshotCurrentRound(bytes calldata signature)
    external
    override(VotingInterface, VotingAncillaryInterface)
    onlyIfNotMigrated()
  {
    uint256 blockTime = getCurrentTime();
    require(
      voteTiming.computeCurrentPhase(blockTime) == Phase.Reveal,
      'Only snapshot in reveal phase'
    );

    require(
      ECDSA.recover(snapshotMessageHash, signature) == msg.sender,
      'Signature must match sender'
    );
    uint256 roundId = voteTiming.computeCurrentRoundId(blockTime);
    _freezeRoundVariables(roundId);
  }

  function revealVote(
    bytes32 identifier,
    uint256 time,
    int256 price,
    bytes memory ancillaryData,
    int256 salt
  ) public override onlyIfNotMigrated() {
    require(
      voteTiming.computeCurrentPhase(getCurrentTime()) == Phase.Reveal,
      'Cannot reveal in commit phase'
    );

    uint256 roundId = voteTiming.computeCurrentRoundId(getCurrentTime());

    PriceRequest storage priceRequest =
      _getPriceRequest(identifier, time, ancillaryData);
    VoteInstance storage voteInstance = priceRequest.voteInstances[roundId];
    VoteSubmission storage voteSubmission =
      voteInstance.voteSubmissions[msg.sender];

    {
      require(voteSubmission.commit != bytes32(0), 'Invalid hash reveal');
      require(
        keccak256(
          abi.encodePacked(
            price,
            salt,
            msg.sender,
            time,
            ancillaryData,
            roundId,
            identifier
          )
        ) == voteSubmission.commit,
        'Revealed data != commit hash'
      );

      require(rounds[roundId].snapshotId != 0, 'Round has no snapshot');
    }

    uint256 snapshotId = rounds[roundId].snapshotId;

    delete voteSubmission.commit;

    FixedPoint.Unsigned memory balance =
      FixedPoint.Unsigned(votingToken.balanceOfAt(msg.sender, snapshotId));

    voteSubmission.revealHash = keccak256(abi.encode(price));

    voteInstance.resultComputation.addVote(price, balance);

    emit VoteRevealed(
      msg.sender,
      roundId,
      identifier,
      time,
      price,
      ancillaryData,
      balance.rawValue
    );
  }

  function revealVote(
    bytes32 identifier,
    uint256 time,
    int256 price,
    int256 salt
  ) public override {
    revealVote(identifier, time, price, '', salt);
  }

  /**
   * @notice commits a vote and logs an event with a data blob, typically an encrypted version of the vote
   * @dev An encrypted version of the vote is emitted in an event `EncryptedVote` to allow off-chain infrastructure to
   * retrieve the commit. The contents of `encryptedVote` are never used on chain: it is purely for convenience.
   * @param identifier unique price pair identifier. Eg: BTC/USD price pair.
   * @param time unix timestamp of for the price request.
   * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
   * @param hash keccak256 hash of the price you want to vote for and a `int256 salt`.
   * @param encryptedVote offchain encrypted blob containing the voters amount, time and salt.
   */
  function commitAndEmitEncryptedVote(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData,
    bytes32 hash,
    bytes memory encryptedVote
  ) public override {
    commitVote(identifier, time, ancillaryData, hash);

    uint256 roundId = voteTiming.computeCurrentRoundId(getCurrentTime());
    emit EncryptedVote(
      msg.sender,
      roundId,
      identifier,
      time,
      ancillaryData,
      encryptedVote
    );
  }

  // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
  function commitAndEmitEncryptedVote(
    bytes32 identifier,
    uint256 time,
    bytes32 hash,
    bytes memory encryptedVote
  ) public override {
    commitVote(identifier, time, '', hash);

    commitAndEmitEncryptedVote(identifier, time, '', hash, encryptedVote);
  }

  /**
   * @notice Submit a batch of commits in a single transaction.
   * @dev Using `encryptedVote` is optional. If included then commitment is emitted in an event.
   * Look at `project-root/common/Constants.js` for the tested maximum number of
   * commitments that can fit in one transaction.
   * @param commits struct to encapsulate an `identifier`, `time`, `hash` and optional `encryptedVote`.
   */
  function batchCommit(CommitmentAncillary[] memory commits) public override {
    for (uint256 i = 0; i < commits.length; i++) {
      if (commits[i].encryptedVote.length == 0) {
        commitVote(
          commits[i].identifier,
          commits[i].time,
          commits[i].ancillaryData,
          commits[i].hash
        );
      } else {
        commitAndEmitEncryptedVote(
          commits[i].identifier,
          commits[i].time,
          commits[i].ancillaryData,
          commits[i].hash,
          commits[i].encryptedVote
        );
      }
    }
  }

  // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
  function batchCommit(Commitment[] memory commits) public override {
    CommitmentAncillary[] memory commitsAncillary =
      new CommitmentAncillary[](commits.length);

    for (uint256 i = 0; i < commits.length; i++) {
      commitsAncillary[i].identifier = commits[i].identifier;
      commitsAncillary[i].time = commits[i].time;
      commitsAncillary[i].ancillaryData = '';
      commitsAncillary[i].hash = commits[i].hash;
      commitsAncillary[i].encryptedVote = commits[i].encryptedVote;
    }
    batchCommit(commitsAncillary);
  }

  /**
   * @notice Reveal multiple votes in a single transaction.
   * Look at `project-root/common/Constants.js` for the tested maximum number of reveals.
   * that can fit in one transaction.
   * @dev For more info on reveals, review the comment for `revealVote`.
   * @param reveals array of the Reveal struct which contains an identifier, time, price and salt.
   */
  function batchReveal(RevealAncillary[] memory reveals) public override {
    for (uint256 i = 0; i < reveals.length; i++) {
      revealVote(
        reveals[i].identifier,
        reveals[i].time,
        reveals[i].price,
        reveals[i].ancillaryData,
        reveals[i].salt
      );
    }
  }

  // Overloaded method to enable short term backwards compatibility. Will be deprecated in the next DVM version.
  function batchReveal(Reveal[] memory reveals) public override {
    RevealAncillary[] memory revealsAncillary =
      new RevealAncillary[](reveals.length);

    for (uint256 i = 0; i < reveals.length; i++) {
      revealsAncillary[i].identifier = reveals[i].identifier;
      revealsAncillary[i].time = reveals[i].time;
      revealsAncillary[i].price = reveals[i].price;
      revealsAncillary[i].ancillaryData = '';
      revealsAncillary[i].salt = reveals[i].salt;
    }
    batchReveal(revealsAncillary);
  }

  /**
   * @notice Retrieves rewards owed for a set of resolved price requests.
   * @dev Can only retrieve rewards if calling for a valid round and if the call is done within the timeout threshold
   * (not expired). Note that a named return value is used here to avoid a stack to deep error.
   * @param voterAddress voter for which rewards will be retrieved. Does not have to be the caller.
   * @param roundId the round from which voting rewards will be retrieved from.
   * @param toRetrieve array of PendingRequests which rewards are retrieved from.
   * @return totalRewardToIssue total amount of rewards returned to the voter.
   */
  function retrieveRewards(
    address voterAddress,
    uint256 roundId,
    PendingRequestAncillary[] memory toRetrieve
  ) public override returns (FixedPoint.Unsigned memory totalRewardToIssue) {
    if (migratedAddress != address(0)) {
      require(msg.sender == migratedAddress, 'Can only call from migrated');
    }
    require(
      roundId < voteTiming.computeCurrentRoundId(getCurrentTime()),
      'Invalid roundId'
    );

    Round storage round = rounds[roundId];
    bool isExpired = getCurrentTime() > round.rewardsExpirationTime;
    FixedPoint.Unsigned memory snapshotBalance =
      FixedPoint.Unsigned(
        votingToken.balanceOfAt(voterAddress, round.snapshotId)
      );

    FixedPoint.Unsigned memory snapshotTotalSupply =
      FixedPoint.Unsigned(votingToken.totalSupplyAt(round.snapshotId));
    FixedPoint.Unsigned memory totalRewardPerVote =
      round.inflationRate.mul(snapshotTotalSupply);

    totalRewardToIssue = FixedPoint.Unsigned(0);

    for (uint256 i = 0; i < toRetrieve.length; i++) {
      PriceRequest storage priceRequest =
        _getPriceRequest(
          toRetrieve[i].identifier,
          toRetrieve[i].time,
          toRetrieve[i].ancillaryData
        );
      VoteInstance storage voteInstance =
        priceRequest.voteInstances[priceRequest.lastVotingRound];

      require(
        priceRequest.lastVotingRound == roundId,
        'Retrieve for votes same round'
      );

      _resolvePriceRequest(priceRequest, voteInstance);

      if (voteInstance.voteSubmissions[voterAddress].revealHash == 0) {
        continue;
      } else if (isExpired) {
        emit RewardsRetrieved(
          voterAddress,
          roundId,
          toRetrieve[i].identifier,
          toRetrieve[i].time,
          toRetrieve[i].ancillaryData,
          0
        );
      } else if (
        voteInstance.resultComputation.wasVoteCorrect(
          voteInstance.voteSubmissions[voterAddress].revealHash
        )
      ) {
        FixedPoint.Unsigned memory reward =
          snapshotBalance.mul(totalRewardPerVote).div(
            voteInstance.resultComputation.getTotalCorrectlyVotedTokens()
          );
        totalRewardToIssue = totalRewardToIssue.add(reward);

        emit RewardsRetrieved(
          voterAddress,
          roundId,
          toRetrieve[i].identifier,
          toRetrieve[i].time,
          toRetrieve[i].ancillaryData,
          reward.rawValue
        );
      } else {
        emit RewardsRetrieved(
          voterAddress,
          roundId,
          toRetrieve[i].identifier,
          toRetrieve[i].time,
          toRetrieve[i].ancillaryData,
          0
        );
      }

      delete voteInstance.voteSubmissions[voterAddress].revealHash;
    }

    if (totalRewardToIssue.isGreaterThan(0)) {
      require(
        votingToken.mint(voterAddress, totalRewardToIssue.rawValue),
        'Voting token issuance failed'
      );
    }
  }

  function retrieveRewards(
    address voterAddress,
    uint256 roundId,
    PendingRequest[] memory toRetrieve
  ) public override returns (FixedPoint.Unsigned memory) {
    PendingRequestAncillary[] memory toRetrieveAncillary =
      new PendingRequestAncillary[](toRetrieve.length);

    for (uint256 i = 0; i < toRetrieve.length; i++) {
      toRetrieveAncillary[i].identifier = toRetrieve[i].identifier;
      toRetrieveAncillary[i].time = toRetrieve[i].time;
      toRetrieveAncillary[i].ancillaryData = '';
    }

    return retrieveRewards(voterAddress, roundId, toRetrieveAncillary);
  }

  /****************************************
   *        VOTING GETTER FUNCTIONS       *
   ****************************************/

  /**
   * @notice Gets the queries that are being voted on this round.
   * @return pendingRequests array containing identifiers of type `PendingRequest`.
   * and timestamps for all pending requests.
   */
  function getPendingRequests()
    external
    view
    override(VotingInterface, VotingAncillaryInterface)
    returns (PendingRequestAncillary[] memory)
  {
    uint256 blockTime = getCurrentTime();
    uint256 currentRoundId = voteTiming.computeCurrentRoundId(blockTime);

    // Solidity memory arrays aren't resizable (and reading storage is expensive). Hence this hackery to filter
    // `pendingPriceRequests` only to those requests that have an Active RequestStatus.
    PendingRequestAncillary[] memory unresolved =
      new PendingRequestAncillary[](pendingPriceRequests.length);
    uint256 numUnresolved = 0;

    for (uint256 i = 0; i < pendingPriceRequests.length; i++) {
      PriceRequest storage priceRequest =
        priceRequests[pendingPriceRequests[i]];
      if (
        _getRequestStatus(priceRequest, currentRoundId) == RequestStatus.Active
      ) {
        unresolved[numUnresolved] = PendingRequestAncillary({
          identifier: priceRequest.identifier,
          time: priceRequest.time,
          ancillaryData: priceRequest.ancillaryData
        });
        numUnresolved++;
      }
    }

    PendingRequestAncillary[] memory pendingRequests =
      new PendingRequestAncillary[](numUnresolved);
    for (uint256 i = 0; i < numUnresolved; i++) {
      pendingRequests[i] = unresolved[i];
    }
    return pendingRequests;
  }

  /**
   * @notice Returns the current voting phase, as a function of the current time.
   * @return Phase to indicate the current phase. Either { Commit, Reveal, NUM_PHASES_PLACEHOLDER }.
   */
  function getVotePhase()
    external
    view
    override(VotingInterface, VotingAncillaryInterface)
    returns (Phase)
  {
    return voteTiming.computeCurrentPhase(getCurrentTime());
  }

  /**
   * @notice Returns the current round ID, as a function of the current time.
   * @return uint256 representing the unique round ID.
   */
  function getCurrentRoundId()
    external
    view
    override(VotingInterface, VotingAncillaryInterface)
    returns (uint256)
  {
    return voteTiming.computeCurrentRoundId(getCurrentTime());
  }

  /****************************************
   *        OWNER ADMIN FUNCTIONS         *
   ****************************************/

  /**
   * @notice Disables this Voting contract in favor of the migrated one.
   * @dev Can only be called by the contract owner.
   * @param newVotingAddress the newly migrated contract address.
   */
  function setMigrated(address newVotingAddress)
    external
    override(VotingInterface, VotingAncillaryInterface)
    onlyOwner
  {
    migratedAddress = newVotingAddress;
  }

  /**
   * @notice Resets the inflation rate. Note: this change only applies to rounds that have not yet begun.
   * @dev This method is public because calldata structs are not currently supported by solidity.
   * @param newInflationRate sets the next round's inflation rate.
   */
  function setInflationRate(FixedPoint.Unsigned memory newInflationRate)
    public
    override(VotingInterface, VotingAncillaryInterface)
    onlyOwner
  {
    inflationRate = newInflationRate;
  }

  /**
   * @notice Resets the Gat percentage. Note: this change only applies to rounds that have not yet begun.
   * @dev This method is public because calldata structs are not currently supported by solidity.
   * @param newGatPercentage sets the next round's Gat percentage.
   */
  function setGatPercentage(FixedPoint.Unsigned memory newGatPercentage)
    public
    override(VotingInterface, VotingAncillaryInterface)
    onlyOwner
  {
    require(newGatPercentage.isLessThan(1), 'GAT percentage must be < 100%');
    gatPercentage = newGatPercentage;
  }

  /**
   * @notice Resets the rewards expiration timeout.
   * @dev This change only applies to rounds that have not yet begun.
   * @param NewRewardsExpirationTimeout how long a caller can wait before choosing to withdraw their rewards.
   */
  function setRewardsExpirationTimeout(uint256 NewRewardsExpirationTimeout)
    public
    override(VotingInterface, VotingAncillaryInterface)
    onlyOwner
  {
    rewardsExpirationTimeout = NewRewardsExpirationTimeout;
  }

  /****************************************
   *    PRIVATE AND INTERNAL FUNCTIONS    *
   ****************************************/

  // Returns the price for a given identifer. Three params are returns: bool if there was an error, int to represent
  // the resolved price and a string which is filled with an error message, if there was an error or "".
  function _getPriceOrError(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData
  )
    private
    view
    returns (
      bool,
      int256,
      string memory
    )
  {
    PriceRequest storage priceRequest =
      _getPriceRequest(identifier, time, ancillaryData);
    uint256 currentRoundId = voteTiming.computeCurrentRoundId(getCurrentTime());

    RequestStatus requestStatus =
      _getRequestStatus(priceRequest, currentRoundId);
    if (requestStatus == RequestStatus.Active) {
      return (false, 0, 'Current voting round not ended');
    } else if (requestStatus == RequestStatus.Resolved) {
      VoteInstance storage voteInstance =
        priceRequest.voteInstances[priceRequest.lastVotingRound];
      (, int256 resolvedPrice) =
        voteInstance.resultComputation.getResolvedPrice(
          _computeGat(priceRequest.lastVotingRound)
        );
      return (true, resolvedPrice, '');
    } else if (requestStatus == RequestStatus.Future) {
      return (false, 0, 'Price is still to be voted on');
    } else {
      return (false, 0, 'Price was never requested');
    }
  }

  function _getPriceRequest(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData
  ) private view returns (PriceRequest storage) {
    return priceRequests[_encodePriceRequest(identifier, time, ancillaryData)];
  }

  function _encodePriceRequest(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData
  ) private pure returns (bytes32) {
    return keccak256(abi.encode(identifier, time, ancillaryData));
  }

  function _freezeRoundVariables(uint256 roundId) private {
    Round storage round = rounds[roundId];

    if (round.snapshotId == 0) {
      round.snapshotId = votingToken.snapshot();

      rounds[roundId].inflationRate = inflationRate;

      rounds[roundId].gatPercentage = gatPercentage;

      rounds[roundId].rewardsExpirationTime = voteTiming
        .computeRoundEndTime(roundId)
        .add(rewardsExpirationTimeout);
    }
  }

  function _resolvePriceRequest(
    PriceRequest storage priceRequest,
    VoteInstance storage voteInstance
  ) private {
    if (priceRequest.index == UINT_MAX) {
      return;
    }
    (bool isResolved, int256 resolvedPrice) =
      voteInstance.resultComputation.getResolvedPrice(
        _computeGat(priceRequest.lastVotingRound)
      );
    require(isResolved, "Can't resolve unresolved request");

    uint256 lastIndex = pendingPriceRequests.length - 1;
    PriceRequest storage lastPriceRequest =
      priceRequests[pendingPriceRequests[lastIndex]];
    lastPriceRequest.index = priceRequest.index;
    pendingPriceRequests[priceRequest.index] = pendingPriceRequests[lastIndex];
    pendingPriceRequests.pop();

    priceRequest.index = UINT_MAX;
    emit PriceResolved(
      priceRequest.lastVotingRound,
      priceRequest.identifier,
      priceRequest.time,
      resolvedPrice,
      priceRequest.ancillaryData
    );
  }

  function _computeGat(uint256 roundId)
    private
    view
    returns (FixedPoint.Unsigned memory)
  {
    uint256 snapshotId = rounds[roundId].snapshotId;
    if (snapshotId == 0) {
      return FixedPoint.Unsigned(UINT_MAX);
    }

    FixedPoint.Unsigned memory snapshottedSupply =
      FixedPoint.Unsigned(votingToken.totalSupplyAt(snapshotId));

    return snapshottedSupply.mul(rounds[roundId].gatPercentage);
  }

  function _getRequestStatus(
    PriceRequest storage priceRequest,
    uint256 currentRoundId
  ) private view returns (RequestStatus) {
    if (priceRequest.lastVotingRound == 0) {
      return RequestStatus.NotRequested;
    } else if (priceRequest.lastVotingRound < currentRoundId) {
      VoteInstance storage voteInstance =
        priceRequest.voteInstances[priceRequest.lastVotingRound];
      (bool isResolved, ) =
        voteInstance.resultComputation.getResolvedPrice(
          _computeGat(priceRequest.lastVotingRound)
        );
      return isResolved ? RequestStatus.Resolved : RequestStatus.Active;
    } else if (priceRequest.lastVotingRound == currentRoundId) {
      return RequestStatus.Active;
    } else {
      return RequestStatus.Future;
    }
  }

  function _getIdentifierWhitelist()
    private
    view
    returns (IdentifierWhitelistInterface supportedIdentifiers)
  {
    return
      IdentifierWhitelistInterface(
        finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist)
      );
  }
}
