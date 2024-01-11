// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./Owned.sol";
import "./libImg.sol";
import "./png.sol";
import "./JSON.sol";

interface IBasedGhouls {
    function ownerOf(uint256 id) external view returns (address owner);
}

contract ghoulBalls is ERC721, Owned(msg.sender) {

    uint32 constant WIDTH_AND_HEIGHT = 128;
    int256 constant CIRCLE_RADIUS = 69;

    IBasedGhouls ghouls = IBasedGhouls(0xeF1a89cbfAbE59397FfdA11Fc5DF293E9bC5Db90);

    mapping(uint256 => bytes) internal colours;

    function _hash(bytes memory SAUCE) internal pure returns(bytes memory) {
        return abi.encodePacked(keccak256(SAUCE));
    }

    function toUint256(bytes memory _bytes) internal pure returns (uint256) {
        require(_bytes.length >= 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(_bytes, 0x20))
        }

        return tempUint;
    }

    // Each RGB is 3 bytes, determine number of balls that will be in the PNG then generate the colours
    function _generateColour(uint256 id) internal view returns(bytes memory) {
        uint256 randomish = toUint256(_hash(abi.encodePacked(id, msg.sender, block.timestamp)));

        if((randomish % 69) > 60) {
            return abi.encodePacked((uint144(randomish))); //6
        } else if((randomish % 69) > 50) {
            return abi.encodePacked((uint96(randomish))); //4
        } else if((randomish % 69) > 40) {
            return abi.encodePacked((uint48(randomish))); //2
        } else {
            return abi.encodePacked((uint24(randomish))); //1
        }
        
    }

    function mint_the_ball(uint256 id) public {
        require(id < 10000, "invalid ball.");
        if (id<6666) {
            require(ghouls.ownerOf(id) == msg.sender, "not your ghoul.");
        }
        require(_ownerOf[id] == address(0), "someone else got this ghoulBall.");

        colours[id] = _generateColour(id);

        _mint(msg.sender, id);
    }

    function click_for_utility(uint256 id) public {
        _burn(id);
    }

    function getPalette(uint256 id) internal view returns (bytes3[] memory) {
        bytes memory _coloursArr = colours[id];

        bytes3[] memory palette = new bytes3[](_coloursArr.length/3);

        for(uint256 i = 0; i<palette.length; i++) {
            palette[i] = 
                bytes3(
                    bytes.concat(
                        _coloursArr[i*3],
                        _coloursArr[i*3+1],
                        _coloursArr[i*3+2]
                    )
                );
        }

        return palette;
    }

    function tokenPNG(uint256 id) public view returns (string memory) {
        bytes3[] memory _palette = getPalette(id);

        libImg.IMAGE memory imgPixels = libImg.IMAGE(
            WIDTH_AND_HEIGHT,
            WIDTH_AND_HEIGHT,
            new bytes(WIDTH_AND_HEIGHT*WIDTH_AND_HEIGHT+1)
        );
        
        return png.encodedPNG(WIDTH_AND_HEIGHT, WIDTH_AND_HEIGHT, _palette, libImg.drawImage(imgPixels, _palette.length), true);

    }

    function tokenAttributes(uint256 id) internal view returns (string memory) {
        bytes memory plte = colours[id];

        string memory palettes;
        bool last;

        for (uint256 i = 0; i<plte.length/3; i++) {
            last = (i == (plte.length/3-1)) ? true : false;

            palettes = string.concat(
                palettes,
                json._attr(
                    string.concat('ball ', json.toString(i+1)),
                    string.concat(
                        json.toString(uint8(plte[i*3])),
                        ', ',
                        json.toString(uint8(plte[i*3+1])),
                        ', ',
                        json.toString(uint8(plte[i*3+2]))
                    ),
                    last
                )
            );
        }

        // we attach the number of balls, and colour palette to the ERC721 JSON
        return string.concat(
            json._attr('ball count', json.toString(plte.length/3)),
            palettes
        );

    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return json.formattedMetadata(
            'ghoulBalls',
            "ghoulBalls are fully onchain PNGs that evolve with every block, absolutely rugging the right-click savers after everyblock. No roadmap, no development, no utility, no marketing, and nothing more. They promise nothing and deliver even less. They're just PNGs.",
            tokenPNG(id),
            tokenAttributes(id)
        );
    }

    //never know if they'll rug us again with a v3
    function updateGhoulAddr(address ghoulAddr) public onlyOwner {
        ghouls = IBasedGhouls(ghoulAddr);
    }
    
    constructor() ERC721("ghoulBalls", unicode"🎊"){}

}
