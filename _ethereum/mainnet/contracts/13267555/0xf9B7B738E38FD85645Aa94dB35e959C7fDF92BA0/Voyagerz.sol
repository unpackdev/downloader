//
// @title Voyagerz NFT -- Mystery Labs / Danooka
// SPDX-License-Identifier: MIT
//
pragma solidity >=0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./console.sol";

interface IN is IERC721Enumerable, IERC721Metadata {
    function getFirst(uint256 tokenId) external view returns (uint256);

    function getSecond(uint256 tokenId) external view returns (uint256);

    function getThird(uint256 tokenId) external view returns (uint256);

    function getFourth(uint256 tokenId) external view returns (uint256);

    function getFifth(uint256 tokenId) external view returns (uint256);

    function getSixth(uint256 tokenId) external view returns (uint256);

    function getSeventh(uint256 tokenId) external view returns (uint256);

    function getEight(uint256 tokenId) external view returns (uint256);
}



interface ISpacetime is IERC721Enumerable {
    
    function withdraw(address payable _owner) external view;
    
    function reserveSpacetimes(address _to, uint256 _reserveAmount) external view;


    function setBaseURI(string memory baseURI) external view;

    function flipSaleState() external view;
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory );

    function setSpacetimeName(uint256 _tokenId, string calldata _currName) external view;

    function viewSpacetimeName(uint _tokenId) external view returns(string memory);

    function mintSpacetime(uint _numberOfTokens) external;
}

contract Voyagerz is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    uint256 public constant MAX_MULTI_MINT_AMOUNT = 10;
    
    uint256 public constant MAX_ADDRESS_HISTORY = 40;
    uint256 public constant MAX_MINT_COUNT = 1500;
    uint256 private constant MAX_RADIUS = 160;
    
    // Dependent contracts
    IN public immutable         n;
    IERC721 public immutable    ribonzContract;
    ISpacetime public immutable    spacetimeContract;

    bool private immutable      _test_chain_mode;


    uint256 public immutable    maxTotalSupply;

    uint256 public     mintPrice                        = 50000000000000000;
    uint256 public     mintPriceSpecialOfferForRZHolders               =  0;

    mapping(uint256 => uint256) public n_sum_first;
    mapping(uint256 => bool)    public stats_disable;
    mapping(uint256 => uint256) public image_seed; 

    mapping(uint256 => uint256) public voyage_count;
    mapping(uint256 => string[]) public address_history;

    // RIBONZ:Genesis + Spacetime holders get to 'consume' an ST mint slot corresponding
    // To their owned token for the special offer
    uint256[1000]               spaceTimeMintSlots;

    bool public saleIsActive = true;

    constructor(bool test_chain_mode) ERC721("VOYAGERZ", "VZ") {
        n = IN(address(0x05a46f1E545526FB803FF974C790aCeA34D1f2D6));
        ribonzContract = IERC721(address(0xaa44dD92BC64BF8E700bb515a9Bf95547b413E4e));
        spacetimeContract = ISpacetime(address(0xc0B1d8c41eF69a72a41Ba36A248C76aFeea30A0C));

        maxTotalSupply = MAX_MINT_COUNT;
        _test_chain_mode = test_chain_mode;
    }

    // MUST TAKE OUT OF PROD
    function testForceTravel(uint256 tokenId, uint256 trips) public returns (uint256) {
        uint256 index;
        for (index = 0; index < trips; index++) {
            updateVoyagerState(msg.sender, tokenId);
        }
        return 0;
    }

    //
    // OWNER ONLY Routines
    //
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    function withdrawAll() external onlyOwner {
        require(msg.sender == owner(), "only owner!");
        payable(owner()).transfer(address(this).balance);
    }
    function updateMintPrice(uint256 newPrice) external onlyOwner {
        require(msg.sender == owner(), "only owner!");
        mintPrice = newPrice;
    }
    function updateSpecialOfferMintPrice(uint256 newPrice) external onlyOwner {
        require(msg.sender == owner(), "only owner!");
        mintPriceSpecialOfferForRZHolders = newPrice;
    }

    function clearStatsDisplay(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "not the owner");
        stats_disable[tokenId] = true;
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function addrToString(address account, uint256 limit) internal pure returns (string memory) {
        return internalToString(abi.encodePacked(account), limit);
    }

    function internalToString(bytes memory data, uint256 limit) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        uint256 end = data.length;
        if (limit < end) {
            end = limit;
        }

        bytes memory str = new bytes(2 + end * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < end; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
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

    //
    // Does state updates at mint time and on every transfer
    //
    function updateVoyagerState(address to, uint256 cvMintIndex) private {
        uint256 n_tokens = 0;
        if (!_test_chain_mode) {
            // Query any n's we hold
            n_tokens = n.balanceOf(to);
        }
        uint256 new_voyage_count = voyage_count[cvMintIndex] + 1;

        string memory trunc_addr = addrToString(to, 3);

        // Track in the circular ring buffer
        if (new_voyage_count <= MAX_ADDRESS_HISTORY) {
            address_history[cvMintIndex].push(trunc_addr);
        } else {
            uint256 write_idx = new_voyage_count % MAX_ADDRESS_HISTORY;
            address_history[cvMintIndex][write_idx] = trunc_addr;
        }

        // Accumulate totals of the N's taking the firs token we find
        if (n_tokens > 0) {
            uint256 n_id = (n.tokenOfOwnerByIndex(to, 0));
            uint256 n_first = n.getFirst(n_id);
            n_sum_first[cvMintIndex] += n_first;
        }

        voyage_count[cvMintIndex] = new_voyage_count;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        updateVoyagerState(to, tokenId);
    }

    // RZ Mint Slots
    function availableRZMintSlots() public view returns (uint256) {

        uint256 availableMintSlots = 0;
        if (ribonzContract.balanceOf(msg.sender) == 0) {
            // If not holding RIBONZ genesis can't get an RZ mint slot
            return 0;
        }

        uint256[] memory stTokensOfOwner = spacetimeContract.tokensOfOwner(msg.sender);

        
        for (uint256 i= 0; i<stTokensOfOwner.length; i++) {
            if (spaceTimeMintSlots[stTokensOfOwner[i]] == 0) {
                availableMintSlots++;
            }
        }
        
        return availableMintSlots;
    }

    // Defining a function to generate
    // a random number
    function randSeed(uint256 tokenId, uint256 modulus) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty, tokenId, n_sum_first[tokenId]))) % modulus;
    }

    function mintVoyagerzInternal(uint256 num_to_mint, uint256 curMintPrice) internal  {
        require(msg.value >= curMintPrice * num_to_mint, "Didn't pass in enough funds!");
        require(saleIsActive, "sale not active at this time!");
        require((totalSupply() + num_to_mint) <= MAX_MINT_COUNT, "Minting would exceed supply");
        require(num_to_mint <= MAX_MULTI_MINT_AMOUNT, "Max mint at a time exceeded!");


        for (uint256 i = 0; i < num_to_mint; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < maxTotalSupply) {
                _safeMint(msg.sender, mintIndex);

                // Store the seed for eternity -- it will be used to deterministically generate the image
                image_seed[mintIndex] = randSeed(mintIndex, 13999234923493293432397);
            }
        }

    }

    /**
     * @notice Allow anyone to mint a token with the supply id if this pass is unrestricted.
     *         n token holders can use this function without using the n token holders allowance,
     *         this is useful when the allowance is fully utilized.
     * @param num_to_mint num to mint
     */
    function mintVoyagerz(uint256 num_to_mint) public payable virtual nonReentrant {
        mintVoyagerzInternal(num_to_mint, mintPrice);
    }

    //
    // Mint a voygagerz with special promo for RIBONZ Genesis  + Spacetime holders
    //
    function mintVoyagerzWithRZ(uint256 num_to_mint) public payable virtual nonReentrant {
        // Precondition checks here
        uint256 availableSlots = availableRZMintSlots();

        
        require(availableSlots >= num_to_mint, "Need to hold RIBONZ: Genesis and more RIBONZ: Spacetime than mint count");
        console.log('RZ MINT SLOTS', availableSlots);

        // Each special offer mint 'consumes' a spacetime special offer slot
        uint256[] memory stTokensOfOwner = spacetimeContract.tokensOfOwner(msg.sender);
        

        // Do the mint at discount price!
        mintVoyagerzInternal(num_to_mint, mintPriceSpecialOfferForRZHolders);

        uint256 mintSlotsToConsume = num_to_mint;

        //
        // Consume the mint slots
        //
        for (uint256 i= 0; i<stTokensOfOwner.length; i++) {
            // Eat up a slot 
            if (mintSlotsToConsume > 0 && (spaceTimeMintSlots[stTokensOfOwner[i]] == 0)) {
                spaceTimeMintSlots[stTokensOfOwner[i]] = 1;
                mintSlotsToConsume--;
                console.log('ST Mint Slot CONSUME', stTokensOfOwner[i]);
            }
        }
    }


    /**
     * @notice Calculate the currently available number of open mints
     * @return Open mint available
     */
    function openMintsAvailable() public view returns (uint256) {
        uint256 maxOpenMints = maxTotalSupply ;
        uint256 currentOpenMints = totalSupply();
        return maxOpenMints - currentOpenMints;
    }



    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? b : a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    struct RenderParams {
        uint256 hue_base;
        uint256 hue_sat;
        uint256 hue_delta;
        uint256 hue_l;
        uint256 hue_l_delta;
        uint256 stop_offset1;
        string  bgcol;
        uint    bgindex;
        uint    voyage_distance;
    }

    function getRenderParams(uint256 tokenId) internal view returns (RenderParams memory) {
        RenderParams memory rp;
        // 32 bytes of seed
        uint256 seed = image_seed[tokenId];

        // Uncapped
        rp.voyage_distance = voyage_count[tokenId] * 10 + 50 + n_sum_first[tokenId] * 13;

        
        rp.hue_base = seed & 0xFF; // 0-255
        seed = seed >> 8;
        rp.hue_delta = ((seed & 0xFF) % 33) + 3; //(3, 36)
        seed = seed >> 8;

        rp.hue_sat = ((seed & 0xFF) % 60) + 30; //(30, 90)
        seed = seed >> 8;

        rp.hue_l = ((seed & 0xFF) % 20) + 30; //(30, 50)
        seed = seed >> 8;

        rp.hue_l_delta = ((seed & 0xFF) % 45) + 5; //(5, 50)
        seed = seed >> 8;

        rp.stop_offset1 = ((seed & 0xFF) % 10) + 15; //(15, 25)
        seed = seed >> 8;

        if ((seed & 0xFF) > 50) { // >50/255 = 0.8% chance of black
            seed = seed >> 8;
            rp.bgcol = "hsl(0,0,0)";
            rp.bgindex = 0;
        }
        else {
            seed = seed >> 8;
            if (seed & 0x3 == 0) {
                rp.bgcol = "#F59738";
                rp.bgindex = 1;
            }
            else if (seed & 0x3 == 1) {
                rp.bgcol = "#E5FCC2";
                rp.bgindex = 2;
            }
            else if (seed & 0x3 == 2) {
                rp.bgcol = "#DCEDC2";
                rp.bgindex = 3;
            }
            else {
                rp.bgcol = "#ACCBFF";
                rp.bgindex = 4;
            }
        }

        return rp;
    }

    function getSvg(uint256 tokenId) internal view returns (string memory, RenderParams memory) {
        //
        // Generate SVG
        //
        RenderParams memory rp = getRenderParams(tokenId);
        string memory buf;

        buf = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">'
                "<style>"
                ".base {"
                "fill : hsl(",
                toString((rp.hue_base)),
                ",",
                toString(rp.hue_sat),
                "%, 30%);"
                "font-family: monospace;"
                "font-size: 6px;"
                "}</style>"
                "<defs>"
                '<radialGradient id="xgro">'
                '<stop offset="0%" stop-color="hsl(0,0,0,0)" />'
                '<stop offset="5%" stop-color="hsl(',
                toString(rp.hue_base),
                ',77%, 26%)" />'
            )
        );

        {
            // Scope for stack too deep
            buf = string(
                abi.encodePacked(
                    buf,
                    '<stop offset="',
                    toString(rp.stop_offset1),
                    '%" stop-color="hsl(',
                    toString(((rp.hue_base + rp.hue_delta)) % 255),
                    ",",
                    toString(rp.hue_sat),
                    '%, 46%)" />'
                )
            );
        }

        buf = string(abi.encodePacked(
                buf,
                '<stop offset="35%" stop-color="hsl(',
                toString((rp.hue_base + rp.hue_delta * 2) % 255),
                ",",
                toString((rp.hue_sat)),
                "%,",
                toString((rp.hue_l + rp.hue_l_delta * 0) % 47),
                '%)" />'));

        buf = string(
            abi.encodePacked(
                buf,
                '<stop offset="50%" stop-color="hsl(',
                toString((rp.hue_base + rp.hue_delta * 2) % 255),
                ",",
                toString((rp.hue_sat)),
                "%,",
                toString((rp.hue_l + rp.hue_l_delta * 1) % 57),
                '%)" />'
            )
        );

        buf = string(
            abi.encodePacked(
                buf,
                '<stop offset="60%" stop-color="hsl(',
                toString((rp.hue_base + rp.hue_delta * 3) % 255),
                ",",
                toString((rp.hue_sat)),
                "%,",
                toString((rp.hue_l + rp.hue_l_delta * 2) % 97),
                '%)" />'
            )
        );

        buf = string(
            abi.encodePacked(
                buf,
                '<stop offset="70%" stop-color="hsl(',
                toString((rp.hue_base + rp.hue_delta * 3) % 255),
                ",",
                toString((rp.hue_sat)),
                "%,",
                toString((rp.hue_l + rp.hue_l_delta * 3) % 67),
                '%)" />'
            )
        );

        buf = string(
            abi.encodePacked(buf, '<stop offset="100%" stop-color="', rp.bgcol, '" stop-opacity="0"/></radialGradient>')
        );

        {
            uint256 radius = min(rp.voyage_distance, MAX_RADIUS);
            uint256 circle_radius = (radius * 13) / 10;
            string memory s_r = toString(radius);
            string memory s_2r = toString(radius * 2);
            string memory s_cx;
            {
                // Handle negative
                s_cx = (175 > radius) ? toString(175 - radius) : string(abi.encodePacked('-', toString(radius - 175)));
            }

            buf = string(abi.encodePacked(buf, '<path id="textpath" d="M ', s_cx, " 175"));
            buf = string(abi.encodePacked(buf, " a ", s_r, ",", s_r, ",", "0 1,1,", s_2r, ", 0"));
            buf = string(abi.encodePacked(buf, " a ", s_r, ",", s_r, ",", "0 1,1,-", s_2r, ", 0"));
            buf = string(abi.encodePacked(buf, '" stroke="hsl(255,50%,50%)" fill="none"/>'
                    "</defs>"
                    '<rect width="100%" height="100%" fill="', rp.bgcol, '"></rect>'
                    '<circle cx="175" cy="175" r="',
                    toString(circle_radius)));

                if (radius < MAX_RADIUS) {
                    buf = string(abi.encodePacked(buf, '" fill="url(#xgro)" />'));
                }
                else {
                    // End state!
                    buf = string(abi.encodePacked(buf, '" fill="url(#xgro)" >',
                    ' <animate attributeName="r" values="170; 175; 196; 177; 170" keyTimes="0; 0.1; 0.3; 0.7; 1.0"  dur="8s" repeatCount="indefinite"></animate></circle>'));
                }
        }

        // Owner can turn of this cool element if they choose
        if (!stats_disable[tokenId]) {
            uint256 i;
            buf = string(abi.encodePacked(buf, '<text class="base" ><textPath href="#textpath">'));
            for (i = 0; i < address_history[tokenId].length; i++) {
                buf = string(abi.encodePacked(buf, (address_history[tokenId][i]), " "));
            }
            buf = string(abi.encodePacked(buf, "</textPath></text></svg>"));
        }

        return (buf, rp);
    }

    function tokenURI(uint256 tokenId) public virtual view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        (string memory svgBuf, RenderParams memory rp) = getSvg(tokenId);

        string memory voyage_layer = 'Tropo';
        {
            if (rp.voyage_distance >= MAX_RADIUS) {
                voyage_layer = 'Space';
            }
            else if (rp.voyage_distance >= 140) {
                voyage_layer = 'Exo';
            }
            else if (rp.voyage_distance >= 120) {
                voyage_layer = 'Thermo';
            }
            else if (rp.voyage_distance >= 100) {
                voyage_layer = 'Meso';
            }
            else if (rp.voyage_distance >= 80) {
                voyage_layer = 'Strato';
            }
        }


        //
        // Attributes
        //
        string memory metadata_attr = string(
            abi.encodePacked(
                'attributes": [{"trait_type": "Voyages", "value": ',
                toString(rp.voyage_distance),
                "},",
                '{"trait_type": "Chain hops #", "value": ',
                toString(voyage_count[tokenId]),
                "},",
                '{"trait_type": "Voyage Layer", "value": "',
                voyage_layer,
                '"},',
                '{"trait_type": "Voyage#", "value": "',
                toString(rp.voyage_distance),
                '"},',
                '{"trait_type": "Background color#", "value": "',
                toString(rp.bgindex),
                '"}',                
                "]"
            )
        );


        string memory json = Base64.encode(
            (
                bytes(
                    abi.encodePacked(
                        '{"name": "VOYAGERZ #',
                        toString(tokenId),
                        '", "description": "VOYAGERZ is a fully on chain Generative Transfer Art Project.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svgBuf)),
                        '","',
                        metadata_attr,
                        "}"
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}

// @title Base64
/// @author Brecht Devos - <brecht@loopring.org>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}