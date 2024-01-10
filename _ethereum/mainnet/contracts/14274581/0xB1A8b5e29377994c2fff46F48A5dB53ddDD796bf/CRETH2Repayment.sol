// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./MerkleProof.sol";

interface RepaymentContract {
    function claimFor(address _address, uint256 amount, bytes32[] memory proof) external;
}

// Contract for claiming CRETH2 and optionally YUSD.
contract CRETH2Repayment is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Claim(address from, address to, address token, uint256 amount);
    event TokenSeized(address token, uint256 amount);
    event Paused(bool paused);
    event MerkleRootUpdated(bytes32 oldMerkleRoot, bytes32 newMerkleRoot);
    event ExcludedUpdated(address user, address token, uint256 amount);

    address public immutable CREAM;
    address public immutable CRETH2;
    address public creamReceiver;

    bytes32 public merkleRoot;
    bool public paused;
    mapping(address => uint256) public excluded;
    mapping(address => bool) public claimed;

    constructor(bytes32 _merkleRoot, address _creth2, address _cream, address _creamReceiver) {
        merkleRoot = _merkleRoot;
        CRETH2 = _creth2;
        CREAM = _cream;
        creamReceiver = _creamReceiver;
    }

    function claim(uint256 amount, uint256 creamReturnAmount, bytes32[] memory proof) external {
        _claimAndTransfer(msg.sender, msg.sender, amount, creamReturnAmount, proof);
    }

    // Like claim(), but transfer to `to` address.
    function claimAndTransfer(address to, uint256 amount, uint256 creamReturnAmount, bytes32[] memory proof) external {
        _claimAndTransfer(msg.sender, to, amount, creamReturnAmount, proof);
    }

    // Claim for a contract and transfer tokens to `to` address.
    function adminClaimAndTransfer(address from, address to, uint256 amount, uint256 creamReturnAmount, bytes32[] memory proof) external onlyOwner {
        require(Address.isContract(from), "not a contract");
        _claimAndTransfer(from, to, amount, creamReturnAmount, proof);
    }

    function _claimAndTransfer(address from, address to, uint256 amount, uint256 creamReturnAmount, bytes32[] memory proof) internal nonReentrant {
        require(claimed[from] == false, "claimed");
        require(!paused, "claim paused");

        // Check the Merkle proof.
        bytes32 leaf = keccak256(abi.encodePacked(from, amount, creamReturnAmount));
        bool verified = MerkleProof.verify(proof, merkleRoot, leaf);
        require(verified, "invalid merkle proof");

        // Update the storage.
        claimed[from] = true;

        if (amount > excluded[from]) {
            IERC20(CREAM).transferFrom(from, creamReceiver, creamReturnAmount);

            IERC20(CRETH2).transfer(to, amount - excluded[from]);
            emit Claim(from, to, CRETH2, amount - excluded[from]);
        }
    }

    function seize(address token, uint amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
        emit TokenSeized(token, amount);
    }

    function updateMerkleTree(bytes32 _merkleRoot) external onlyOwner {
        bytes32 oldMerkleRoot = merkleRoot;
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(oldMerkleRoot, _merkleRoot);
    }

    function pause(bool _paused) external onlyOwner {
        require(paused != _paused, "invalid paused");

        paused = _paused;
        emit Paused(_paused);
    }

    function setExcluded(address user, uint256 amount) external onlyOwner {
        require(!claimed[user], "already claimed");

        if (amount != excluded[user]) {
            excluded[user] = amount;
            emit ExcludedUpdated(user, CRETH2, amount);
        }
    }
}
