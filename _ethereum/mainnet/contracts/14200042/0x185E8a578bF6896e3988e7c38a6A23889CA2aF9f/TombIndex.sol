                                                                                                                                           
//    .^7??????????????????????????????????????????????????????????????????7!:       .~7????????????????????????????????: 
//     :#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y   ^#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5 
//    ^@@@@@@#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB&@@@@@B ~@@@@@@#BBBBBBBBBBBBBBBBBBBBBBBBBBBBB#7 
//    Y@@@@@#                                                                ~@@@@@@ P@@@@@G                                 
//    .&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G~ ~@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P~   
//      J&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.!B@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B~   .Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B  
//         ...........................B@@@@@5  .7#@@@@@@@#?^....................          ..........................:#@@@@@J 
//    ^5YYYJJJJJJJJJJJJJJJJJJJJJJJJJJY&@@@@@?     .J&@@@@@@&5JJJJJJJJJJJJJJJJJJJYYYYYYYYYYJJJJJJJJJJJJJJJJJJJJJJJJJJY@@@@@@! 
//    5@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?         :5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@7  
//    !GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPY~              ^JPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPJ^    

//  _______________________________________________________ Tomb Series  ___________________________________________________

//       :!JYYYYJ!.                   .JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY?~.   7YYYYYYYYY?~.              ^JYYYYYYYYY^ 
//     ~&@@@@@@@@@@#7.                ?@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P  &@@@@@@@@@@@@B!           :@@@@@@@@@@@5 
//    ^@@@@@@BB@@@@@@@B!              ?@@@@@&PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG&@@@@@# JGGGGGGG#@@@@@@@G^         !PGGGGGGGGG! 
//    5@@@@@5  .7#@@@@@@@P^           ?@@@@@P                                .@@@@@@.         .J&@@@@@@&5:                   
//    Y@@@@@Y     .J&@@@@@@&5:        ?@@@@@G                                 @@@@@@.            :Y&@@@@@@&J.                
//    Y@@@@@5        :5&@@@@@@&J.     ?@@@@@G                                 @@@@@@.               ^P@@@@@@@#7.             
//    Y@@@@@5           ^P@@@@@@@#7.  J@@@@@G                                 @@@@@@.                  ~G@@@@@@@B!           
//    Y@@@@@5              ~B@@@@@@@BG@@@@@@! PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP#@@@@@# JGPPPPPPPP5:        .7#@@@@@@@GPPPPPPG~ 
//    5@@@@@5                .7#@@@@@@@@@@&! .@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G  &@@@@@@@@@@&           .J&@@@@@@@@@@@@5 
//    ^5YYY5~                   .!JYYYYY7:    Y5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ~.   ?5YYYYYYY5J.              :7JYYYYYYYY5^ 

//  _______________________________________________________ Tomb Index  _____________________________________________________

// _________________________________________________ Deployed by TERRAIN 2022 _______________________________________________

// _____________________________________________ All tombs drawn by David Rudnick ___________________________________________

// ______________________________________________ Contract architect: Luke Miles ____________________________________________


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./lib.sol";

contract TombIndex is ERC721, Ownable {
    string public imageURI;
    bool public isFrozen;

    event TombUpdated(uint256 id);
    string[] private houses = ["GENESIS", "LUX", "X2", "SHADOW", "COMETS", "DEVASTATORS", "TERRA", "RONIN"];

    struct deployment {
        uint16 chainID;
        bool deployed;
        address hostContract;
        uint256 tokenID;
    }

    struct Tomb {
        bool _initialized;
        uint32 weight;
        uint8 numberInHouse;
        uint house;
        deployment deployment;
    }

    mapping(uint8 => Tomb) public tombByID;
    mapping(uint8 => string) public tombNameByID;

    constructor(
        string memory _imageURI,
        address artistAddress
    ) ERC721("Tomb Series", "TOMB") {
        _initializeTombs(artistAddress);
        imageURI = _imageURI;
    }

    function freezeContract() public onlyOwner {
        isFrozen = true;
    }

    modifier notFrozen() {
        require(!isFrozen, "Contract is frozen");
        _;
    }

    function _saveTomb(uint256 id, string memory name, Tomb memory tomb) internal {
        require(id > 0 && id <= 177, "Tomb out of bounds");
        uint8 id8 = uint8(id);
        tombByID[id8] = tomb;
        tombNameByID[id8] = name;
        emit TombUpdated(id);
    }

    function saveTombs(uint256[] calldata ids, string[] calldata names, Tomb[] calldata tombs) public onlyOwner notFrozen {
        require(ids.length == tombs.length, "invalid input");
        require(names.length == tombs.length, "invalid input");
        for (uint256 i = 0; i < tombs.length; i++) {
            _saveTomb(ids[i], names[i], tombs[i]);   
        }
    }

    function _initializeTombs(address artistAddress) internal onlyOwner {
        _saveTomb(1, "AEON", Tomb({
            _initialized: true,
            weight: 18762694,
            numberInHouse: 1,
            house: 0,
            deployment: deployment({
                hostContract: 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405,
                tokenID: 20583,
                chainID: 1,
                deployed: true
            })
        }));

        _saveTomb(2, "TAROT", Tomb({
            _initialized: true,
            weight: 21598168,
            numberInHouse: 2,
            house: 0,
            deployment: deployment({
                hostContract: 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405,
                tokenID: 20586,
                chainID: 1,
                deployed: true
            })
        }));

        _saveTomb(3, "CADMIUM", Tomb({
            _initialized: true,
            weight: 24129641,
            numberInHouse: 3,
            house: 0,
            deployment: deployment({
                hostContract: 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405,
                tokenID: 20592,
                chainID: 1,
                deployed: true
            })
        }));

        _saveTomb(4, "NIAGARA", Tomb({
            _initialized: true,
            weight: 22108549,
            numberInHouse: 4,
            house: 0,
            deployment: deployment({
                hostContract: 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405,
                tokenID: 20609,
                chainID: 1,
                deployed: true
            })
        }));

        _saveTomb(5, "ARK", Tomb({
            _initialized: true,
            weight: 23257493,
            numberInHouse: 5,
            house: 0,
            deployment: deployment({
                hostContract: 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405,
                tokenID: 20614,
                chainID: 1,
                deployed: true
            })
        }));

        _saveTomb(6, "ORION", Tomb({
            _initialized: true,
            weight: 23205361,
            numberInHouse: 6,
            house: 0,
            deployment: deployment({
                hostContract: 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405,
                tokenID: 20616,
                chainID: 1,
                deployed: true
            })
        }));

        _saveTomb(7, "MIDNIGHT", Tomb({
            _initialized: true,
            weight: 19431160,
            numberInHouse: 7,
            house: 0,
            deployment: deployment({
                hostContract: 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405,
                tokenID: 20617,
                chainID: 1,
                deployed: true
            })
        }));

        _saveTomb(8, "ORIGIN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 1,
            house: 1,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(9, "TURING", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 1,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(10, "HOME", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 1,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(11, "EPOCH", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 1,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(12, "TEMPO", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 2,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(13, "THE NEW JEWS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 1,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(14, "ORIGIN UNKNOWN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 1,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(15, "HEAT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 2,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(16, "FFF", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 3,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(17, "NEW FORM ZONE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 2,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(18, "ANAMNESIS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 2,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(19, "SYNTAX", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 2,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(20, "NUXUI-N", Tomb({
            _initialized: true,
            weight: 18447712,
            numberInHouse: 3,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(21, "EQUINOX", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 4,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(22, "EUROPE AFTER THE RAIN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 3,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(23, "SEA OF SQUARES", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 3,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(24, "STORM", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 4,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(25, "FANTAZIA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 5,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(26, "DREAMSCAPE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 6,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(27, "HYPERSPECTRAL DAWN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 4,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(28, "SKYLINE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 7,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(29, "KHAOS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 8,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(30, "ON REMAND", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 9,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(31, "OUTER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 3,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(32, "ORDER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 4,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(33, "ALPHA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 1,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(34, "VAPOUR", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 2,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(35, "HYPER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 3,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(36, "EXODUS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 4,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(37, "DAWN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 5,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(38, "TOTAL ECLIPSE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 6,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(39, "VANISHING POINT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 7,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(40, "FAINT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 8,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(41, "IRIDIUM", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 8,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(42, "KILO", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 9,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(43, "CENSER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 10,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(44, "QUARTO", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 11,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(45, "KINGFISHER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 12,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(46, "UNITE OR PERISH", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 13,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(47, "NANGA PARBAT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 14,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(48, "DUAL EVENT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 9,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(49, "OPACITY", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 10,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(50, "NEXUS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 4,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(51, "POINT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 5,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(52, "HALON", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 6,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(53, "VOID", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 11,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(54, "EXCEEDING LIGHT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 12,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(55, "BLACK HOLES IN THE NOW", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 13,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(56, "UNKNOWN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 14,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(57, "TRANSPARENCY", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 15,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(58, "UNANIMOUS NIGHT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 16,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(59, "GHOST", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 17,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(60, "ENTIRE WORLDS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 18,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(61, "ANTIGEN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 5,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(62, "FREED FROM DESIRE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 5,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(63, "PARADISE CONQUISTADORS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 5,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(64, "HARD LEADERS II", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 10,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(65, "WHITE 001", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 11,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(66, "JUNGLIST", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 12,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(67, "VOID ARROWS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 6,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(68, "EARTH", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 6,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(69, "THE KNOT TIES ITSELF", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 6,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(70, "DEATH IMITATES LANGUAGE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 7,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(71, "NECTAR AND LIGHT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 7,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(72, "RECUR", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 7,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(73, "PAX", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 2,
            house: 1,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(74, "FLOW COMA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 13,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(75, "TOTAL XSTACY", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 14,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(76, "TRAGEDY [FOR YOU]", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 15,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(77, "VERDANT PERJURY", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 8,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(78, "ACEN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 16,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(79, "PROTOCOL", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 8,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(80, "NONREAL PACKET MAZE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 9,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(81, "ABSOLUTE POWER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 15,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(82, unicode"TANTŌ", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 16,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(83, "JAG MANDIR", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 17,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(84, "NATION", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 18,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(85, "SESSION", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 19,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(86, "HERE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 20,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(87, "TACTA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 21,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(88, "WING OF A BLUE ROLLER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 7,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(89, "SHADDAI", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 3,
            house: 1,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(90, "DEFENSOR MUNDI", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 8,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(91, "TIME PASSES", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 22,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(92, "DYNAMICS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 23,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(93, "CONFUSION", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 24,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(94, unicode"IDEEËN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 25,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(95, "ZEITUNG", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 26,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(96, "MONUMENT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 27,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(97, "ENERGY REMAINS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 28,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(98, "HACKED AMAZON", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 10,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(99, "SUPRA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 8,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(100, unicode"ÆTHER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 4,
            house: 1,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(101, "RADAR", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 9,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(102, "ARRAY", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 10,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(103, "QUADRATIC EMPIRE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 11,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(104, "ENERGY FLASH", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 17,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(105, "INTO DREAMS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 18,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(106, "SLOW", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 19,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(107, "VENOM HORIZON", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 12,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(108, "2099", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 20,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(109, "LEMUR", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 9,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(110, "SUBTROPICAL SHRINES", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 13,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(111, "TERRAIN", Tomb({
            _initialized: true,
            weight: 22862184,
            numberInHouse: 10,
            house: 7,
            deployment: deployment({
                hostContract: address(this),
                tokenID: 111,
                chainID: 1,
                deployed: true
            })
        }));

        _saveTomb(112, "AEGIS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 9,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(113, "VIBE SARCOPHAGI", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 14,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(114, "HALCYON", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 21,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(115, "JOYRIDER 2", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 22,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(116, "WORLD [PRICE OF LOVE]", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 23,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(117, "OZYMANDIAS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 15,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(118, "FOREVER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 11,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(119, "FRONTIER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 10,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(120, "STRAYLIGHT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 12,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(121, "HYDRA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 11,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(122, "SWIFT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 12,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(123, "ANON", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 19,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(124, "INDEX", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 20,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(125, "HARD TARGET", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 21,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(126, "BLACKBIRD", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 22,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(127, "OBSERVE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 23,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(128, "AFTER EARTH", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 24,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(129, "UMBRA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 25,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(130, "POEM", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 26,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(131, "MONT BLANC", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 29,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(132, "TOURBILLON", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 30,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(133, "CALIBAN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 31,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(134, "CYGNUS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 32,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(135, "VOYAGES", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 33,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(136, "LOAM", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 34,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(137, "HNX_T01", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 35,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(138, "ENDSTATE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 27,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(139, "TERMINAL", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 28,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(140, "FORGERY", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 11,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(141, "NOMAD", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 13,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(142, "XENON", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 14,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(143, "REVEAL", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 29,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(144, "LONE AND LEVEL", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 30,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(145, "PHANTOM", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 31,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(146, "TRUE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 32,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(147, "STEALTH", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 33,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(148, "VANTA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 34,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(149, "KAIROS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 35,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(150, "SHADOW", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 36,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(151, "TRANCE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 13,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(152, "REPLICA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 12,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(153, "THE FOG OF JUNK PSALMS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 16,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(154, "VALLEY OF THE SHADOWS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 24,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(155, "THE END", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 25,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(156, "PHOSPHOR", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 26,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(157, "ABOUT PLATO'S CAVE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 17,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(158, "IX. SECTOR", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 14,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(159, "FICTION", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 13,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(160, "SOLUTION", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 15,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(161, "TOPOS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 15,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(162, "LIGHT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 16,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(163, "THE BEZEL EPOQUE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 18,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(164, "I STILL DREAM", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 27,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(165, "TIME PROBLEM", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 28,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(166, "ARCOURS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 29,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(167, "SELBSTVERSELBSTLICHUNG", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 19,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(168, "ISENHEIM", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 14,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(169, unicode"T1A–T [RONIN]", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 16,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(170, "ETERNA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 5,
            house: 1,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(171, "EMPYREAN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 36,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(172, "TACIT BLUE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 37,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(173, "ARDENNES", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 38,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(174, "VOYAGES 2", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 39,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(175, "INPUT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 40,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(176, "ULTRA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 41,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(177, "GENESIS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 42,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _mint(artistAddress, 111);
    }

    function setImageURI(string memory _url) public onlyOwner notFrozen {
        imageURI = _url;
    }

    function _tombName(uint8 id) internal view returns (string memory) {
        return string(abi.encodePacked("Tomb ", RomanNumeral.ofNum(id), unicode' — ', tombNameByID[id]));
    }

    function _ordinalString(uint8 number) internal pure returns (string memory) {
        if (number <= 0) {
            return "0";
        }

        string memory suffix = "th";
        uint8 j = number % 10;
        uint8 k = number % 100;

        if (j == 1 && k != 11) {
            suffix = "st";
        } else if (j == 2 && k != 12) {
            suffix = "nd";
        } else if (j == 3 && k != 13) {
            suffix = "rd";
        }

        return string(abi.encodePacked(_u256toString(number), suffix));
    }

    function _tombDescription(uint8 id, Tomb memory tomb) internal view returns (string memory) {
        return string(abi.encodePacked(tombNameByID[id], " is the ", _ordinalString(id), " Tomb in the Tomb Series. It is the ", _ordinalString(tomb.numberInHouse), " Tomb in the ",
            houses[tomb.house], " house, at a weight of ", _periodSeparatedNum(tomb.weight), "."));
    }

    function ownerOfTomb(uint8 id) public view returns (address) {
        Tomb memory tomb = tombByID[id];
        require(tomb._initialized, "Tomb doesn't exist");
        require(tomb.deployment.chainID == 1, "Can only check ownership value for Ethereum mainnet based Tombs");
        return ERC721(tomb.deployment.hostContract).ownerOf(tomb.deployment.tokenID);
    }

    function _makeAttribute(string memory name, string memory value, bool isJSONString) internal pure returns (string memory) {
        string memory strDelimiter = '';
        if (isJSONString) {
            strDelimiter = '"';
        }

        return string(abi.encodePacked(
            '{"trait_type":"', name, '","value":', strDelimiter, value, strDelimiter, '}'
        ));
    }

    function jsonForTomb(uint8 id) public view returns (bytes memory) {
        Tomb memory tomb = tombByID[id];
        require(tomb._initialized, "Tomb doesn't exist");
        return abi.encodePacked('{"name":"',_tombName(id),
                '","description":"', _tombDescription(id, tomb),
                '","image":"',
                imageURI, _u256toString(id), '.png","attributes":[', 
                _makeAttribute('House', houses[tomb.house], true), ',',
                _makeAttribute('Weight', _u256toString(tomb.weight), false), ',',
                _makeAttribute('Number in house', _u256toString(tomb.numberInHouse), false),
              ']}');
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(jsonForTomb(uint8(id)))));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC721)
        returns (bool)
    {
        return
            interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
    }

    function _concatDotParts(string memory base, uint256 part, bool needsDot) internal pure returns (string memory) {  
        string memory glue = ".";
        if (!needsDot) {
            glue = "";
        }

        return string(abi.encodePacked(_u256toString(part), glue, base));
    }

    function _periodSeparatedNum(uint256 value) internal pure returns (string memory) {
        string memory result = "";
        uint128 index;
        while(value > 0) {
            uint256 part = value % 10;
            bool needsDot = index != 0 && index % 3 == 0;

            result = _concatDotParts(result, part, needsDot);
            value = value / 10;
            index += 1;
        }
 
        return result;
    }

    function _u256toString(uint256 value) internal pure returns (string memory) {
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
}