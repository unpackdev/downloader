// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title IConnext
 *
 * @notice Defines the common interfaces and data types used
 * to interact with Connext Amarok.
 */

/**
 * @notice These are the parameters that will remain constant between the
 * two chains. They are supplied on `xcall` and should be asserted on `execute`
 * @property to - The account that receives funds, in the event of a crosschain call,
 * will receive funds if the call fails.
 *
 * @param originDomain - The originating domain (i.e. where `xcall` is called). Must match nomad domain schema
 * @param destinationDomain - The final domain (i.e. where `execute` / `reconcile` are called). Must match nomad domain schema
 * @param canonicalDomain - The canonical domain of the asset you are bridging
 * @param to - The address you are sending funds (and potentially data) to
 * @param delegate - An address who can execute txs on behalf of `to`, in addition to allowing relayers
 * @param receiveLocal - If true, will use the local nomad asset on the destination instead of adopted.
 * @param callData - The data to execute on the receiving chain. If no crosschain call is needed, then leave empty.
 * @param slippage - Slippage user is willing to accept from original amount in expressed in BPS (i.e. if
 * a user takes 1% slippage, this is expressed as 1_000)
 * @param originSender - The msg.sender of the xcall
 * @param bridgedAmt - The amount sent over the bridge (after potential AMM on xcall)
 * @param normalizedIn - The amount sent to `xcall`, normalized to 18 decimals
 * @param nonce - The nonce on the origin domain used to ensure the transferIds are unique
 * @param canonicalId - The unique identifier of the canonical token corresponding to bridge assets
 */
struct TransferInfo {
  uint32 originDomain;
  uint32 destinationDomain;
  uint32 canonicalDomain;
  address to;
  address delegate;
  bool receiveLocal;
  bytes callData;
  uint256 slippage;
  address originSender;
  uint256 bridgedAmt;
  uint256 normalizedIn;
  uint256 nonce;
  bytes32 canonicalId;
}

/**
 * @notice
 * @param params - The TransferInfo. These are consistent across sending and receiving chains.
 * @param routers - The routers who you are sending the funds on behalf of.
 * @param routerSignatures - Signatures belonging to the routers indicating permission to use funds
 * for the signed transfer ID.
 * @param sequencer - The sequencer who assigned the router path to this transfer.
 * @param sequencerSignature - Signature produced by the sequencer for path assignment accountability
 * for the path that was signed.
 */
struct ExecuteArgs {
  TransferInfo params;
  address[] routers;
  bytes[] routerSignatures;
  address sequencer;
  bytes sequencerSignature;
}

interface IConnext {
  /**
   * @notice Initiates a cross-chain transfer of funds, calldata, and/or various named properties.
   *
   * @param _destination the destination chain's Domain ID
   * @param _to  target address on the destination chain
   * @param _asset contract address of the asset to be bridged
   * @param _delegate address with rights to update slippage tolerance
   * @param _amount  amount of tokens to bridge specified in wei units
   * @param _slippage maximum slippage a user is willing to take, in BPS (e.g. 3 = 0.03%)
   * @param _callData to send
   */
  function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
  )
    external
    payable
    returns (bytes32);

  /**
   * @notice Called on a destination domain to disburse correct assets to end
   * recipient and execute any included calldata
   *
   * @param _args ExecuteArgs arguments
   */
  function execute(ExecuteArgs calldata _args)
    external
    returns (bool success, bytes memory returnData);

  /**
   * @notice Call this function on the origin domain to increase the relayer fee for a transfer
   *
   * @param transferId unique identifier of the crosschain transaction
   */
  function bumpTransfer(bytes32 transferId) external payable;

  /**
   * @notice Allows a user-specified account (delegate in xcall) to update the slippage
   *
   * @param _params TransferInfo associated with the transfer
   * @param _slippage the updated slippage
   */
  function forceUpdateSlippage(TransferInfo calldata _params, uint256 _slippage) external;
}

interface IXReceiver {
  /**
   * @notice Interface that the Connext contracts call into on the _to address specified during xcall.
   *
   * @param _transferId unique id of the xchain transaction
   * @param _amount of token
   * @param _asset address of token
   * @param _originSender address of the contract or EOA that called xcall
   * @param _origin domain ID of the chain that the transaction is coming from
   * @param _callData data passed into xcall on the origin chain
   */
  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory _callData
  )
    external
    returns (bytes memory);
}
