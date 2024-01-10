/// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract Vesting is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 token;

    bytes32 private merkleRoot;
    uint256 public vestingLength;
    uint256 startTime;
    uint256 endTime;

    mapping (address => uint256) claimed;

    constructor(address _token) {
        vestingLength = 365 days;
        startTime = block.timestamp;
        endTime = startTime.add(vestingLength);
        token = IERC20(_token);
    }

    error InvalidProof();
    error AlreadyClaimed();

    /// @notice The total supply of tokens remaining in the contract.
    function totalSupply() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /// @notice Add merkle tree data to the contract.
    /// @param root merkle tree root.
    function addMerkleData(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    /// @notice Returns the total remaining balance the for the calling user.
    /// @param sAmount The total amount the user is entitled to at init time.
    /// @param proof The merkle proof, generated offchain and passed from the frontend.
    function remainingBalance(uint256 sAmount, bytes32[] calldata proof) public view returns (uint256) {
        _verifyProof(msg.sender, sAmount, proof);
        return sAmount.sub(claimed[msg.sender]);
    }

    /// @notice Returns the total amount currently claimable by the user.
    /// @param sAmount The total amount the user is entitled to at init time.
    /// @param proof The merkle proof, generated offchain and passed from the frontend.
    function claimable(uint256 sAmount, bytes32[] calldata proof) public view returns (uint256) {
        if (claimed[msg.sender] > sAmount) revert AlreadyClaimed();
        _verifyProof(msg.sender, sAmount, proof); 

        uint256 amount = _getAmount(msg.sender, sAmount);
        return amount;
    }

    /// @notice Claims the amount the user is entitled to.
    /// @param sAmount The total amount the user is entitled to at init time.
    /// @param proof The merkle proof, generated offchain and passed from the frontend.
    function claim(uint256 sAmount, bytes32[] calldata proof) external nonReentrant {
        if (claimed[msg.sender] >= sAmount) revert AlreadyClaimed();
        _verifyProof(msg.sender, sAmount, proof);

        uint256 amount = _getAmount(msg.sender, sAmount);
        claimed[msg.sender] = claimed[msg.sender].add(amount);
        token.safeTransfer(msg.sender, amount);
    }

    /// @notice Verifies the merkle data.
    /// @param account the user account
    /// @param sAmount The total amount the user is entitled to at init time.
    /// @param proof The merkle proof, generated offchain and passed from the frontend.
    function _verifyProof(address account, uint256 sAmount, bytes32[] calldata proof) internal view {
        bytes32 node = keccak256(abi.encodePacked(account, sAmount));
        require(MerkleProof.verify(proof, merkleRoot, node), "INVALID PROOF");
    }

    /// @notice Returns the total amount the user is currently entitled to. Used during claiming.
    /// @param account the user account
    /// @param sAmount The total amount the user is entitled to at init time.
    /// @return The total amount the user is currently entitled to.
    function _getAmount(address account, uint256 sAmount) internal view returns (uint256) {
        uint256 rate = _getRate(sAmount);
        uint256 timePassed = block.timestamp.sub(startTime);
        uint256 amount = (timePassed.mul(rate)).sub(claimed[account]);
        uint256 rBalance = sAmount.sub(claimed[account]);
        if (amount > rBalance) return rBalance;
        return amount;
    }

    /// @notice The rate the user should receive rewards. Used to calculate their claimable amount.
    /// @param sAmount The total amount the user is entitled to at init time.
    function _getRate(uint256 sAmount) internal view returns (uint256) {
        return sAmount.div(vestingLength);
    }

    /// @notice Emergency withdraws all funds to contract owner. This is only to use in extreme circumstances
    function emergencyWithdraw () external onlyOwner {
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }
}