// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ECDSA.sol";
import "./EnumerableSet.sol";
import "./BaseContract.sol";
import "./Bayc.sol";

//      |||||\          |||||\               |||||\           |||||\
//      ||||| |         ||||| |              ||||| |          ||||| |
//       \__|||||\  |||||\___\|               \__|||||\   |||||\___\|
//          ||||| | ||||| |                      ||||| |  ||||| |
//           \__|||||\___\|       Y u g a         \__|||||\___\|
//              ||||| |             L a b s          ||||| |
//          |||||\___\|                          |||||\___\|
//          ||||| |                              ||||| |
//           \__|||||||||||\                      \__|||||||||||\
//              ||||||||||| |                        ||||||||||| |
//               \_________\|                         \_________\|

contract TreasureHunt is BaseContract {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;
    uint256 private constant _ONE_HOUR = 3600;
    uint256 private immutable _maxBonusSolvers;
    Bayc private immutable _bayc;

    address public winner;
    address public key;
    address public bonusKey;

    EnumerableSet.AddressSet private _bonusSolversSet;

    mapping(address => uint256) private _timeOfLastSubmissionByAddress;
    mapping(uint256 => bool) private _apesClaimedForBonusPuzzle;

    event PuzzleKeySet(address indexed _puzzleKey);
    event BonusPuzzleKeySet(address indexed _bonusPuzzleKey);
    event PuzzleSolved(address indexed _solver);
    event BonusPuzzleSolved(address indexed _solver, uint256 _solverNumber);

    constructor(address baycAddr, uint256 maxBonusSolvers) {
        _bayc = Bayc(baycAddr);
        _maxBonusSolvers = maxBonusSolvers;
        _pause();
    }

    function setKey(address puzzleKey) external onlyOwner {
        key = puzzleKey;
        emit PuzzleKeySet(puzzleKey);
    }

    function setBonusKey(address puzzleKey) external onlyOwner {
        bonusKey = puzzleKey;
        emit BonusPuzzleKeySet(puzzleKey);
    }

    function numBonusSolvers() external view returns (uint) {
        return EnumerableSet.length(_bonusSolversSet);
    }

    function _recoverSigner(bytes32 digest, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return digest.recover(signature);
    }

    function generateDigest(address sender) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender));
    }

    function claimReward(bytes memory signature) external whenNotPaused {
        require(_bayc.balanceOf(msg.sender) > 0, "Must be an Ape-holder to claim");
        require(key != address(0), "Puzzle key not set");
        require(bonusKey != address(0), "Bonus puzzle key not set");
        require(
            _timeOfLastSubmissionByAddress[msg.sender] == 0 || 
            block.timestamp - _timeOfLastSubmissionByAddress[msg.sender] >= _ONE_HOUR,
            "Submitted too recently"
        );

        bytes32 digest = generateDigest(msg.sender);
        address puzzleKey = _recoverSigner(digest, signature);

        if (puzzleKey == key) {
            require(winner == address(0), "Reward has already been claimed");

            winner = msg.sender;
            
            emit PuzzleSolved(winner);            
        } else if (puzzleKey == bonusKey) {
            require(
                !EnumerableSet.contains(_bonusSolversSet, msg.sender),
                "Bonus already claimed"
            );
            require(
                EnumerableSet.length(_bonusSolversSet) < _maxBonusSolvers,
                "Would exceed solver limit"
            );
            uint256 ownedApeId = _bayc.tokenOfOwnerByIndex(msg.sender, 0);
            require(
                !_apesClaimedForBonusPuzzle[ownedApeId],
                "Ape already used to claim bonus."
            );

            _apesClaimedForBonusPuzzle[ownedApeId] = true;
            EnumerableSet.add(_bonusSolversSet, msg.sender);

            emit BonusPuzzleSolved(
                msg.sender,
                EnumerableSet.length(_bonusSolversSet)
            );            
        } else {
            _timeOfLastSubmissionByAddress[msg.sender] = block.timestamp;
        }
    }

    function getBonusSolvers(uint256 startIndex, uint256 num)
        external
        view
        returns (address[] memory)
    {
        require(
            startIndex < EnumerableSet.length(_bonusSolversSet),
            "Invalid start index"
        );
        require(num > 0, "Must get at least 1 bonus solver");
        require(
            startIndex + num - 1 < EnumerableSet.length(_bonusSolversSet),
            "Invalid range"
        );

        address[] memory solvers = new address[](num);

        for (uint256 i = startIndex; i < num + startIndex; i++) {
            solvers[i - startIndex] = EnumerableSet.at(_bonusSolversSet, i);
        }

        return solvers;
    }

    function hasApeBeenUsedToClaimBonus(uint256 apeId) external view returns (bool) {
        require(apeId < 10000, "Invalid Ape ID");
        return _apesClaimedForBonusPuzzle[apeId];
    }

    function getTimeOfLastSubmission(address solverAddress) external view returns (uint256) {
        return _timeOfLastSubmissionByAddress[solverAddress];
    }

    function isBonusSolver(address solverAddress) external view returns (bool) {
        return EnumerableSet.contains(_bonusSolversSet, solverAddress);
    }
}
