pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./AnonymiceLibrary.sol";
import "./OriginalAnonymiceInterface.sol";


//
//  THIS CONTRACT IS THE REVEAL CONTRACT FOR anonymiceburned.com !!
//  To own a burned mice, make sure to first mint it from contract 0x86B130EBb01A1c22f0bE5215dA29daBbEBC43eA8
//  then come here and claim it using the reveal() function. You can easily do that from our dApp on anonymiceburned.com
//
//  This was necessary due to a small bug on mint contract that prevents OpenSea from seeing the minted mice.
//  This contract will be also the core and sole cave of the burned mice!
//

//        d8888                                                   d8b                       888888b.                                           888
//       d88888                                                   Y8P                       888  "88b                                          888
//      d88P888                                                                             888  .88P                                          888
//     d88P 888 88888b.   .d88b.  88888b.  888  888 88888b.d88b.  888  .d8888b .d88b.       8888888K.  888  888 888d888 88888b.   .d88b.   .d88888
//    d88P  888 888 "88b d88""88b 888 "88b 888  888 888 "888 "88b 888 d88P"   d8P  Y8b      888  "Y88b 888  888 888P"   888 "88b d8P  Y8b d88" 888
//   d88P   888 888  888 888  888 888  888 888  888 888  888  888 888 888     88888888      888    888 888  888 888     888  888 88888888 888  888
//  d8888888888 888  888 Y88..88P 888  888 Y88b 888 888  888  888 888 Y88b.   Y8b.          888   d88P Y88b 888 888     888  888 Y8b.     Y88b 888
// d88P     888 888  888  "Y88P"  888  888  "Y88888 888  888  888 888  "Y8888P "Y8888       8888888P"   "Y88888 888     888  888  "Y8888   "Y88888
//                                              888
//                                         Y8b d88P
//                                          "Y88P"

contract AnonymiceBurnedReveal is ERC721Enumerable, Ownable {

    using AnonymiceLibrary for uint8;

    //Mappings
    mapping(uint256 => bool) private _tokenAlreadyRevealed;
    uint16[6450] internal tokenToOriginalMiceId;
    OriginalAnonymiceInterface.Trait[] internal burnedTraitType;

    //uint256s
    uint256 MAX_SUPPLY = 6450;

    //addresses
    address anonymiceContract = 0xbad6186E92002E312078b5a1dAfd5ddf63d3f731;
    address anonymiceResurrectionContract = 0x86B130EBb01A1c22f0bE5215dA29daBbEBC43eA8;

    //string arrays
    string[] LETTERS = [ "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
        "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"
    ];

    //events
    event TokenMinted(uint256 supply);

    constructor() ERC721("Anonymice Burned", "bMICE") {
    }

    //  ███╗   ███╗██╗███╗   ██╗████████╗██╗███╗   ██╗ ██████╗     ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
    //  ████╗ ████║██║████╗  ██║╚══██╔══╝██║████╗  ██║██╔════╝     ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
    //  ██╔████╔██║██║██╔██╗ ██║   ██║   ██║██╔██╗ ██║██║  ███╗    █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
    //  ██║╚██╔╝██║██║██║╚██╗██║   ██║   ██║██║╚██╗██║██║   ██║    ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
    //  ██║ ╚═╝ ██║██║██║ ╚████║   ██║   ██║██║ ╚████║╚██████╔╝    ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
    //  ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝     ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝


    /**
     * @dev Mint internal, this is to avoid code duplication.
     */
    function mintInternal(uint256 tokenId, uint256 originalTokenId, address to) internal {
        tokenToOriginalMiceId[tokenId] = uint16(originalTokenId);
        _safeMint(to, tokenId);
        emit TokenMinted(tokenId);
    }

    /**
     * @dev Kills the mice again, this time forever.
     * @param _tokenId The token to burn.
     */
    function killForever(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender);
        //Burn token
        _transfer(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            _tokenId
        );
    }

    //  ██████╗ ███████╗ █████╗ ██████╗     ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
    //  ██╔══██╗██╔════╝██╔══██╗██╔══██╗    ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
    //  ██████╔╝█████╗  ███████║██║  ██║    █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
    //  ██╔══██╗██╔══╝  ██╔══██║██║  ██║    ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
    //  ██║  ██║███████╗██║  ██║██████╔╝    ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
    //  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝     ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝


    /**
     * @dev Helper function to reduce pixel size within contract
     */
    function letterToNumber(string memory _inputLetter)
    internal
    view
    returns (uint8)
    {
        for (uint8 i = 0; i < LETTERS.length; i++) {
            if (
                keccak256(abi.encodePacked((LETTERS[i]))) ==
                keccak256(abi.encodePacked((_inputLetter)))
            ) return (i + 1);
        }
        revert();
    }

    /**
     * @dev Hash to SVG function
     */
    function hashToSVG(string memory _hash)
    public
    view
    returns (string memory)
    {
        string memory svgString;
        bool[24][24] memory placedPixels;
        OriginalAnonymiceInterface originalMiceCollection = OriginalAnonymiceInterface(anonymiceContract);

        for (uint8 i = 0; i < 9; i++) {
            uint8 thisTraitIndex = AnonymiceLibrary.parseInt(
                AnonymiceLibrary.substring(_hash, i, i + 1)
            );
            OriginalAnonymiceInterface.Trait memory trait;
            if (i == 0) {
                trait = OriginalAnonymiceInterface.Trait(
                    burnedTraitType[thisTraitIndex].traitName,
                    burnedTraitType[thisTraitIndex].traitType,
                    burnedTraitType[thisTraitIndex].pixels,
                    burnedTraitType[thisTraitIndex].pixelCount
                );
            } else {
                (string memory traitName, string memory traitType, string memory pixels, uint pixelCount) =
                    originalMiceCollection.traitTypes(i, thisTraitIndex);
                trait = OriginalAnonymiceInterface.Trait(
                    traitName,
                        traitType,
                        pixels,
                        pixelCount
                );
            }

            for (
                uint16 j = 0;
                j < trait.pixelCount;
                j++
            ) {
                string memory thisPixel = AnonymiceLibrary.substring(
                    trait.pixels,
                    j * 4,
                    j * 4 + 4
                );

                uint8 x = letterToNumber(
                    AnonymiceLibrary.substring(thisPixel, 0, 1)
                );
                uint8 y = letterToNumber(
                    AnonymiceLibrary.substring(thisPixel, 1, 2)
                );

                if (placedPixels[x][y]) continue;

                svgString = string(
                    abi.encodePacked(
                        svgString,
                        "<rect class='c",
                        AnonymiceLibrary.substring(thisPixel, 2, 4),
                        "' x='",
                        x.toString(),
                        "' y='",
                        y.toString(),
                        "'/>"
                    )
                );

                placedPixels[x][y] = true;
            }
        }

        svgString = string(
            abi.encodePacked(
                '<svg id="mouse-svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 24 24"> ',
                svgString,
                "<style>rect{width:1px;height:1px;} #mouse-svg{shape-rendering: crispedges;} .c00{fill:#000000}.c01{fill:#B1ADAC}.c02{fill:#D7D7D7}.c03{fill:#FFA6A6}.c04{fill:#FFD4D5}.c05{fill:#B9AD95}.c06{fill:#E2D6BE}.c07{fill:#7F625A}.c08{fill:#A58F82}.c09{fill:#4B1E0B}.c10{fill:#6D2C10}.c11{fill:#D8D8D8}.c12{fill:#F5F5F5}.c13{fill:#433D4B}.c14{fill:#8D949C}.c15{fill:#05FF00}.c16{fill:#01C700}.c17{fill:#0B8F08}.c18{fill:#421C13}.c19{fill:#6B392A}.c20{fill:#A35E40}.c21{fill:#DCBD91}.c22{fill:#777777}.c23{fill:#848484}.c24{fill:#ABABAB}.c25{fill:#BABABA}.c26{fill:#C7C7C7}.c27{fill:#EAEAEA}.c28{fill:#0C76AA}.c29{fill:#0E97DB}.c30{fill:#10A4EC}.c31{fill:#13B0FF}.c32{fill:#2EB9FE}.c33{fill:#54CCFF}.c34{fill:#50C0F2}.c35{fill:#54CCFF}.c36{fill:#72DAFF}.c37{fill:#B6EAFF}.c38{fill:#FFFFFF}.c39{fill:#954546}.c40{fill:#0B87F7}.c41{fill:#FF2626}.c42{fill:#180F02}.c43{fill:#2B2319}.c44{fill:#FBDD4B}.c45{fill:#F5B923}.c46{fill:#CC8A18}.c47{fill:#3C2203}.c48{fill:#53320B}.c49{fill:#7B501D}.c50{fill:#FFE646}.c51{fill:#FFD627}.c52{fill:#F5B700}.c53{fill:#242424}.c54{fill:#4A4A4A}.c55{fill:#676767}.c56{fill:#F08306}.c57{fill:#FCA30E}.c58{fill:#FEBC0E}.c59{fill:#FBEC1C}.c60{fill:#14242F}.c61{fill:#B06837}.c62{fill:#8F4B0E}.c63{fill:#D88227}.c64{fill:#B06837}.c65{fill:#4F10FF}.c66{fill:#3D9EFD}.c67{fill:#98FFE0}.c68{fill:#45C4F8}</style></svg>"
            )
        );

        return svgString;
    }

    /**
     * @dev Hash to metadata function
     */
    function hashToMetadata(string memory _hash, uint _tokenId)
    public
    view
    returns (string memory)
    {
        string memory metadataString;
        OriginalAnonymiceInterface originalMiceCollection = OriginalAnonymiceInterface(anonymiceContract);

        for (uint8 i = 0; i < 9; i++) {
            uint8 thisTraitIndex = AnonymiceLibrary.parseInt(
                AnonymiceLibrary.substring(_hash, i, i + 1)
            );

            OriginalAnonymiceInterface.Trait memory trait;
            if (i == 0) {
                trait = OriginalAnonymiceInterface.Trait(
                    burnedTraitType[thisTraitIndex].traitName,
                    burnedTraitType[thisTraitIndex].traitType,
                    burnedTraitType[thisTraitIndex].pixels,
                    burnedTraitType[thisTraitIndex].pixelCount
                );
            } else {
                (string memory traitName, string memory traitType, string memory pixels, uint pixelCount) =
                originalMiceCollection.traitTypes(i, thisTraitIndex);
                trait = OriginalAnonymiceInterface.Trait(
                    traitName,
                    traitType,
                    pixels,
                    pixelCount
                );
            }

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                        trait.traitType,
                    '","value":"',
                        trait.traitName,
                    '"}'
                )
            );

            if (i != 8)
                metadataString = string(abi.encodePacked(metadataString, ","));
        }

        // add the property of original token id number
        metadataString = string(
            abi.encodePacked(
                metadataString,
                ',{"trait_type":"',
                'original_mice',
                '","value":"',
                AnonymiceLibrary.toString(tokenToOriginalMiceId[_tokenId]),
                '"}'
            )
        );

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     * @dev Returns the SVG and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */
    function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
    {
        require(_exists(_tokenId));

        string memory tokenHash = _tokenIdToHash(_tokenId);

        return
        string(
            abi.encodePacked(
                "data:application/json;base64,",
                AnonymiceLibrary.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Anonymice #',
                                AnonymiceLibrary.toString(_tokenId),
                                '", "description": "Anonymice Burned is a collection of 6,450 burned mices from the Anonymice collection, with the same traits as the burned ones. Like the original collection, metadata and images are generated and stored 100% on-chain. No IPFS, no API. Just the Ethereum blockchain. And a group of resurrected mices", "image": "data:image/svg+xml;base64,',
                                AnonymiceLibrary.encode(
                                    bytes(hashToSVG(tokenHash))
                                ),
                                '","attributes":',
                                hashToMetadata(tokenHash, _tokenId),
                                "}"
                            )
                        )
                    )
                )
            )
        );
    }

    /**
     * @dev Returns a hash for a given tokenId
     * @param _tokenId The tokenId to return the hash for.
     */
    function _tokenIdToHash(uint256 _tokenId)
    public
    view
    returns (string memory)
    {
        OriginalAnonymiceInterface originalMiceCollection = OriginalAnonymiceInterface(anonymiceContract);
        string memory tokenHash = originalMiceCollection._tokenIdToHash(uint256(tokenToOriginalMiceId[_tokenId]));
        //If this is a burned token, override the previous hash
        if (ownerOf(_tokenId) == 0x000000000000000000000000000000000000dEaD) {
            tokenHash = string(
                abi.encodePacked(
                    "1",
                    AnonymiceLibrary.substring(tokenHash, 1, 9)
                )
            );
        } else {
            tokenHash = string(
                abi.encodePacked(
                    "0",
                    AnonymiceLibrary.substring(tokenHash, 1, 9)
                )
            );
        }

        return tokenHash;
    }

    function reveal() public {
        // get tokens of the owner
        ERC721Enumerable resurrectionContract = ERC721Enumerable(anonymiceResurrectionContract);
        ERC721Enumerable originalContract = ERC721Enumerable(anonymiceContract);
        uint numOfTokens = resurrectionContract.balanceOf(msg.sender);
        for (uint i=0; i<numOfTokens; i++) {
            uint tokenId = resurrectionContract.tokenOfOwnerByIndex(msg.sender, i);
            if (_tokenAlreadyRevealed[tokenId]) {
                continue;
            }
            uint originalTokenId = originalContract.tokenOfOwnerByIndex(0x000000000000000000000000000000000000dEaD, tokenId);
            mintInternal(tokenId, originalTokenId, msg.sender);
            _tokenAlreadyRevealed[tokenId] = true;
        }
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
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }


//   ██████╗ ██╗    ██╗███╗   ██╗███████╗██████╗     ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
//  ██╔═══██╗██║    ██║████╗  ██║██╔════╝██╔══██╗    ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
//  ██║   ██║██║ █╗ ██║██╔██╗ ██║█████╗  ██████╔╝    █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
//  ██║   ██║██║███╗██║██║╚██╗██║██╔══╝  ██╔══██╗    ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
//  ╚██████╔╝╚███╔███╔╝██║ ╚████║███████╗██║  ██║    ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
//   ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝    ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝


    /**
     * @dev Clears the traits.
     */
    function clearBurnedTraits() public onlyOwner {
        for (uint256 i = 0; i < burnedTraitType.length; i++) {
            delete burnedTraitType[i];
        }
    }

    /**
     * @dev Add trait types of burned
     * @param traits Array of traits to add
     */

    function addBurnedTraitType(OriginalAnonymiceInterface.Trait[] memory traits)
    public
    onlyOwner
    {
        for (uint256 i = 0; i < traits.length; i++) {
            burnedTraitType.push(
                OriginalAnonymiceInterface.Trait(
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
     * @dev Collects the total amount in the contract
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev Collects the total amount in the contract
     * @param newAddress The new address of the anonymice contract
     */
    function setAnonymiceOriginalContractAddress(address newAddress) public onlyOwner {
        anonymiceContract = newAddress;
    }
    /**
     * @dev Collects the total amount in the contract
     * @param newAddress The new address of the anonymice contract
     */
    function setAnonymiceResurrectionContractAddress(address newAddress) public onlyOwner {
        anonymiceResurrectionContract = newAddress;
    }

}