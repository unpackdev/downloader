// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721URIStorage.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

/// @title Base64
/// @author Brecht Devos - <brecht@loopring.org>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

contract TheGuySoftV2 is ERC721URIStorage, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct Payee {
        address wallet;
        string role;
        uint256 percentage;
    }


    modifier onlyUser(address _sender) {
        //require(tx.origin == msg.sender, "contracts are not allowed");
        uint32 size;
        assembly {
            size := extcodesize(_sender)
        }
        require(size == 0, "contracts are not allowed");
        _;
    }



    // mainnet
    IERC721 internal BLITMAP_CONTRACT = IERC721(0x8d04a8c79cEB0889Bdd12acdF3Fa9D207eD3Ff63);

    // test
    //IERC721 internal BLITMAP_CONTRACT = IERC721(0x1b4C2BA0c7Ee2AAF7710A11c3a2113C24624852B);

    function withdrawToPayees(uint256 _amount) internal onlyUser(msg.sender) {
        
        Payee[4] memory payees = [
            Payee(0x3B99E794378bD057F3AD7aEA9206fB6C01f3Ee60, "artist", 17),
            Payee(0x575CBC1D88c266B18f1BB221C1a1a79A55A3d3BE, "developer", 17),
            Payee(0xBF7288346588897afdae38288fff58d2e27dd235, "developer", 17),
            Payee(BLITMAP_CONTRACT.ownerOf(346), "owner of #346", 49)
        ];
        
        
        for (uint256 i = 0; i < payees.length; i++) {
            payable(payees[i].wallet).transfer(_amount.mul(payees[i].percentage).div(100));
        }
    }

    constructor() ERC721("The Soft Bid Guy", "SOFTGUY") onlyOwner {
       
    }

    function mint(
        address to,
        string memory _description,
        string memory _topText,
        string memory _bottomText
    ) external payable nonReentrant {
        require(msg.value >= 0.03 ether, "not enough ethers");
        withdrawToPayees(msg.value);
        _safeMint(to, _tokenIdCounter.current());
        _setTokenURI(
            _tokenIdCounter.current(),
            generateMetadata(
                "The Soft Bid Guy",
                _description,
                _topText,
                _bottomText
            )
        );
        _tokenIdCounter.increment();
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    


    function svgHeader() internal pure returns (string memory) {
        return
            "<svg xmlns='http://www.w3.org/2000/svg' baseProfile='tiny-ps' viewBox='0 0 320 320' width='350' height='350'><style><![CDATA[text{letter-spacing:-0.8px}.B{font-family:press_start_2pregular}.C{word-spacing:-4px}]]></style><path fill='#d57eb1' d='M320 320H0V0h320v320z'/><path fill='#e5acb3' d='M320 290h-30v-10h-20v-10h-30v-10h-10v-10h-30v-10h-40v-10h-30v-10h-20v-10H80v-10H60v-10H50v-10H30v-20H20v-20H10v-20h10V90h10V80h10V70h20V60h20V50h110v10h40v10h10v10h20v10h20v10h10v10h20v10h10v170z'/><path fill='#ba7393' d='M320 110h-10v-10h-10V90h-20V80h-20V70h-20V60h-10V50h-30V40H80v10H50v10H40v10H20v10H10v30H0v40h10v20h10v10h10v10h10v10h10v10h20v10h30v10h30v10h20v10h40v10h30v10h20v10h20v10h30v10h20v10h10v-20h-29l-1-10h-20v-10h-29l-1-10h-10v-10h-30v-10h-40v-10h-29l-1-10h-20v-10H80v-10H60v-10H50v-10H31l-1-20H20v-20H10v-20h10V90h10V80h10l1-10h19V60h20l1-10h109v10h39l1 10h9l1 10h19l1 10h19l1 10h10v10h19l1 10h10v-10zm-100 60v-20h-10v10H60v-10H50v20h10v19l1 1h139v-10H70v-10h130v9l1 1h9v-10h10zm-60-50v20h30v-20h-30zm-90 20h30v-20H70v20zm-30-40v10h70v-10h10V90h-10V70h-10v30H40zm110-30h-10v20h-10v10h10v10h110v-10H150V70z'/><path fill='#e9e9e9' d='M60 140v10h40v-10H60zm0-40V90h40v10H60zm60-10h10v10h10v10h-30v-10h10V90zm0-20v10h10V70h-10zm30 30V90h50v10h-50zm10 40v10h40v-10h-40zm-50 50v10h30v-10h-30zm90-10v10h10v-10h-10zm20 0h-9l-1-1v-9h10v10z'/>";
    }
    
    function svgBody(string memory _topText, string memory _bottomText) internal pure returns (string memory) {
        return string(
                abi.encodePacked(
                    "<text fill='#fff' x='150' y='30' font-size='12' class='B C' dominant-baseline='middle' text-anchor='middle'>",
                    _topText,
                    "</text><text fill='#fff' x='150' y='290' font-size='12' class='B C' dominant-baseline='middle' text-anchor='middle'>",
                    _bottomText,
                    "</text>"
                    )
            );
    }

    function svgFooter() internal pure returns (string memory) {
        return
            "<defs><style>@font-face{font-family:'press_start_2pregular';src:url(data:application/font-woff2;charset=utf-8;base64,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) format('woff'); font-weight:normal;font-style:normal;}</style></defs></svg>";
    }

    function generateSVG(string memory _topText, string memory _bottomText)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                Base64.encode(
                    bytes(abi.encodePacked(svgHeader(), svgBody(_topText, _bottomText), svgFooter()))
                )
            );
    }

    function generateMetadata(
        string memory _name,
        string memory _description,
        string memory _topText, 
        string memory _bottomText
    ) internal pure returns (string memory) {
        string memory description2 = ' | https://yourbidsux.wtf/ | Original Blitmap ID: #346",';
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "',
                                _name,
                                '",',
                                '"description": "',
                                _description,
                                description2,
                                '"image": "data:image/svg+xml;base64,',
                                generateSVG(_topText, _bottomText),
                                '"}'
                            )
                        )
                    ),
                    "#"
                )
            );
    }
}
