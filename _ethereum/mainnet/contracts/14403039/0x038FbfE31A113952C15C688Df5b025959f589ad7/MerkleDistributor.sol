// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";
import "./IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor, ERC1155Holder, ReentrancyGuard {
    using SafeMath for uint256;

    address public immutable override token;
    bytes32 public immutable override merkleRoot;
    uint256 public claimableTokenAmount0;
    uint256 public claimableTokenAmount1;
    uint256 public claimedTokenAmount0;
    uint256 public claimedTokenAmount1;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    address internal immutable _deployer;
    address internal immutable _beneficiary;

    uint256[] public tokenIds;

    constructor(
        address token_,
        uint256 claimableTokenAmount0_,
        uint256 claimableTokenAmount1_,
        bytes32 merkleRoot_,
        address beneficiary_
    ) {
        token = token_;
        claimableTokenAmount0 = claimableTokenAmount0_;
        claimableTokenAmount1 = claimableTokenAmount1_;
        merkleRoot = merkleRoot_;
        _deployer = msg.sender;
        _beneficiary = beneficiary_;

        tokenIds = [5, 6];
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

    function claim(
        uint256 index,
        address account,
        uint256 amount0,
        uint256 amount1,
        bytes32[] calldata merkleProof
    ) external override nonReentrant {
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount0, amount1));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);

        // Transfer ERC1155 to msg.sender
        uint256[] memory balances = new uint256[](2);
        balances[0] = amount0;
        balances[1] = amount1;
        IERC1155(token).safeBatchTransferFrom(address(this), account, tokenIds, balances, bytes(""));
        claimedTokenAmount0 += amount0;
        claimedTokenAmount1 += amount1;

        emit Claimed(index, account);
    }

    function collectUnclaimed() external {
        require(msg.sender == _deployer, 'MerkleDistributor: not deployer');

        // get the remaining token balance
        uint256[] memory balances = new uint256[](2);
        balances[0] = claimableTokenAmount0.sub(claimedTokenAmount0);
        balances[1] = claimableTokenAmount1.sub(claimedTokenAmount1);
        
        // transfer ERC1155 to the beneficiary
        IERC1155(token).safeBatchTransferFrom(address(this), _beneficiary, tokenIds, balances, bytes(""));
    }
}
