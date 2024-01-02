// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// Core
import "./Fyde.sol";
import "./QuarantineList.sol";
import "./RequestQueue.sol";

// Structs
import "./Structs.sol";

// Utils
import "./BaseChecker.sol";
import "./Ownable.sol";
import "./PercentageMath.sol";

// Interfaces
import "./IFyde.sol";
import "./IGovernanceModule.sol";
import "./IOracle.sol";

///@title Relayer
///@notice The relayer is the entry point contract for users to interact with the protocol.
///        User call request functions to make a deposit or a withdrawal, that request will be
/// queued and be processed by a keeper.
///        The relayer is monitored by a Gelato bot that will process the requests.
///        The relayer is also monitored by a Gelato bot that will update the protocol AUM.

contract Relayer is RequestQueue, QuarantineList, BaseChecker {
  /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

  ///@notice Fyde contract
  IFyde public fyde;

  ///@notice OracleModule contract
  IOracle public oracleModule;

  //@notice GovernanceModule contract
  IGovernanceModule public immutable GOVERNANCE_MODULE;

  //@notice Max number assets accepted in one request
  uint8 public constant MAX_ASSET_TO_REQUEST = 5;

  ///@notice Max requests to be processed in one batch
  uint8 public constant MAX_BATCH_SIZE = 3;

  ///@dev Only used for tracking events offchain
  uint32 public nonce;

  ///@notice Threshold of deviation for updating AUM
  uint16 public deviationThreshold;

  ///@notice State of the protocol
  bool public paused;

  //@notice Swap state
  bool public swapPaused;

  ///@notice Map the relayer action to the gas usage
  ///@dev We hash a string for simplicity : keccak256("Deposit_Standard_2") => Deposit 2 assets in
  /// standard pool
  mapping(bytes32 => uint256) public actionToGasUsage;

  /*//////////////////////////////////////////////////////////////
                                 ERROR
    //////////////////////////////////////////////////////////////*/

  error NoRequest();
  error ValueOutOfBounds();
  error ActionPaused();
  error DuplicatesAssets();
  error IncorrectNumOfAsset();
  error SlippageExceed(uint256 amountOut, uint256 minAmountOut);
  error NotEnoughGas(uint256 received, uint256 required);
  error AssetNotSupported(address asset);
  error SwapDisabled(address asset);
  error AssetPriceNotAvailable();
  error AssetNotAllowedInGovernancePool(address asset);

  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event Pause(uint256 timestamp);
  event Unpause(uint256 timestamp);
  event DepositRequested(uint32 requestId, RequestData request);
  event WithdrawRequested(uint32 requestId, RequestData request);
  event ProcessRequestSuccess(uint32 requestId);
  event ProcessRequestFailed(uint32 requestId, bytes data);
  event SwapRequested(uint32 requestId, RequestData request);

  /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  ///@dev _relayerActions are a hash of a string, like keccak256("Deposit_Standard_1") -> Deposit 1
  /// asset in standard pool
  constructor(
    address _oracleModule,
    address _govModule,
    uint8 _deviationThreshold,
    bytes32[] memory _relayerActions,
    uint256[] memory _gasUsages
  ) Ownable(msg.sender) {
    oracleModule = IOracle(_oracleModule);
    GOVERNANCE_MODULE = IGovernanceModule(_govModule);
    updateDeviationThreshold(_deviationThreshold);

    for (uint256 i; i < _relayerActions.length; i++) {
      actionToGasUsage[_relayerActions[i]] = _gasUsages[i];
    }
  }

  /*//////////////////////////////////////////////////////////////
                                GUARD
    //////////////////////////////////////////////////////////////*/

  ///@notice Pause the protocol
  function pauseProtocol() external onlyGuard {
    paused = true;
    emit Pause(block.timestamp);
  }

  ///@notice Unpause the protocol
  function unpauseProtocol() external onlyGuard {
    paused = false;
    emit Unpause(block.timestamp);
  }

  ///@notice Pause the swaps
  function pauseSwap() external onlyGuard {
    swapPaused = true;
    emit Pause(block.timestamp);
  }

  ///@notice Unpause the swaps
  function unpauseSwap() external onlyGuard {
    swapPaused = false;
    emit Unpause(block.timestamp);
  }

  ///@notice Delete a request from the queue
  function deleteRequest(uint64 _numRequests) external onlyGuard {
    _deleteRequests(_numRequests);
  }

  /*//////////////////////////////////////////////////////////////
                                 OWNER
    //////////////////////////////////////////////////////////////*/

  ///@notice sets the addres of fyde contract
  ///@param _fyde address of fyde
  function setFyde(address _fyde) external onlyOwner {
    fyde = IFyde(_fyde);
  }

  ///@notice Set the oracle module
  function setOracleModule(address _oracleModule) external onlyOwner {
    oracleModule = IOracle(_oracleModule);
  }

  ///@notice Change the deviation threshold
  ///@dev 50 = 0.5 % of deviation
  function updateDeviationThreshold(uint16 _threshold) public onlyOwner {
    // We bound the threshold between 0.1 % to 10%
    if (_threshold < 10 || _threshold > 1000) revert ValueOutOfBounds();
    deviationThreshold = _threshold;
  }

  ///@notice Update the gas usage for a specific relayer action
  ///@param _relayerAction hash of the relayer action
  ///@param _gasUsage gas usage
  function updateGasUsageToAction(bytes32 _relayerAction, uint256 _gasUsage) public onlyOwner {
    actionToGasUsage[_relayerAction] = _gasUsage;
  }

  ///@notice Collect ETH from the contract, this for paying keeper services
  function collectEth(address payable _recipient) external onlyOwner {
    uint256 ethBalance = address(this).balance;
    (bool sent,) = _recipient.call{value: ethBalance}("");
    require(sent);
  }

  /*//////////////////////////////////////////////////////////////
                            EXT USER ENTRY POINT
    //////////////////////////////////////////////////////////////*/

  ///@notice Entry function for requesting a deposit, can be a standard deposit or a governance
  /// deposit
  ///@param _userRequest struct containing data
  ///@param _keepGovRights If true make a governance
  ///@param _minTRSYExpected Slippage parameter ensuring minimum amout of TRSY to be received
  ///@dev User have to forward some eth paying for the keeper
  ///     Once the function is called the request is stack on the queue
  function requestDeposit(
    UserRequest[] calldata _userRequest,
    bool _keepGovRights,
    uint256 _minTRSYExpected
  ) external payable whenNotPaused onlyUser {
    bytes32 actionHash = _keepGovRights
      ? keccak256(abi.encodePacked("Deposit_Governance_", _uint2str(_userRequest.length)))
      : keccak256(abi.encodePacked("Deposit_Standard_", _uint2str(_userRequest.length)));

    uint256 gasToForward = actionToGasUsage[actionHash];
    if (_keepGovRights) {
      bool userHasProxy = GOVERNANCE_MODULE.userToProxy(msg.sender) == address(0x0) ? false : true;
      gasToForward = userHasProxy
        ? gasToForward
        : actionToGasUsage[actionHash]
          + actionToGasUsage[keccak256(abi.encodePacked("Proxy_Creation"))];
    }

    gasToForward = gasToForward * oracleModule.getGweiPrice();

    if (msg.value < gasToForward) revert NotEnoughGas(msg.value, gasToForward);

    _checkNumberOfAsset(_userRequest.length);

    address[] memory assetIn = new address[](_userRequest.length);
    uint256[] memory amountIn = new uint256[](_userRequest.length);

    for (uint256 i; i < _userRequest.length; i++) {
      // Checks zero inputs
      _checkZeroValue(_userRequest[i].amount);
      _checkZeroAddress(_userRequest[i].asset);

      // Unpack data
      assetIn[i] = _userRequest[i].asset;
      amountIn[i] = _userRequest[i].amount;
    }

    // Length assetIn == amountIn
    _checkForConsistentLength(assetIn, amountIn);
    // Check not double assets
    _checkForDuplicates(assetIn);

    // Checks if asset is supported and not quarantined
    _checkIsSupported(assetIn);
    _checkIsNotQuarantined(assetIn);
    if (_keepGovRights) _checkIsAllowedInGov(assetIn);

    // Put request in queue, for deposits, assetOut and amountOut are set to empty array
    RequestData memory request = RequestData({
      // Id is only used for events purpose
      id: nonce,
      requestor: msg.sender,
      assetIn: assetIn,
      amountIn: amountIn,
      assetOut: new address[](0),
      amountOut: new uint256[](0),
      keepGovRights: _keepGovRights,
      slippageChecker: _minTRSYExpected
    });
    _enqueueRequest(request);

    emit DepositRequested(nonce, request);
    nonce++;
  }

  ///@notice Entry function for requesting a standard
  ///@param _userRequest struct containing data
  ///@param _maxTRSYToPay Slippage parameter ensure maximum amout of TRSY willing to pay
  ///@dev User have to forward some eth paying for the keeper
  ///     Once the function is called the request is stack on the queue
  function requestWithdraw(UserRequest[] calldata _userRequest, uint256 _maxTRSYToPay)
    external
    payable
    whenNotPaused
    onlyUser
  {
    bytes32 actionHash =
      keccak256(abi.encodePacked("Withdraw_Standard_", _uint2str(_userRequest.length)));
    uint256 gasToForward = actionToGasUsage[actionHash] * oracleModule.getGweiPrice();

    if (msg.value < gasToForward) revert NotEnoughGas(msg.value, gasToForward);

    _checkNumberOfAsset(_userRequest.length);

    address[] memory assetOut = new address[](_userRequest.length);
    uint256[] memory amountOut = new uint256[](_userRequest.length);

    for (uint256 i; i < _userRequest.length; i++) {
      // Checks zero inputs
      _checkZeroValue(_userRequest[i].amount);
      _checkZeroAddress(_userRequest[i].asset);

      assetOut[i] = _userRequest[i].asset;
      amountOut[i] = _userRequest[i].amount;
    }
    // Check not double assets
    _checkForDuplicates(assetOut);

    // Length assetIn == amountIn
    _checkForConsistentLength(assetOut, amountOut);

    // Checks asset is supported in Fyde
    _checkIsNotQuarantined(assetOut);
    _checkIsSupported(assetOut);

    // put request in queue, for withdraw, assetIn and amountIn are set to empty array
    RequestData memory request = RequestData({
      id: nonce,
      requestor: msg.sender,
      assetIn: new address[](0),
      amountIn: new uint256[](0),
      assetOut: assetOut,
      amountOut: amountOut,
      keepGovRights: false,
      slippageChecker: _maxTRSYToPay
    });

    _enqueueRequest(request);

    emit WithdrawRequested(nonce, request);
    nonce++;
  }

  ///@notice Function used by user to make a (single-token) withdrawal from their governance proxy
  ///@param _userRequest struct containing data
  ///@param _user address of user who makes the withdraw
  ///@param _maxTRSYToPay maximum amout of stTRSY willing to pay, otherwise withdraw reverts
  ///@dev This function create a request that will be process by the keeper
  ///@dev owner of fyde can force withdraw for other users
  function requestGovernanceWithdraw(
    UserRequest memory _userRequest,
    address _user,
    uint256 _maxTRSYToPay
  ) external payable whenNotPaused onlyUser {
    bytes32 actionHash = keccak256(abi.encodePacked("Withdraw_Governance_1"));
    uint256 gasToForward = actionToGasUsage[actionHash] * oracleModule.getGweiPrice();

    if (msg.value < gasToForward) revert NotEnoughGas(msg.value, gasToForward);

    if (msg.sender != _user && msg.sender != owner) revert Unauthorized();

    address[] memory assetOut = new address[](1);
    uint256[] memory amountOut = new uint256[](1);

    // Checks zero inputs
    _checkZeroValue(_userRequest.amount);
    _checkZeroAddress(_userRequest.asset);

    assetOut[0] = _userRequest.asset;
    amountOut[0] = _userRequest.amount;

    // Checks asset is supported in Fyde
    _checkIsNotQuarantined(assetOut);
    _checkIsSupported(assetOut);

    // put request in queue, for withdraw, assetIn and amountIn are set to empty array
    RequestData memory request = RequestData({
      id: nonce,
      requestor: _user,
      assetIn: new address[](0),
      amountIn: new uint256[](0),
      assetOut: assetOut,
      amountOut: amountOut,
      keepGovRights: true,
      slippageChecker: _maxTRSYToPay
    });

    _enqueueRequest(request);

    emit WithdrawRequested(nonce, request);
    nonce++;
  }

  function getGasToForward(string memory action, bool isGovDeposit) external view returns (uint256) {
    bytes32 actionHash = keccak256(abi.encodePacked(action));
    uint256 gasToForward = actionToGasUsage[actionHash];
    if (isGovDeposit) {
      bool userHasProxy = GOVERNANCE_MODULE.userToProxy(msg.sender) == address(0x0) ? false : true;
      gasToForward = userHasProxy
        ? gasToForward
        : actionToGasUsage[actionHash]
          + actionToGasUsage[keccak256(abi.encodePacked("Proxy_Creation"))];
    }

    gasToForward = gasToForward * oracleModule.getGweiPrice();
    return gasToForward;
  }

  /*//////////////////////////////////////////////////////////////
                               SWAP
    //////////////////////////////////////////////////////////////*/

  function requestSwap(
    address _assetIn,
    uint256 _amountIn,
    address _assetOut,
    uint256 _minAmountOut
  ) external payable whenSwapNotPaused onlySwapper {
    // Gas comsumption
    bytes32 actionHash = keccak256(abi.encodePacked("Swap"));
    uint256 gasToForward = actionToGasUsage[actionHash] * oracleModule.getGweiPrice();

    if (msg.value < gasToForward) revert NotEnoughGas(msg.value, gasToForward);

    // Checks zero inputs
    _checkZeroValue(_amountIn);
    _checkZeroAddress(_assetIn);
    _checkZeroAddress(_assetOut);
    if (_assetIn == _assetOut) revert DuplicatesAssets();

    // Checks if asset is supported and not quarantined
    address[] memory assets = new address[](2);
    assets[0] = _assetIn;
    assets[1] = _assetOut;
    _checkIsSupported(assets);
    _checkIsNotQuarantined(assets);
    _checkIfSwapAllowed(assets);

    address[] memory assetIn = new address[](1);
    uint256[] memory amountIn = new uint256[](1);
    address[] memory assetOut = new address[](1);
    uint256[] memory amountOut = new uint256[](1);

    assetIn[0] = _assetIn;
    amountIn[0] = _amountIn;
    assetOut[0] = _assetOut;

    // put request in queue
    RequestData memory request = RequestData({
      id: nonce,
      requestor: msg.sender,
      assetIn: assetIn,
      amountIn: amountIn,
      assetOut: assetOut,
      amountOut: amountOut,
      keepGovRights: false,
      slippageChecker: _minAmountOut
    });

    _enqueueRequest(request);

    emit SwapRequested(nonce, request);
    nonce++;
  }

  /*//////////////////////////////////////////////////////////////
                            GELATO FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  ///@notice Check if there is pending request
  function checker_processRequest() external view returns (bool, bytes memory) {
    if (getNumPendingRequest() == 0) return (false, bytes("No pending request"));

    uint256 protocolAUM = fyde.computeProtocolAUM();

    return (true, abi.encodeCall(this.processRequests, (protocolAUM)));
  }

  ///@notice Batch process requests in queue
  ///@param _protocolAUM Computed by the keeper off chain
  ///@dev This function is called by the keeper parsing the AUM and will execute both deposits and
  /// withdraws
  function processRequests(uint256 _protocolAUM) external onlyKeeper whenNotPaused {
    uint256 nReq = getNumPendingRequest();
    if (nReq == 0) revert NoRequest();
    nReq = MAX_BATCH_SIZE >= nReq ? nReq : MAX_BATCH_SIZE;

    //collect management fee
    fyde.collectManagementFee();

    uint256 currentAUM = _protocolAUM;

    // Loop over requests and execute
    for (uint256 i; i < nReq; i++) {
      if (getRequest(0).assetIn.length > 0 && getRequest(0).assetOut.length == 0) {
        RequestData memory request = _dequeueRequest();

        // Deposit
        try fyde.processDeposit(currentAUM, request) returns (uint256 usdDeposit) {
          currentAUM += usdDeposit;
          emit ProcessRequestSuccess(request.id);
        } catch (bytes memory reason) {
          emit ProcessRequestFailed(request.id, reason);
        }
      } else if (getRequest(0).assetOut.length > 0 && getRequest(0).assetIn.length == 0) {
        RequestData memory request = _dequeueRequest();

        // Withdraw
        try fyde.processWithdraw(currentAUM, request) returns (uint256 usdWithdraw) {
          currentAUM -= usdWithdraw;
          emit ProcessRequestSuccess(request.id);
        } catch (bytes memory reason) {
          emit ProcessRequestFailed(request.id, reason);
        }
      } else if (getRequest(0).assetIn.length == 1 && getRequest(0).assetOut.length == 1) {
        RequestData memory request = _dequeueRequest();

        // Swap
        try fyde.processSwap(_protocolAUM, request) returns (int256 deltaAUM) {
          if (deltaAUM > 0) currentAUM += uint256(deltaAUM);
          else if (deltaAUM < 0) currentAUM -= uint256(-deltaAUM);
          else currentAUM = currentAUM;
          emit ProcessRequestSuccess(request.id);
        } catch (bytes memory reason) {
          emit ProcessRequestFailed(request.id, reason);
        }
      }
    }
  }

  ///@notice Offchain checker for gelato bot
  function checker_updateProtocolAUM() external view returns (bool, bytes memory) {
    uint256 aum = fyde.getProtocolAUM();
    uint256 nAum = fyde.computeProtocolAUM();

    if (aum == 0 && nAum != 0) return (true, abi.encodeCall(this.updateProtocolAUM, (nAum)));
    // Update if deviation threshold % (0.5 by default)  diff between on-chain and offchain
    if (PercentageMath._isInRange(aum, nAum, deviationThreshold)) {
      return (false, bytes("AUM is in range"));
    } else {
      return (true, abi.encodeCall(this.updateProtocolAUM, (nAum)));
    }
  }

  ///@notice Update the protocol AUM, called by Gelato Bot
  function updateProtocolAUM(uint256 nAum) external onlyKeeper {
    fyde.updateProtocolAUM(nAum);
  }
  /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/

  function _checkNumberOfAsset(uint256 userRequestLength) internal pure {
    if (userRequestLength > MAX_ASSET_TO_REQUEST || userRequestLength == 0) {
      revert IncorrectNumOfAsset();
    }
  }

  function _checkIsSupported(address[] memory _assets) internal view {
    address notSupportedAsset = fyde.isAnyNotSupported(_assets);
    if (notSupportedAsset != address(0x0)) revert AssetNotSupported(notSupportedAsset);
  }

  function _checkIsNotQuarantined(address[] memory _assets) internal view {
    address quarantinedAsset = isAnyQuarantined(_assets);
    if (quarantinedAsset != address(0x0)) revert AssetIsQuarantined(quarantinedAsset);
  }

  function _checkIsAllowedInGov(address[] memory _assets) internal view {
    address notAllowedInGovAsset = GOVERNANCE_MODULE.isAnyNotOnGovWhitelist(_assets);
    if (notAllowedInGovAsset != address(0x0)) {
      revert AssetNotAllowedInGovernancePool(notAllowedInGovAsset);
    }
  }

  function _checkForDuplicates(address[] memory _assetList) internal pure {
    for (uint256 idx; idx < _assetList.length - 1; idx++) {
      for (uint256 idx2 = idx + 1; idx2 < _assetList.length; idx2++) {
        if (_assetList[idx] == _assetList[idx2]) revert DuplicatesAssets();
      }
    }
  }

  function _checkIfSwapAllowed(address[] memory _assets) internal view {
    address notAllowedAsset = fyde.isSwapAllowed(_assets);
    if (notAllowedAsset != address(0x0)) revert SwapDisabled(notAllowedAsset);
  }

  function _uint2str(uint256 _i) internal pure returns (string memory) {
    if (_i == 0) return "0";
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  modifier whenNotPaused() {
    if (paused) revert ActionPaused();
    _;
  }

  modifier whenSwapNotPaused() {
    if (swapPaused) revert ActionPaused();
    _;
  }
}
