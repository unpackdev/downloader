// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC2981PerTokenRoyalties.sol";
import "./DynaTokenBase.sol";
import "./ColourWork.sol";
import "./StringUtils.sol";
import "./DynaModel.sol";
import "./DynaTraits.sol";

contract DynaStripes is DynaTokenBase, ERC2981PerTokenRoyalties {
    uint16 public constant TOKEN_LIMIT = 1119; // first digits of "dyna" in ascii: (100 121 110 97) --> 1119
    uint16 public constant ROYALTY_BPS = 1000;
    bool private descTraitsEnabled = true;
    uint16 private tokenLimit = 100;
    uint16 private tokenIndex = 0;
    mapping(uint16 => DynaModel.DynaParams) private dynaParamsMapping;
    mapping(uint24 => bool) private usedRandomSeeds;
    uint256 private mintPrice = 0.01 ether;

    constructor() DynaTokenBase("DynaStripes", "DSS") { }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(DynaTokenBase, ERC2981PerTokenRoyalties)
        returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // for OpenSea
    function contractURI() public pure returns (string memory) {
        return "https://www.dynastripes.com/storefront-metadata";
    }

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function getTokenLimit() public view returns (uint16) {
        return tokenLimit;
    }
    function setTokenLimit(uint16 _tokenLimit) public onlyOwner {
        if (_tokenLimit > TOKEN_LIMIT) {
            _tokenLimit = TOKEN_LIMIT;
        }
        tokenLimit = _tokenLimit;
    }

    function getDescTraitsEnabled() public view returns (bool) {
        return descTraitsEnabled;
    }
    function setDescTraitsEnabled(bool _enabled) public onlyOwner {
        descTraitsEnabled = _enabled;
    }

    function payOwner(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Amount too high");
        address payable owner = payable(owner());
        owner.transfer(amount);
    }

    receive() external payable { }

    function mintStripes(uint24 _randomSeed, 
                         uint8 _zoom,
                         uint8 _tintRed,
                         uint8 _tintGreen,
                         uint8 _tintBlue,
                         uint8 _tintAlpha,
                         uint8 _rotationMin, 
                         uint8 _rotationMax, 
                         uint8 _stripeWidthMin, 
                         uint8 _stripeWidthMax, 
                         uint8 _speedMin, 
                         uint8 _speedMax) public payable {
        uint16 tokenId = tokenIndex;
        require(tokenId < tokenLimit && tokenId < TOKEN_LIMIT, "Token limit reached");
        require(msg.value >= getMintPrice(), "Not enough ether");
        require(_zoom <= 100, "Zoom invalid");
        require(_tintRed <= 255, "tint red invalid");
        require(_tintGreen <= 255, "tint green invalid");
        require(_tintBlue <= 255, "tint blue invalid");
        require(_tintAlpha < 230, "tint alpha invalid");
        require(_rotationMax <= 180 && _rotationMin <= _rotationMax, "Rotation invalid");
        require(_stripeWidthMin >= 25 && _stripeWidthMax <= 250 && _stripeWidthMin <= _stripeWidthMax, "Stripe width invalid");
        require(_speedMin >= 25 && _speedMax <= 250 && _speedMin <= _speedMax, "Speed value invalid");
        require(_randomSeed < 5000000 && usedRandomSeeds[_randomSeed] == false, "Random seed invalid");

        _safeMint(msg.sender, tokenId);
        _setTokenRoyalty(tokenId, msg.sender, ROYALTY_BPS);
        dynaParamsMapping[tokenId] = DynaModel.DynaParams(_randomSeed, _zoom, _tintRed, _tintGreen, _tintBlue, _tintAlpha, _rotationMin, _rotationMax, _stripeWidthMin, _stripeWidthMax, _speedMin, _speedMax);
        usedRandomSeeds[_randomSeed] = true;

        tokenIndex += 1;
    }

    function banRandomSeeds(uint24[] memory seeds) public onlyOwner {
        for (uint i; i < seeds.length; i++) {
            usedRandomSeeds[seeds[i]] = true;
        }
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(_tokenId), "token ID doesn't exist");
        require(_tokenId < TOKEN_LIMIT, "token ID doesn't exist");

        string memory copyright = string(abi.encodePacked("\"copyright\": \"The owner of this NFT is its legal copyright holder. By selling this NFT, the seller/owner agrees to assign copyright to the buyer. All buyers and sellers agree to payment of royalties to the original minter on sale of the artwork.\""));

        string memory traits = DynaTraits.getTraits(descTraitsEnabled, dynaParamsMapping[uint16(_tokenId)]);
        string memory svg = generateSvg(_tokenId);
        return string(abi.encodePacked("data:text/plain,{\"name\":\"DynaStripes #", StringUtils.uint2str(_tokenId), "\", \"description\":\"on-chain, generative DynaStripes artwork\", ", copyright, ", ", traits, ", \"image\":\"data:image/svg+xml,", svg, "\"}")); 
    }
    
    function generateSvg(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "token ID doesn't exist");
        require(_tokenId < TOKEN_LIMIT, "token ID doesn't exist");

        DynaModel.DynaParams memory dynaParams = dynaParamsMapping[uint16(_tokenId)];
        (string memory viewBox, string memory clipRect) = getViewBoxClipRect(dynaParams.zoom);
        string memory rendering = dynaParams.rotationMin == dynaParams.rotationMax ? "crispEdges" : "auto";
        string memory defs = string(abi.encodePacked("<defs><clipPath id='masterClip'><rect ", clipRect, "/></clipPath></defs>"));
        string memory rects = getRects(dynaParams);

        return string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' viewBox='", viewBox, "' shape-rendering='", rendering, "'>", defs, "<g clip-path='url(#masterClip)'>", rects, "</g></svg>"));
    }

    function getViewBoxClipRect(uint _zoom) private pure returns (string memory, string memory) {
        _zoom = _zoom * 20;
        string memory widthHeight = StringUtils.uint2str(1000 + _zoom);

        if (_zoom > 1000) {
            string memory offset = StringUtils.uint2str((_zoom - 1000) / 2);
            string memory viewBox = string(abi.encodePacked("-", offset, " -", offset, " ",  widthHeight, " ", widthHeight));
            string memory clipRect = string(abi.encodePacked("x='-", offset, "' y='-", offset, "' width='",  widthHeight, "' height='", widthHeight, "'"));
            return (viewBox, clipRect);
        } else {
            string memory offset = StringUtils.uint2str((_zoom == 1000 ? 0 : (1000 - _zoom) / 2));
            string memory viewBox = string(abi.encodePacked(offset, " ", offset, " ",  widthHeight, " ", widthHeight));
            string memory clipRect = string(abi.encodePacked("x='", offset, "' y='", offset, "' width='",  widthHeight, "' height='", widthHeight, "'"));

            return (viewBox, clipRect);
        }
    }

    function getRects(DynaModel.DynaParams memory _dynaParams) private pure returns (string memory) {
        uint randomSeed = _dynaParams.randomSeed;
        uint xPos = 0;
        string memory rects = "";

        while ((2000 - xPos) > 0) {

            uint stripeWidth = randomIntFromInterval(randomSeed, _dynaParams.stripeWidthMin, _dynaParams.stripeWidthMax) * 2;
    
            if (stripeWidth > 2000 - xPos) {
                stripeWidth = 2000 - xPos;
            } else if ((2000 - xPos) - stripeWidth < _dynaParams.stripeWidthMin) {
                stripeWidth += (2000 - xPos) - stripeWidth;
            }

            string memory firstColour = getColour(randomSeed + 3, _dynaParams);
            string memory colours = string(abi.encodePacked(firstColour, ";", getColour(randomSeed + 13, _dynaParams), ";", firstColour));
            
            rects = string(abi.encodePacked(rects, "<rect x='", StringUtils.uint2str(xPos), "' y='0' width='", StringUtils.uint2str(stripeWidth), "' height='2000' fill='", firstColour, "' opacity='0.8'", " transform='rotate(",  getRotation(randomSeed + 1, _dynaParams), " 1000 1000)'><animate begin= '0s' dur='", getSpeed(randomSeed + 2, _dynaParams), "ms' attributeName='fill' values='", colours, ";' fill='freeze' repeatCount='indefinite'/></rect>"));
            
            xPos += stripeWidth;
            randomSeed += 100;
        }

        return rects; 
    }

    function getRotation(uint _randomSeed, DynaModel.DynaParams memory _dynaParams) private pure returns (string memory) {
        uint rotation = randomIntFromInterval(_randomSeed, _dynaParams.rotationMin, _dynaParams.rotationMax);
        return StringUtils.smallUintToString(rotation);
    }

    function getSpeed(uint _randomSeed, DynaModel.DynaParams memory _dynaParams) private pure returns (string memory) {
        uint speed = randomIntFromInterval(_randomSeed, _dynaParams.speedMin, _dynaParams.speedMax) * 20;
        return StringUtils.uint2str(speed);
    }

    function getColour(uint _randomSeed, DynaModel.DynaParams memory _dynaParams) private pure returns (string memory) {
        uint red = ColourWork.safeTint(randomIntFromInterval(_randomSeed, 0, 255), _dynaParams.tintRed, _dynaParams.tintAlpha);
        uint green = ColourWork.safeTint(randomIntFromInterval(_randomSeed + 1, 0, 255), _dynaParams.tintGreen, _dynaParams.tintAlpha);
        uint blue = ColourWork.safeTint(randomIntFromInterval(_randomSeed + 2, 0, 255), _dynaParams.tintBlue, _dynaParams.tintAlpha);

        return string(abi.encodePacked("rgb(", StringUtils.smallUintToString(red), ", ", StringUtils.smallUintToString(green), ", ", StringUtils.smallUintToString(blue), ")"));
    }

    // ----- Utils

    function randomIntFromInterval(uint _randomSeed, uint _min, uint _max) private pure returns (uint) {
        if (_max <= _min) {
            return _min;
        }

        uint seed = uint(keccak256(abi.encode(_randomSeed)));
        return uint(seed % (_max - _min)) + _min;
    }
}

// Love you John, Christine, Clara and Lynus! 😁❤️