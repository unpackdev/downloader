// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./SafeERC20.sol";
import "./Math.sol";
import "./Initializable.sol";

import "./RelayerRegistry.sol";
import "./InstanceRegistry.sol";
import "./ITornadoInstance.sol";
import "./Tornado.sol";
import "./ITornadoTrees.sol";

contract PGRouter is Initializable {
  using SafeERC20 for IERC20;

  event EncryptedNote(address indexed sender, bytes encryptedNote);
  event TornadoTreesUpdated(ITornadoTrees addr);
  event NewGovernanceAddressUpdated(address newGovernanceAddress);

  address public governance;
  InstanceRegistry public instanceRegistry;
  RelayerRegistry public relayerRegistry;
  ITornadoTrees public tornadoTrees;

  modifier onlyGovernance() {
    require(msg.sender == governance, "Not authorized");
    _;
  }

  modifier onlyInstanceRegistry() {
    require(msg.sender == address(instanceRegistry), "Not authorized");
    _;
  }

  constructor(address _tornadoTrees, address _governance, address _instanceRegistry, address _relayerRegistry) {
    tornadoTrees = ITornadoTrees(_tornadoTrees);
    governance = _governance;
    instanceRegistry = InstanceRegistry(_instanceRegistry);
    relayerRegistry = RelayerRegistry(_relayerRegistry);
  }

  /**
    @notice For proxy pattern
  */
  function initialize(
    address _tornadoTrees,
    address _governance,
    address _instanceRegistry,
    address _relayerRegistry
  ) public initializer {
    tornadoTrees = ITornadoTrees(_tornadoTrees);
    governance = _governance;
    instanceRegistry = InstanceRegistry(_instanceRegistry);
    relayerRegistry = RelayerRegistry(_relayerRegistry);
  }

  /**
    @notice Deposit funds into the contract.
    @param _tornado PortralGate pool instance address
    @param _commitment the note commitment, which is PedersenHash(nullifier + secret)
    @param _encryptedNote the encrypted note
    @param sender the sender address (used in cases when the sender is not the caller e.g. zapper contract)
  */
  function deposit(
    ITornadoInstance _tornado,
    bytes32 _commitment,
    bytes memory _encryptedNote,
    address sender
  ) public payable virtual {
    (bool isERC20, IERC20 token, InstanceRegistry.InstanceState state, , , uint256 maxDepositAmount) = instanceRegistry.instances(
      _tornado
    );
    require(state != InstanceRegistry.InstanceState.DISABLED, "The instance is not supported");
    require(token.balanceOf(address(_tornado)) < maxDepositAmount, "Exceed deposit Cap for the pool");

    if (isERC20) {
      token.safeTransferFrom(msg.sender, address(this), _tornado.denomination());
    }
    _tornado.deposit{ value: msg.value }(_commitment);

    if (state == InstanceRegistry.InstanceState.MINABLE) {
      tornadoTrees.registerDeposit(address(_tornado), _commitment);
    }

    emit EncryptedNote(sender, _encryptedNote);
  }

  /**
    @notice Withdraw a deposit from the contract. Relayer withdrawn should have different _relayer and _recipient addresses.
    @param _tornado TC pool instance address
    @param _proof is a zkSNARK proof data, and input is an array of circuit public inputs `input` array
    @param _root merkle root of all deposits in the contract
    @param _nullifierHash hash of unique deposit nullifier to prevent double spends
    @param _recipient the recipient address to recieve the token
    @param _relayer the relayer address
    @param _fee the token amount sent to relayer as fee
    @param _refund the eth amount sent to recipient as gas
  */
  function withdraw(
    ITornadoInstance _tornado,
    bytes calldata _proof,
    bytes32 _root,
    bytes32 _nullifierHash,
    address payable _recipient,
    address payable _relayer,
    uint256 _fee,
    uint256 _refund
  ) public payable virtual {
    (, , InstanceRegistry.InstanceState state, , , ) = instanceRegistry.instances(_tornado);
    require(state != InstanceRegistry.InstanceState.DISABLED, "The instance is not supported");

    if (_relayer != _recipient) {
      require(relayerRegistry.isRelayerRegistered(_relayer) && msg.sender == _relayer, "Invalid Relayer.");
    }

    _tornado.withdraw{ value: msg.value }(_proof, _root, _nullifierHash, _recipient, _relayer, _fee, _refund);

    if (state == InstanceRegistry.InstanceState.MINABLE) {
      tornadoTrees.registerWithdrawal(address(_tornado), _nullifierHash);
    }
  }

  /**
   @dev Sets `amount` allowance of `_spender` over the router's (this contract) tokens.
  */
  function approveExactToken(IERC20 _token, address _spender, uint256 _amount) external onlyInstanceRegistry {
    _token.safeApprove(_spender, _amount);
  }

  /**
   @notice Manually backup encrypted notes
  */
  function backupNotes(bytes[] calldata _encryptedNotes) external virtual {
    for (uint256 i = 0; i < _encryptedNotes.length; i++) {
      emit EncryptedNote(msg.sender, _encryptedNotes[i]);
    }
  }

  /**
    @dev Update new tornado tree instance.
    @param _tornadoTrees new tornado tree instance address
  */
  function setTornadoTreesContract(ITornadoTrees _tornadoTrees) external virtual onlyGovernance {
    tornadoTrees = _tornadoTrees;
    emit TornadoTreesUpdated(_tornadoTrees);
  }

  /**
    @notice Set new governance address.
    @param _govAddr new governance address
  */
  function setNewGovernance(address _govAddr) external onlyGovernance {
    require(_govAddr != address(0), "Empty governance address.");
    governance = _govAddr;
    emit NewGovernanceAddressUpdated(_govAddr);
  }

  /// @dev Method to claim junk and accidentally sent tokens
  function rescueTokens(IERC20 _token, address payable _to, uint256 _amount) external virtual onlyGovernance {
    require(_to != address(0), "PG: can not send to zero address");

    if (address(_token) == address(0)) {
      // for Ether
      uint256 totalBalance = address(this).balance;
      uint256 balance = Math.min(totalBalance, _amount);
      (bool sent, ) = _to.call{ value: balance }("");
      require(sent, "Failed to send Ether");
    } else {
      // any other erc20
      uint256 totalBalance = _token.balanceOf(address(this));
      uint256 balance = Math.min(totalBalance, _amount);
      require(balance > 0, "PG: trying to send 0 balance");
      _token.safeTransfer(_to, balance);
    }
  }
}
