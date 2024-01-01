// SPDX-License-Identifier: UNLICENSED
/*

███╗   ███╗███████╗███╗   ███╗███████╗██████╗ ██╗   ██╗██████╗ ██████╗ ██╗   ██╗
████╗ ████║██╔════╝████╗ ████║██╔════╝██╔══██╗██║   ██║██╔══██╗██╔══██╗╚██╗ ██╔╝
██╔████╔██║█████╗  ██╔████╔██║█████╗  ██████╔╝██║   ██║██║  ██║██║  ██║ ╚████╔╝ 
██║╚██╔╝██║██╔══╝  ██║╚██╔╝██║██╔══╝  ██╔══██╗██║   ██║██║  ██║██║  ██║  ╚██╔╝  
██║ ╚═╝ ██║███████╗██║ ╚═╝ ██║███████╗██████╔╝╚██████╔╝██████╔╝██████╔╝   ██║   
╚═╝     ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═════╝ ╚═════╝    ╚═╝   

*/

pragma solidity ^0.8.13;

import "./MerkleProofLib.sol";
import "./Owned.sol";

contract Rewards is Owned {
    uint256 public lockStartTime;

    bytes32 public root;
    mapping(bytes32 => mapping(uint256 => bool)) private _isClaimed;

    error AlreadyClaimed();
    error InvalidProof();
    error ClaimsLocked();

    event Claimed(address indexed recipient, bytes32 indexed root, uint256 amount);
    event RootAdded(bytes32 newRoot);
    event LockStartTimeSet(uint256 _lockStartTime);

    /**
     * @dev contract constructor
     */
    constructor() Owned(msg.sender) {}

    /**
     * @dev Checks if the claims are locked - 1 hour every 7 days for updates.
     * @return A boolean that indicates if the claims are locked
     */
    function isLocked() public view returns (bool) {
        return (block.timestamp - lockStartTime) % 7 days < 1 hours;
    }

    /**
     * @dev Allows a user to claim their rewards
     * @param proof The Merkle proof for the claim
     * @param index The index of the claim
     * @param amount The amount of the claim
     */
    function claim(bytes32[] calldata proof, uint256 index, uint256 amount) external {
        if (isLocked()) {
            revert ClaimsLocked();
        }

        if (_isClaimed[root][index]) revert AlreadyClaimed();

        bytes32 leaf = keccak256(abi.encodePacked(index, msg.sender, amount));

        if (!MerkleProofLib.verify(proof, root, leaf)) revert InvalidProof();

        _isClaimed[root][index] = true;
        payable(msg.sender).transfer(amount);

        emit Claimed(msg.sender, root, amount);
    }

    /**
     * @dev Allows the owner to update the root of the Merkle tree and transfer the total allocation
     * @param _root The new root of the Merkle tree
     */
    function updateRoot(bytes32 _root) external onlyOwner {
        root = _root;
        emit RootAdded(_root);
    }

    /**
     * @dev Allows the owner to set the lock start time
     * @param _lockStartTime The new lock start time
     */
    function setLockStartTime(uint256 _lockStartTime) external onlyOwner {
        lockStartTime = _lockStartTime;
        emit LockStartTimeSet(_lockStartTime);
    }

    receive() external payable {}
}
