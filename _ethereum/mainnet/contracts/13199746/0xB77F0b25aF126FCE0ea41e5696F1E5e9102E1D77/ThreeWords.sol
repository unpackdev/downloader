/*
______       __ __ __   ______   ______    ______   ______      
/_____/\     /_//_//_/\ /_____/\ /_____/\  /_____/\ /_____/\     
\:::_:\ \    \:\\:\\:\ \\:::_ \ \\:::_ \ \ \:::_ \ \\::::_\/_    
   /_\:\ \    \:\\:\\:\ \\:\ \ \ \\:(_) ) )_\:\ \ \ \\:\/___/\   
   \::_:\ \    \:\\:\\:\ \\:\ \ \ \\: __ `\ \\:\ \ \ \\_::._\:\  
   /___\:\ '    \:\\:\\:\ \\:\_\ \ \\ \ `\ \ \\:\/.:| | /____\:\ 
   \______/      \_______\/ \_____\/ \_\/ \_\/ \____/_/ \_____\/
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Context.sol";
import "./Counters.sol";

contract ThreeWords is
    Context,
    ERC721
{
    event Mint(
        bytes32 indexed phraseId,
        uint256 indexed tokenId,
        string word1,
        string word2,
        string word3
    );

    address payable public multisig;
    address payable DRIBNET = payable(0x370433a205B84839B507420B8E22900BAb902a8b);
    address dev1 = 0x8E9da8Ac8643D24Fb19B70Afe563fdE2eC7A7DeC;
    address dev2 = 0xEf3c42eB484aE448CBbE4391D3CC4E16AAaB0d24;
    address dev3 = 0x01f81279Fec131a3E2fa7a61C429cf953d8f3f83;

    uint MAX_SUPPLY = 333;
    uint DEV_RESERVED = 33;
    uint256 PRICE = 333 * 10**15; // 0.333 ETH
    uint256 ROYALTY_PRICE = 999 * 10**13; // 3% of PRICE

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _devReserveTracker;

    mapping(bytes32 => uint256) private _phraseIdToTokenId;

    mapping(uint256 => bytes32) private _tokenIdToPhraseId;

    mapping(uint256 => string[]) private _tokenIdToWords;

    constructor(
        string memory name,
        string memory symbol,
        address payable _multisig
    ) ERC721(name, symbol) {
        multisig = _multisig;
        _tokenIdTracker.increment(); // start tokenIds from 1
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked("https://3wordsproject.com/metadata/", Strings.toString(tokenId), ".json"));
    }

    function tokenIdToPhraseId(uint256 tokenId) public view returns (bytes32) {
        require(_exists(tokenId), "ERC721Metadata: tokenPhrase query for nonexistent token");

        return _tokenIdToPhraseId[tokenId];
    }

    function wordsToTokenId(string memory _word1, string memory _word2, string memory _word3) public view returns (uint256) {
        return phraseIdToTokenId(wordsToPhraseId(_word1, _word2, _word3));
    }

    function wordsToPhraseId(string memory _word1, string memory _word2, string memory _word3) public view returns (bytes32) {
        return keccak256(abi.encodePacked(_word1, _word2, _word3));
    }

    function phraseIdToTokenId(bytes32 phraseId) public view returns (uint256) {
        uint256 tokenId = _phraseIdToTokenId[phraseId];
        require(tokenId != 0 && _exists(tokenId), "ERC721Metadata: tokenPhrase query for nonexistent token");
        return tokenId;
    }

    function tokenIdToWords(uint256 tokenId) public view returns (string[] memory) {
        return _tokenIdToWords[tokenId];
    }

    function mint(string memory _word1, string memory _word2, string memory _word3)
        public
        payable
    {
        require (bytes(_word1).length <= 16 && bytes(_word2).length <= 16 && bytes(_word3).length <= 16, "words must be less than 16 bytes");
        address receiver = _msgSender();
        bool receiverIsDev = (receiver == dev1 || receiver == dev2 || receiver == dev3);
        require (msg.value >= PRICE, "must pay mint fee");
        if (receiverIsDev) {
            require (_devReserveTracker.current() < DEV_RESERVED, "multisig cannot mint more than reserve amount");
            _devReserveTracker.increment();
        }
        uint256 multisigFee = msg.value - ROYALTY_PRICE;
        DRIBNET.call{value: ROYALTY_PRICE}("");
        multisig.call{value: multisigFee}("");
        require(_tokenIdTracker.current() - 1 + DEV_RESERVED - _devReserveTracker.current() < MAX_SUPPLY, "max supply reached"); // - 1 because tokenIdTracker.current starts at 1
        bytes32 phraseId = wordsToPhraseId(_word1, _word2, _word3);
        require(_phraseIdToTokenId[phraseId] == 0, "phrase already minted"); // this is why we start tokenid at 1
        uint256 tokenId = _tokenIdTracker.current();
        _phraseIdToTokenId[phraseId] = tokenId;
        _tokenIdToPhraseId[tokenId] = phraseId;
        _tokenIdToWords[tokenId] = [_word1, _word2, _word3];
        _mint(receiver, tokenId);
        _tokenIdTracker.increment();
        emit Mint(phraseId, tokenId, _word1, _word2, _word3);
    }
}
