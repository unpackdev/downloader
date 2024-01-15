// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";


//   
//	oooooo   oooooo     oooo       .o.       ooooooooo.   
//	 `888.    `888.     .8'       .888.      `888   `Y88. 
//	  `888.   .8888.   .8'       .8"888.      888   .d88' 
//	   `888  .8'`888. .8'       .8' `888.     888ooo88P'  
//		`888.8'  `888.8'       .88ooo8888.    888`88b.    
//		 `888'    `888'       .8'     `888.   888  `88b.  
//		  `8'      `8'       o88o     o8888o o888o  o888o
//
//          >> location.href = "https://war.wtf.cards"
//



interface External {
    function getCardNameByIndex(uint256 _index) external view returns (string memory);
    function getCardIconByIndex(uint256 _index) external view returns (string memory);
    function shuffle(address _addr) external view returns (uint160);
    function airdrop(address _address, uint256 _amount) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
}


contract War is ERC721A, ERC721ABurnable, ReentrancyGuard, Ownable, VRFConsumerBaseV2  {

    mapping(address => bool) internal limiter;
    mapping(uint256 => bool) public cardsTokenUsed;
    mapping(address => uint256) public wins;
    mapping(uint256 => uint256) public roundToHash;

    address cardsAddress = 0x490eBBea3d433a35902d948c5251318f25f68407;
    address shufflerAddress = 0x27eCbfa2a112DCb6672D9A5B85112F0a1595e3F2;
    address airdropAddress;

    uint256 round = 0;
    uint256 cardsClaimed;

    bool hiddenCards = true;
    bool airdropIsActive;
    bool vrfIsActive;
    bool claimIsEnabled;

    constructor()
    VRFConsumerBaseV2(0x271682DEB8C4E0901D1a1550aD2e64D568E69909)
    ERC721A("War", "WAR")
    {

        COORDINATOR = VRFCoordinatorV2Interface(0x271682DEB8C4E0901D1a1550aD2e64D568E69909);
        vrfSubscriptionId = 346;
        vrfKeyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    }
    
    struct communication {
        uint256 timestamp;
        string message;
    }                                           

    communication[] communications;

    function devMessage(string memory _message) external onlyOwner {
        communications.push(communication(block.timestamp, _message));
    }

    function getDevMessages() external view returns (communication[] memory) {
        return communications;
    }

    function startClaim() external onlyOwner {
        claimIsEnabled = true;
    }

    function claim(uint160 _shuffleIndex) public nonReentrant shuffle(_shuffleIndex) {
        require(claimIsEnabled, "Claim is not live.");
        require(!limiter[msg.sender], "One claim per wallet.");
        require(tx.origin == msg.sender, "EOAs only.");
        require(totalSupply() < 777 + cardsClaimed, "Max supply of 999.");
        limiter[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function claimWithCards(uint256 _tokenId) public nonReentrant {
        require(claimIsEnabled, "Claim is not live.");
        require(msg.sender == External(cardsAddress).ownerOf(_tokenId), "You do not own this CARDS token.");
        require(!cardsTokenUsed[_tokenId], "Token already used.");
        require(cardsClaimed < 333, "Only 333 can be regist with CARDS.");
        cardsClaimed++;
        cardsTokenUsed[_tokenId] = true;
        _safeMint(msg.sender, 1);
    }

    function mintFirstToken() external onlyOwner {
        require(totalSupply() == 0, "This function can only mint the first token in the collection.");
        _safeMint(msg.sender, 1);
    }

    function registerWin(uint256 _tokenId) public nonReentrant {
        require(ownerOf(_tokenId) == msg.sender);
        require(results(_tokenId) == 1);
        wins[msg.sender]++;
        _burn(_tokenId);
    }

    function winnerClaimAirdrop() external nonReentrant {
        uint amount = wins[msg.sender];
        require(hiddenCards);
        require(airdropIsActive);
        require(amount > 0);
        wins[msg.sender] = 0;
        External(airdropAddress).airdrop(msg.sender, amount);   
    }

    function setAirdropState(address _airdropAddress, bool _active) public onlyOwner {
        require(hiddenCards);
        airdropIsActive = _active;
        airdropAddress = _airdropAddress;
    }

    function startNextRound() external onlyOwner {
        require(hiddenCards);
        vrfIsActive = true;
        requestRandomWords();
    }

    function endRound() public onlyOwner {
        hiddenCards = true;
    }

    function getWinCount(address _addr) public view returns (uint256) {
        return wins[_addr];
    }

    function wasCardsTokenUsed(uint256 _tokenId) public view returns (bool) {
        return cardsTokenUsed[_tokenId];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked('data:application/json;base64,', getMetadataJSON(tokenId)));
    }

    function resultsToString(uint256 _tokenId) public view returns (string memory) {
        uint256 results = results(_tokenId);
        string memory resultString;
        if (results == 2) {
            resultString = "Loser";
        } else if (results == 1) {
            resultString = "Winner";
        } else if (results == 3) {
            resultString = "Draw";
        }
        return resultString;
    }

    function getMetadataImage(uint256 _tokenId) internal view returns (string memory) {
        uint256 houseCard = getHouseCard(_tokenId);
        uint256 playerCard = getPlayerCard(_tokenId);
        string memory houseColor = (houseCard < 13 || 38 < houseCard) ? 'Black' : 'Red';
        string memory playerColor = (playerCard < 13 || 38 < playerCard ) ? 'Black' : 'Red';
        string memory houseCardIcon = External(cardsAddress).getCardIconByIndex(houseCard);
        string memory playerCardIcon = External(cardsAddress).getCardIconByIndex(playerCard);
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500"><style>.title{fill:Black;font-size:40px;font-family:Courier}}</style><style>.card1{fill:',
            houseColor,
            ';font-size:250px;}</style><style>.card2{fill:',
            playerColor,
            ';font-size:250px;}</style><rect width="100%" height="100%" fill="white" /> <text x="30%" y="376px" class="title" dominant-baseline="middle" text-anchor="middle">House</text> <text x="30%" y="251px" class="card1" dominant-baseline="middle" text-anchor="middle">',
            houseCardIcon,
            '</text> <text x="70%" y="121px" class="title" dominant-baseline="middle" text-anchor="middle">Player</text> <text x="70%" y="301px" class="card2" dominant-baseline="middle" text-anchor="middle"',
            playerCardIcon,
            '</text></svg>'
        ));
    }

    function getMetadataJSON(uint256 _tokenId) internal view returns (string memory) {
        string memory json;
        if (!hiddenCards) {

            uint256 houseCard = getHouseCard(_tokenId);
            uint256 playerCard = getPlayerCard(_tokenId);
            string memory houseColor = (houseCard < 13 || 38 < houseCard) ? 'Black' : 'Red';
            string memory playerColor = (playerCard < 13 || 38 < playerCard ) ? 'Black' : 'Red';
            string memory houseCardIcon = External(cardsAddress).getCardIconByIndex(houseCard);
            string memory playerCardIcon = External(cardsAddress).getCardIconByIndex(playerCard);
            string memory svg = string(abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500"><style>.title{fill:Black;font-size:40px;font-family:Courier}}</style><style>.card1{fill:',
                houseColor,
                ';font-size:250px;}</style><style>.card2{fill:',
                playerColor,
                ';font-size:250px;}</style><rect width="100%" height="100%" fill="white" /> <text x="30%" y="376px" class="title" dominant-baseline="middle" text-anchor="middle">House</text> <text x="30%" y="251px" class="card1" dominant-baseline="middle" text-anchor="middle">',
                houseCardIcon,
                '</text> <text x="70%" y="121px" class="title" dominant-baseline="middle" text-anchor="middle">Player</text> <text x="70%" y="301px" class="card2" dominant-baseline="middle" text-anchor="middle">',
                playerCardIcon,
                '</text></svg>'
            ));
            string memory resultString = resultsToString(_tokenId);
            json = Base64.encode(bytes(string(abi.encodePacked(
                '{"name": "Game #',
                _toString(_tokenId),
                '","attributes": [ { "trait_type": "House Card", "value": "',
                External(cardsAddress).getCardNameByIndex(houseCard),
                '" },{ "trait_type": "Player Card", "value": "',
                External(cardsAddress).getCardNameByIndex(playerCard),
                '" },{ "trait_type": "Results", "value": "',
                resultString,
                '" }], "description": "Results: ',
                resultString,
                ' - Be sure to refresh the metadata before acquiring a winning token. Once you acquire a winning token be sure to redeem it before the end of the round as it will be reset during the next one.","image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '"}'
            ))));
        } else {
            json = Base64.encode(bytes(string(abi.encodePacked(
                '{"name": "War #',
                _toString(_tokenId),
                '","attributes": [ { "trait_type": "House Card", "value": "?" },{ "trait_type": "Player Card", "value": "?" },{ "trait_type": "Result", "value": "Undrawn" }], "description": "War is an on-chain card game. If you have a winning token, register it by burning it on the dApp before the end of the current round as it might be a loser in the next one.",',
                '"image": "data:image/svg+xml;base64,',
                Base64.encode(bytes('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500"> <style>.card1{fill:Black;font-size:250px;}</style> <style>.card2{fill:Black;font-size:250px;}</style> <style>.title{fill:Black;font-size:40px;font-family:Courier}}</style> <rect width="100%" height="100%" fill="white" /> <text x="30%" y="376px" class="title" dominant-baseline="middle" text-anchor="middle">House</text> <text x="30%" y="251px" class="card1" dominant-baseline="middle" text-anchor="middle">\xf0\x9f\x82\xa0</text> <text x="70%" y="121px" class="title" dominant-baseline="middle" text-anchor="middle">Player</text> <text x="70%" y="301px" class="card2" dominant-baseline="middle" text-anchor="middle">\xf0\x9f\x82\xa0</text> </svg>')),
                '"}'
            ))));
          }
        return json;
    }

    modifier activeVRF() {
        require(!vrfIsActive);
        _;
    }

    modifier shuffle(uint160 _shuffleIndex) {
        require(_shuffleIndex == getShuffleIndex(msg.sender), "Invalid Shuffle Index");
        _;
    }

    function transferFrom(address from, address to, uint256 tokenId) public activeVRF override {
        super.transferFrom(from, to, tokenId);
    }

    function getHouseCard(uint256 _tokenId) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(getCurrentRoundHash(), _tokenId, "houseCard", "0", ownerOf(_tokenId)))) % 52;
    }

    function getPlayerCard(uint256 _tokenId) internal view returns (uint256) {
        require(hiddenCards == false);
        uint256 index = uint256(keccak256(abi.encodePacked(getCurrentRoundHash(), _tokenId, "playerCard", "0", ownerOf(_tokenId)))) % 52;
        if (index == getHouseCard(_tokenId)) {
            for (uint256 i = 1; i < 52; i++) {
                index = uint256(keccak256(abi.encodePacked(getCurrentRoundHash(), _tokenId, "houseCards", _toString(i), ownerOf(_tokenId)))) % 52;
                if (index != getHouseCard(_tokenId)) {
                    break;
                }
            }
        }
        return index;
    }


    function getPointsForCardIndex(uint256 _index) internal view returns (uint256) {
        require(hiddenCards == false);
        uint256 i = _index;
        uint256 points;
        if (i == 0 || i == 13 || i == 26 || i == 39) {
            points = 14;
        } else if (i == 1 || i == 14 || i == 27 || i == 40) {
            points = 2;
        } else if (i == 2 || i == 15 || i == 28 || i == 41) {
            points = 3;
        } else if (i == 3 || i == 16 || i == 29 || i == 42) {
            points = 4;
        } else if (i == 4 || i == 17 || i == 30 || i == 43) {
            points = 5;
        } else if (i == 5 || i == 18 || i == 31 || i == 44) {
            points = 6;
        } else if (i == 6 || i == 19 || i == 32 || i == 45) {
            points = 7;
        } else if (i == 7 || i == 20 || i == 33 || i == 46) {
            points = 8;
        } else if (i == 8 || i == 21 || i == 34 || i == 47) {
            points = 9;
        } else if (i == 9 || i == 22 || i == 35 || i == 48) {
            points = 10;
        } else if (i == 10 || i == 23 || i == 36 || i == 49) {
            points = 11;
        } else if (i == 11 || i == 24 || i == 37 || i == 50) {
            points = 12;
        } else if (i == 12 || i == 25 || i == 38 || i == 51) {
            points = 13;
        }
        return points;

    }

    function results(uint256 _tokenId) public view returns (uint256) {
        uint256 houseScore = getPointsForCardIndex(getHouseCard(_tokenId));
        uint256 playerScore = getPointsForCardIndex(getPlayerCard(_tokenId));
        uint256 results; //1 = win; 2 = loss; 3 = draw
        if (houseScore > playerScore) {
            results = 2;
        } else if (houseScore < playerScore) {
            results = 1;
        } if (houseScore == playerScore) {
            results = 3;
        }
        return results;
    }

    function getShuffleIndex(address _addr) internal view returns (uint160) {
        return External(shufflerAddress).shuffle(_addr);
    }

    function getCurrentRoundHash() internal view returns (uint256) {
        return roundToHash[round];
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }                                   

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 vrfSubscriptionId;
    bytes32 vrfKeyHash;
    uint32 callbackGasLimit = 250000;
    uint16 requestConfirmations = 3;
    event RequestedRandomness(uint256 requestId);

    function requestRandomWords() private { 
        uint32 numWords =  1;
        uint256 requestId = COORDINATOR.requestRandomWords(
            vrfKeyHash,
            vrfSubscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 extraNoise = uint256(keccak256(abi.encodePacked(msg.sender))) % 10000000;
        round++;
        roundToHash[round] = randomWords[0] + extraNoise;
        hiddenCards = false;
        vrfIsActive = false;
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
