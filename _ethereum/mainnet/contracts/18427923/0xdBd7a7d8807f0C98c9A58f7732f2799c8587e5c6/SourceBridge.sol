/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

import "./IAxelarGateway.sol";
import "./IAxelarGasService.sol";
import "./IMulticall.sol";
import "./IRWALike.sol";
import "./StringAddressUtils.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract SourceBridge is Ownable, Pausable, IMulticall {
  /// @notice Mapping from destination chain to bridge address on that chain
  /// @dev Axelar uses the string representation of addresses, hence we store
  ///      the address as a string
  mapping(string => string) public destChainToContractAddr;

  /// @notice Token contract bridged by this contract
  IRWALike public immutable TOKEN;

  /// @notice Pointer  to AxelarGateway contract
  IAxelarGateway public immutable AXELAR_GATEWAY;

  /// @notice Pointer to AxelarGasService contract
  IAxelarGasService public immutable GAS_RECEIVER;

  /// @notice Versioning for payload
  bytes32 public constant VERSION = "1.0";

  /// @notice Monotonically increasing nonce for each transaction
  uint256 public nonce;

  /// @notice src Chain Id, used to salt txnHash on dst Chain
  uint256 public immutable CHAIN_ID;

  /**
   * @notice Constructor
   *
   * @param _token The address of the token bridged
   * @param _axelarGateway The address of the AxelarGateway contract
   * @param _gasService The address of the AxelarGasService contract
   * @param owner The owner of the contract
   */
  constructor(
    address _token,
    address _axelarGateway,
    address _gasService,
    address owner
  ) {
    TOKEN = IRWALike(_token);
    AXELAR_GATEWAY = IAxelarGateway(_axelarGateway);
    GAS_RECEIVER = IAxelarGasService(_gasService);
    _transferOwnership(owner);
    CHAIN_ID = block.chainid;
  }

  /**
   * @notice Burns tokens on the source Chain and calls AxelarGateway contract
   *         to mint tokens on the destination chain
   *
   * @param amount The amount of tokens to burn
   * @param destinationChain The destination chain to mint tokens on
   *
   * @dev The amount of tokens to mint is the same as the amount burned
   * @dev User must approve `amount` tokens to this contract before bridging
   */
  function burnAndCallAxelar(
    uint256 amount,
    string calldata destinationChain
  ) external payable whenNotPaused {
    // Ensure that some gas is sent
    if (msg.value == 0) {
      revert GasFeeTooLow();
    }

    // Ensure that amount bridged is not zero
    if (amount == 0) {
      revert CannotBridgeZero();
    }

    // Check destinationChain is correct
    string memory destContract = destChainToContractAddr[destinationChain];

    if (bytes(destContract).length == 0) {
      revert DestinationNotSupported();
    }

    // burn amount
    TOKEN.burnFrom(msg.sender, amount);

    bytes memory payload = abi.encode(
      VERSION,
      CHAIN_ID,
      msg.sender,
      amount,
      nonce++
    );

    _payGasAndCallContract(destinationChain, destContract, payload);
    emit BridgeInitiated(msg.sender, nonce - 1, CHAIN_ID, VERSION, amount);
  }

  /**
   * @notice Helper function that pays gas and calls the AxelarGateway contract
   *
   * @param destinationChain The destination chain to mint tokens on
   * @param destContract The contract address on the destination chain
   * @param payload The payload to send to the AxelarGateway contract
   */
  function _payGasAndCallContract(
    string calldata destinationChain,
    string memory destContract,
    bytes memory payload
  ) private {
    GAS_RECEIVER.payNativeGasForContractCall{value: msg.value}(
      address(this),
      destinationChain,
      destContract,
      payload,
      msg.sender
    );

    // Send all information to AxelarGateway contract.
    AXELAR_GATEWAY.callContract(destinationChain, destContract, payload);
  }

  /*//////////////////////////////////////////////////////////////
                          Admin Functions
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Sets the destination chain to contract address mapping
   *
   * @param destinationChain The destination chain
   * @param contractAddress The contract address on the destination chain
   *
   * @dev Chain name must come from list of supported chains
   *      at https://docs.axelar.dev/dev/reference/mainnet-chain-names
   */
  function setDestinationChainContractAddress(
    string calldata destinationChain,
    address contractAddress
  ) external onlyOwner {
    destChainToContractAddr[destinationChain] = AddressToString.toString(
      contractAddress
    );
    emit DestinationChainContractAddressSet(destinationChain, contractAddress);
  }

  /**
   * @notice Deletes an entry w/n the destination chain to contract address
   *         mapping
   *
   * @param destinationChain The destination chain to disallow
   */
  function removeDestinationChainContractAddress(
    string calldata destinationChain
  ) external onlyOwner {
    delete destChainToContractAddr[destinationChain];
    emit ChainSupportRemoved(destinationChain);
  }

  /**
   * @notice Admin function to pause the contract
   *
   * @dev Only used for bridge functions
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Admin function to unpause the contract
   *
   * @dev Only used for bridge functions
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice Allows for arbitrary batched calls
   *
   * @dev All external calls made through this function will
   *      msg.sender == contract address
   *
   * @param exCallData Struct consisting of
   *       1) target - contract to call
   *       2) data - data to call target with
   *       3) value - eth value to call target with
   */
  function multiexcall(
    ExCallData[] calldata exCallData
  ) external payable override onlyOwner returns (bytes[] memory results) {
    results = new bytes[](exCallData.length);
    for (uint256 i = 0; i < exCallData.length; ++i) {
      (bool success, bytes memory ret) = address(exCallData[i].target).call{
        value: exCallData[i].value
      }(exCallData[i].data);
      require(success, "Call Failed");
      results[i] = ret;
    }
  }

  /*//////////////////////////////////////////////////////////////
                           Events & Errors
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Event emitted when the destination chain to contract address mapping is set
   *
   * @param destinationChain The destination chain
   * @param contractAddress The contract address on the destination chain
   */
  event DestinationChainContractAddressSet(
    string indexed destinationChain,
    address contractAddress
  );

  /**
   * @notice Event emitted when a message is passed to an Axelar gateway
   *
   * @param user    The account initiating the msg pass
   * @param nonce   The nonce of the src bridge for this msg pass
   * @param chainId The chainId of the chain which the src bridge is deployed to
   * @param version The payload version
   * @param amount  The amount field in the msg being passed
   */
  event BridgeInitiated(
    address indexed user,
    uint256 indexed nonce,
    uint256 indexed chainId,
    bytes32 version,
    uint256 amount
  );
  /**
   * @notice Event emitted when the destination chain to contract address mapping is
   *         deleted
   *
   * @param destinationChain The destination chain to be removed;
   */
  event ChainSupportRemoved(string indexed destinationChain);

  // Errors
  error DestinationNotSupported();
  error GasFeeTooLow();
  error CannotBridgeZero();
}
