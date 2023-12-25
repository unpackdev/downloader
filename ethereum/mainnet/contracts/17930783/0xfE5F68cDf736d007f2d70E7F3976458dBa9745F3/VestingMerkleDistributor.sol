// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeCast.sol";
import "./MerkleProof.sol";

contract VestingMerkleDistributor {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    uint256 constant ONE_IN_TEN_DECIMALS = 1e10;
    uint8 constant MAX_CLAIM_VALUE = 255;

    address public immutable TOKEN_ADDRESS;
    bytes32 public immutable MERKLE_ROOT;

    event Claimed(address indexed account, uint256 amount);

    // Packed value for claim computation
    // uint128: timestamp of start
    // uint128: timestamp of end
    uint256 private immutable VESTING_START_AND_END;

    // Each user has a 8 bits marking the claimed amount
    // 32 users per uint256
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token, bytes32 merkleRoot, uint256 startTimestamp, uint256 endTimestamp) {
        require(endTimestamp >= startTimestamp, "Invalid interval");
        
        TOKEN_ADDRESS = token;
        MERKLE_ROOT = merkleRoot;
        VESTING_START_AND_END = (startTimestamp << 128) + endTimestamp.toUint128();
    }

    function getVestingStartAndEnd() public view returns (uint256 vestingStart, uint256 vestingEnd) {
        vestingStart = uint256(VESTING_START_AND_END >> 128);
        vestingEnd = uint256(uint128(VESTING_START_AND_END));
    }

    function fractionVested() public view returns (uint8) {
        (uint256 vestingStart, uint256 vestingEnd) = getVestingStartAndEnd();

        if(block.timestamp <= vestingStart){
            return 0;
        } else if(block.timestamp >= vestingEnd) {
            return MAX_CLAIM_VALUE;
        } else {
            return ((MAX_CLAIM_VALUE*(block.timestamp - vestingStart))/(vestingEnd - vestingStart)).toUint8();
        }
    }

    function claimVested(uint256 index, address account, uint256 tokenGrant, bytes32[] calldata merkleProof) external {
        bytes32 node = keccak256(abi.encodePacked(index, account, tokenGrant));
        require(MerkleProof.verify(merkleProof, MERKLE_ROOT, node), "Invalid proof");

        uint8 _fractionClaimed = getClaimAmount(index);
        uint8 _fractionVested = fractionVested();

        require(_fractionVested > _fractionClaimed, "Nothing to claim");

        uint256 amountToSend = ((_fractionVested - _fractionClaimed)*tokenGrant)/MAX_CLAIM_VALUE;
        
        _setClaimAmount(index, _fractionVested);
        IERC20(TOKEN_ADDRESS).safeTransfer(account, amountToSend);

        emit Claimed(account, amountToSend);
    }

    function getClaimAmount(uint256 index) public view returns (uint8) {
        uint256 claimedKey = index / 32;
        uint256 claimedWord = (index % 32);
        return uint8(claimedBitMap[claimedKey] >> (claimedWord*8));
    }

    function _setClaimAmount(uint256 index, uint8 amount) private {
        uint256 claimedWordIndex = index / 32;
        uint256 claimedWord = (index % 32);

        // Shift the "amount" bits into the correct spot in the word, for instance
        // New claim mask could be: 00000000110111010000000
        uint256 newClaimMask = uint256(amount) << (claimedWord*8);
        // myMask is 0s in the slot:
        // myMask could be 11111111000000011111111
        uint256 myMask = ~(uint256(MAX_CLAIM_VALUE) << (claimedWord*8));
        // (claimedBitMap[claimedWordIndex] & myMask) is the existing bitmap with my slot zero'd out
        claimedBitMap[claimedWordIndex] = (claimedBitMap[claimedWordIndex] & myMask) | newClaimMask;
    }
}
