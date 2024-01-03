// SPDX-License-Identifier: gpl-3.0

pragma solidity 0.7.5;

import "./VestingReserve.sol";
import "./MerkleProof.sol";

/**
 * @title MerkeTreeVestingReserve
 * Transfers fixed amount of tokens to anybody, presented merkle proof for merkle root, placed in contract
 * Adapted from https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol
 * @author Raul Martinez
 */
contract MerkleTreeVestingReserve is VestingReserve {
    bytes32 public immutable merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private verifiedBitMap;

    constructor(
        IERC20 _token,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _editAddressUntil,
        bytes32 _merkleRoot
    ) VestingReserve(_token, _startTime, _endTime, _editAddressUntil) {
        merkleRoot = _merkleRoot;
        initialized = true;
    }

     function isVerified(uint256 _index) public view returns (bool) {
        uint256 verifiedWordIndex = _index / 256;
        uint256 verifiedBitIndex = _index % 256;
        uint256 verifiedWord = verifiedBitMap[verifiedWordIndex];
        uint256 mask = (1 << verifiedBitIndex);
        return verifiedWord & mask == mask;
    }

    function _setVerified(uint256 _index) private {
        uint256 verifiedWordIndex = _index / 256;
        uint256 verifiedBitIndex = _index % 256;
        verifiedBitMap[verifiedWordIndex] = verifiedBitMap[verifiedWordIndex] | (1 << verifiedBitIndex);
    }

    function verifyAndAddEntry(
        uint256 _index,
        address _account,
        uint256 _amount,
        bytes32[] calldata _proof
    ) public {
        require(
            msg.sender == _account || msg.sender == owner(),
            'MerkeTreeeVestingReserve: caller is neither herself or owner'
        );
        require(!isVerified(_index), 'MerkeTreeeVestingReserve: account already claimed before, use claim methods');
        bytes32 node = keccak256(abi.encodePacked(_index, _account, _amount));
        require(
            MerkleProof.verify(_proof, merkleRoot, node),
            'MerkeTreeeVestingReserve: account not on the list'
        );
        _setVerified(_index);
        locked[_account] = _amount;
    }

    function firstClaim(
        uint256 _index,
        address _account,
        uint256 _amount,
        bytes32[] calldata _proof
    ) public {
        verifyAndAddEntry(_index, _account, _amount, _proof);
        _claim(_account, _amount);
    }
}
