//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

contract SkyrimRefund is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public immutable rate;
    IERC20 public immutable input;
    IERC20 public immutable output;
    bytes32 public merkleRoot;
    bool public paused;
    mapping(address => uint256) public deposits;
    uint256 public totalDeposits;
    uint256 public totalUsers;

    event SetMerkleRoot(bytes32 merkleRoot);
    event SetPaused(bool paused);
    event Swap(address indexed user, uint256 amount);

    constructor(uint256 _rate, address _input, address _output, bytes32 _merkleRoot) Ownable() {
        rate = _rate;
        input = IERC20(_input);
        output = IERC20(_output);
        merkleRoot = _merkleRoot;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit SetMerkleRoot(_merkleRoot);
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit SetPaused(_paused);
    }

    function deposit(uint256 amount, uint256 allocation, bytes32[] calldata merkleProof) external nonReentrant {
        require(!paused, "paused");
        require(amount > 0, "need amount > 0");
        
        bytes32 node = keccak256(abi.encodePacked(msg.sender, allocation));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "invalid proof");

        if (deposits[msg.sender] == 0) {
            totalUsers++;
        }
        totalDeposits += amount;
        deposits[msg.sender] += amount;
        require(deposits[msg.sender] <= allocation, "over allocation");

        IERC20(input).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(output).safeTransfer(msg.sender, amount * rate / 1e12);
        
        emit Swap(msg.sender, amount);
    }

    function withdrawToken(address token, uint amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}