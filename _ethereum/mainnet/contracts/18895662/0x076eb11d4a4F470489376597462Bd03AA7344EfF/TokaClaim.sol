// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./OwnableUpgradeable.sol";

contract TokaClaim is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    IERC20 public toka;

    uint256 public caStartTime;
    uint256 public withdrawStartTime;

    bytes32 public claimMerkleRoot;
    mapping(address => bool) public hasClaimed;

    bytes32 public withdrawMerkleRoot;
    mapping(address => bool) public hasWithdrawed;

    bytes32 public airdropMerkleRoot;
    mapping(address => bool) public hasAirdroped;

    error AlreadyClaimed();
    error AlreadyWithdrawed();
    error AlreadyAirdrop();
    error IsNotStarted();
    error NotInMerkle();

    /// @notice Emitted after a successful token claim
    /// @param to recipient of claim
    /// @param amount of tokens claimed
    event Claim(address indexed to, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);
    event Airdrop(address indexed to, uint256 amount);

    function initialize(IERC20 _token) public initializer {
        __Ownable_init(msg.sender);
        toka = _token;
    }

    // set start time for claim and airdroop
    function setCaStartTime(uint256 _start) external onlyOwner {
        caStartTime = _start;
    }

    // set start time for withdraw
    function setWithdrawStartTime(uint256 _start) external onlyOwner {
        withdrawStartTime = _start;
    }

    function setClaimMerkleRoot(bytes32 _claimMerkleRoot) external onlyOwner {
        claimMerkleRoot = _claimMerkleRoot;
    }

    function setWithdrawMerkleRoot(bytes32 _withdrawMerkleRoot) external onlyOwner {
        withdrawMerkleRoot = _withdrawMerkleRoot;
    }

    function setAirdropMerkleRoot(bytes32 _airdropMerkleRoot) external onlyOwner {
        airdropMerkleRoot = _airdropMerkleRoot;
    }

    /// @notice Allows claiming tokens if address is part of merkle tree
    /// @param _quota of tokens (Toka Token) due to claimee
    /// @param _proof merkle proof to prove address and amount are in tree
    function claim(uint256 _quota, bytes32[] calldata _proof) external {
        if (caStartTime > block.timestamp) revert IsNotStarted();
        address msgSender = msg.sender; // address of claimee

        // Throw if address has already claimed tokens
        if (hasClaimed[msgSender]) revert AlreadyClaimed();

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(msgSender, _quota));
        bool isValidLeaf = MerkleProof.verify(_proof, claimMerkleRoot, leaf);

        if (!isValidLeaf) revert NotInMerkle();

        hasClaimed[msgSender] = true; // Set address to claimed

        toka.safeTransfer(msg.sender, _quota);

        emit Claim(msgSender, _quota);
    }

    /// @notice Allows get airdrop tokens if address is part of merkle tree
    /// @param _amount of tokens (Toka Token) due to airdropee
    /// @param _proof merkle proof to prove address and amount are in tree
    function airdrop(uint256 _amount, bytes32[] calldata _proof) external {
        if (caStartTime > block.timestamp) revert IsNotStarted();
        address msgSender = msg.sender;

        if (hasAirdroped[msgSender]) revert AlreadyAirdrop();

        bytes32 leaf = keccak256(abi.encodePacked(msgSender, _amount));
        bool isValidLeaf = MerkleProof.verify(_proof, airdropMerkleRoot, leaf);
        if (!isValidLeaf) revert NotInMerkle();

        hasAirdroped[msgSender] = true;

        toka.safeTransfer(msg.sender, _amount);

        emit Airdrop(msgSender, _amount);
    }

    /// @notice Allows withdraw ETH if address is part of merkle tree
    /// @param _amount of ETH  due to withdrawee
    /// @param _proof merkle proof to prove address and amount are in tree
    function withdraw(uint256 _amount, bytes32[] calldata _proof) external {
        if (withdrawStartTime > block.timestamp) revert IsNotStarted();

        address msgSender = msg.sender;

        if (hasWithdrawed[msgSender]) revert AlreadyWithdrawed();

        bytes32 leaf = keccak256(abi.encodePacked(msgSender, _amount));
        bool isValidLeaf = MerkleProof.verify(_proof, withdrawMerkleRoot, leaf);
        if (!isValidLeaf) revert NotInMerkle();

        hasWithdrawed[msgSender] = true;

        payable(msgSender).transfer(_amount);

        emit Withdraw(msgSender, _amount);
    }

    function collect(address _token, uint256 _amount, bool _isETH) external onlyOwner {
        address msgSender = msg.sender;

        if (_isETH) {
            payable(msgSender).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(msgSender, _amount);
        }
    }

    receive() external payable {}
}
