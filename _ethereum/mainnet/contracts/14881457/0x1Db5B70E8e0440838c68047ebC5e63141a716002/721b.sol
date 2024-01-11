// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC721B.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

/*
 * &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
 * ##&&&&&&#&&#&&#&&#&&#&&#&&#&&#&&#&&#&&#&&#&&#&&#&&#&&#&&#&&#&&#&&#&&#&&#&&&&&&&#
 * B55PB##################################################################&##BG5JJB
 * &#5JJYY5GB########################################################&##BG5Y?7!!J#&
 * &&&PJJJJJJYY5GB#################################################BG5Y?7!!!!!!5&&&
 * &&&&BYJJJJJJJJJYYPGB####################################&&#BGPY?7!!!!!777!?G&&&&
 * &&&&&#5JJJJJJJJJJJJJY5PGB###########################&##GPY?7!!!!!7777777!J#&&&&&
 * &&&&&&&PJJJJJJJJJJJJJJJJJY5PGB#################&##BPYJ7!!!!!!777777777775&&&&&&&
 * &&&&&&&&BYJJJJJJJJJJJJJJJJJJJJY5PGB#######&##BPYJ77!!!!!!777777777777!7G&&&&&&&&
 * &&&&&&&&&#5JJJJJJJJJJJJJJJJJJJJJJJJY5PGBBP5J77!!!!!77777777777777777!J#&&&&&&&&&
 * &&&&&&&&&&&PJJJJJJJJJJJJJJJJJJJJJJJJJJJJ7!!!!!77777777777777777777775#&&&&&&&&&&
 * &&&&&&&&&&&&GJJJJJJJJJJJJJJJJJJJJJJJJJJJ7!7777777777777777777777777P&&&&&&&&&&&&
 * &&&&&&&&&&&&&#YJJJJJJJJJJJJJJJJJJJJJJJJJ7777777777777777777777777J#&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&PJJJJJJJJJJJJJJJJJJJJJJJJ777777777777777777777777Y&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&GYJJJJJJJJJJJJJJJJJJJJJJ77777777777777777777777P&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&BYJJJJJJJJJJJJJJJJJJJJJ777777777777777777777?B&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&PJJJJJJJJJJJJJJJJJJJJ77777777777777777777Y#&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&GJJJJJJJJJJJJJJJJJJJ7777777777777777777P&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&BYJJJJJJJJJJJJJJJJJ77777777777777777?B&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&#5JJJJJJJJJJJJJJJJ7777777777777777Y#&&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&&&GJJJJJJJJJJJJJJJ777777777777777P&&&&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&&&&BYJJJJJJJJJJJJJ7777777777777?G&&&&&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&&&&&#5JJJJJJJJJJJJ777777777777Y#&&&&&&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&&&&&&&GJJJJJJJJJJJ77777777777P&&&&&&&&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&&&&&&&&BYJJJJJJJJJ777777777?B&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#5JJJJJJJJ77777777J#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&PJJJJJJJ77777775&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&BYJJJJJ77777?G&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#5JJJJ7777Y#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&PJJJ7775&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&GYJ7?G&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#YJ#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
 * &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
 */

contract TrianglizeBirds is ERC721B, ReentrancyGuard {
    uint256 constant MaxTotalSupply = 3333;
    uint256 constant MaxFreeMintSupply = 3333 / 3; // 1111
    uint256 constant MaxFreeMintPerWallet = 10;
    mapping(address => uint8) freeMintCountMap;

    uint256 price = 0.0333 ether;

    string baseURI;

    constructor() ERC721B("AI Trianglize Moonbirds", "AITMB") {}
    

    function freeMint(uint8 quantity) external nonReentrant payable {
        freeMintCountMap[msg.sender] = freeMintCountMap[msg.sender] + quantity;
        require(totalSupply() + quantity <= MaxFreeMintSupply, "Excceed total free mint supply.");
        require(freeMintCountMap[msg.sender] <= MaxFreeMintPerWallet, "max free mint quantity is MaxFreeMintPerWallet");
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external nonReentrant payable {
        require(totalSupply() + quantity <= MaxTotalSupply, "Exceed the max total supply.");
        require(msg.value >= price * quantity, "Ether value sent is not correct");
        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), 
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length, 
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for { 
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp { 
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } { // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }
            
            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }
    
    function withdraw() external {
        uint256 balance = address(this).balance * 3 / 10;
        Address.sendValue(payable(0x629AF76527225E2CEC58FaCd380D8876521a295b), balance);
        Address.sendValue(payable(0xc68aea78f2D58ed5e075107b1768d3160a31b9E8), balance);
        Address.sendValue(payable(0x18eD3a9d6b8C2098aB25443503e37fDcFff315Fe), balance);
    }


}