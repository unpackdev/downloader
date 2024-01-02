// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./CCIPReceiver.sol";
import "./IRouterClient.sol";
import "./Client.sol";

interface IWrapped {
  function deposit(uint256 amount) external;

  function withdraw(uint256 amount) external;
}

contract CCIPBridge is CCIPReceiver, Context, Ownable {
  using SafeERC20 for IERC20;

  uint64 constant MAINNET_SELECTOR = 5009297550715157269;
  address immutable MAINNET_BRIDGE;
  bool immutable SHOULD_WRAP;

  IERC20 _main = IERC20(0x85225Ed797fd4128Ac45A992C46eA4681a7A15dA);
  IWrapped _wrapped = IWrapped(0x4Dc3FDbb0a08395a71405Ae081dca1b52c6F9E7E);

  IRouterClient public router;
  mapping(uint64 => bool) public chains;

  modifier onlyWhitelistedChain(uint64 _chainSelector) {
    require(chains[_chainSelector], 'VCHAIN');
    _;
  }

  event TokensBridged(
    bytes32 indexed messageId,
    uint64 indexed destChainSelector,
    address receiver,
    address token,
    uint256 tokenAmount,
    address feeToken,
    uint256 fees
  );

  event TokensReceived(
    bytes32 indexed messageId,
    uint64 indexed sourceChainSelector,
    address receiver,
    address token,
    uint256 tokenAmount
  );

  constructor(
    IRouterClient _router,
    address _mainnetBridge,
    bool _shouldWrap
  ) CCIPReceiver(address(_router)) {
    router = _router;
    MAINNET_BRIDGE = _mainnetBridge;
    SHOULD_WRAP = _shouldWrap;
  }

  /// @notice Receive tokens to sender from the source chain.
  function _ccipReceive(
    Client.Any2EVMMessage memory _message
  ) internal override {
    address _bridger = abi.decode(_message.data, (address));
    require(_message.destTokenAmounts[0].token == address(_wrapped), 'VAL');
    _wrapped.withdraw(_message.destTokenAmounts[0].amount);
    _main.safeTransfer(_bridger, _message.destTokenAmounts[0].amount);
    emit TokensReceived(
      _message.messageId,
      _message.sourceChainSelector,
      _bridger,
      _message.destTokenAmounts[0].token,
      _message.destTokenAmounts[0].amount
    );
  }

  /// @notice Transfer tokens to receiver on the destination chain.
  /// @notice Pay in native gas such as ETH on Ethereum or MATIC on Polgon.
  /// @notice the token must be in the list of supported tokens.
  /// @param _destChainSelector The identifier (aka selector) for the destination blockchain.
  /// @param _receiver The address of the recipient on the destination blockchain.
  /// @param _token token address.
  /// @param _amount token amount.
  /// @return _messageId The ID of the message that was sent.
  function bridgeTokens(
    uint64 _destChainSelector,
    address _receiver,
    address _token,
    uint256 _amount
  )
    external
    payable
    onlyWhitelistedChain(_destChainSelector)
    returns (bytes32 _messageId)
  {
    require(_token == address(_main), 'VAL');
    IERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);
    address _bridgingToken = _token;
    if (SHOULD_WRAP) {
      IERC20(_token).safeIncreaseAllowance(address(_wrapped), _amount);
      _wrapped.deposit(_amount);
      _bridgingToken = address(_wrapped);
    }

    Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
      _destChainSelector,
      _receiver,
      _bridgingToken,
      _amount,
      address(0) // fees paid in native ETH
    );

    uint256 fees = router.getFee(_destChainSelector, evm2AnyMessage);
    require(msg.value >= fees, 'FEES');

    uint256 _refund = msg.value - fees;
    if (_refund > 0) {
      (bool _wasRef, ) = payable(_msgSender()).call{ value: _refund }('');
      require(_wasRef, 'REFUND');
    }

    IERC20(_bridgingToken).safeIncreaseAllowance(address(router), _amount);
    _messageId = router.ccipSend{ value: fees }(
      _destChainSelector,
      evm2AnyMessage
    );

    emit TokensBridged(
      _messageId,
      _destChainSelector,
      _receiver,
      _bridgingToken,
      _amount,
      address(0), // fees paid in native ETH
      fees
    );
    return _messageId;
  }

  /// @notice Gets the native gas fees to construct and send a message
  /// @param _destChainSelector The identifier (aka selector) for the destination blockchain.
  /// @param _receiver The address of the recipient on the destination blockchain.
  /// @param _amount token amount.
  /// @return _fees the native fees to send this message
  function getMessageFee(
    uint64 _destChainSelector,
    address _receiver,
    uint256 _amount
  ) external view returns (uint256) {
    Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
      _destChainSelector,
      _receiver,
      address(_wrapped),
      _amount,
      address(0) // fees paid in native ETH
    );
    return router.getFee(_destChainSelector, evm2AnyMessage);
  }

  /// @notice Construct a CCIP message.
  /// @dev This function will create an EVM2AnyMessage struct with all the necessary information for tokens transfer.
  /// @param _receiver The address of the receiver.
  /// @param _token The token to be transferred.
  /// @param _amount The amount of the token to be transferred.
  /// @param _feeToken The address of the token used for fees. Set address(0) for native gas.
  /// @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message.
  function _buildCCIPMessage(
    uint64 _destChainSelector,
    address _receiver,
    address _token,
    uint256 _amount,
    address _feeToken
  ) internal view returns (Client.EVM2AnyMessage memory) {
    bytes memory data;
    if (_destChainSelector == MAINNET_SELECTOR) {
      data = abi.encode(_receiver);
      _receiver = MAINNET_BRIDGE;
    }

    // Set the token amounts
    Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](
      1
    );
    Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
      token: _token,
      amount: _amount
    });
    tokenAmounts[0] = tokenAmount;

    Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
      receiver: abi.encode(_receiver), // ABI-encoded receiver address
      data: data,
      tokenAmounts: tokenAmounts, // The amount and type of token being transferred
      extraArgs: Client._argsToBytes(
        // Additional arguments, setting gas limit to 0 and non-strict sequencing mode
        Client.EVMExtraArgsV1({ gasLimit: 0, strict: false })
      ),
      feeToken: _feeToken
    });
    return evm2AnyMessage;
  }

  function setChain(
    uint64 _chainSelector,
    bool _isWhitelisted
  ) external onlyOwner {
    require(chains[_chainSelector] != _isWhitelisted, 'TOGGLE');
    chains[_chainSelector] = _isWhitelisted;
  }

  function setRouter(IRouterClient _router) external onlyOwner {
    router = _router;
  }
}
