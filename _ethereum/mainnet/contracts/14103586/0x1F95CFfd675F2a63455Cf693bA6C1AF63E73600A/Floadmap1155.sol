//
//                  &&&&&&&&&&//////////////////////////////
//                  &&&&&&&&&&//////////////////////////////
//                  &&&&&&&&&&//////////////////////////////
//                  &&&&&&&&&&//////////////////////////////
//                  &&&&&&&&&&&&&&&&&&&&          //////////
//                  &&&&&&&&&&&&&&&&&&&&          //////////
//                  &&&&&&&&&&&&&&&&&&&&          //////////
//                  &&&&&&&&&&&&&&&&&&&&          //////////
//                  &&&&&&&&&&          ////////////////////
//                  &&&&&&&&&&          ////////////////////
//                  &&&&&&&&&&          ////////////////////
//                  &&&&&&&&&&          ////////////////////
//                  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&//////////
//                  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&//////////
//                  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&//////////
//                  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&//////////
//
//                               flipmap.art
//
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Flipmap.sol";
import "./Flipdata.sol";
import "./Flipkey1155.sol";

contract Floadmap1155 is ERC1155, Ownable, ERC1155Supply, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    using Address for address;

    string public name = 'Floadmaps';

    struct Quest {
        string clue;
        bytes32 answer;
        string feature;
        string keyword;
        string cipher;
        uint256 keys;
    }

    uint256 public constant maxQuests = 12;
    uint256[13] public _solvedQuests;

    mapping(uint256 => Quest)   public _quests;
    mapping(uint256 => string)  public _tokenPayload;

    Flipmap     private flipmap;
    Flipkey1155 private flipkey;
    Flipdata    private flipdata;

    event QuestUpdated(uint256 questId);
    event PayloadUpdated(uint256 tokenId);
    event QuestSolved(uint256 questId, uint256 tokenId, address solver);

    constructor(address _flipmapAddress, address _flipkeyAddress, address _flipdataAddress) ERC1155("") {
        flipmap = Flipmap(_flipmapAddress);
        flipkey = Flipkey1155(_flipkeyAddress);
        flipdata = Flipdata(_flipdataAddress);

        for(uint i=0; i<maxQuests; i++) {
            _tokenIds.increment();
        }
    }

    function mint(uint256 id, address to) public onlyOwner {
        _mint(to, id, 1, bytes(""));
    }

    function airdropBatch(address[] calldata userAddresses, uint256[] calldata ids, uint256[] calldata amounts) public onlyOwner {
        bytes memory data;
        for(uint256 i=0; i<userAddresses.length; i++) {
            _mint(userAddresses[i], ids[i], amounts[i], data);
        }
    }

    function setQuest(uint256 id, string memory clue, bytes32 answer, string memory feature, string memory keyword, string memory cipher, uint256 keys) public onlyOwner {
        require(id <= maxQuests);
        Quest memory quest;
        quest.clue = clue;
        quest.answer = answer;
        quest.feature = feature;
        quest.keyword = keyword;
        quest.cipher = cipher;
        quest.keys = keys;
        _quests[id] = quest;
        emit QuestUpdated(id);
    }

    function resetQuest(uint256 id) public onlyOwner {
        _solvedQuests[id] = 0;
    }

    function setPayload(uint256 id, string memory payload) public onlyOwner {
        _tokenPayload[id] = payload;
        emit PayloadUpdated(id);
    }

    function solveQuest(uint256 questId, string memory answer) public nonReentrant {
        require(balanceOf(msg.sender, questId) > 0);
        require(_solvedQuests[questId] == 0);
        require(checkQuest(questId, answer));

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        _solvedQuests[questId] = tokenId;
        _burn(msg.sender, questId, 1);
        _mint(msg.sender, tokenId, 1, bytes(""));

        uint256 keys = _quests[questId].keys;
        if(keys > 1) {
            flipkey.mintRandomBatch(msg.sender, keys);
        } else {
            flipkey.mintRandom(msg.sender);
        }

        emit QuestSolved(questId, tokenId, msg.sender);
    }

    function checkQuest(uint256 questId, string memory answer) public view returns (bool) {
        bytes32 hashed = sha256(bytes(answer));
        if(hashed == _quests[questId].answer) {
            return true;
        }
        return false;
    }

    function getByOwner(address owner) view public returns(uint256[] memory ids, uint256[] memory result) {
        uint256 totalTokens;
        for(uint256 i = 0; i <= _tokenIds.current(); i++) {
            if(balanceOf(owner, i) > 0) {
                totalTokens++;
            }
        }
        result = new uint256[](totalTokens);
        ids = new uint256[](totalTokens);
        uint256 resultIndex = 0;
        for (uint256 t = 1; t <= _tokenIds.current(); t++) {
            if (balanceOf(owner, t) > 0) {
                result[resultIndex] += balanceOf(owner, t);
                ids[resultIndex] = t;
                resultIndex++;
            }
        }
    }

    function setFlipdataAddress(address _flipdata) public onlyOwner {
        flipdata = Flipdata(_flipdata);
    }

    function setFlipmapAddress(address _flipmap) public onlyOwner {
        flipmap = Flipmap(_flipmap);
    }

    function setFlipkeyAddress(address _flipkey) public onlyOwner {
        flipkey = Flipkey1155(_flipkey);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        uint solved;
        if(tokenId <=12) {
            solved = _solvedQuests[tokenId];
        }
        return flipdata.getJSON(tokenId, _quests[tokenId], solved, _tokenPayload[tokenId]);
    }

    function toString(uint256 value) public pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }}
