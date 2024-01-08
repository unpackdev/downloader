// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;


import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Emojiland is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string[] emojiGrid;
    uint256[] emojiPlacement;
    mapping(uint256 => bool) placementExists;

    uint256 b1 = 14847130;
    uint256 b2 = 14855573;

    uint256 b3 = 4036984964;
    uint256 b4 = 4036995762;

    uint256 b5 = 249042553518223;
    uint256 b6 = 250184427616399;

    uint256 b7 = 10115200151880611;
    uint256 b8 = 67729485498136719;

    uint256 b9 = 17338726241471006632;
    uint256 b10 = 17338726348845189052;

    uint256 b11 = 290895720109770093197502138;
    uint256 b12 = 290896144096653412365477565;

    uint256 b13 = 19064140619185476506089144957071;
    uint256 b14 = 19064169765631408777539437443215;

    
    constructor() ERC721 ("Emojiland", "EMOJI") {  }

    function bytesToUint(bytes memory b) internal pure returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(uint8(b[i]))*(2**(8*(b.length-(i+1))));
        }
        return number;
    }

    function isSingleEmoji(string memory em) view public returns(bool) {
        uint256 test = bytesToUint(bytes(em));

        return (
            (test >= b1 && test <= b2) || 
            (test >= b3 && test <= b4) || 
            (test >= b5 && test <= b6) || 
            (test >= b7 && test <= b8) || 
            (test >= b9 && test <= b10) ||
            (test >= b11 && test <= b12) ||
            (test >= b13 && test <= b14));
    }

    function setEmoji(uint256 tokenId, string memory em) public {
        bool allowed = _isApprovedOrOwner(msg.sender, tokenId);
        bool isEmoji = isSingleEmoji(em);
        require(isEmoji, "Must be an emoji");
        require(allowed, "Must own spot");
        emojiGrid[tokenId] = em;
    }

    function getEmojiGrid() public view returns(string[] memory) {
        return emojiGrid;
    }

    function getEmojiPlacement() public view returns(uint256[] memory) {
        return emojiPlacement;
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;

            uint256 tokenId;

            for (tokenId = 0; tokenId < _tokenIds.current(); tokenId++) {
                if (ownerOf(tokenId) == _owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function uint2str(uint value) internal pure returns (string memory) {
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

    function mintSpot(string memory em, uint256 x, uint256 y) public {
        uint256 newItemId = _tokenIds.current();

        bool isEmoji = isSingleEmoji(em);
        require(isEmoji, "Must be an emoji");

        uint256 loc = x*100 + y;
        require(!placementExists[loc]);

        placementExists[loc] = true;
        emojiPlacement.push(loc);
        emojiGrid.push(em);

        string memory xStr = uint2str(x);
        string memory yStr = uint2str(y);


        string memory finalTokenUri = string(
            abi.encodePacked(
                "https://api.injectmagic.com/emojiland_metadata/",
                        yStr,
                        "_",
                        xStr,
                        ".json"
            )
        );

        _safeMint(msg.sender, newItemId);
        
        // Update your URI!!!
        _setTokenURI(newItemId, finalTokenUri);
    
        _tokenIds.increment();
    

   
    }
}