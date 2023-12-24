// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

import "./IPortal.sol";
import "./StateUpdateLibrary.sol";
import "./IAssetChainManager.sol";
import "./IRollup.sol";
import "./Id.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

/// @title Portal
/// @author Arseniy Klempner
/// @notice Deployed on each chain supported by the protocol. Traders use the Portal to deposit funds that become
/// collateralized for trading on an off-chain orderbook (participating interface). When traders wish to withdraw, they
/// request settlement through this contract.
contract Portal is IPortal {
    using SafeERC20 for IERC20;
    using IdLib for Id;

    /// Stores an incremental identifier assigned to each Deposit and SettlementRequest that occurs on this chain.
    Id public chainSequenceId = ID_ZERO;
    address immutable participatingInterface;
    IAssetChainManager immutable manager;
    bool public depositsPaused = false;

    /// Maps hashes of deposits to the deposit record
    mapping(bytes32 => StateUpdateLibrary.Deposit) public deposits;
    /// Maps hashes of deposits to a flag indicating if they've been rejected
    mapping(bytes32 => bool) public rejectedDeposits;
    /// Maps chain sequence ID to record of settlement request
    mapping(Id => StateUpdateLibrary.SettlementRequest) public settlementRequests;

    event DepositUtxo(
        address wallet, uint256 amount, address token, address participatingInterface, Id chainSequenceId, bytes32 utxo
    );

    error CALLER_NOT_ROLLUP();
    error INSUFFICIENT_BALANCE_TOKEN();
    error INSUFFICIENT_BALANCE_OBLIGATION();
    error INSUFFICIENT_BALANCE_WITHDRAW();
    error TRANSFER_FAILED_WITHDRAW();
    error TOKEN_TRANSFER_FAILED_WITHDRAW();

    // Alpha compatibility
    event Deposit(address wallet, uint256 amount, address token, Id chainSequenceId);
    event SettlementRequested(address trader, address token, Id chainSequenceId);
    event SettlementProcessed(address trader, address token, uint256 amount);
    event RejectedDeposit(address trader, address asset, uint256 amount);
    event Withdraw(address wallet, uint256 amount, address token);
    event WithdrawRejectedDeposit(address wallet, uint256 amount, address token);
    event DepositsPaused();
    event DepositsResumed();

    mapping(address => uint256) public collateralized;
    mapping(address => mapping(address => uint256)) public settled;
    mapping(address => mapping(address => uint256)) public rejected;

    constructor(address _participatingInterface, address _manager) {
        participatingInterface = _participatingInterface;
        manager = IAssetChainManager(_manager);
    }

    function pauseDeposits() external {
        if (msg.sender != manager.admin()) revert();
        depositsPaused = true;
        emit DepositsPaused();
    }

    function resumeDeposits() external {
        if (msg.sender != manager.admin()) revert();
        depositsPaused = false;
        emit DepositsResumed();
    }

    /// Called by a trader to deposit the native asset of this chain for trading on the participating interface.
    /// Generates a record of deposit that is broadcast to the participating interface and validators.
    /// The participating interface must acknowledge or reject this deposit in a SignedStateUpdate broadcast to
    /// validators.
    function depositNativeAsset() external payable {
        if (depositsPaused) revert();
        if (!manager.supportedAsset(address(0))) revert("Native asset is not supported");
        if (msg.value < manager.getMinimumDeposit(address(0))) revert("Below minimum deposit");
        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            msg.sender, address(0), participatingInterface, msg.value, chainSequenceId, Id.wrap(block.chainid)
        );
        bytes32 utxo = keccak256(abi.encode(deposit));
        deposits[utxo] = deposit;
        unchecked {
            collateralized[address(0)] += msg.value;
        }
        emit DepositUtxo(msg.sender, msg.value, address(0), participatingInterface, chainSequenceId, utxo);
        chainSequenceId = chainSequenceId.increment();
    }

    /// Called by a trader to deposit an ERC20 token for trading on the participating interface.
    /// Generates a record of deposit that is broadcast to the participating interface and validators.
    /// The participating interface must acknowledge or reject this deposit in a SignedStateUpdate broadcast to
    /// validators.
    /// @param _token Address of the token to deposit
    /// @param _amount Amount of the token to deposit
    function depositToken(address _token, uint256 _amount) external {
        if (depositsPaused) revert();
        if (!manager.supportedAsset(_token)) revert("Asset is not supported");
        if (_amount < manager.getMinimumDeposit(_token)) revert("Below minimum deposit");
        StateUpdateLibrary.Deposit memory deposit = StateUpdateLibrary.Deposit(
            msg.sender, _token, participatingInterface, _amount, chainSequenceId, Id.wrap(block.chainid)
        );
        bytes32 utxo = keccak256(abi.encode(deposit));
        deposits[utxo] = deposit;
        unchecked {
            collateralized[_token] += _amount;
        }
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        emit DepositUtxo(msg.sender, _amount, _token, participatingInterface, chainSequenceId, utxo);
        chainSequenceId = chainSequenceId.increment();
    }

    /// Called by a trader to request settlement of an asset by the participating interface.
    /// Creates an on-chain record and emits an event to the participating interface and validators.
    /// After enough confirmations, the participating interface is expected to broadcast a SignedStateUpdate to
    /// validators with the trader's balance at the time the settlement was processed. The validator will include the
    /// state update in a state root in the Rollup contract of the processing chain. Once processsed, the obligation
    /// data will be relayed to this contract, allowing the trader to withdraw.
    /// @param _token Address of the asset being requested (address(0) for the native asset)
    function requestSettlement(address _token) external {
        if (!manager.supportedAsset(_token)) revert("Asset is not supported");
        settlementRequests[chainSequenceId] = StateUpdateLibrary.SettlementRequest(
            msg.sender, _token, participatingInterface, chainSequenceId, Id.wrap(block.chainid)
        );
        emit SettlementRequested(msg.sender, _token, chainSequenceId);
        chainSequenceId = chainSequenceId.increment();
    }

    /// Called by AssetChainLz after receiving obligation data from the Rollup contract on the processing chain via
    /// LayerZero. Moves amounts of assets from collateralized to settled, where they can then be withdrawn by the
    /// trader who received the obligation as a result of the settlement.
    function writeObligations(Obligation[] calldata obligations) external {
        if (msg.sender != manager.receiver()) {
            revert("Only receiver can write obligations");
        }
        for (uint256 i = 0; i < obligations.length; i++) {
            if (collateralized[obligations[i].asset] < obligations[i].amount) revert INSUFFICIENT_BALANCE_OBLIGATION();

            collateralized[obligations[i].asset] -= obligations[i].amount;
            settled[obligations[i].recipient][obligations[i].asset] += obligations[i].amount;
            emit SettlementProcessed(obligations[i].recipient, obligations[i].asset, obligations[i].amount);
        }
    }

    /// Called by a trader to withdraw settled funds.
    function withdraw(uint256 _amount, address _token) external {
        if (settled[msg.sender][_token] < _amount) revert INSUFFICIENT_BALANCE_WITHDRAW();

        unchecked {
            settled[msg.sender][_token] -= _amount;
        }

        if (_token == address(0)) {
            (bool success,) = msg.sender.call{ value: _amount }("");
            if (!success) revert TRANSFER_FAILED_WITHDRAW();
        } else {
            IERC20(_token).safeTransfer(msg.sender, _amount);
        }
        emit Withdraw(msg.sender, _amount, _token);
    }

    /// Called by AsssetChainLz after receiving hashes of rejected deposits from the Rollup contract on the processing
    /// chain via LayerZero. Moves amounts from collateralized to rejected, allowing the original depositor to withdraw
    /// those funds.
    function rejectDeposits(bytes32[] calldata _depositHashes) external {
        if (msg.sender != manager.receiver()) revert("Only receiver can reject deposits");
        for (uint256 i = 0; i < _depositHashes.length; i++) {
            StateUpdateLibrary.Deposit memory deposit = deposits[_depositHashes[i]];
            if (deposit.amount == 0) revert("Deposit hash does not exist");
            if (rejectedDeposits[_depositHashes[i]]) revert("Deposit already rejected");
            if (collateralized[deposit.asset] < deposit.amount) revert("Insufficient balance");
            rejected[deposit.trader][deposit.asset] += deposit.amount;
            collateralized[deposit.asset] -= deposit.amount;
            rejectedDeposits[_depositHashes[i]] = true;
            emit RejectedDeposit(deposit.trader, deposit.asset, deposit.amount);
        }
    }

    /// Called by a depositor to withdraw funds that have been rejected by the participating interface.
    function withdrawRejected(uint256 _amount, address _token) external {
        if (rejected[msg.sender][_token] < _amount) revert INSUFFICIENT_BALANCE_WITHDRAW();

        unchecked {
            rejected[msg.sender][_token] -= _amount;
        }

        if (_token == address(0)) {
            (bool success,) = msg.sender.call{ value: _amount }("");
            if (!success) revert TRANSFER_FAILED_WITHDRAW();
        } else {
           IERC20(_token).safeTransfer(msg.sender, _amount);
        }
        emit WithdrawRejectedDeposit(msg.sender, _amount, _token);
    }

    function getAvailableBalance(address _trader, address _token) external view returns (uint256) {
        return settled[_trader][_token];
    }
}
