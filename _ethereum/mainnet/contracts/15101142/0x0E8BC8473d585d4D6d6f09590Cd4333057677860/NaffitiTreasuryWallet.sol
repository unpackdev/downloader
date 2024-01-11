// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ECDSA.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";

/**
 *  @title  Naffiti Treasury Wallet
 *  @author Naffiti
 *  @dev    Using receiver hook and EIP-712 standard to record and verify the in out transaction.
 */
contract NaffitiTreasuryWallet is
    IERC721Receiver,
    IERC1155Receiver,
    Initializable,
    OwnableUpgradeable,
    EIP712Upgradeable
{
    mapping(address => mapping(address => mapping(uint256 => uint256))) private records;
    mapping(address => bool) private isApprover;

    struct DepositArgs {
        address owner;
        address approver;
    }

    struct WithdrawArgs {
        address signer;
        bytes4 tokenType;
        address nftContract;
        uint256 tokenId;
        uint256 amount;
        address recipient;
        uint256 expiryTime;
        uint256 nonce;
    }

    bytes32 public constant WITHDRAW_HASH =
        keccak256(
            "WithdrawArgs(address signer,bytes4 tokenType,address nftContract,uint256 tokenId,uint256 amount,"
            "address recipient,uint256 expiryTime,uint256 nonce)"
        );

    error InvalidTokenType();
    error InconsistentWithdrawArgs();
    error InvalidSignature();
    error InvalidTimestamp();
    error InvalidWithdrawAmount();
    error InvalidApprover();
    error RecordNotExist();

    event RecordInserted(address owner, address nftContract, uint256 tokenId, uint256 amount, address approver);

    function initialize(
        string memory name,
        string memory version,
        address[] memory approvers
    ) public initializer {
        for (uint256 i = 0; i < approvers.length; i += 1) {
            isApprover[approvers[i]] = true;
        }
        __Ownable_init();
        __EIP712_init(name, version);
    }

    /**
     * @notice Check whether the client deposited a specific token in here or not.
     */
    function balanceOf(
        address client,
        address nftContract,
        uint256 tokenId
    ) public view returns (uint256) {
        return records[client][nftContract][tokenId];
    }

    /**
     * @dev Encapsulate verification process For withdraw function to verify several signature.
     */
    function _verifyWithdrawSignautre(WithdrawArgs memory args, bytes calldata _signature) private view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    WITHDRAW_HASH,
                    args.signer,
                    args.tokenType,
                    args.nftContract,
                    args.tokenId,
                    args.amount,
                    args.recipient,
                    args.expiryTime,
                    args.nonce
                )
            )
        );

        address recoverAddress = ECDSA.recover(digest, _signature);
        if (recoverAddress != args.signer) revert InvalidSignature();
        if (block.timestamp >= args.expiryTime) revert InvalidTimestamp();
        return true;
    }

    /**
     * @dev Return a hash for comparing WithdrawArgs data.
     */
    function _encodeMsg(WithdrawArgs memory args) private pure returns (bytes32) {
        return keccak256(abi.encode(args.tokenType, args.nftContract, args.tokenId, args.amount, args.recipient));
    }

    /**
     * @notice Check the payloads consistency and signature correctness, then determine the token type transfer to the
     * specified recipient.
     *
     * @dev Index 0 for the array is the owner payload and signature, and index 1 is the approver payload and signature.
     */
    function withdraw(
        bytes[2] calldata payloads,
        bytes[2] calldata signatures,
        bytes calldata data,
        bool isLazyTransfer
    ) public {
        WithdrawArgs memory msg1 = abi.decode(payloads[0], (WithdrawArgs));
        WithdrawArgs memory msg2 = abi.decode(payloads[1], (WithdrawArgs));

        if (_encodeMsg(msg1) != _encodeMsg(msg2)) revert InconsistentWithdrawArgs();

        _verifyWithdrawSignautre(msg1, signatures[0]);
        _verifyWithdrawSignautre(msg2, signatures[1]);

        if (records[msg1.signer][msg1.nftContract][msg1.tokenId] == 0) revert RecordNotExist();
        if (!isApprover[msg2.signer]) revert InvalidApprover();

        records[msg1.signer][msg1.nftContract][msg1.tokenId] -= msg1.amount;

        if (isLazyTransfer) {
            records[msg1.recipient][msg1.nftContract][msg1.tokenId] += msg1.amount;
            emit RecordInserted(msg1.recipient, msg1.nftContract, msg1.tokenId, msg1.amount, msg2.signer);
        } else {
            if (msg1.tokenType == type(IERC721).interfaceId) {
                if (msg1.amount > 1) revert InvalidWithdrawAmount();
                IERC721(msg1.nftContract).safeTransferFrom(address(this), msg1.recipient, msg1.tokenId, data);
            } else if (msg1.tokenType == type(IERC1155).interfaceId)
                IERC1155(msg1.nftContract).safeTransferFrom(
                    address(this),
                    msg1.recipient,
                    msg1.tokenId,
                    msg1.amount,
                    data
                );
            else revert InvalidTokenType();
        }
    }

    /**
     * @dev Here using require message instead of revert error cause external contract cannot recognize
     * the custom error code.
     *
     * Emits a {RecordInserted} event.
     */
    function _insertRecord(
        address operator,
        address from,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) private {
        DepositArgs memory args = abi.decode(data, (DepositArgs));

        // If the hook is called by safeMint, checking the executor is approver or not, else only safeTransferFrom
        // will call it, then the from address should be the owner
        if (from == address(0)) require(isApprover[operator], "InvalidOperator");
        else require(from == args.owner, "InconsistentOwner");

        require(isApprover[args.approver], "InvalidApprover");

        // msg.sender is the NFT contract address
        records[args.owner][msg.sender][tokenId] += amount;
        emit RecordInserted(args.owner, msg.sender, tokenId, amount, args.approver);
    }

    /**
     *  @dev Implementation of @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        _insertRecord(operator, from, tokenId, 1, data);
        return this.onERC721Received.selector;
    }

    /**
     *  @dev Implementation of @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        _insertRecord(operator, from, id, value, data);
        return this.onERC1155Received.selector;
    }

    /**
     *  @dev Implementation of @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        for (uint256 i = 0; i < ids.length; i += 1) {
            _insertRecord(operator, from, ids[i], values[i], data);
        }
        return this.onERC1155BatchReceived.selector;
    }

    /**
     *  @dev EIP-165: Standard Interface Detection - https://eips.ethereum.org/EIPS/eip-165
     */
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC721Receiver).interfaceId;
    }

    /**
     *  @notice Allow adding / deleting multiple approvers
     */
    function changeApproverStatus(address[] calldata approvers, bool[] calldata statuses) public onlyOwner {
        for (uint256 i = 0; i < approvers.length; i += 1) {
            isApprover[approvers[i]] = statuses[i];
        }
    }
}
