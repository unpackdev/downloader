// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "./SafeERC20.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;

    struct Layer {
        address token;
        uint96 startTime;
        uint96 endTime;
        mapping(uint256 => uint256) claimed;
    }

    mapping(bytes32 => Layer) public layers;

    address public owner;

    event Claimed(address account, address token, uint256 amount);
    event SetOwner(address owner);

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;

        emit SetOwner(_owner);
    }

    constructor() public {
        owner = msg.sender;
    }

    function newlayer(
        bytes32 merkleRoot,
        address token,
        uint96 startTime,
        uint96 endTime
    ) external onlyOwner {
        require(
            layers[merkleRoot].token == address(0),
            "merkleRoot already register"
        );
        require(merkleRoot != bytes32(0), "empty root");
        require(token != address(0), "empty token");
        require(startTime < endTime, "wrong dates");

        Layer storage _layer = layers[merkleRoot];
        _layer.token = token;
        _layer.startTime = startTime;
        _layer.endTime = endTime;
    }

    function isClaimed(bytes32 merkleRoot, uint256 index)
        public
        view
        returns (bool)
    {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = layers[merkleRoot].claimed[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);

        return claimedWord & mask == mask;
    }

    function _setClaimed(bytes32 merkleRoot, uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        layers[merkleRoot].claimed[claimedWordIndex] =
            layers[merkleRoot].claimed[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProofs
    ) external {
        bytes32 leaf = keccak256(abi.encodePacked(index, account, amount));
        bytes32 merkleRoot = processProof(merkleProofs, leaf);

        require(layers[merkleRoot].token != address(0), "empty token");
        require(
            layers[merkleRoot].startTime < block.timestamp &&
                layers[merkleRoot].endTime >= block.timestamp,
            "out of time"
        );

        require(!isClaimed(merkleRoot, index), "already claimed");

        _setClaimed(merkleRoot, index);

        IERC20(layers[merkleRoot].token).safeTransfer(account, amount);

        emit Claimed(account, address(layers[merkleRoot].token), amount);
    }

    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) public pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        return computedHash;
    }
}
