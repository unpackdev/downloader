// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./TrieProofs.sol";
import "./RLP.sol";

import "./Multicall.sol";

import "./ERC20.sol";
import "./ECDSA.sol";

contract WrappedPoWETH is ERC20, Multicall {
    using TrieProofs for bytes;
    using RLP for RLP.RLPItem;
    using RLP for bytes;

    event Withdrawal(uint256 id, uint256 amount, address withdrawMadeBy, address recipient);
    event StateRootRelay(uint256 block, bytes32 root);

    uint8 private constant ACCOUNT_STORAGE_ROOT_INDEX = 2;

    address public immutable relayer;
    address public immutable depositContract;
    uint256 public immutable depositsMapSlotIndex;

    uint256 public withdrawalsCount;
    mapping(uint256 => bytes32) public withdrawals;

    mapping(uint256 => bytes32) public stateRoots;
    mapping(uint256 => bytes32) public depositContractStorageRoots;

    mapping(uint256 => bool) public processedDeposits;

    uint256 private constant ONE = 10**18;
    uint256 public constant mintFeeRate = ONE / 100; // 1/100 = 1%.
    address public constant feeRecipient = 0xF9c89ee442cE6D2c14b9dB97f367E0A72657271f;

    uint256 public feesAccrued;

    constructor(
        address _relayer,
        address _depositContract,
        uint256 _depositsMapSlotIndex
    ) ERC20("WrappedPoWETH", "WPOWETH") {
        relayer = _relayer;
        depositContract = _depositContract;
        depositsMapSlotIndex = _depositsMapSlotIndex;
    }

    function updateDepositContractStorageRoot(uint256 blockNumber, bytes memory accountProof) public {
        bytes32 stateRoot = stateRoots[blockNumber];
        require(stateRoot != bytes32(0), "ERR_STATE_ROOT_NOT_AVAILABLE");

        bytes32 accountProofPath = keccak256(abi.encodePacked(depositContract));
        bytes memory accountRLP = accountProof.verify(stateRoot, accountProofPath); // reverts if proof is invalid
        bytes32 accountStorageRoot = bytes32(accountRLP.toRLPItem().toList()[ACCOUNT_STORAGE_ROOT_INDEX].toUint());

        depositContractStorageRoots[blockNumber] = accountStorageRoot;
    }

    function mint(
        uint256 depositId,
        address recipient,
        uint256 amount,
        uint256 depositBlockNumber,
        bytes memory storageProof
    ) public {
        bytes32 accountStorageRoot = depositContractStorageRoots[depositBlockNumber];
        require(accountStorageRoot != bytes32(0), "ERR_STORAGE_ROOT_NOT_AVAILABLE");

        uint256 slot = uint256(keccak256(abi.encode(depositId, depositsMapSlotIndex)));

        require(!processedDeposits[depositId], "ERR_DEPOSIT_ALREADY_PROCESSED");

        bytes32 proofPath = keccak256(abi.encodePacked(slot));
        uint256 slotValue = storageProof.verify(accountStorageRoot, proofPath).toRLPItem().toUint(); // reverts if proof is invalid

        require(keccak256(abi.encode(amount, recipient)) == bytes32(slotValue), "ERR_INVALID_DATA");

        uint256 feeAmount = (amount * mintFeeRate) / ONE;
        feesAccrued += feeAmount;

        processedDeposits[depositId] = true;
        _mint(recipient, amount - feeAmount);
    }

    function withdraw(uint256 amount, address recipient) public {
        _burn(msg.sender, amount);
        withdrawals[withdrawalsCount] = keccak256(abi.encode(amount, recipient));
        emit Withdrawal(withdrawalsCount++, amount, msg.sender, recipient);
    }

    function withdrawFees() external {
        uint256 tokensToMint = feesAccrued;
        feesAccrued = 0;
        _mint(feeRecipient, tokensToMint);
    }

    function relayStateRoot(
        uint256 blockNumber,
        bytes32 stateRoot,
        bytes calldata signature
    ) public {
        require(relayer == ECDSA.recover(stateRoot, signature));
        stateRoots[blockNumber] = stateRoot;
        emit StateRootRelay(blockNumber, stateRoot);
    }
}
