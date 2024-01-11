// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*

 mmmm                              
 #   "m  mmm    mmm    m mm   mmm  
 #    # #" "#  #" "#   #"  " #   " 
 #    # #   #  #   #   #      """m 
 #mmm"  "#m#"  "#m#"   #     "mmm" 
                                   

Doors is a collection of 66 on-chain artworks.

Project by Rafaël Rozendaal https://newrafael.com/
Smart contract by Alberto Granzotto https://granzotto.net/

*/

import "./DoorsSVG.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract Doors is DoorsSVG, ERC721, ERC2981ContractWideRoyalties, Ownable {
    address payable constant dev =
        payable(0x39596955f9111e12aF0B96A96160C5f7211B20EF);

    // From the MSB:
    // - 8 bit started (0 or 1)
    // - 8 bit total minted
    // - 240 bit minted bitmap
    uint256 private _state;
    bytes1[66] private _tokens;

    constructor() ERC721("Doors", "DOORS") {
        // Assign 5% royalties to msg.sender
        _setRoyalties(payable(owner()), 500);
    }

    function mint(
        address to,
        uint8 door,
        uint8 knob
    ) public payable {
        require(
            door < 16 && knob < 16 && door != knob,
            "Doors: invalid colors"
        );

        uint256 state = _state;
        bool isOpen = (state & (1 << 248)) > 0;
        uint8 total = uint8(state >> 240);
        uint240 bitmap = uint240(state);

        uint240 mask;
        unchecked {
            mask = uint240(1 << ((door * 15) + knob - (door > knob ? 0 : 1)));
        }

        require(bitmap & mask == 0, "Doors: token exists");
        require(total < 66, "Doors: no more tokens available");

        unchecked {
            _tokens[total] = bytes1((door << 4) + knob);
            total++;
            _state =
                (uint256(isOpen ? 1 : 0) << 248) |
                (uint256(total) << 240) |
                (bitmap | mask);
        }

        _safeMint(to, total);

        address payable owner = payable(owner());

        if (_msgSender() == owner) {
            require(msg.value == 0, "Doors: wrong amount");
        } else {
            require(isOpen, "Doors: closed");
            require(msg.value == 0.25 ether, "Doors: wrong amount");
            (bool success, ) = owner.call{value: 0.20 ether}("");
            require(success, "Doors: unable transfer to A");
            (success, ) = dev.call{value: 0.05 ether}("");
            require(success, "Doors: unable transfer to B");
        }
    }

    function open() public onlyOwner {
        _state |= 1 << 248;
    }

    function close() public onlyOwner {
        uint256 mask = 1 << 248;
        _state &= ~mask;
    }

    function getState()
        public
        view
        returns (
            bool isOpen,
            uint8 total,
            uint240 bitmap,
            bytes1[66] memory tokens
        )
    {
        uint256 state = _state;
        isOpen = (state & (1 << 248)) > 0;
        total = uint8(state >> 240);
        bitmap = uint240(state);
        tokens = _tokens;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Doors: nonexistent token");
        uint8 colors = uint8(_tokens[tokenId - 1]);
        return string(_getJSON(tokenId, colors >> 4, colors & 0x0f));
    }

    /// @notice Allows to set the royalties on the contract
    /// @dev This function in a real contract should be protected with a onlyOwner (or equivalent) modifier
    /// @param recipient the royalties recipient
    /// @param value royalties value (between 0 and 10000)
    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
