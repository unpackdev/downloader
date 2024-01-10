// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./IERC20.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

// Allows anyone to claim a token if they exist in a merkle root.
interface IAirdropTokenDistributor {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);
}

contract GUMPAirdrop is IAirdropTokenDistributor, Ownable {
    address public immutable override token;
    bytes32 public immutable override merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_) {
        token = token_;
        merkleRoot = 0x7df271fa573a827f08c1d66c875a275fadcab659db97d8cbeaef3d31fd3d1474;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external override {
        require(!isClaimed(index), 'GUMPAirdrop: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'GUMPAirdrop: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'GUMPAirdrop: Transfer failed.');

        emit Claimed(index, account, amount);
    }

    function returnAllToken() public onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transfer(msg.sender, amount), 'GUMPAirdrop: Transfer failed.');
    }
}