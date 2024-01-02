// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "./MerkleProof.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract Airdrop is Ownable {
    struct AirdropBucket {
        uint256 deadline;
        bytes32 root;
        mapping(address => bool) claimed;
    }
    address public from;
    IERC20 public token;
    mapping(uint256 => AirdropBucket) buckets;
    event claimAirdrop(
        address to,
        uint256 bucket,
        uint256 amount,
        uint256 blocktime
    );

    constructor(address _token) Ownable(msg.sender) {
        token = IERC20(_token);
        from = address(this);
    }

    function newAirdrop(
        uint256 _bucket,
        bytes32 _root,
        uint256 _deadline,
        bool _force
    ) public onlyOwner {
        require(block.timestamp <= _deadline, "Expire deadline");
        if (!_force) {
            require(buckets[_bucket].deadline == 0, "Bucket init already");
        }
        buckets[_bucket].deadline = _deadline;
        buckets[_bucket].root = _root;
    }

    function disableAirdrop(uint256 _bucket) public onlyOwner {
        buckets[_bucket].root = bytes32(0);
    }

    function claim(
        uint256 _bucket,
        address _to,
        uint256 _amount,
        bytes32[] calldata _proof
    ) external {
        AirdropBucket storage era = buckets[_bucket];
        require(!era.claimed[_to], "Already claimed airdrop");
        require(block.timestamp <= era.deadline, "Expire deadline");
        bytes32 _leaf = keccak256(
            bytes.concat(keccak256(abi.encode(_to, _amount)))
        );
        require(
            MerkleProof.verify(_proof, era.root, _leaf),
            "Incorrect merkle proof"
        );
        era.claimed[_to] = true;
        token.transfer(_to, _amount);
        emit claimAirdrop(_to, _bucket, _amount, block.timestamp);
    }

    function getAirdropInfo(
        uint256 _bucket,
        address _to
    ) external view returns (uint deadline, bytes32 root, bool claimed) {
        return (
            buckets[_bucket].deadline,
            buckets[_bucket].root,
            buckets[_bucket].claimed[_to]
        );
    }
}
