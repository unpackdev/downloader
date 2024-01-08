// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./IMinter.sol";

contract Minter is Ownable, IMinter {
    using SafeERC20 for IERC20;

    // Token decimals
    uint256 internal constant DECIMALS = 18;

    ///  @inheritdoc IMinter
    address public immutable override token;
    ///  @inheritdoc IMinter
    bytes32 public override merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_) {
        token = token_;
        merkleRoot = merkleRoot_;
    }

    ///  @inheritdoc IMinter
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override {
        if (isClaimed(index)) revert AlreadyClaimed(_msgSender());

        // Verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) revert InvalidProof();

        // Mark it claimed and send the token
        _setClaimed(index);
        IERC20(token).safeTransfer(account, amount * (10 ** DECIMALS));

        emit Claimed(index, account, amount * (10 ** DECIMALS));
    }

    ///  @inheritdoc IMinter
    function setMerkleRoot(bytes32 merkleRoot_) external override onlyOwner {
        merkleRoot = merkleRoot_;
    }

    ///  @inheritdoc IMinter
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
}
