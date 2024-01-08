
// SPDX-License-Identifier: MIT

import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";

pragma solidity ^0.8.0;


/// @title Dice
/// @notice This contract mints 1000 Dice NFTs that can be rolled by anyone.
/// Metadata and pRNG are all stored on chain and can be used by anyone, whether they hold the NFT or not.
/// NFT holders can optionally set administrative functions around NFTs they hold, including modifying the payable.
/// Minting is 0.01 ETH, proceeds will be used for other experiments. Don't want to pay, you're welcome to fork.
/// There are known limitations of pRNG utilising onchain information, which could be subject to manipulation.
/// @notice This contract is experimental and has not been audited. Use at your own risk.


contract Dice is ERC721Enumerable, ReentrancyGuard {

    uint256 constant BASIS_POINTS = 2530;
    uint256 internal nonce = 0;
    
    address public deployerAddress;

    struct DiceRoll {
        uint256 rollCount; // keep track of the number of times that this dice has been rolled
        uint256 rollValue; // last value rolled
        uint256 rollPrice; // price to roll this dice
        uint256 rollKeep; // amount of ETH paid to this dice
    }

    mapping (uint256 => DiceRoll) public diceRolls;

    event DiceRolled(uint256 tokenId, uint256 rollValue, uint256 timeStamp);

    string[] private dieFaces = [
        '', // should show nothing when first initiatized
        '<circle cx="145" cy="175" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" />',
        '<circle cx="220" cy="100" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" /><circle cx="70" cy="250" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" />',
        '<circle cx="220" cy="100" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" /><circle cx="70" cy="250" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" /><circle cx="145" cy="175" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" />',
        '<circle cx="220" cy="100" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" /><circle cx="70" cy="250" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" /><circle cx="70" cy="100" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" /><circle cx="220" cy="250" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" />',
        '<circle cx="220" cy="100" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" /><circle cx="70" cy="250" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" /><circle cx="145" cy="175" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" /><circle cx="70" cy="100" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" /><circle cx="220" cy="250" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" />',
        '<circle cx="220" cy="100" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" /><circle cx="70" cy="250" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" /><circle cx="70" cy="100" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" /><circle cx="220" cy="250" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" /><circle cx="70" cy="175" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" /><circle cx="220" cy="175" r="30" fill="url(#number_surface)" filter="url(#virtual_light_bottom)" />'
    ];

    function random(uint256 _tokenId) internal virtual returns (uint256) {
        nonce++;
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number,
                    _tokenId,
                    nonce
                )
            )
        );
        return (seed - ((seed / BASIS_POINTS) * BASIS_POINTS));
    }

    function setRollPrice(uint256 _tokenId, uint256 _newPrice) public {
        require(_exists(_tokenId), "This token ID does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "You cannot set the price of this token");

        diceRolls[_tokenId].rollPrice = _newPrice;
    }

    function _roll(uint256 _tokenId) internal returns (uint256) {
        
        uint256 _diceRoll = (random(_tokenId) % 6) + 1;

        diceRolls[_tokenId].rollCount += 1;
        diceRolls[_tokenId].rollValue = _diceRoll;

        return _diceRoll;

    }

    function rollDice(uint256 _tokenId) public nonReentrant payable {
        // need to add a check that the ID exists
        require(_exists(_tokenId), "this token ID does not exist");

        DiceRoll storage roll = diceRolls[_tokenId];

        // We check that the payable is sufficient
        require(roll.rollPrice <= msg.value, "Ether value sent is not correct");
        roll.rollKeep += msg.value;

        uint256 diceRoll = _roll(_tokenId);

        emit DiceRolled(_tokenId, diceRoll, block.timestamp);
    }

    function rollDiceMulti(uint256[] memory _tokenId) public nonReentrant payable {
        
        // Keep a running tab on the payable
        uint256 remainingPayable = msg.value;
        
        for (uint i; i<_tokenId.length; i++){
            // We need to add a check that the ID exists
            require(_exists(_tokenId[i]), "this token ID does not exist");
            
            DiceRoll storage roll = diceRolls[_tokenId[i]];

            // We check that there is sufficient balance left in the payable
            require(roll.rollPrice <= remainingPayable, "Ether value sent is not correct");
            remainingPayable -= roll.rollPrice;
            roll.rollKeep += roll.rollPrice;

            uint256 diceRoll = _roll(_tokenId[i]);

        // We emit an event with every roll, if rolling a large number of dice this will consumer a lot of gas
        emit DiceRolled(_tokenId[i], diceRoll, block.timestamp);
        }

        // If someone overpays we're nice and send back the change.
        if (remainingPayable > 0){
            payable(_msgSender()).transfer(remainingPayable);
        }
    }



    function withdrawRollKeep(uint256 _tokenId) public nonReentrant {
        require(_exists(_tokenId), "This token ID does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "You cannot set the price of this token");

        uint256 amtToPay = diceRolls[_tokenId].rollKeep;

        // check that there is sufficient ETH in the contract, otherwise reduce the amount to be paid out
        if (address(this).balance < amtToPay) {
            amtToPay = address(this).balance;
        }

        diceRolls[_tokenId].rollKeep = 0;
        payable(_msgSender()).transfer(amtToPay);
    }

    
    function getRollCount(uint256 _tokenId) public view returns (uint256) {
        return diceRolls[_tokenId].rollCount;
    }

    function getLastRoll(uint256 _tokenId) public view returns (uint256) {
        return diceRolls[_tokenId].rollValue;
    }

    function getRollPrice(uint256 _tokenId) public view returns (uint256) {
        return diceRolls[_tokenId].rollPrice;
    }

    function _buildJson(uint256 _tokenId) internal view returns (string memory) {
        string[10] memory parts;

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 290 320"><style>.base { fill: black; font-family: monospace; font-size: 14px; }</style>';

        parts[1] = '<defs><linearGradient id="face_surface" gradientUnits="objectBoundingBox" x1="1" x2="1" y1="0" y2="1"><stop stop-color="#F0F0F0" offset="0"/><stop stop-color="#EAEAEA" offset="0.67"/></linearGradient><linearGradient id="number_surface" gradientUnits="objectBoundingBox" x1="1" x2="1" y1="0" y2="1"><stop stop-color="#FF0000" offset="0"/><stop stop-color="#AD0000" offset="0.67"/></linearGradient><filter id="virtual_light_top" filterUnits="objectBoundingBox" x="-0.1" y="-0.1" width="1.2" height="1.2"><feGaussianBlur in="SourceAlpha" stdDeviation="2" result="alpha_blur"/><feSpecularLighting in="alpha_blur" surfaceScale="5" specularConstant="1" specularExponent="20" lighting-color="#FFFFFF" result="spec_light"><fePointLight x="500" y="-1000" z="5000"/></feSpecularLighting><feComposite in="spec_light" in2="SourceAlpha" operator="in" result="spec_light"/><feComposite in="SourceGraphic" in2="spec_light" operator="out" result="spec_light_fill"/></filter><filter id="virtual_light_bottom" filterUnits="objectBoundingBox" x="-0.1" y="-0.1" width="1.2" height="1.2"><feGaussianBlur in="SourceAlpha" stdDeviation="1" result="alpha_blur"/><feSpecularLighting in="alpha_blur" surfaceScale="10" specularConstant="1" specularExponent="20" lighting-color="#000000" result="spec_light"><fePointLight x="-500" y="1000" z="5000"/></feSpecularLighting><feComposite in="spec_light" in2="SourceAlpha" operator="out" result="spec_light"/><feComposite in="SourceGraphic" in2="spec_light" operator="out" result="spec_light_fill"/></filter></defs>';
        
        parts[2] = '<rect x="20" y="50" rx="20" ry="20" width="250" height="250" fill="url(#face_surface)" filter="url(#virtual_light_top)"/>';

        parts[3] = dieFaces[getLastRoll(_tokenId)];

        parts[4] = '<text x="20" y="20" class="base" >Dice: ';

        parts[5] = toString(_tokenId);

        parts[6] = '</text>';

        parts[7] = '<text x="20" y="35" class="base" >Rolled: ';

        parts[8] = toString(getLastRoll(_tokenId));

        parts[9] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Dice #', toString(_tokenId), '", "description": "Dice, a pseudo randomized onchain 6-sided game dice that anyone can roll. Feel free to use Dice in anyway you like.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;

    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return _buildJson(tokenId);
    }

    function claim(uint256 _tokenId) public nonReentrant payable {
        require(_tokenId > 0 && _tokenId < 991, "Token ID invalid");
        
        require(1e16 <= msg.value, "Ether value sent is not correct");  // pay 0.01 ETH to mint
        payable(deployerAddress).transfer(msg.value);
        
        _safeMint(_msgSender(), _tokenId);
    }
    
    function deployerClaim() public nonReentrant {
        require(deployerAddress == _msgSender(), "You are not the deployer.");
        
        for (uint i=991; i<1001; i++) {
            _safeMint(deployerAddress, i);    
        }
    }
   
    function toString(uint256 value) internal pure returns (string memory) {
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
    
    constructor() ERC721("Dice", "DICE") {
        deployerAddress = _msgSender();
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
