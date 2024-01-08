//                                  ___           ___           ___
//       _____        ___          /__/\         /  /\         /  /\
//      /  /::\      /  /\         \  \:\       /  /:/_       /  /::\
//     /  /:/\:\    /  /:/          \  \:\     /  /:/ /\     /  /:/\:\
//    /  /:/~/::\  /__/::\      _____\__\:\   /  /:/_/::\   /  /:/  \:\
//   /__/:/ /:/\:| \__\/\:\__  /__/::::::::\ /__/:/__\/\:\ /__/:/ \__\:\
//   \  \:\/:/~/:/    \  \:\/\ \  \:\~~\~~\/ \  \:\ /~~/:/ \  \:\ /  /:/
//    \  \::/ /:/      \__\::/  \  \:\  ~~~   \  \:\  /:/   \  \:\  /:/
//     \  \:\/:/       /__/:/    \  \:\        \  \:\/:/     \  \:\/:/
//      \  \::/        \__\/      \  \:\        \  \::/       \  \::/
//       \__\/                     \__\/         \__\/         \__\/
//
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "./ERC721.sol";
import "./Counters.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./VRFConsumerBase.sol";
import "./KeeperCompatibleInterface.sol";

library BingoGenerate {
    using SafeMath for uint256;

    // Card
    struct Card {
        uint256[5] B;
        uint256[5] I;
        uint256[5] N;
        uint256[5] G;
        uint256[5] O;
    }

    // Settings
    uint256 constant maxCount = 15;

    function generateBingoCard(uint256 randomness) internal pure returns (Card memory card) {
        if(randomness == 0) {
            return card;
        }
        uint256[5] memory col;
        uint256 i;

        for(uint256 k=0; k<5; k++) {
            col = generateColumn(uint256(keccak256(abi.encode(randomness, k))));
            for(i=0;i<5;i++) {
                if(k==2 && i==2) {
                    col[i] = 99;
                } else {
                    col[i] = col[i] + (k*maxCount);
                }
            }

            // Not sure how to do this better without switch :)
            if(k == 0) {
                card.B = col;
            } else if(k == 1) {
                card.I = col;
            } else if(k == 2) {
                card.N = col;
            } else if(k == 3) {
                card.G = col;
            } else if(k == 4) {
                card.O = col;
            }
        }

        return card;
    }

    function generateColumn(uint256 randomness) internal pure returns(uint256[5] memory col) {
        uint256[15] memory possible;
        for(uint256 i=0; i<15; i++) {
            possible[i] = i+1;
        }
        uint256 idx;
        for(uint256 k=0; k<5; k++) {
            idx = uint256(keccak256(abi.encode(randomness, k))).mod(maxCount-(1+k));
            col[k] = possible[idx];
            if(idx != 15 - (1+k)) {
                possible[idx] = possible[15 - (1+k)];
            }
        }
        return col;
    }

    function validateWinner(uint256 randomness,  mapping (uint256 => bool) storage Balls, uint256 pattern) internal view returns (bool found) {
        /*
        Patterns:
            1 = line
            2 = X
            3 = Full card
            4 = Four corners
        */
        Card memory card = generateBingoCard(randomness);
        uint256[5][13] memory lines;
        uint256 i;
        for(i=0; i<5; i++) {
            lines[i] = [card.B[i], card.I[i], card.N[i], card.G[i], card.O[i]];
        }
        lines[5] = uint256[5](card.B);
        lines[6] = card.I;
        lines[7] = card.N;
        lines[8] = card.G;
        lines[9] = card.O;
        lines[10] = [card.B[0], card.I[1], card.N[2], card.G[3], card.O[4]];
        lines[11] = [card.B[4], card.I[3], card.N[2], card.G[1], card.O[0]];
        lines[12] = [card.B[0], card.O[0], card.B[4], card.O[4], card.B[0]]; // 4 corners

        found = false;
        uint256 foundDiagonal;
        uint256 foundLines;
        uint256 k;
        uint256 matches;
        for(i=0; i<13; i++) {
            matches=0;
            for(k=0; k<5; k++) {
                if(Balls[lines[i][k]] || lines[i][k] == 99) {
                    matches++;
                    if(i == 10 || i == 11) {
                        foundDiagonal++;
                    }
                }
            }
            if(matches == 5) {
                foundLines++;
            }
            if((pattern == 1 && matches == 5 && i != 12)
            || (pattern == 2 && foundDiagonal == 10)
            || (pattern == 3 && foundLines == 12)
            || (pattern == 4 && matches == 5 && i == 12)
            ) {
                found = true;
            }
        }
    }
}

// Welcome to BINGO
contract Bingo is ERC721, VRFConsumerBase, KeeperCompatibleInterface {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _gameIds;

    // Settings
    uint256 public minCards = 1;     // 10
    uint256 public maxCards = 1000;
    uint256 public pricePerCard = 10000000000000000; // 0.01 ETH
    uint256 public ballDrawTime = 60;   // 86400
    uint256 public prizeSplit = 2;
    uint256 public pattern = 1;
    bool public startGame;
    bool public startAuto;
    address weedContract;
    address owner;

    // Game
    uint256 public gameFloor;
    uint256 public lastBallTime;
    bytes32 public ballRequest;
    uint256 public prizePool;
    uint256 public winnerPool;
    bool public outOfBalls;

    // Random
    bytes32 internal keyHash;
    uint256 internal fee;

    // Mappings
    mapping (bytes32 => uint256) cardRequests;
    mapping (uint256 => uint256) public cardRandomness;
    mapping (uint256 => uint256) public winners;
    mapping (uint256 => bool) Balls;

    event BallPicked(uint256 game, uint256 ball);
    event BingoWinner(uint256 game, uint256 tokenId);
    event CardGenerated(uint256 game, address owner, uint256 tokenId);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(address _weedContract)
    ERC721("Bingo", "BINGO")
    VRFConsumerBase(
        0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator - Kovan
        0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token - Main
    )
    {
        owner = msg.sender;
        weedContract = _weedContract;
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)

        // Automatically start the first game
        _gameIds.increment();
        lastBallTime = block.timestamp;
    }

    /*
    *   Purchase.
    */
    function mintCard(uint256 amount) public payable {
        require(amount <= 10 && startGame && (_tokenIds.current().add(amount) - gameFloor) <= maxCards, "E");
        require(LINK.balanceOf(address(this)) >= fee*amount, "L");

        // Mint in ETH
        if(msg.value > 0) {
            require(pricePerCard.mul(amount) <= msg.value, "WP");
            if(prizeSplit > 0) {
                prizePool += msg.value / prizeSplit;
            }
        // Mint in WEED
        } else {
            require(IERC20(weedContract).balanceOf(msg.sender) >= 4000 * 1e18 * amount, "NB");
            require(IERC20(weedContract).allowance(msg.sender, address(this)) >= 4000 * 1e18 * amount, "NP");
            IERC20(weedContract).transferFrom(msg.sender, address(this), 4000 * 1e18 * amount);
        }

        uint256 cardId;
        for(uint256 i=0; i<amount; i++) {
            _tokenIds.increment();
             cardId = _tokenIds.current();
            _safeMint(msg.sender, cardId);
            cardRequests[requestRandomness(keyHash, fee)] = cardId;
        }
    }

    /*
    *   Randomness.
    */
    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (_tokenIds.current() - gameFloor >= minCards) && (block.timestamp > lastBallTime+ballDrawTime && !outOfBalls && startGame);
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        require(block.timestamp > lastBallTime+ballDrawTime && _tokenIds.current() - gameFloor >= minCards, "MT");
        uint256 _winners = checkForWinners();
        if(_winners == 0) {
            require(LINK.balanceOf(address(this)) >= fee, "L");
            lastBallTime = block.timestamp;
            ballRequest = requestRandomness(keyHash, fee);
        } else {
            // Reset game
            prizePool = 0;
            _gameIds.increment();
            lastBallTime = block.timestamp;
            outOfBalls = false;
            gameFloor = _tokenIds.current();
            startGame = startAuto;
            for(uint256 b=1; b<76; b++) {
                Balls[b] = false;
            }
        }
        performData;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if(requestId == ballRequest) {
            require(requestId == ballRequest, "IR");
            uint256 choice;
            for(uint256 idx=0; idx<76; idx++) {
                choice = randomness.add(idx).mod(75).add(1);
                if(Balls[choice] == false) {
                    Balls[choice] = true;
                    emit BallPicked(_gameIds.current(), choice);
                    break;
                } else if(idx == 75) {
                    outOfBalls = true;
                }
            }
            ballRequest = 0;
        } else {
            uint256 cardId = cardRequests[requestId];
            require(cardId > 0, "NA");
            cardRandomness[cardId] = randomness;
            cardRequests[requestId] = 0;
            emit CardGenerated(_gameIds.current(), ownerOf(cardId), cardId);
        }
    }

    function checkForWinners() internal returns (uint256) {
        uint256 winIdx;
        for(uint256 i=gameFloor+1; i<= _tokenIds.current(); i++) {
            if(BingoGenerate.validateWinner(cardRandomness[i], Balls, pattern)) {
                winIdx++;
            }
        }
        if(winIdx > 0) {
            for(uint256 k=gameFloor+1; k<= _tokenIds.current(); k++) {
                if(BingoGenerate.validateWinner(cardRandomness[k], Balls, pattern)) {
                    winners[k] = prizePool.div(winIdx);
                    winnerPool = winnerPool + winners[k];
                    emit BingoWinner(_gameIds.current(), k);
                }
            }
        }
        return winIdx;
    }

    /*
    *   Claim.
    */
    function claimBingo(uint256 cardId) public payable {
        require(winners[cardId] > 0 && ownerOf(cardId) == msg.sender, 'C');
        payable(msg.sender).transfer(winners[cardId]);
        winnerPool = winnerPool - winners[cardId];
        winners[cardId] = 0;
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId), "NA");
        _burn(tokenId);
    }

    /*
    *   Getters.
    */
    function generateCard(uint256 cardId) public view returns (BingoGenerate.Card memory) {
        return BingoGenerate.generateBingoCard(cardRandomness[cardId]);
    }

    function validateCard(uint256 cardId) public view returns (bool) {
        return BingoGenerate.validateWinner(cardRandomness[cardId], Balls, pattern);
    }

    function getCurrent() public view returns (uint256 game, uint256 token) {
        game = _gameIds.current();
        token = _tokenIds.current();
    }

    function exists(uint256 tokenId) public view returns(bool) {
        return _exists(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://api.bingoswap.art/bingo-json/";
    }

    /*
    *   Setters.
    */
    function contractSettings(bool _startGame, bool _startAuto, uint256 _ballDrawTime, uint256 _minCardsPerGame, uint256 _maxCardsPerGame, uint256 _pricePerCard, uint256 _prizeSplit, uint256 _pattern, address _owner) public onlyOwner {
        startGame = _startGame;
        startAuto = _startAuto;
        ballDrawTime = _ballDrawTime;
        minCards = _minCardsPerGame;
        maxCards = _maxCardsPerGame;
        pricePerCard = _pricePerCard;
        prizeSplit = _prizeSplit;
        pattern = _pattern;
        owner = _owner;
    }

    /*
    *   Money management.
    */
    function withdraw(IERC20 _token, uint256 _amount) public payable onlyOwner {
        if(_amount > 0) {
            _token.transfer(msg.sender, _amount);
        } else {
            uint256 _each = address(this).balance.sub(prizePool+winnerPool).div(4);
            require(payable(0x00796e910Bd0228ddF4cd79e3f353871a61C351C).send(_each));   // sara
            require(payable(0x7fc55376D5A29e0Ee86C18C81bb2fC8F9f490E50).send(_each));   // shaun
            require(payable(0xB58Fb5372e9Aa0C86c3B281179c05Af3bB7a181b).send(_each));   // mark
            require(payable(0xd83Dd8A288270512b8A46F581A8254CD971dCb09).send(_each));   // community (@todo replace)
        }
    }
}
