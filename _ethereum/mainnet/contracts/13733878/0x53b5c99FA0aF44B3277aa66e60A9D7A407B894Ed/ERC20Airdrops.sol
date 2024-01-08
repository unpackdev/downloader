// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";

contract ERC20Airdrops is MerkleProof {
    using SafeERC20 for IERC20;

    mapping(address => mapping(bytes32 => uint256)) public deadlineOf;
    mapping(address => mapping(bytes32 => address)) public walletOf;
    mapping(address => mapping(bytes32 => mapping(bytes32 => bool))) internal _hasClaimed;

    event AddMerkleRoot(address indexed token, bytes32 indexed merkleRoot, address wallet, uint256 deadline);
    event Claim(
        address indexed token,
        bytes32 indexed merkleRoot,
        address wallet,
        address indexed account,
        uint256 amount
    );

    function addMerkleRoot(
        address token,
        bytes32 merkleRoot,
        uint256 deadline
    ) external {
        address wallet = walletOf[token][merkleRoot];
        require(wallet == address(0), "LEVX: DUPLICATE_ROOT");
        walletOf[token][merkleRoot] = msg.sender;
        deadlineOf[token][merkleRoot] = deadline;

        emit AddMerkleRoot(token, merkleRoot, msg.sender, deadline);
    }

    function claim(
        address token,
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof,
        uint256 amount
    ) external {
        address wallet = walletOf[token][merkleRoot];
        require(wallet != address(0), "LEVX: INVALID_ROOT");
        require(deadlineOf[token][merkleRoot] < block.timestamp, "LEVX: EXPIRED");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(!_hasClaimed[token][merkleRoot][leaf], "LEVX: FORBIDDEN");
        require(verify(merkleRoot, leaf, merkleProof), "LEVX: INVALID_PROOF");

        _hasClaimed[token][merkleRoot][leaf] = true;
        IERC20(token).safeTransferFrom(wallet, msg.sender, amount);

        emit Claim(token, merkleRoot, wallet, msg.sender, amount);
    }
}
