// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


//   ****            ******                               **  
//  *///**          **////**                             /**  
// /*  */* **   ** **    //   ******   ******  ******   ******
// /* * /*//** ** /**        //////** //**//* //////** ///**/ 
// /**  /* //***  /**         *******  /** /   *******   /**  
// /*   /*  **/** //**    ** **////**  /**    **////**   /**  
// / ****  ** //** //****** //********/***   //********  //** 
//  ////  //   //   //////   //////// ///     ////////    //  

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./Counters.sol";
import "./SafeMath.sol";


/**
 * @title DichoStudio 0xCarat
 * @author codesza, adapted from NPassCore.sol, NDerivative.sol, Voyagerz.sol, and CryptoCoven.sol
 * and inspired by Vows and Runners: Next Generation
 */


contract DichoStudio0xCarat is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    
    /// @notice A counter for tokens
    Counters.Counter private _tokenIds;
    
    uint256 private constant _maxPublicSupply = 888;
    uint256 private constant _maxRingsPerWallet = 3;
    uint256 public saleStartTimestamp;
    address private openSeaProxyRegistryAddress;
    
    /// @notice Records of crafter- and wearer- derived seeds 
    mapping(uint256 => uint256) private _ringSeed;
    mapping(uint256 => uint256) private _wearerSeed;

    /// @notice Recordkeeping beyond balanceOf
    mapping(address => uint256) private _crafterBalance;
    
    constructor(address _openSeaProxyRegistryAddress) ERC721("Dicho Studio 0xCarat", "RING") {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
    }

    /// @notice Craft rings, a.k.a. mint 
    function craft(uint256 numToMint) external nonReentrant {
        require(isSaleOpen(), "Sale not open");
        require(numToMint > 0 && numToMint <= mintsAvailable(), "Out of rings");
        require(
            _crafterBalance[msg.sender] + numToMint <= _maxRingsPerWallet,
            "Max rings to craft is three"
        );
        
        uint256 tokenId; 

        for (uint256 i = 0; i < numToMint; i++) {
            _tokenIds.increment();
            tokenId = _tokenIds.current();
            _safeMint(msg.sender, tokenId);
            _ringSeed[tokenId] = randSeed(msg.sender, tokenId, 13999234923493293432397);
            _wearerSeed[tokenId] = _ringSeed[tokenId];
        }
        _crafterBalance[msg.sender] += numToMint;
    }

    /// @notice Gift rings using safeTransferFrom
    function gift(address to, uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Gift a ring you own");
        safeTransferFrom(msg.sender, to, tokenId);
    }

    /// @notice To divorce, burn the ring.
    function divorce(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Burn a ring you own");
        _burn(tokenId);
    }

    /// @notice Is it time yet? 
    function isSaleOpen() public view returns (bool) {
        return block.timestamp >= saleStartTimestamp && saleStartTimestamp != 0;
    }
    
    /// @notice Calculate available open mints
    function mintsAvailable() public view returns (uint256) {
        return _maxPublicSupply - _tokenIds.current();
    }


    // ============ OWNER ONLY ROUTINES ============

    /// @notice Allows owner to withdraw amount
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /// @notice Allows owner to change sale time start
    function setSaleTimestamp(uint256 timestamp) external onlyOwner {
        saleStartTimestamp = timestamp;
    }

    // ============ HELPER FUNCTIONS / UTILS ============
    
    /// @notice Random seed generation, from Voyagerz contract
    function randSeed(address addr, uint256 tokenId, uint256 modulus) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(addr, block.timestamp, block.difficulty, tokenId))) % modulus;
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

    function correctColor(uint256 hue, uint256 sat, uint256 lum, uint256 seed) internal pure returns (uint256, uint256) {
        if (hue <= 55 && hue >= 27 && sat < 66 && lum < 49) {
            sat = 70;
            lum = (seed % 33) + 48;
        }
        return (sat, lum);
    }


    // ============ RING CONSTRUCTION ============
    
    /// @notice Baseline parameters for a ring 
    struct RingParams {
        uint256 gemcol_h;
        uint256 gemcol_s;
        uint256 gemcol_l;
        uint256 bgcol_h;
        uint256 bgcol_s;
        uint256 cut_idx; 
        uint256 band_idx;
        string bandcol;
    }

    /// @notice Using wearer and crafter seeds to define ring parameters
    function getRingParams(uint256 tokenId) internal view returns (RingParams memory) {
        RingParams memory rp;
        {
            uint256 rSeed = _ringSeed[tokenId];

            // gem color derived from minter-derived seed. still influences ethereum cut
            rp.gemcol_h = rSeed % 335;
            rSeed = rSeed >> 8;
            rp.gemcol_s = ((rSeed & 0xFF) % 40) + 40; // (40, 80) 
            rSeed = rSeed >> 8;
            rp.gemcol_l = ((rSeed & 0xFF) % 50) + 30; // (30, 80) 
            rSeed = rSeed >> 8;
            (rp.gemcol_s, rp.gemcol_l) = correctColor(rp.gemcol_h, rp.gemcol_s, rp.gemcol_l, rSeed);

            // gem cut and ring band color 
            if ((rSeed & 0xFF) < 8) { // 8/255 = ~3% chance of "ethereum" cut 
                rp.cut_idx = 0;
            } else if ((rSeed & 0xFF) < 59) { // between 8 and 59 / 255 = ~20% chance of emerald cut
                rp.cut_idx = 2;
            } else if ((rSeed & 0xFF) < 148) { // between 59 and 148 / 255 = ~35% chance of solitaire cut 
                rp.cut_idx = 3;
            } else {
                rp.cut_idx = 1; // round
            }
            
            rSeed = rSeed >> 8;

            if ((rSeed & 0xFF) < 26) { // <26/255 = ~10% chance of rose gold band 
                rp.bandcol = "#C48891";
                rp.band_idx = 0;
            } else if ((rSeed & 0xFF) < 115) { // between 26 and 115 / 255 = 35% chance of platinum band 
                rp.bandcol = "#C4C4C4";
                rp.band_idx = 1;
            } else {
                rp.bandcol = "#D7BB59";
                rp.band_idx = 2;
            }

            if (_wearerSeed[tokenId] != _ringSeed[tokenId]) {
                uint256 wSeed = _wearerSeed[tokenId];
                rp.bgcol_h = wSeed % 335;
                wSeed = wSeed >> 8; 
                (rp.bgcol_s,) = correctColor(rp.bgcol_h, ((wSeed & 0xFF) % 35) + 35, 35, 0); // (35, 70)
            } else {
                rp.bgcol_h = rp.gemcol_h;
                rp.bgcol_s = rp.gemcol_s;

                if (rp.band_idx == 2 && rp.gemcol_h < 48 && rp.gemcol_h > 27) {
                    rp.band_idx = 1;
                    rp.bandcol = "#C4C4C4";
                }
            }
        }

        return rp;
    }
    
    /// @notice Constructing the ring's svg using its parameters 
    function getSvg(uint256 tokenId) internal view returns (bytes memory, RingParams memory) {
        RingParams memory rp = getRingParams(tokenId);

        bytes memory buf;

        {
            buf = abi.encodePacked(
                '<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg">'
                "<defs>"
            );

            if (rp.cut_idx == 0) {
                buf = abi.encodePacked(
                    buf,
                    '<radialGradient id="b" r="2" cy="100%" cx="30%" fx="100%" fy="10%">'
                    '<stop stop-color="#7FDEFF"/>'
                    '<stop offset=".19" stop-color="#CFC7FA" stop-opacity=".8"/>'
                    '<stop offset=".23" stop-color="#CED9ED" stop-opacity=".79"/>'
                    '<stop offset=".32" stop-opacity="1" stop-color="hsl(',
                    toString(rp.gemcol_h),
                    ",",
                    toString(rp.gemcol_s),
                    "%,",
                    toString(rp.gemcol_l),
                    '%)" />'
                    '<stop stop-color="#EFC8DD" offset=".33" stop-opacity=".6"/>'
                    '<stop stop-color="#CED9ED" offset=".4" stop-opacity=".8"/>'
                    '</radialGradient>'
                );
            } else {
                if (rp.cut_idx == 3) {
                    buf = abi.encodePacked(
                        buf,
                        '<radialGradient id="b" cx="1.6" cy="0" r="1" fy="0.6" spreadMethod="reflect" gradientUnits="userSpaceOnUse" gradientTransform="'
                        'matrix(0 45.7397 -53.6119 0 250 165)">'
                    );
                } else if (rp.cut_idx == 2) {
                    buf = abi.encodePacked(
                        buf,
                        '<radialGradient id="b" spreadMethod="reflect" fy="1" r="1" cy="0" cx="1.6" gradientTransform="'
                        'rotate(179.48 125.62 79.01) scale(177.459 42.9393)" gradientUnits="userSpaceOnUse">'
                    );
                    
                } else {
                    buf = abi.encodePacked(
                        buf,
                        '<radialGradient id="b" gradientUnits="userSpaceOnUse" gradientTransform="'
                        'matrix(0 -100 60 0 249.9 161.75)" spreadMethod="reflect" fy="0.9" r="1" cy="0" cx="1.7">'
                    );
                    
                }
                buf = abi.encodePacked(
                    buf,
                    '<stop stop-color="hsl(',
                    toString(rp.gemcol_h + 25),
                    ",",
                    toString(rp.gemcol_s + 20),
                    "%,",
                    toString(rp.gemcol_l + 10),
                    '%)"/>'
                    '<stop offset="1" stop-color="hsl(',
                    toString(rp.gemcol_h),
                    ",",
                    toString(rp.gemcol_s),
                    "%,",
                    toString(rp.gemcol_l),
                    '%)" stop-opacity="0.4" />'
                    '</radialGradient>'
                );
            }
        
        }

        {
            buf = abi.encodePacked(
                buf,
                '<filter id="a" x="0" y="0" width="100%" height="100%" '
                'filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">'
                '<feFlood flood-opacity="0" result="BackgroundImageFix"/>'
                '<feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>'
                '<feOffset xmlns="http://www.w3.org/2000/svg" dy="3" dx="3" />'
                '<feComposite in2="hardAlpha" operator="out"/>'
                '<feColorMatrix values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0"/>'
                '<feBlend in2="BackgroundImageFix" result="effect1_dropShadow"/>'
                '<feBlend in="SourceGraphic" in2="effect1_dropShadow" result="shape"/>'
                '<feGaussianBlur stdDeviation="2" result="blur1"/>'
                '<feSpecularLighting result="spec1" in="blur1" specularExponent="70" lighting-color="hsl(',
                toString(rp.bgcol_h + 25),
                ",",
                toString(rp.bgcol_s + 20),
                "%, ",
                toString((rp.bgcol_h + 25) < 210 ? 35 : (rp.bgcol_h + 25) < 330 ? 65 : 80),
                '%)">'
                '<fePointLight x="140" y="150" z="300" /></feSpecularLighting>'
                '<feComposite in="SourceGraphic" in2="spec1" operator="arithmetic" k1="0" k2="1" k3="1" k4="0" />'
                "</filter>"
            );

            buf = abi.encodePacked(
                buf,
                '<radialGradient id="bg" cx="0.4" cy="0.32" r="2.5">'
                '<stop offset="0%" stop-color="hsl(',
                toString(rp.bgcol_h),
                ",",
                toString(rp.bgcol_s),
                '%, 40%)" />'
                '<stop offset="20%" stop-color="hsl(',
                toString(rp.bgcol_h),
                ",",
                toString(rp.bgcol_s),
                '%, 22%)" />'
                '<stop offset="60%" stop-color="hsl(',
                toString(rp.bgcol_h),
                ",",
                toString(rp.bgcol_s),
                '%, 10%)" />'
                "</radialGradient>"
                "</defs>"
            );
        }

        buf = abi.encodePacked(
            buf,
            '<rect x="0" y="0" width="100%" height="100%" fill="url(#bg)" />'
            '<g filter="url(#a)">'
            '<path d="M249.5 343c-37.3 0-67.5-30.2-67.5-67.5s30.2-67.5 67.5-67.5 67.5 30.2 67.5 67.5-30.2 67.5-67.5 67.5Z" '
            'stroke="',
            rp.bandcol, 
            '" stroke-width="13.8" fill="none"/>'
        );

        {
            if (rp.cut_idx == 0) { // eth cut 
                buf = abi.encodePacked(
                    buf,
                    '<path d="M249.3 113.8c-.2.4-5.4 9.3-11.7 19.6-6.3 10.4-11.4 19-11.5 19.2-.1.2 3.3 2.3 11.9 7.4l12 7.1 '
                    '12-7.1c8.6-5.1 12-7.2 11.9-7.4-.4-1.1-23.8-39.6-24.1-39.6-.1 0-.4.3-.5.8Zm-23.2 43.9c.5.8 23.8 33.7 23.9 '
                    '33.7.2 0 24.1-33.8 24-33.9-.1-.1-22.4 13.1-23.4 13.8l-.6.4-11.6-6.8c-6.4-3.8-11.8-7-12.1-7.2-.3-.3-.4-.3-.2 0Z" fill="url(#b)"/>'
                    '<path fill-rule="evenodd" clip-rule="evenodd" d="m237 179 13 17.1 13-17.1 3.5-5 .3-.3c.3-.3.7-.1.7.3v.1l-7 16-5 '
                    '12.5h-11l-5-12.5-7-16v-.1c0-.4.4-.6.7-.3l.3.3 3.5 5Z" fill="',
                    rp.bandcol,
                    '"/></g></svg>'
                );
            } else if (rp.cut_idx == 1) { // round 
                buf = abi.encodePacked(
                    buf,
                    '<path d="M210 164.9a34.76 34.76 0 0 1 33.9-34.75l6.1-.15 6.1.15A34.76 34.76 0 0 1 290 164.9c0 1.31-.66 '
                    '2.53-1.76 3.24l-36.06 23.44a4 4 0 0 1-4.36 0l-36.06-23.44a3.86 3.86 0 0 1-1.76-3.24Z" fill="url(#b)"/>'
                    '<path fill-rule="evenodd" clip-rule="evenodd" d="M210.49 167.01 250 192.23l39.51-25.22a4.86 4.86 0 0 1 '
                    '5.9.53c.85.78.84 2.12-.03 2.88L259 202.5l-9-.5-9 .5-36.38-32.08a1.94 1.94 0 0 1-.04-2.88 4.86 4.86 0 0 1 5.9-.53Z" '
                    'fill="',
                    rp.bandcol,
                    '"/></g></svg>'
                );
            } else if (rp.cut_idx == 2) { // emerald
                buf = abi.encodePacked(
                    buf,
                    '<path d="M241.1 191h30.2l14.9-10 13.6-9.6c.9-.6 1.8-1.4 2.5-2.2l6.9-7.6 6.8-9.6c.3-.4.5-.9.5-1.4v-.4c0-.9-.2-1.8-'
                    '.7-2.6l-2.9-4.8c-1.8-3-5.1-4.8-8.6-4.8H198.7c-3.5 0-6.8 1.8-8.6 4.8l-2.9 4.8c-.5.8-.7 1.7-.7 2.6v.4c0 .5.2 1 .5 '
                    '1.4l6.8 9.6 6.9 7.6c.7.8 1.6 1.6 2.5 2.2l13.6 9.6 14.9 10h9.4Z" fill="url(#b)"/>'
                    '<path fill-rule="evenodd" clip-rule="evenodd" d="m232.8 191 18.2-2 19 2 6.1-4.5-25.1-3-24.3 3 6.1 4.5Zm18.2-14 '
                    '39.3-.4c.6 0 1.3-.1 1.9-.4l4.8-3.2c.32-.25.63-.5.97-.75.71-.55 1.5-1.16 2.53-2.05l8.6-9.6 '
                    '5.7-8.3c.6-.9.8-1.9.6-2.9l-.2-1.4 3.6-1v13l-3.8 8-15 10-38 25-11-1-10.2 1-38-25-15-10-3.8-8v-13l3.6 '
                    '1-.2 1.4c-.2 1 0 2 .6 2.9l5.7 8.3 8.6 9.6c1.02.89 1.82 1.5 2.53 2.05.34.25.65.5.97.75l4.8 3.2c.6.3 1.3.4 1.9.4l38.5.4Z" '
                    'fill="',
                    rp.bandcol,
                    '"/></g></svg>'
                );
            } else { // solitaire 
                buf = abi.encodePacked(
                    buf,
                    '<path d="M255 194.5c-2.9 2-6.7 2-9.6 0l-46.4-31.6c-5.2-3.6-4.9-11.4.6-14.4l10-5.6c1.3-.7 2.7-1.1 '
                    '4.2-1.1h72.8c1.5 0 2.9.4 4.2 1.1l10 5.6c5.5 3.1 5.8 10.9.6 14.4l-46.4 31.6Z" fill="url(#b)"/>'
                    '<path d="m249.9 196.3 5-11.4-3.2-22.9-.8-8.7h-2.8l-.8 8.7-2.54 22.9 5.14 11.4Z" fill="',
                    rp.bandcol,
                    '"/>'
                    '<path d="m245.9 202.4-5.4.5-46.9-33.8c-2.4-1.7-3.9-5.2-3.7-7.4l.9-4.1c0-.1 0-.1.1-.4l1.7-4 3.5-.2-.7 '
                    '1.9c-.3.9-.2 1.8-.1 2.8v.5c.3 1.6 1.8 3 3.2 3.9l39.4 25.6c2.7 1.8 5.88 0 6.98-3.1l7.92 18 1.1.1 5.2.5 '
                    '47.2-34c2.4-1.7 3.9-5.2 3.7-7.4l-.9-4.1c0-.1 0-.1-.1-.4l-1.7-4-3.5-.2.7 1.9c.3.9.2 1.8.1 '
                    '2.8v.5c-.3 1.6-1.8 3-3.2 3.9l-39.4 25.6c-2.7 1.8-6.12-.1-7.12-3.2l-4 8.9-3.48 9" fill="',
                    rp.bandcol,
                    '"/></g></svg>'
                );
            }
        }        

        return (buf, rp);
    }

    // ============ OVERRIDES ============

    /// @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /// @notice Updates tokenId's wearer and seed to update background
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (!(from == address(0x0) || to == address(0x0))) {
            uint256 prevBg = _wearerSeed[tokenId] % 335;
            _wearerSeed[tokenId] = randSeed(to, tokenId, 13999234923493293432397);
            uint256 thisBg = _wearerSeed[tokenId] % 335;
            uint256 thisBg30 = thisBg + 30;
            uint256 prevBg30 = prevBg + 30;
            if ((thisBg > prevBg ? thisBg30 - prevBg30 : prevBg30 - thisBg30) < 30) {
                _wearerSeed[tokenId] += 65;
            }
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        
        (bytes memory svgBuf, RingParams memory rp) = getSvg(tokenId);

        // Attributes 
        string memory bandcol = rp.band_idx == 0 ? "Rose gold" : rp.band_idx == 1 ? "Platinum" : "Gold";
        string memory gemcol;
        string memory cutname;
        {
            if (rp.cut_idx == 0) {
                gemcol = "Holographic";
                cutname = "Ethereum";
            } else {
                gemcol = string(abi.encodePacked("hsl(", toString(rp.gemcol_h), ", ", toString(rp.gemcol_s), "%, ", toString(rp.gemcol_l), "%)"));
                cutname = rp.cut_idx == 1 ? "Round" : rp.cut_idx == 2 ? "Emerald" : "Solitaire";
            }
        }

        string memory metadata_attr = string(
            abi.encodePacked(
                'attributes": [{"trait_type": "Cut", "value": "',
                cutname,
                '"},',
                '{"trait_type": "Band color", "value": "',
                bandcol,
                '"},',
                '{"trait_type": "Background color", "value": "hsl(',
                toString(rp.bgcol_h),
                ", ",
                toString(rp.bgcol_s),
                "%, 50%)",
                '"},',
                '{"trait_type": "Gem color", "value": "',
                gemcol,
                '"}',
                "]"
            )
        );

        string memory json = Base64.encode(
            bytes(
                abi.encodePacked(   
                    '{"name": "0xCarat #',
                    toString(tokenId),
                    '", "description": "A fully on-chain ring to celebrate on-chain love.", "image": "data:image/svg+xml;base64,',
                    Base64.encode(svgBuf),
                    '","',
                    metadata_attr,
                    "}"
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}

/// @notice These contract definitions are used to create a reference to the OpenSea ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
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