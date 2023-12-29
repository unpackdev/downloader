// SPDX-License-Identifier: MIT
// t11s god himself
// ✅ make mintPrice constant
// 🔴 consider removing creators
// 🔴 consider removing ourMessage
// ✅ make heartURIs a mapping of uint256s
// ✅ don't use OZ counters
// ✅ dont use a uint8 for the loop counter (its gonna get cast to 256 bits as thats the evm wordsize)
// ✅ dont cast to a uint8 for digit
// 🔴 the "slow down" ratelimit in mint is basically useless, consider removing
// ✅ don't use uint8 for loop in mint
// ✅ dont use uint8 for loop in setHeartURIs
// ✅ don't use uint8 for loop in setCustomURIs
// ✅ make maxSupply constant
// ✅ precompute the empty hash in a constant for setCustomURIs (keccak256(abi.encodePacked("")))
// ✅ make all arrays args in external funcs `calldata`
// ✅ wrap all ur loop counters in unchecked
// ✅ rule of thumb: always calldata if the compiler will let u
/*
   _      ΞΞΞΞ      _
  /_;-.__ / _\  _.-;_\
     `-._`'`_/'`.-'
         `\   /`
          |  /
         /-.(
         \_._\
          \ \`;
           > |/
          / //
          |//
          \(\
           ``
     defijesus.eth
*/
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";

error NonExistantToken();
error SlowDown();
error CorrectChangeOnly();
error TooMany();
error WrongArraySize();

contract CryptoHeart is ERC721, Pausable, Ownable {
    // these 2 have to stay
    string public constant CREATORS =
        "defijesus.eth+gbaby.eth+jpegmedia.eth+kingkav.eth";
    string public constant README =
        "People with disabilities have helped us gain a better perspective on life. I hope this project does the same for you.";

    uint256 public constant mintPrice = 50000000000000000;

    bytes32 private constant emptyString = keccak256(abi.encodePacked(""));

    // mapping is cheaper than string[]
    mapping(uint256 => string) public heartURIs;

    // token ID => custom token URI
    mapping(uint256 => string) public customURIs;

    uint256 public constant maxSupply = 1000;

    uint256 public currentSupply = 0;

    constructor(string[] memory _heartURIs) ERC721("CryptoHeart", "HEART") {
        unchecked {
            for (uint256 i = 0; i < 10; i++) {
                heartURIs[i] = _heartURIs[i];
                safeMint(msg.sender);
            }
        }
        pause();
    }

    // CUSTOM FUNCTIONS

    // PUBLIC

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert NonExistantToken();
        }
        if (keccak256(abi.encodePacked(customURIs[tokenId])) != emptyString) {
            return customURIs[tokenId];
        }
        uint256 digit = uint256(tokenId % 10);
        return heartURIs[digit];
    }

    function mint(uint256 amount) external payable whenNotPaused {
        if (amount > 20) {
            revert SlowDown();
        } else if (msg.value != mintPrice * amount) {
            revert CorrectChangeOnly();
        } else if (currentSupply + amount > maxSupply) {
            revert TooMany();
        }
        unchecked {
            for (uint256 i = 0; i < amount; i++) {
                safeMint(msg.sender);
            }
        }
    }

    // ONLY OWNER

    function setHeartURIs(string[] calldata URIs) external onlyOwner {
        if (URIs.length != 10) {
            revert WrongArraySize();
        }
        unchecked {
            for (uint256 i = 0; i < URIs.length; i++) {
                heartURIs[i] = URIs[i];
            }
        }
    }

    function setCustomURIs(
        uint256[] calldata tokenIDs,
        string[] calldata tokenURIs
    ) external onlyOwner {
        if (tokenIDs.length != tokenURIs.length) {
            revert WrongArraySize();
        }
        unchecked {
            for (uint256 i = 0; i < tokenIDs.length; i++) {
                if (keccak256(abi.encodePacked(tokenURIs[i])) == emptyString) {
                    delete customURIs[tokenIDs[i]];
                } else {
                    customURIs[tokenIDs[i]] = tokenURIs[i];
                }
            }
        }
    }

    function withdrawEther(address payable to) external onlyOwner {
        to.call{value: address(this).balance}("");
    }

    function safeMint(address to) internal {
        _safeMint(to, currentSupply);
        currentSupply += 1;
    }

    // DEFAULT FUNCTIONS

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
