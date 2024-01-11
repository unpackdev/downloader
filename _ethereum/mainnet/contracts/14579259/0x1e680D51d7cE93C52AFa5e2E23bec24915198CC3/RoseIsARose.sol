// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

//             o8888888o.                                            
//            88;;     *88o   o8888888o                        +     
//           o88OOo;     *8888*      *88o                     ##    
//         o88*  *OO;;;;OO    OOo;    OO88o                  ###+   
//        88;;;;;;OO]]OO*   OO *OO;;Oo   *88o              +#####   
//        88;;;;OO;;;;;;;;OOOO  OOOOOO      88o          +#######+  
//       o88]];;OO;;;;;;OOOO* OO  OO;;       *88      +###########  
//     o88OOOO;;;;OO]]OOOO*   OO   *Oo;;       88  +##########;;##+ 
//    88]]]]OO]];;OOOO;;      OO    OO;;        ############*;;;##+ 
//   o88]]OO]]OO]];;;;;;;;OOOO;;;;  *Oo;;;      ###########*::##### 
//  88]]]]OO]]]]OOOOOO;;OOOO;;;;;;    OO;;     +##############**;;#+
//  88;;]]OO]];;;;;;;*OOOO]];;;;;;    OO;;    +#############*::*####
//  88;;]]OO;;;;;;;;      *OOo;;;;  OO*;;;   +############::*##*;;##
//   *88;;]]OO;;;;;;;;;;;;   *OOOOOO*;;;   +################*::*++##
//     *88OO]]OO;;;;;oOOOOOOOO]];;;;;;;; +################*::*######
//      88]];;]]OOOOOO*;;;;; *OO;;;;;;  ## +##############::##*:####
//      88;;;;;;;;;;;;;;;;;;  OO;;;;;+##+   ############::##*::*####
//      88;;;;;;;;;;;;;;;;;; oOO######+      +############*::*######
//      88o;;;;;;;;;;;;;;; +########LL#+      +###########::##*:++#+
//       *88o;;;;;;;;;;; +##########BBLL#+      +#######::##*:++##+ 
//         *8888o;;;  .+##+   +###BBBBBB##+    +  +#######*:++##+   
//              +###########+     +#########+ ##    +########+      
//            +################+       +######GG##+     ##          
//           +####################+      +######GG##+   #+          
//         +###############################+   +#GG##+ ##          
//        +#################;;###;;#####+         +#######+         
//       +############::##:::##;;####                +###GG#+      
//      +###########::###:::##;;####                      ##GG#+    
//     +########::##::##::##;;;;##+                       ####GG##+ 
//    #####;;#::##::###:;###;;###+                     +########GG##
//   ####;;###;;##;;##;;##;;###+A rose is a rose is a rose is a rose#

contract RoseIsARoseNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    using Strings for uint256;
    
    string private _baseURIextended = "ipfs://QmPJvnsveUY1jV8yqnSTxmRvDcW2sYsuC53ej5DLGFSt19";
    string private _description = "Loveliness extreme.";
    string private _label = "Rose";
    uint256 private _first_new_moon = 947182440;

    constructor() ERC721 ("ARoseIsARose", "ROSE") {}

    function setFirstNewMoonTimestamp(uint256 newTimestamp) external onlyOwner {
        _first_new_moon = newTimestamp;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function setLabel(string memory label_) external onlyOwner {
        _label = label_;
    }

    function setDescription(string memory description_) external onlyOwner {
        _description = description_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function mint(address recipient)
        public onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        return newItemId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory name = string(
            abi.encodePacked(
                _label,
                " #",
                toString(tokenId)
                )
            );
        string memory description = _description;
        uint256 moon_id = moon();
        string memory image = string(
            abi.encodePacked(
                _baseURIextended, 
                "/",
                toString(tokenId),
                "/",
                toString(moon_id),
                ".png"
                )
            );

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', 
                            name,
                            '", "description":"', 
                            description,
                            '", "image": "', 
                            image,
                            '"}'
                        )
                    )
                )
            )
        );
    }


    function moon()
        public view
        returns (uint256)
    {
     
        uint256 _b = block.timestamp;        
        uint256 seconds_per_cycle = 2551442;
        uint256 total_secs = _b - _first_new_moon;
        uint256 currentsecs = total_secs % seconds_per_cycle;

        if ((currentsecs < 91123) || ((currentsecs > 2460348) && (currentsecs < 2551442))) {
            return 14;
        } else if (((currentsecs > 91124) && (currentsecs < 182247)) || ((currentsecs > 2369224) && (currentsecs < 2460347))) {
            return 13;
        } else if (((currentsecs > 182248) && (currentsecs < 273371)) || ((currentsecs > 2278100) && (currentsecs < 2369223))) {
            return 12;
        } else if (((currentsecs > 273372) && (currentsecs < 364495)) || ((currentsecs > 2186976) && (currentsecs < 2278099))) {
            return 11;
        } else if (((currentsecs > 364496) && (currentsecs < 455619)) || ((currentsecs > 2095852) && (currentsecs < 2186975))) {
            return 10;
        } else if (((currentsecs > 455620) && (currentsecs < 546743)) || ((currentsecs > 2004728) && (currentsecs < 2095851))) {
            return 9;
        } else if (((currentsecs > 546744) && (currentsecs < 637867)) || ((currentsecs > 1913604) && (currentsecs < 2004727))) {
            return 8;
        } else if (((currentsecs > 637868) && (currentsecs < 728991)) || ((currentsecs > 1822480) && (currentsecs < 1913603))) {
            return 7;
        } else if (((currentsecs > 728992) && (currentsecs < 820115)) || ((currentsecs > 1731356) && (currentsecs < 1822479))) {
            return 6;
        } else if (((currentsecs > 820116) && (currentsecs < 911239)) || ((currentsecs > 1640232) && (currentsecs < 1731355))) {
            return 5;
        } else if (((currentsecs > 911240) && (currentsecs < 1002363)) || ((currentsecs > 1549108) && (currentsecs < 1640231))) {
            return 4;
        } else if (((currentsecs > 1002364) && (currentsecs < 1093487)) || ((currentsecs > 1457984) && (currentsecs < 1549107))) {
            return 3;
        } else if (((currentsecs > 1093488) && (currentsecs < 1184611)) || ((currentsecs > 1366860) && (currentsecs < 1457983))) {
            return 2;
        } else {
            // full moon
            return 1;
        } 
    }

    /**
     * from: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Strings.sol
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    function blocktime()
        public view
        returns (uint256)
    {    
        return block.timestamp;
    }
}
// @naftponk


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
