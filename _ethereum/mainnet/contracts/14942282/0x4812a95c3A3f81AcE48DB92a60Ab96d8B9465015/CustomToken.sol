// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { LibDiamond } from  "../libraries/LibDiamond.sol";
import "./ERC721Enumerable.sol";
import "./MyNFTTokenLibrary.sol";
import "./LibAppStorage.sol";
import "./ERC721Base.sol";
import "./ERC721BaseStorage.sol";
import "./ERC165.sol";
import "./Strings.sol";

contract CustomToken is ERC721Enumerable, ERC721Base {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;
    using MyNFTTokenLibrary for uint8;

    AppStorage private s;

   // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external override pure returns (bool) {
        return true;
    }
     /**
     * @dev Converts a digit from 0 - 10000 into its corresponding rarity based on the given rarity tier.
     * @param _randinput The input from 0 - 10000 to use for rarity gen.
     * @param _rarityTier The tier to use.
     */
    function rarityGen(uint256 _randinput, uint8 _rarityTier)
        internal
        view
        returns (string memory)
    {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < s.TIERS[_rarityTier].length; i++) {
            uint16 thisPercentage = s.TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) {
                return s.LETTERS[i];
            }
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    /**
     * @dev Mint internal, this is to avoid code duplication.
     */
    function mintInternal() internal {
        uint256 _totalSupply = totalSupply();
        require(_totalSupply < s.MAX_SUPPLY);
        require(!MyNFTTokenLibrary.isContract(msg.sender));
        uint256 thisTokenId = _totalSupply;
        s.tokenIdToHash[thisTokenId] = hash(thisTokenId, msg.sender, 0);
        s.hashToMinted[s.tokenIdToHash[thisTokenId]] = true;
        _mint(msg.sender, thisTokenId);
    }

    /**
     * @dev Mints new tokens.
     */
    function mint() public {
        return mintInternal();
    }

    /**
     * @dev Generates a 7 digit hash from a tokenId, address, and random number.
     * @param _t The token id to be used within the hash.
     * @param _a The address to be used within the hash.
     * @param _c The custom nonce to be used within the hash.
     */
    function hash(
        uint256 _t,
        address _a,
        uint256 _c
    ) internal returns (string memory) {
        require(_c < 80);

        // This will generate a 7 character string.
        //The last 6 digits are random, the first is a, due to the nft not being burned.
        string memory currentHash = "";

        for (uint8 i = 0; i < 6; i++) {
            s.SEED_NONCE++;
            uint16 _randinput = uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.coinbase,
                            block.difficulty,
                            _t,
                            _a,
                            _c,
                            s.SEED_NONCE
                        )
                    )
                ) % 10000
            );

            currentHash = string(
                abi.encodePacked(currentHash, rarityGen(_randinput, i))
            );
        }

        if (s.hashToMinted[currentHash]) return hash(_t, _a, _c + 1);

        return currentHash;
    }
  // custom code...
   /**
     * @dev Returns the SVG and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        require(ERC721BaseStorage.layout().exists(_tokenId));

        string memory thisName = s.name;

        string memory tokenHash = s.tokenIdToHash[_tokenId];
        string memory name = string(abi.encodePacked("", thisName, " #", MyNFTTokenLibrary.toString(_tokenId)));
        string memory bio = string(abi.encodePacked("Stored 100% on-chain. ", s.name, " #", MyNFTTokenLibrary.toString(_tokenId)));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    MyNFTTokenLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "',
                                    name,
                                    '", "description": "',
                                    bio,
                                    '","image": "data:image/svg+xml;base64,',
                                    MyNFTTokenLibrary.encode(
                                        bytes(hashToSVG(tokenHash))
                                    ),
                                    '","attributes":',
                                    hashToMetadata(tokenHash),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Hash to metadata function
     */
    function hashToMetadata(string memory _hash)
        internal
        view
        returns (string memory)
    {
        string memory metadataString = '';

        for (uint8 i = 0; i < 6;) {
            uint256 thisTraitIndex = letterToNumber(
                MyNFTTokenLibrary.substring(_hash, i, i + 1)
            );

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    s.traitTypes[i][thisTraitIndex].traitType,
                    '","value":"',
                    s.traitTypes[i][thisTraitIndex].traitName,
                    '"}'
                )
            );

            if (i != 5)
                metadataString = string(abi.encodePacked(metadataString, ","));
            unchecked {
              ++i;
            }
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }

     /**
     * @dev Hash to SVG function
     */
    function hashToSVG(string memory _hash)
        public
        view
        returns (string memory)
    {

        string memory svgString = "";
        bool[24][24][24] memory placedPixels;

        for (uint8 i = 0; i < 6; i++) {
            uint8 thisTraitIndex = letterToNumber(MyNFTTokenLibrary.substring(_hash, i, i + 1));

            for (
                uint8 k = 0;
                k < s.traitTypes[i][thisTraitIndex].pixelCount.length;
                k++
            ) {
                string memory da = "";
                for (
                    uint8 p = 0;
                    p < s.traitTypes[i][thisTraitIndex].pixelCount.length;
                    p++
                )  {
                    if (p == k) {
                        da = string(abi.encodePacked(da, "inline;"));
                    } else {
                        da = string(abi.encodePacked(da, "none;"));
                    }
                }
                if (s.traitTypes[i][thisTraitIndex].pixelCount[k] > 0)  {
                    svgString = string(
                            abi.encodePacked(
                                svgString,
                                "<g>",
                                "<animate id='", s.LETTERS[k], "' attributeName='display' values='", da, "' repeatCount='indefinite' dur='0.45s' begin='0s'/>"
                        )
                    );
                }
                for (
                    uint256 j = 0;
                    j < s.traitTypes[i][thisTraitIndex].pixelCount[k];
                    j++
                ) {
                    string memory thisPixel = MyNFTTokenLibrary.substring(
                        s.traitTypes[i][thisTraitIndex].pixels[k],
                        j * 4,
                        j * 4 + 4
                    );

                    uint8 x = letterToNumber(
                        MyNFTTokenLibrary.substring(thisPixel, 0, 1)
                    );
                    uint8 y = letterToNumber(
                        MyNFTTokenLibrary.substring(thisPixel, 1, 2)
                    );

                    if (placedPixels[k][x][y]) continue;

                    string memory color = MyNFTTokenLibrary.substring(thisPixel, 2, 4);

                    svgString = string(
                        abi.encodePacked(
                            svgString,
                            "<rect class='c",
                            color,
                            "' x='",
                            x.toString(),
                            "' y='",
                            y.toString(),
                            "'></rect>"
                        )
                    );

                    placedPixels[k][x][y] = true;
                }

                if (s.traitTypes[i][thisTraitIndex].pixelCount[k] > 0)  {
                    svgString = string(
                            abi.encodePacked(
                                svgString,
                                "</g>"
                        )
                    );
                }
            }
        }

        svgString = string(
            abi.encodePacked(
                '<svg id="svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 24 24"> ',
                svgString,
                "<style>rect{width:1px;height:1px;}#svg{shape-rendering: crispedges;}.c00{fill:#000000}.c01{fill:#222034}.c02{fill:#45283c}.c03{fill:#663931}.c04{fill:#8f563b}.c05{fill:#df7126}.c06{fill:#d9a066}.c07{fill:#eec39a}.c08{fill:#fbf236}.c09{fill:#99e550}.c10{fill:#6abe30}.c11{fill:#37946e}.c12{fill:#4b692f}.c13{fill:#524b24}.c14{fill:#323c39}.c15{fill:#3f3f74}.c16{fill:#306082}.c17{fill:#5b6ee1}.c18{fill:#639bff}.c19{fill:#5fcde4}.c20{fill:#cbdbfc}.c21{fill:#ffffff}.c22{fill:#9badb7}.c23{fill:#847e87}.c24{fill:#696a6a}.c25{fill:#595652}.c26{fill:#76428a}.c27{fill:#ac3232}.c28{fill:#d95763}.c29{fill:#d77bba}.c30{fill:#8f974a}.c31{fill:#8a6f30}.c32{fill:#814848}.c33{fill:#9d4a4a}.c34{fill:#403640}.c35{fill:#868282}.c36{fill:#424058}.c37{fill:#2f315a}.c38{fill:#34378b}.c39{fill:#dcd530}.c40{fill:#fefff4}.c41{fill:#e3e1e1}.c42{fill:#634464}.c43{fill:#7d4881}.c44{fill:#b549bc}.c45{fill:#343cff}.c46{fill:#f6d953}.c47{fill:#bd8228}.c48{fill:#ebb337}</style>",
                "</svg>"
            )
        );

        return svgString;
    }


    /**
     * @dev Helper function to reduce pixel size within contract
     */
    function letterToNumber(string memory _inputLetter)
        internal
        view
        returns (uint8)
    {
        for (uint8 i = 0; i < s.LETTERS.length;) {
            if (
                keccak256(abi.encodePacked((s.LETTERS[i]))) ==
                keccak256(abi.encodePacked((_inputLetter)))
            ) return i;
            unchecked { ++i; }
        }
        revert();
    }

   modifier onlyOwner() {
        require(s._owner == msg.sender, "only owner");
        _;
    }


        /**
     * @dev Clears the traits.
    //  */
    // function clearTraits() public onlyOwner {
    //     for (uint256 i = 0; i < 6; i++) {
    //         delete s.traitTypes[i];
    //     }
    // }

    /**
     * @dev Add a trait type
     * @param _traitTypeIndex The trait type index
     * @param traits Array of traits to add
     */

    function addTraitType(uint256 _traitTypeIndex, Trait[] memory traits)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < traits.length; i++) {
            s.traitTypes[_traitTypeIndex].push(
                Trait(
                    traits[i].traitName,
                    traits[i].traitType,
                    traits[i].pixels,
                    traits[i].pixelCount
                )
            );
        }

        return;
    }

    /**
     * @dev Returns the wallet of a given wallet. Mainly for ease for frontend devs.
     * @param _wallet The wallet to get the tokens of.
     */
    function walletOfOwner(address _wallet)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = _balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

}
