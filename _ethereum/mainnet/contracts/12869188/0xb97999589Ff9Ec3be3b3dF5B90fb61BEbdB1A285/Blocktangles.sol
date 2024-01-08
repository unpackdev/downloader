// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./Initializable.sol";
import "./SafeMath.sol";

contract Blocktangles is Initializable, ERC721EnumerableUpgradeable {

    using SafeMath for uint256;

    uint256 public reserve;
    address payable public creator;

    uint256 public totalEverMinted;
    uint256 public constant initialPrice = 0.001 ether;
    uint256 public constant creatorCutPerMille = 10;

    bytes12[] public palettes;
    uint8[] public activePalettes;

    string internal metadataURI;

    event Minted(
        uint256 indexed tokenId, 
        address indexed owner, 
        uint256 indexed timestamp, 
        uint256 mintPrice, 
        uint256 supplyAfterMint, 
        uint256 reserveAfterMint
    );

    event Burned(
        uint256 indexed tokenId, 
        address indexed owner, 
        uint256 indexed timestamp, 
        uint256 burnPrice, 
        uint256 supplyAfterBurn, 
        uint256 reserveAfterBurn
    );

    event PaletteAdded(
        bytes12 indexed palette, 
        uint256 indexed timestamp
    );

    event PaletteRemoved(
        bytes12 indexed palette, 
        uint256 indexed timestamp
    );

    function initialize(address payable _creator, string memory _metadataURI) initializer public {
        __ERC721_init("Blocktangles", "BTG");

        creator = _creator;
        metadataURI = _metadataURI;
        reserve = 0;
        totalEverMinted = 0;
    }

    function transferCreatorship(address payable _newCreator) external virtual {
        require(msg.sender == creator, "unauthorized");
        creator = _newCreator;
    }

    function setMetadataURI(string memory _newMetadataUri) external virtual {
        require(msg.sender == creator, "unauthorized");
        metadataURI = _newMetadataUri;
    }

    function _baseURI() internal override view returns (string memory) {
        return metadataURI;
    }


    /*
    Minting and burning
    */

    function mint() external virtual payable returns (uint256 tokenId) {
        uint256 mintPrice = getCurrentPriceToMint();
        require(msg.value >= mintPrice, "low_eth");

        // generate token id
        tokenId = _generateTokenId(msg.sender);

        // mint the token
        _mint(msg.sender, tokenId);

        // increase total ever minted count
        totalEverMinted += 1;

        // disburse
        uint256 reserveCut = _getReserveCut(mintPrice);
        reserve = reserve.add(reserveCut); // 99% goes to reserve
        creator.transfer(mintPrice.sub(reserveCut)); // 1% goes to creator

        if (msg.value.sub(mintPrice) > 0) {
            payable(msg.sender).transfer(msg.value.sub(mintPrice)); // excess goes back to sender
        }

        emit Minted(tokenId, msg.sender, block.timestamp, mintPrice, totalSupply(), reserve);

        return tokenId;
    }

    function burn(uint256 tokenId) external virtual {
        require(msg.sender == ownerOf(tokenId), "not_owner");

        uint256 burnPrice = getCurrentPriceToBurn();
        
        // burn the token
        _burn(tokenId);

        reserve = reserve.sub(burnPrice);
        payable(msg.sender).transfer(burnPrice);

        emit Burned(tokenId, msg.sender, block.timestamp, burnPrice, totalSupply(), reserve);
    }
    
    // if supply 0, mint price = 0.001
    function getCurrentPriceToMint() public virtual view returns (uint256) {
        return initialPrice.add(totalSupply().mul(initialPrice));
    }

    // if supply 1, then burn price = 0.00099
    function getCurrentPriceToBurn() public virtual view returns (uint256) {
        return _getReserveCut(totalSupply().mul(initialPrice));
    }

    // returns price minus creator cut
    function _getReserveCut(uint256 price) internal pure returns (uint256) {
        return (price * (1000 - creatorCutPerMille)) / 1000;
    }

    function _generateTokenId(address to) internal view returns (uint256 tokenId) {
        require(activePalettes.length > 0, "no_palettes");

        // pseudo-randomly generated image seed
        bytes32 seed = keccak256(abi.encodePacked(totalEverMinted, block.timestamp, to));

        // based on the last byte of the generated seed select one of the active palettes
        uint8 paletteId = activePalettes[uint8(seed[seed.length-1]) % activePalettes.length];

        // set last byte of the seed to palette id
        tokenId = uint256(seed) / 256 * 256 + paletteId;

        return tokenId;
    }


    /*
    Palette setters
    */

    function addPalette(bytes12 _palette) external virtual {
        require(msg.sender == creator, "unauthorized");

        uint8 i;
        uint8 paletteIndex = 0;

        // search palette array for the same palette
        for (i = 0; i < palettes.length; i++) {
            if (palettes[i] == _palette) {
                paletteIndex = i;
                break;
            }
        }
        
        // if the palette doesn't exist yet, add it to palettes array and save the index
        if (i >= palettes.length) {
            require(palettes.length <= 256, "palettes_full");
            palettes.push(_palette);
            paletteIndex = uint8(palettes.length-1);
        }

        // activate palette index
        activePalettes.push(paletteIndex);
        emit PaletteAdded(_palette, block.timestamp);
    }

    function removePalette(bytes12 _palette) external virtual {
        require(msg.sender == creator, "unauthorized");

        uint8 i;
        uint8 paletteIndex = 0;

        // search palette array for the this palette
        for (i = 0; i < palettes.length; i++) {
          if (palettes[i] == _palette) {
              paletteIndex = i;
              break;
          }
        }

        // revert if this palette doesn't exist
        if (i >= palettes.length) {
            revert("palette_missing");
        }

        // remove this palette from active palettes if present in the array
        for (i = 0; i < activePalettes.length; i++) {
            if (activePalettes[i] == paletteIndex) {
                activePalettes[i] = activePalettes[activePalettes.length - 1];    // replace this value with last element in array
                activePalettes.pop();                                             // delete last element in array
                break;
            }
        }

        emit PaletteRemoved(_palette, block.timestamp);
    }


    /*
    Palette getters
    */

    function getPalettes() external view returns(bytes12[] memory) {
        return palettes;
    }

    function getActivePalettes() external view returns(uint8[] memory) {
        return activePalettes;
    }


    /*
    SVG generator related code
    */

    function generateSVG(uint256 _tokenId) external virtual view returns (string memory) {
        bytes32 seed = bytes32(_tokenId);

        // pallete id is in the last byte of the seed
        bytes12 palette = palettes[uint8(seed[seed.length-1])];

        string memory svg = string(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 512 512'><g transform='scale(32)' shape-rendering='crispEdges'>", 
            string(abi.encodePacked(
                "<rect x='0' y='0' width='16' height='16' fill='",
                _getRGBColor(palette, 3),
                "'/>"
            ))
        ));

        // first 31 bytes renders pseudo-random rectangles
        for (uint8 i = 0; i < 31; i++) {
            uint8 s = uint8(seed[i]);
            int8 w = 7;
            int8 h = 7;
            int8 x = int8(s / 16) - 3;
            int8 y = int8(s % 16) - 3;
            if (x < 0) {
                w = w + x;
                x = 0;
            }
            if (y < 0) {
                h = h + y;
                y = 0;
            }
            if (x > 9) {
                w = 16 - x;
            }
            if (y > 9) {
                h = 16 - y;
            }
            svg = string(abi.encodePacked(
                svg,
                "<rect x='",
                _uint2str(uint8(x)),
                "' y='",
                _uint2str(uint8(y)),
                "' width='",
                _uint2str(uint8(w)),
                "' height='",
                _uint2str(uint8(h)),
                "' fill='",
                _getRGBColor(palette, s % 4),
                "' opacity='0.85'/>"
            ));
        }

        svg = string(abi.encodePacked(svg,"</g></svg>"));

        return svg;
    }

    // https://github.com/provable-things/ethereum-api/blob/master/provableAPI_0.6.sol
    function _uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _getRGBColor(bytes12 _palette, uint8 _colorIndex) internal pure returns (string memory _rgbColor) {
        _rgbColor = string(abi.encodePacked(
            "rgb(",
            _uint2str(uint8(_palette[_colorIndex * 3])),
            " ",
            _uint2str(uint8(_palette[_colorIndex * 3 + 1])),
            " ",
            _uint2str(uint8(_palette[_colorIndex * 3 + 2])),
            ")"
        ));
        return _rgbColor;
    }

}