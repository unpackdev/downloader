// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.11;

/*
  Extended Uniswap's MerkleDistributor.sol
  https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol
*/
import "./MerkleDistributor.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

interface IERC20 {
    function balanceOf(address account) external returns (uint256);

    function transfer(address to, uint256 amount) external;
}

contract ForthClaim is MerkleDistributor, Ownable {
    // Block timestamp representing deadline to claim. After this time, unclaimed tokens are burned.
    uint256 public immutable expiryTimestampSec;

    // modifiers
    modifier onlyDistributionExpired() {
        require(block.timestamp > expiryTimestampSec, "ForthClaim: distribution active");
        _;
    }

    constructor(
        address token_,
        bytes32 merkleRoot_,
        uint256 timeToExpirySec
    ) public MerkleDistributor(token_, merkleRoot_) {
        expiryTimestampSec = block.timestamp + timeToExpirySec;
    }

    // convenience getters
    function verifyProof(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        return MerkleProof.verify(merkleProof, merkleRoot, node);
    }

    // owner functions
    function rescueFunds(address recipient) external onlyOwner onlyDistributionExpired {
        IERC20 rescueToken = IERC20(token);
        rescueToken.transfer(recipient, rescueToken.balanceOf(address(this)));
    }
}
