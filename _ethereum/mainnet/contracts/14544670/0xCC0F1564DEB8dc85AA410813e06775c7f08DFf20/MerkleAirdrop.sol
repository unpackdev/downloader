// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./MerkleProof.sol";

/**
 * @dev Extension of the BKN contract to support wrapping and distribution through merkle tree.
 * After this contract is deployed, some BKN must be sent to this contract, so that airdropped users can claim those
 */
contract MerkleAirdrop {
    using SafeERC20 for IERC20;

    IERC20 public underlying;

    address public sweeper;

    bytes32 public merkleRoot;

    mapping(address => bool) claimedAccounts;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(address account, uint256 amount);

    // This event is triggered whener a call to #nominateSweeper succeeds.
    event Nominated(address account);

    // This event is triggered whener a call to #sweepLeft succeeds.
    event Sweeped(address account, uint256 amount);

    constructor(IERC20 _token, bytes32 _merkleRoot, address _sweeper) {
        underlying = _token;
        merkleRoot = _merkleRoot;
        sweeper = _sweeper;
    }

    // Function to claim wrapped tokens from airdrop
    function claim(
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public virtual {
        require(!claimedAccounts[msg.sender], "MerkleDistributor: Drop already claimed.");
        claimedAccounts[msg.sender] = true;
        
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));

        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        // Send tokens to user
        underlying.safeTransfer(msg.sender, amount);

        emit Claimed( msg.sender, amount);
    }

    function getter(uint256 amount) public view returns(bytes32, address, uint256) {
        return (keccak256(abi.encodePacked(msg.sender, amount)), msg.sender, amount);
    }

    function nominateSweeper(address account) external {
        require(msg.sender == sweeper, "Caller is not sweeper");
        sweeper = account;
        emit Nominated(account);
    }

    function sweepLeft() external {
        require(msg.sender == sweeper, "Caller is not sweeper");
        uint256 amount = underlying.balanceOf(address(this));
        underlying.safeTransfer(sweeper, amount);
        emit Sweeped(msg.sender, amount);
    }
}