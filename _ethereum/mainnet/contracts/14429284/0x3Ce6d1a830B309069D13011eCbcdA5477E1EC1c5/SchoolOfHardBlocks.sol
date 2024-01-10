// SPDX-License-Identifier: MIT
/*
  _    _      _                             _                   
 | |  | |    | |                           | |                  
 | |  | | ___| | ___ ___  _ __ ___   ___   | |_ ___             
 | |/\| |/ _ \ |/ __/ _ \| '_ ` _ \ / _ \  | __/ _ \            
 \  /\  /  __/ | (_| (_) | | | | | |  __/  | || (_) |           
  \/  \/ \___|_|\___\___/|_| |_| |_|\___|   \__\___/            
                                                               
                                                               
 _____ _             _____      _                 _           __ 
|_   _| |           /  ___|    | |               | |         / _|
  | | | |__   ___   \ `--.  ___| |__   ___   ___ | |    ___ | |_ 
  | | | '_ \ / _ \   `--. \/ __| '_ \ / _ \ / _ \| |   / _ \|  _|
  | | | | | |  __/  /\__/ / (__| | | | (_) | (_) | |  | (_) | |  
  \_/ |_| |_|\___|  \____/ \___|_| |_|\___/ \___/|_|   \___/|_|  
                                                               
                                                               
  _   _               _   ______ _            _                 
 | | | |             | |  | ___ \ |          | |                
 | |_| | __ _ _ __ __| |  | |_/ / | ___   ___| | _____          
 |  _  |/ _` | '__/ _` |  | ___ \ |/ _ \ / __| |/ / __|         
 | | | | (_| | | | (_| |  | |_/ / | (_) | (__|   <\__ \         
 \_| |_/\__,_|_|  \__,_|  \____/|_|\___/ \___|_|\_\___/         
                                                          

  To the Prospective Student,

    Welcome to the School of Hard Blocks. This is not a normal school and
  it is not a normal NFT. The School is open to everyone who loves
  learning about web3. There are no books or teachers. There are no
  student debts. The School exists only as permissionless smart
  contracts on Ethereum. To increase access, we’ve kept the gas cost as
  low as we could.

    When you are ready to enrol, you can try to mint your student ID (an
  NFT). Just like the School, all NFTs are 100% on-chain, interactive
  and upgradeable. We favour knowledge over luck or speed here at the
  School, so your NFT’s attributes will depend on how much you’ve
  learned, not on how lucky or fast you were. So learn some Solidity,
  solve the puzzle to mint your ID, and join the class. If you have
  feedback, tell us @DadJokeLabs. We’re students of web3 too.

    How to mint?
    1. Find the mint function.
    2. Find out how to call it.
    3. Explore the contract to mint the best student IDs.

    Once you have your Student ID, you’ve passed the Freshman year. Stay
  tuned for more on-chain challenges (Sophomore, Junior & Senior years)
  to upgrade your NFT.

    See you in class,

      Dad Joke Labs

*/
pragma solidity >=0.8.4 <0.9.0;
import "./Base64.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./HardBlocksStudent.sol";
import "./SchoolOfHardBlocksPuzzle.sol";

error NoContractCall();
error InvalidAmountSent();
error SupplyExhausted();
error YouFailed();
error InvalidName();
error PuzzleNotReady();
error NotOwnerOfToken();
error NonExistantToken();
error PuzzleAlreadyAttempted();
error WithdrawFailure();

contract TheAnswer {
    function equals() public pure returns (uint256) {}
}

contract SchoolOfHardBlocks is ERC721, Ownable {
    using Strings for uint256;
    using Address for address;

    address public studentMetadataAddress;
    uint256 public constant MAX_SUPPLY = 4096;
    uint256 public entrancePuzzlePrice = 0.01 ether;
    bool public entrancePuzzleOpen = false;
    uint256 private immutable schoolBuilt;
    string public constant answer1 = "Welcome";
    uint256 private immutable _answer2;
    uint256 private constant _answer3 = 0x15^0x19;

    uint16[4096] public scores;
    mapping(uint256 => string) public studentNames;

    struct Puzzle {
        address puzzleAddress;
        uint256[16] attempted;
        bool open;
        uint256 puzzlePrice;
    }
    Puzzle[] public puzzles;

    address private _devAddress;
    address private _artistAddress;

    constructor(
        address _answer2_address,
        address _initArtistAddress
    ) ERC721("School of Hard Blocks", "HRDBLK") {
        _answer2 = TheAnswer(_answer2_address).equals();
        schoolBuilt = block.number;
        _devAddress = msg.sender;
        _artistAddress = _initArtistAddress;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) {
            revert NonExistantToken();
        }
        string memory _studentName = studentNames[_tokenId];
        if (bytes(_studentName).length == 0) {
            _studentName = string(abi.encodePacked("Student#", _tokenId.toString()));
        }
        return IHardBlocksStudent(studentMetadataAddress).tokenURI(
            _tokenId,
            _studentName,
            scores[_tokenId]
        );
    }

    /************************************************************
    ******************** Personalise Answers ********************
    ************************************************************/
    function personaliseNumber(
        uint _number,
        address _studentAddress
    ) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_number, _studentAddress));
    }
    function personaliseString(
        string memory _string,
        address _studentAddress
    ) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_string, _studentAddress));
    }

    /*****************************************************************************
     * Well done, you found it. Now can you solve the puzzle and become a student?
     * If you do pass, how good a student will you be? 
     * 
     *
     * Notes:
     * * Be careful sharing or copying answers, they need to be personalised
     *     for each student and some may change with time.
     * * If you don't know an answer use
     *     0x0000000000000000000000000000000000000000000000000000000000000000
     ******************************************************************************/
    function mint(
        bytes32 _personalisedAnswer1,
        bytes32 _personalisedAnswer2,
        bytes32 _personalisedAnswer3,
        bytes32 _personalisedAnswer4,
        bytes32 _personalisedAnswer5
    ) external payable {
        if (msg.sender.isContract()) {
            revert NoContractCall();
        }
        if (!entrancePuzzleOpen) {
            revert PuzzleNotReady();
        }
        uint supply = _owners.length;
        if (supply >= MAX_SUPPLY) {
            revert SupplyExhausted();
        }
        if (msg.value != entrancePuzzlePrice) {
            revert InvalidAmountSent();
        }
        uint _answer4 = (block.number - schoolBuilt) / 1650;
        string memory _answer5 = Base64.ENCODE("Encode this");

        bool answer1Correct = personaliseString(answer1, msg.sender) == _personalisedAnswer1;
        bool answer2Correct = personaliseNumber(_answer2, msg.sender) == _personalisedAnswer2;
        bool answer3Correct = personaliseNumber(_answer3, msg.sender) == _personalisedAnswer3;
        bool answer4Correct = personaliseNumber(_answer4, msg.sender) == _personalisedAnswer4;
        bool answer5Correct = personaliseString(_answer5, msg.sender) == _personalisedAnswer5;

        if (!(answer1Correct ||
              answer2Correct ||
              answer3Correct ||
              answer4Correct ||
              answer5Correct)) {
            revert YouFailed();
        }
        
        _internalMint(
            supply,
            answer1Correct,
            answer2Correct,
            answer3Correct,
            answer4Correct,
            answer5Correct
        );
    }

    // Optional: Give your student a name and it will appear in the image.
    //   Free but you'll have to pay gas.
    //   Name must be 1-12 alphanumeric characters or space.
    function setStudentName(string calldata _studentName, uint256 _tokenId) external {
        if (msg.sender != ownerOf(_tokenId)) revert NotOwnerOfToken();
        bytes memory nameBytes = bytes(_studentName);
        uint256 nameLength = nameBytes.length;
        if (nameLength == 0) revert InvalidName();
        if (nameLength > 12) revert InvalidName();
        for (uint256 i; i < nameLength;) {
            bytes1 char = nameBytes[i];
            if (!(char > 0x2F && char < 0x3A) && // 0-9
                !(char > 0x40 && char < 0x5B) && // A-Z
                !(char > 0x60 && char < 0x7B) && // a-z
                !(char == 0x20)) { // space
                revert InvalidName();
            }
            unchecked { ++i; }
        }
        studentNames[_tokenId] = _studentName;
    }

    // Your student will evolve as you solve more puzzles
    function setStudentMetadataAddress(address addr) external onlyOwner {
        studentMetadataAddress = addr;
    }

    function addPuzzle(address _puzzleAddress, uint256 _puzzlePrice) external onlyOwner {
        Puzzle memory newPuzzle;
        newPuzzle.puzzleAddress = _puzzleAddress;
        newPuzzle.open = false;
        newPuzzle.puzzlePrice = _puzzlePrice;
        puzzles.push(newPuzzle);
    }

    function togglePuzzleOpen(uint _puzzleIndex) external onlyOwner {
        if (_puzzleIndex >= puzzles.length) {
            revert PuzzleNotReady();
        }
        puzzles[_puzzleIndex].open = !puzzles[_puzzleIndex].open;
    }

    /*****************************************************************
     ************************ Future puzzles *************************
     * Some puzzles will be free (enter 0 in the amount field)
     *   although you can donate if you are enjoying the school.
     * More complex puzzles and metadata that take us considerable 
     *   time to build may have a small fee.
     ****************************************************************/
    function attemptPuzzle(
        uint256 _tokenId,
        uint _puzzleIndex,
        bytes32 _personalisedAnswer1,
        bytes32 _personalisedAnswer2,
        bytes32 _personalisedAnswer3,
        bytes32 _personalisedAnswer4,
        bytes32 _personalisedAnswer5
    ) external payable {
        if (msg.sender.isContract()) {
            revert NoContractCall();
        }
        if (_puzzleIndex >= puzzles.length || !puzzles[_puzzleIndex].open) {
            revert PuzzleNotReady();
        }
        if (msg.value < puzzles[_puzzleIndex].puzzlePrice) {
            revert InvalidAmountSent();
        }
        if (msg.sender != ownerOf(_tokenId)) {
            revert NotOwnerOfToken();
        }
        if (_alreadyAttempted(_puzzleIndex, _tokenId)) {
            revert PuzzleAlreadyAttempted();
        }
        address puzzleAddress = puzzles[_puzzleIndex].puzzleAddress;

        uint8 puzzleScore = SchoolOfHardBlocksPuzzle(puzzleAddress).attemptPuzzle(
            msg.sender,
            _personalisedAnswer1,
            _personalisedAnswer2,
            _personalisedAnswer3,
            _personalisedAnswer4,
            _personalisedAnswer5
        );
        scores[_tokenId] += puzzleScore;
        _setAttempted(_puzzleIndex, _tokenId);
    }

    function _setAttempted(uint _puzzleIndex, uint _tokenId) private {
        uint i = _tokenId / 256;
        uint j = _tokenId % 256;
        puzzles[_puzzleIndex].attempted[i] = puzzles[_puzzleIndex].attempted[i] | uint256(1) << j;
    }

    function _alreadyAttempted(uint _puzzleIndex, uint _tokenId) private view returns(bool) {
        uint i = _tokenId / 256;
        uint j = _tokenId % 256;
        uint256 flag = (puzzles[_puzzleIndex].attempted[i] >> j) & uint256(1);
        return flag == 1;
    }

    /*******************************
     ******* Owner functions *******
     ******************************/
    function toggleEntrancePuzzle() external onlyOwner {
        entrancePuzzleOpen = !entrancePuzzleOpen;
    }

    function changeEntrancePrice(uint256 _newPrice) external onlyOwner {
        entrancePuzzlePrice = _newPrice;
    }

    function ownerMint(
        uint _mintAmount,
        bool _setAnswer1,
        bool _setAnswer2,
        bool _setAnswer3,
        bool _setAnswer4,
        bool _setAnswer5
    ) external onlyOwner {
        uint supply = _owners.length;
        if (supply >= MAX_SUPPLY) {
            revert SupplyExhausted();
        }
        for(uint i; i < _mintAmount;) {
            _internalMint(
                supply + i,
                _setAnswer1,
                _setAnswer2,
                _setAnswer3,
                _setAnswer4,
                _setAnswer5
            );
            unchecked { ++i; }
        }
    }

    function setPaymentAddresses(address _dev, address _artist) external onlyOwner {
        _devAddress = _dev;
        _artistAddress = _artist;
    }

    function withdraw() external onlyOwner {
        if (_devAddress == address(0) || _artistAddress == address(0)) {
            revert WithdrawFailure();
        }
        uint256 half = address(this).balance / 2;
        payable(_devAddress).transfer(half);
        payable(_artistAddress).transfer(half);
    }

    function _internalMint(
        uint _tokenId, 
        bool _setAnswer1, 
        bool _setAnswer2, 
        bool _setAnswer3, 
        bool _setAnswer4, 
        bool _setAnswer5
    ) private {
        _safeMint(_msgSender(), _tokenId);
        uint8 _score = 0;
        if (_setAnswer1) {
            ++_score;
        }
        if (_setAnswer2) {
            ++_score;
        }
        if (_setAnswer3) {
            ++_score;
        }
        if (_setAnswer4) {
            ++_score;
        }
        if (_setAnswer5) {
            ++_score;
        }
        scores[_tokenId] = _score;
    }
}