pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC1155.sol";
import "./IERC721.sol";

contract TokenizeNFT is Ownable {
    using SafeMath for uint256;

    uint256 public currentRace = 0;
    uint256 public constant maxParticipants = 10;
    uint256 public minParticipant = 2;

    struct Participant {
        address nftContract;
        uint256 nftId;
        uint256 score;
        address payable add;
    }

    mapping(uint256 => Participant[]) public participants;
    mapping(uint256 => uint256) public raceParticipants;
    mapping(uint256 => uint256) public raceMaxScore;
    mapping(uint256 => uint256) public raceStart;
    mapping(address => uint256) public whitelist;
    uint256 public entryPrice = 1 ether / 10; //0.1 eth
    uint256 public raceDuration = 2 * 1 hours;

    address payable raceMaster = address(0);

    event raceEnded(uint256 prize, address winner);
    event participantEntered(uint256 bet, address who);

    constructor() public {}

    function settleRaceIfPossible() public {
        if (
            raceStart[currentRace] + raceDuration < now ||
            raceParticipants[currentRace] >= maxParticipants
        ) {
            uint256 maxScore = 0;
            address payable winner = address(0);
            // logic to distribute prize
            for (uint256 i; i < participants[currentRace].length; i++) {
                participants[currentRace][i].score = randomNumber(i, 100).mul(99 + whitelist[participants[currentRace][i].nftContract]).div(100); // Need to check this one more
                if (participants[currentRace][i].score > maxScore) {
                    winner = participants[currentRace][i].add;
                    maxScore = participants[currentRace][i].score;
                }
            }
            currentRace = currentRace.add(1);
            winner.transfer(participants[currentRace].length.mul(entryPrice).mul(95).div(100)); //Check reentrency
            raceMaster.transfer(participants[currentRace].length.mul(entryPrice).mul(5).div(100));
            //Emit race won event
            emit raceEnded(participants[currentRace].length.mul(entryPrice).mul(95).div(100), winner);
        }
    }

    function joinRace(address _tokenAddress, uint256 _tokenId, uint256 _tokenType) public payable {
        require(msg.value > entryPrice, "Not enough ETH to participate");
        require(whitelist[_tokenAddress] > 0, "This NFT is not whitelisted");
        if (_tokenType == 725) {
            require(IERC721(_tokenAddress).ownerOf(_tokenId) == msg.sender, "You don't own the NFT");
        } else if (_tokenType == 1155) {
            require(IERC1155(_tokenAddress).balanceOf(msg.sender, _tokenId) > 0, "You don't own the NFT");
        }
        // check if nft is not already registered
        participants[currentRace].push(Participant(_tokenAddress, _tokenId, 0, msg.sender));
        settleRaceIfPossible(); // this will launch the previous race if possible
        emit participantEntered(entryPrice, msg.sender);
    }

    function getRaceInfo(uint256 raceNumber)
        public
        view
        returns (uint256 _raceNumber, uint256 _participantsCount, Participant[maxParticipants] memory _participants)
    {
        _raceNumber = raceNumber;
        _participantsCount = participants[raceNumber].length;
         for (uint256 i; i < participants[raceNumber].length; i++) {
             _participants[i] = participants[raceNumber][i];
         }
    }

    /* generates a number from 0 to 2^n based on the last n blocks */
    function randomNumber(uint256 seed, uint256 max)
        public
        view
        returns (uint256 _randomNumber)
    {
        uint256 n = 0;
        for (uint256 i = 0; i < 2; i++) {
            if (
                uint256(
                    keccak256(
                        abi.encodePacked(blockhash(block.number - i - 1), seed)
                    )
                ) %
                    2 ==
                0
            ) n += 2**i;
        }
        return n % max;
    }

    function max(uint a, uint b) private pure returns (uint) {
        return a > b ? a : b;
    }
}
