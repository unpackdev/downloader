// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract Airdrop1E is Ownable {
    IERC20 public token;
    bytes32 public merkleRoot;
    uint256 public snapshotTimestamp;
    uint256 public snapshotTotalSupply;
    uint256 public airdropTotalSupply;
    uint256 constant DECIMALS = 18;
    uint256 constant SCALE_FACTOR = 10**DECIMALS;


    mapping(address => bool) public excludedAddresses;
    mapping (address => mapping (bytes32 => bool)) public claimed;

    constructor(address _token) {
        token = IERC20(_token);

        // Exclude the zero address
        excludedAddresses[address(0)] = true;

        // Exclude the dev wallet
        excludedAddresses[0x2B7bE30a0dB89642686d4e377Ff7AcdC8526f260] = true;

        // Exclude the lp pair address
        excludedAddresses[0x63221ae0DefE5B2e3e4901Df45B2fc7a3985451f] = true;
    }

    function setSnapshotTimestamp(uint256 _snapshotTimestamp)
        external
        onlyOwner
    {
        snapshotTimestamp = _snapshotTimestamp;
    }

    function setSnapshotTotalSupply(uint256 totalSupply) external onlyOwner {
        snapshotTotalSupply = totalSupply;
    }

    function setAirdropTotalSupply(uint256 _airdropTotalSupply)
        external
        onlyOwner
    {
        airdropTotalSupply = _airdropTotalSupply;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getTokenBalance(address user) external view returns (uint256) {
    return token.balanceOf(user);
    }

    function updateExcludedAddress(address addr, bool isExcluded) external onlyOwner {
    excludedAddresses[addr] = isExcluded;
    }

    event TokensClaimed(address indexed user, uint256 amount);

    function claim(address user, bytes32[] calldata proof) external {
        require(!claimed[user][merkleRoot], "Already claimed");
        require(!excludedAddresses[user], "Address excluded from claiming");
        require(block.timestamp >= snapshotTimestamp, "Airdrop not started");

        // Perform calculations with fixed-point arithmetic
        uint256 userPercentage = (token.balanceOf(user) * SCALE_FACTOR) / snapshotTotalSupply;
        uint256 userAirdropAmount = (airdropTotalSupply * userPercentage) / SCALE_FACTOR;
 

        // Calculate the user's Merkle root from the current snapshot
        require(isWhitelisted(msg.sender, proof), "Invalid Proof");

        // Emit an event with the relevant information
        emit TokensClaimed(user, userAirdropAmount);

        // Mark as claimed and send the tokens
        claimed[user][merkleRoot] = true;
        token.transfer(user, userAirdropAmount);
    }


    function isWhitelisted(address account, bytes32[] calldata proof) public view returns (bool) {
        return _verify(_leaf(account), proof, merkleRoot);
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf,bytes32[] memory proof,bytes32 root) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function withdrawUnclaimedTokens() external onlyOwner {
        uint256 remainingTokens = token.balanceOf(address(this));
        require(remainingTokens > 0, "No remaining tokens");
        token.transfer(owner(), remainingTokens);
    }


    }

