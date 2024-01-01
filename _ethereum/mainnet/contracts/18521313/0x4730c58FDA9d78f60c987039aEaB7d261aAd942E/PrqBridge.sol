// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./IDeBridgeGate.sol";
import "./Flags.sol";
import "./ICallProxy.sol";
import "./ITokenController.sol";
import "./ReentrancyGuard.sol";

contract PrqBridge is Ownable, ReentrancyGuard {
  /**
   * @notice Reverts when chain contract address is not specified
   */
  error ChainContractAddressNotSpecified();

  /**
   * @notice Reverts when chain id does not match
   * @param expected Expected chain id
   * @param actual Actual chain id
   */
  error ChainMismatch(uint256 expected, uint256 actual);

  /**
   * @notice Reverts when cross-chain caller is not a proxy
   * @param proxyAddress Proxy address
   * @param callerAddress Caller address
   */
  error OnlyProxyCanBeACaller(address proxyAddress, address callerAddress);

  /**
   * @notice Reverts when sender is not the expected one
   */
  error WrongSender();

  /**
   * @notice Reverts when fees are not covered
   * @param required Required amount
   * @param provided Provided amount
   */
  error FeesAreNotCovered(uint256 required, uint256 provided);

  IDeBridgeGate public deBridgeGate;
  uint256 public immutable currentChainId;

  mapping(uint256 => address) public counterChainContract;

  ITokenController public tokenController;

  modifier checkChainContract(uint256 _chainId) {
    if (counterChainContract[_chainId] == address(0)) {
      revert ChainContractAddressNotSpecified();
    }
    _;
  }

  constructor(IDeBridgeGate _deBridgeGate, ITokenController _tokenController) Ownable() {
    deBridgeGate = _deBridgeGate;
    tokenController = _tokenController;
    currentChainId = block.chainid;
  }

  /**
   * @dev Send tokens to another chain
   * @param _toChainID Chain id of the destination chain
   * @param _amount Amount of tokens to send
   * @param _recipient Address of the recipient on the destination chain
   */
  function sendToChain(uint256 _toChainID, uint256 _amount, address _recipient) external payable nonReentrant checkChainContract(_toChainID) {
    tokenController.reserveTokens(_msgSender(), _amount);

    bytes memory dstTxCall = _encodeUnlockCommand(_amount, _recipient);
    _send(dstTxCall, _toChainID, 0);
  }

  /**
   * @dev Unlock tokens from another chain
   * @param _fromChainID Chain id of the source chain
   * @param _amount Amount of tokens to unlock
   * @param _recipient Address of the recipient on the destination chain
   */
  function unlock(uint256 _fromChainID, uint256 _amount, address _recipient) external checkChainContract(_fromChainID) {
    _onlyCrossChain(_fromChainID);

    tokenController.releaseTokens(_recipient, _amount);
  }

  /**
   * @dev Validates that the call is coming from the CallProxy contract
   * @param _fromChainID Chain id of the source chain
   */
  function _onlyCrossChain(uint256 _fromChainID) internal {
    ICallProxy callProxy = ICallProxy(deBridgeGate.callProxy());

    // caller is CallProxy?
    if (address(callProxy) != _msgSender()) {
      revert OnlyProxyCanBeACaller(address(callProxy), _msgSender());
    }

    if (callProxy.submissionChainIdFrom() != _fromChainID) {
      revert ChainMismatch(callProxy.submissionChainIdFrom(), _fromChainID);
    }

    bytes memory nativeSender = callProxy.submissionNativeSender();

    if (keccak256(abi.encodePacked(counterChainContract[_fromChainID])) != keccak256(nativeSender)) {
      revert WrongSender();
    }
  }

  /**
   * @dev Encodes the unlock command to be sent to the destination chain
   * @param _amount Amount of tokens to unlock
   * @param _recipient Address of the recipient on the destination chain
   */
  function _encodeUnlockCommand(uint256 _amount, address _recipient) view internal returns (bytes memory) {
    return
      abi.encodeWithSelector(
      this.unlock.selector,
      currentChainId,
      _amount,
      _recipient
    );
  }

  /**
   * @dev Sends a transaction to the destination chain
   * @param _dstTransactionCall Destination transaction call
   * @param _toChainId Chain id of the destination chain
   * @param _executionFee Execution fee to be paid to the executor
   */
  function _send(bytes memory _dstTransactionCall, uint256 _toChainId, uint256 _executionFee) internal {
    //
    // sanity checks
    //
    uint256 protocolFee = deBridgeGate.globalFixedNativeFee();
    uint256 totalFee = protocolFee + _executionFee;

    if (msg.value < totalFee) {
      revert FeesAreNotCovered(msg.value, totalFee);
    }

    // we bridge as much asset as specified in the _executionFee arg
    // (i.e. bridging the minimum necessary amount to to cover the cost of execution)
    // However, deBridge cuts a small fee off the bridged asset, so
    // we must ensure that executionFee < amountToBridge
    uint assetFeeBps = deBridgeGate.globalTransferFeeBps();
    uint amountToBridge = _executionFee;
    uint amountAfterBridge = amountToBridge * (10000 - assetFeeBps) / 10000;

    //
    // start configuring a message
    //
    IDeBridgeGate.SubmissionAutoParamsTo memory autoParams;

    // use the whole amountAfterBridge as the execution fee to be paid to the executor
    autoParams.executionFee = amountAfterBridge;

    // Exposing nativeSender must be requested explicitly
    // We request it bc of CrossChainCounter's onlyCrossChainIncrementor modifier
    autoParams.flags = Flags.setFlag(
      autoParams.flags,
      Flags.PROXY_WITH_SENDER,
      true
    );

    // if something happens, we need to revert the transaction, otherwise the sender will loose assets
    autoParams.flags = Flags.setFlag(
      autoParams.flags,
      Flags.REVERT_IF_EXTERNAL_FAIL,
      true
    );

    autoParams.data = _dstTransactionCall;
    autoParams.fallbackAddress = abi.encodePacked(_msgSender());

    deBridgeGate.send{value: msg.value}(
      address(0), // _tokenAddress
      amountToBridge, // _amount
      _toChainId, // _chainIdTo
      abi.encodePacked(counterChainContract[_toChainId]), // _receiver
      "", // _permit
      true, // _useAssetFee
      0, // _referralCode
      abi.encode(autoParams) // _autoParams
    );
  }

  /**
   * @dev Sets the DeBridgeGate contract address
   * @param _deBridgeGate DeBridgeGate contract address
   */
  function setDeBridgeGate(IDeBridgeGate _deBridgeGate) external onlyOwner {
    deBridgeGate = _deBridgeGate;
  }

  /**
   * @dev Sets the TokenController contract address
   * @param _tokenController TokenController contract address
   */
  function setTokenController(ITokenController _tokenController) external onlyOwner {
    tokenController = _tokenController;
  }

  /**
   * @dev Sets the contract address for a specific chain
   * @param _chainId Chain id
   * @param _contract Contract address
   */
  function setCounterChainContract(uint256 _chainId, address _contract) external onlyOwner {
    counterChainContract[_chainId] = _contract;
  }
}
