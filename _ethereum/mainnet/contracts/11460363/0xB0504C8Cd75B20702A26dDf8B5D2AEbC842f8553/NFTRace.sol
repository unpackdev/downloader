pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC1155.sol";
import "./IERC721.sol";

interface IERC721Mintable {
    function mint(address to) external;
}

contract NFTRace is Ownable {
    using SafeMath for uint256;

    uint256 public currentRace = 0;
    uint256 public constant maxParticipants = 6;

    struct Participant {
        address nftContract;
        uint256 nftId;
        uint256 score;
        address payable add;
    }

    mapping(uint256 => Participant[]) public participants;
    mapping(uint256 => uint256) public raceStart;
    mapping(uint256 => uint256) public raceEnd;
    mapping(uint256 => uint256) public raceWinner;

    mapping(address => uint256) public whitelist; //holds percent of bonus per projects
    uint256 public entryPrice;
    uint256 public raceDuration;
    uint256 public devPercent;
    address public devAddress;

    mapping(bytes32 => bool) public tokenParticipants;

    address payable raceMaster = address(0);

    IERC721Mintable public immutable vnft;

    event raceEnded(uint256 currentRace, uint256 prize, address winner, bool wonNFT);
    event participantEntered(
        uint256 currentRace,
        uint256 bet,
        address who,
        address tokenAddress,
        uint256 tokenId
    );

    constructor(IERC721Mintable _vnft) public {
        vnft = _vnft;
        raceStart[currentRace] = now;
    }

    function setRaceParameters(
        uint256 _entryPrice,
        uint256 _raceDuration,
        address _devAddress,
        uint256 _devPercent
    ) public onlyOwner {
        entryPrice = _entryPrice;
        raceDuration = _raceDuration;
        devAddress = _devAddress;
        devPercent = _devPercent;
    }

    function setBonusPercent(address _nftToken, uint256 _percent)
        public
        onlyOwner
    {
        whitelist[_nftToken] = _percent;
    }

    function settleRaceIfPossible() public {
        //Shouldn't this be >=now?
        // No cause the condition is: Did the timethe race started + the time theraceshould take is after now
        if (
            (raceStart[currentRace] + raceDuration <= now ||
            participants[currentRace].length >= maxParticipants) && participants[currentRace].length > 1
        ) {
            uint256 maxScore = 0;
            address payable winner = address(0);
            // logic to distribute prize
            uint256 baseSeed = randomNumber(
                currentRace + now + raceStart[currentRace],
                256256256256256256256257256256
            ) + 2525252511;
            for (uint256 i; i < participants[currentRace].length; i++) {
                participants[currentRace][i].score = (baseSeed * (i + 5 + currentRace)) % (100 + whitelist[participants[currentRace][i].nftContract]);


                if (participants[currentRace][i].score > maxScore) {
                    winner = participants[currentRace][i].add;
                    maxScore = participants[currentRace][i].score;
                    raceWinner[currentRace] = i;
                }
            }
           
            emit raceEnded(
                currentRace,
                participants[currentRace].length.mul(entryPrice).mul(100 - devPercent).div(
                    100
                ),
                winner,
                (baseSeed % 100 < 10)
            );

            raceEnd[currentRace] = now;
            // The entry price is multiplied by the number of participants
             winner.transfer(
                participants[currentRace].length.mul(entryPrice).mul(100 - devPercent).div(
                    100
                )
            );
             if (baseSeed % 100 < 10) { // 10% luck to get a vnft
                vnft.mint(address(winner));
            }
            currentRace = currentRace + 1;
            // We set the time for the new race (so after the + 1)
            raceStart[currentRace] = now;
            raceMaster.transfer(address(this).balance);
        }
    }

    function getParticipantId(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _tokenType,
        uint256 _raceNumber
    ) public pure returns (bytes32) {
        return (
            keccak256(
                abi.encodePacked(
                    _tokenAddress,
                    _tokenId,
                    _tokenType,
                    _raceNumber
                )
            )
        );
    }

    function joinRace(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _tokenType
    ) public payable {
        require(msg.value == entryPrice, "Not enough ETH to participate");
        require(
            tokenParticipants[getParticipantId(
                _tokenAddress,
                _tokenId,
                _tokenType,
                currentRace
            )] == false,
            "This NFT is already registered for the race"
        );
        if (_tokenType == 721) {
            require(
                IERC721(_tokenAddress).ownerOf(_tokenId) == msg.sender,
                "You don't own the NFT"
            );
        } else if (_tokenType == 1155) {
            require(
                IERC1155(_tokenAddress).balanceOf(msg.sender, _tokenId) > 0,
                "You don't own the NFT"
            );
        } else {
            require(false, "Wrong NFT Type");
        }
        participants[currentRace].push(
            Participant(_tokenAddress, _tokenId, 0, msg.sender)
        );
        tokenParticipants[getParticipantId(
            _tokenAddress,
            _tokenId,
            _tokenType,
            currentRace
        )] = true;

        emit participantEntered(
            currentRace,
            entryPrice,
            msg.sender,
            _tokenAddress,
            _tokenId
        );
        settleRaceIfPossible(); // this will launch the previous race if possible
    }

    function getRaceInfo(uint256 raceNumber)
        public
        view
        returns (
            uint256 _raceNumber,
            uint256 _participantsCount,
            Participant[maxParticipants] memory _participants,
            uint256 _raceWinner,
            uint256 _raceStart,
            uint256 _raceEnd
        )
    {
        _raceNumber = raceNumber;
        _participantsCount = participants[raceNumber].length;
        for (uint256 i; i < participants[raceNumber].length; i++) {
            _participants[i] = participants[raceNumber][i];
        }
        _raceWinner = raceWinner[raceNumber];
        _raceStart = raceStart[raceNumber];
        _raceEnd = raceEnd[raceNumber];
    }

    /* generates a number from 0 to 2^n based on the last n blocks */
    function randomNumber(uint256 seed, uint256 max)
        public
        view
        returns (uint256 _randomNumber)
    {
        uint256 n = 0;
        for (uint256 i = 0; i < 3; i++) {
            n += uint256(
                keccak256(
                    abi.encodePacked(blockhash(block.number - i - 1), seed)
                )
            );
        }
        return n % max;
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }
}
