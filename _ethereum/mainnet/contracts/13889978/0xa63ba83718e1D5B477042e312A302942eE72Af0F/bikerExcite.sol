//SPDX-License-Identifier: MIT
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)

pragma solidity ^0.8.0;

/*
CHAIN BIKERZ - EXCITE WHITELIST NFT GAME 
*/

import "./ERC721.sol";
import "./IERC20.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./Counters.sol";
import "./Strings.sol";

interface animations {
    function draw(uint256 tokenId, uint256 pts) external view returns (string memory);
}

contract BikerzExcite is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    uint8 private tricks;

    uint256 public maxBikerz;
    uint256 public maxGiftedBikerz;
    uint256 public maxFreeBikerz;
    uint256 public numGiftedBikerz;
    uint256 public cooldown = 6000;

    uint256 public constant PUBLIC_SALE_PRICE = 0.02 ether;

    uint256 public startBlock;
    uint8 public MAX_PER_WALLET = 5;
    uint8 public MAX_FREE_PER_WALLET = 2;
    string private randomizer;

    animations[9] private animationAddress;
    uint256[9] private pointValues;

    struct Score {
        uint256 currentTrick;
        uint256 pts;
    }

    mapping (uint256 => Score) public scoreMap;

    modifier canMintBikerz(uint256 numberOfTokens) {
        require(
            tokenCounter.current() + numberOfTokens <=
                maxBikerz - maxGiftedBikerz,
            "Not enough Bikerz remaining to mint"
        );
        _;
    }

    modifier canMintFreeBikerz(uint256 numberOfTokens) {
        require(
            tokenCounter.current() + numberOfTokens <=
                maxFreeBikerz,
            "Not enough Free Bikerz remaining to mint"
        );
        _;
    }

    modifier canGiftBikerz(uint256 num) {
        require(
            numGiftedBikerz + num <= maxGiftedBikerz,
            "Not enough Bikerz remaining to gift"
        );
        require(
            tokenCounter.current() + num <= maxBikerz,
            "Not enough Bikerz remaining to mint"
        );
        _;
    }

    constructor(
        uint256 _maxBikerz,
        uint256 _maxGiftedBikerz,
        uint256 _maxFreeBikerz,
        animations[9] memory createTricks,
        uint256[9] memory vals
    ) ERC721("Bikerz Excite", "BIKERZ") {
        maxBikerz = _maxBikerz;
        maxGiftedBikerz = _maxGiftedBikerz;
        maxFreeBikerz = _maxFreeBikerz;
        resetData (createTricks, vals, "START");
        cooldown = 6000;
    }

    function resetData (animations[9] memory createTricks, uint256[9] memory vals, string memory randomizePhrase) public onlyOwner {
       setMetadataAddress(createTricks);
       setPointValues(vals);
       setRandomizer(randomizePhrase);
       saveAllPoints();
       startBlock = block.number;
    }

    function setRandomizer(string memory str) public onlyOwner {
        randomizer = str;
    }

    function setCooldown(uint256 cd) public onlyOwner {
        cooldown = cd;
    }

    function setMetadataAddress(animations[9] memory addrs) public onlyOwner {
        for (uint8 i = 0; i < 9; i++) {
            animationAddress[i] = addrs[i];
        }
    }

    function setPointValues(uint256[9] memory values) public onlyOwner {
        for (uint8 i = 0; i < 9; i++) {
            pointValues[i] = values[i];
        }
    }

    modifier maxBikerzPerWallet(uint256 numberOfTokens) {
        require(
            balanceOf(msg.sender) + numberOfTokens <= MAX_PER_WALLET,
            "Max bikerz to mint is five"
        );
        _;
    }
    modifier maxFreeBikerzPerWallet(uint256 numberOfTokens) {
        require(
            balanceOf(msg.sender) + numberOfTokens <= MAX_PER_WALLET,
            "Max free bikerz to mint is two"
        );
        _;
    }


    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    function mintFree(uint256 numberOfTokens)
        external
        nonReentrant
        canMintFreeBikerz(numberOfTokens)
        maxFreeBikerzPerWallet(numberOfTokens)
    {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function mint(uint256 numberOfTokens)
        external
        nonReentrant
        payable
        canMintBikerz(numberOfTokens)
        maxBikerzPerWallet(numberOfTokens)
        isCorrectPayment(PUBLIC_SALE_PRICE, numberOfTokens)
    {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        
        string memory parts;              
        parts = animationAddress[trick(tokenId)].draw(tokenId, scoreMap[tokenId].pts); 
        string memory scene = parts;      
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Chain Bikerz - Excite #', toString(tokenId), '", "description": "',  "Excite Chain Bikers is a on-chain NFT game.", '", "image": "data:image/svg+xml;base64,',Base64.encode(bytes(scene)),'" }'))));
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));
           
        return output;
    }
    
    function toString(uint256 value) public pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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


    function randomizeTrick(uint256 tokenId) private view returns (uint256){
        return uint256(keccak256(abi.encodePacked(randomizer, tokenId))) % 9;
    }
    
    function trick(uint256 tokenId) private view returns (uint256) { 
        uint256 delta = block.number - startBlock;
        uint256 trickNum = delta / cooldown;
        uint256 ranTrick = randomizeTrick(tokenId);
        uint256 doTrick = ((trickNum + ranTrick) % 9);
        return doTrick;
    }
    
    function saveAllPoints() public onlyOwner {      
        for (uint256 i = 0; i <= tokenCounter.current(); i++) {
            savePoints(i);
        }   
    }

    function savePoints(uint256 tokenId) private onlyOwner {      
        uint256 delta = block.number - startBlock;        
        uint256 numberOfTotalTricks = delta / cooldown;   

        for (uint256 i = 0; i <= numberOfTotalTricks; i++) {
            uint256 ranTrick = randomizeTrick(tokenId);
            uint256 doTrick = ((i + ranTrick) % 9);
            scoreMap[tokenId].pts += pointValues[doTrick];
        }   
    }

    function giftBikerz(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
        canGiftBikerz(addresses.length)
    {
        uint256 numToGift = addresses.length;
        numGiftedBikerz += numToGift;

        for (uint256 i = 0; i < numToGift; i++) {
            _safeMint(addresses[i], nextTokenId());
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
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
