// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import "./IERC20.sol";
import "./SafeMath64.sol";

contract IMerkleDistributorManager {
    using SafeMath64 for uint64;

    struct Distribution {
        address token;
        bytes32 merkleRoot;
        uint256 remainingAmount;
    }

    uint64 public nextDistributionId = 1;
    mapping(uint64 => Distribution) public distributionMap;

    // This is a packed array of booleans.
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;

    function token(uint64 distributionId) external view returns (address) {
        return distributionMap[distributionId].token;
    }

    function merkleRoot(uint64 distributionId) external view returns (bytes32) {
        return distributionMap[distributionId].merkleRoot;
    }

    function remainingAmount(uint64 distributionId) external view returns (uint256) {
        return distributionMap[distributionId].remainingAmount;
    }

    function isClaimed(uint64 distributionId, uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[distributionId][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint64 distributionId, uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[distributionId][claimedWordIndex] =
        claimedBitMap[distributionId][claimedWordIndex] | (1 << claimedBitIndex);
    }

    function addDistribution(
        address payable newToken,
        bytes32 newMerkleRoot,
        uint256 allowance
    ) public {
        Distribution memory dist = Distribution(newToken, newMerkleRoot, allowance);
        distributionMap[nextDistributionId] = dist;
        nextDistributionId = nextDistributionId.add(1);
        IERC20 erc20 = IERC20(newToken);

        erc20.transferFrom(msg.sender, address(this), allowance);
    }

    event Claimed(
        uint64 indexed distributionId,
        address indexed account,
        uint256 amount
    );
}
