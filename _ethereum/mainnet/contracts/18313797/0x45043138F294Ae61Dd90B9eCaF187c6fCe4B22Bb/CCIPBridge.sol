// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./IRouterClient.sol";
import "./Client.sol";

contract CCIPBridge is Context, Ownable {
  using SafeERC20 for IERC20;

  IRouterClient public router;
  mapping(uint64 => bool) public chains;

  modifier onlyWhitelistedChain(uint64 _chainSelector) {
    require(chains[_chainSelector], 'VCHAIN');
    _;
  }

  event TokensTransferred(
    bytes32 indexed messageId,
    uint64 indexed destChainSelector,
    address receiver,
    address token,
    uint256 tokenAmount,
    address feeToken,
    uint256 fees
  );

  constructor(address _router) {
    router = IRouterClient(_router);
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
    IERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);

    Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
      _receiver,
      _token,
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

    IERC20(_token).approve(address(router), _amount);
    _messageId = router.ccipSend{ value: fees }(
      _destChainSelector,
      evm2AnyMessage
    );

    // Emit an event with message details
    emit TokensTransferred(
      _messageId,
      _destChainSelector,
      _receiver,
      _token,
      _amount,
      address(0), // fees paid in native ETH
      fees
    );
    return _messageId;
  }

  /// @notice Gets the native gas fees to construct and send a message
  /// @param _destChainSelector The identifier (aka selector) for the destination blockchain.
  /// @param _receiver The address of the recipient on the destination blockchain.
  /// @param _token token address.
  /// @param _amount token amount.
  /// @return _fees the native fees to send this message
  function getMessageFee(
    uint64 _destChainSelector,
    address _receiver,
    address _token,
    uint256 _amount
  ) external view returns (uint256) {
    Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
      _receiver,
      _token,
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
    address _receiver,
    address _token,
    uint256 _amount,
    address _feeToken
  ) internal pure returns (Client.EVM2AnyMessage memory) {
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
      data: '', // No data
      tokenAmounts: tokenAmounts, // The amount and type of token being transferred
      extraArgs: Client._argsToBytes(
        // Additional arguments, setting gas limit to 0 as we are not sending any data and non-strict sequencing mode
        Client.EVMExtraArgsV1({ gasLimit: 0, strict: false })
      ),
      // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
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
}
