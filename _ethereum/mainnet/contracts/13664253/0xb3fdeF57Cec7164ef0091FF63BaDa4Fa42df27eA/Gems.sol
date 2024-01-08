// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./IBallerBars.sol";

// FIXME: link to ChainsLibrary.sol since functions are the same
import "./GemsLibrary.sol";

contract Gems is ERC721Enumerable, Ownable {

    using GemsLibrary for uint8;
    using ECDSA for bytes32;

    struct Trait {
        string traitName;
        string traitType;
        string pixels;
        uint256 pixelCount;
    }
    
    bool public saleLive;

    //Mappings
    mapping(uint256 => Trait[]) public traitTypes;
    mapping(string => bool) hashToMinted;
    mapping(uint256 => string) internal tokenIdToHash;

    //uint256s
    uint256 MAX_SUPPLY = 5000; 
    uint256 SEED_NONCE = 0;

    //string arrays
    string[] LETTERS = [
        "a",
        "b",
        "c",
        "d",
        "e",
        "f",
        "g",
        "h",
        "i",
        "j",
        "k",
        "l",
        "m",
        "n",
        "o",
        "p",
        "q",
        "r",
        "s",
        "t",
        "u",
        "v",
        "w",
        "x",
        "y",
        "z"
    ];

    //uint arrays
    uint16[][8] TIERS;

    //address
    address ballerbarsAddress;
    address _owner;
    
    constructor() ERC721("Gems", "GEMS") {
        _owner = msg.sender;
        
        TIERS[0] = [50, 100, 400, 750, 1100, 1250, 1350, 1500, 1700, 1800];  // Gem Holder
        TIERS[1] = [50, 100, 200, 800, 1100, 1200, 1300, 1450, 1650, 2150];  // Gem
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
        for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
            uint16 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i.toString();
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
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
        require(_c < 10);

        // This will generate a 7 character string.
        // The last 6 digits are random, the first is 0, due to the chain is not being burned.

        string memory currentHash = "";

        for (uint8 i = 0; i < 2; i++) {
            SEED_NONCE++;
            uint16 _randinput = uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            _t,
                            _a,
                            _c,
                            SEED_NONCE
                        )
                    )
                ) % 10000
            );

            currentHash = string(
                abi.encodePacked(currentHash, rarityGen(_randinput, i))
            );
        }
    
        return currentHash;
    }

    /**
     * @dev Returns the current ballerbars cost of mint.
     */
    function currentBallerBarsCost() public pure returns (uint256) {
        return 10 ether;
    }
 
    function mintGem(uint256 tokenQuantity) external {
        require(saleLive, "SALE_NOT_LIVE");
               
        for (uint256 i = 0; i < tokenQuantity; i++) {
            require(totalSupply() < MAX_SUPPLY, "OUT_OF_STOCK");

            IBallerBars(ballerbarsAddress).burnFrom(msg.sender, currentBallerBarsCost());

            mintInternal();
        }
    }


    /**
     * @dev Mint internal, this is to avoid code duplication.
     */
    function mintInternal() internal {
        uint256 _totalSupply = totalSupply();
        require(_totalSupply < MAX_SUPPLY);
        require(!GemsLibrary.isContract(msg.sender));

        uint256 thisTokenId = _totalSupply;

        tokenIdToHash[thisTokenId] = hash(thisTokenId, msg.sender, 0);

        hashToMinted[tokenIdToHash[thisTokenId]] = true;

        _mint(msg.sender, thisTokenId);
    }
    
    
    function mintReserve() onlyOwner external  {
        require(totalSupply() < 5); 

        return mintInternal();
    }

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
 

        for (uint8 i = 0; i < 2; i++) {  
            uint8 thisTraitIndex = GemsLibrary.parseInt(
                GemsLibrary.substring(_hash, i, i + 1)
            );

            for (
                uint16 j = 0;
                j < traitTypes[i][thisTraitIndex].pixelCount; // <
                j++
            ) {
                string memory thisPixel = GemsLibrary.substring(
                    traitTypes[i][thisTraitIndex].pixels,
                    j * 4,
                    j * 4 + 4
                );

                uint8 x = letterToNumber(
                    GemsLibrary.substring(thisPixel, 0, 1)
                );
                uint8 y = letterToNumber(
                    GemsLibrary.substring(thisPixel, 1, 2)
                );

                if (placedPixels[x][y]) continue;

                svgString = string(
                    abi.encodePacked(
                        svgString,
                        "<rect class='c",
                        GemsLibrary.substring(thisPixel, 2, 4),
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
                '<svg id="c" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 26 26" > ',
                svgString,
                "<style>rect{width:1px;height:1px;}#c{shape-rendering: crispedges;}.rect{width:1px;height:1px;}.c00{fill:#222bff}.c01{fill:#8c9dff}.c02{fill:#585eff}.c03{fill:#8293ff}.c04{fill:#5157ff}.c05{fill:#4249ff}.c06{fill:#333aff}.c07{fill:#ff9f34}.c08{fill:#f78e0a}.c09{fill:#ef8500}.c10{fill:#e57f00}.c11{fill:#ff8800}.c12{fill:#ffd051}.c13{fill:#ffc606}.c14{fill:#ffe445}.c15{fill:#ffb100}.c16{fill:#ffa000}.c17{fill:#e3d9e1}.c18{fill:#ddd3db}.c19{fill:#dad0d8}.c20{fill:#d8ced6}.c21{fill:#dcc000}.c22{fill:#fade11}.c23{fill:#f6d900}.c24{fill:#fde766}.c25{fill:#e6c900}.c26{fill:#e1c500}.c27{fill:#5f73df}.c28{fill:#4b5fd2}.c29{fill:#4055ca}.c30{fill:#3c51c1}.c31{fill:#b525fc}.c32{fill:#bf49fa}.c33{fill:#c159f6}.c34{fill:#bb3afc}.c35{fill:#bf4ef7}.c36{fill:#ffba2a}.c37{fill:#f4ab00}.c38{fill:#eca200}.c39{fill:#e19b00}.c40{fill:#eed100}.c41{fill:#ff132f}.c42{fill:#ff4b54}.c43{fill:#ff5d64}.c44{fill:#ff3644}.c45{fill:#ff5059}.c46{fill:#b0d2f5}.c47{fill:#bdddff}.c48{fill:#b9d9fd}.c49{fill:#eaf4ff}.c50{fill:#b0d2f9}.c51{fill:#b3d2f6}.c52{fill:#f7d0c3}.c53{fill:#f0c1b1}.c54{fill:#e3aa96}.c55{fill:#ebb7a5}.c56{fill:#d79881}.c57{fill:#cacaca}.c58{fill:#aaaaaa}.c59{fill:#969696}.c60{fill:#808080}.c61{fill:#b8bfc1}.c62{fill:#d2d2d2}.c63{fill:#cfcfcf}.c64{fill:#d8e9e9}.c65{fill:#e0eff0}.c66{fill:#c0dadc}.c67{fill:#c6c6c6}.c68{fill:#cbcbcb}.c69{fill:#9a9fbf}.c70{fill:#8b91b2}.c71{fill:#8187a9}.c72{fill:#7d82a3}.c73{fill:#1e1e1e}.c74{fill:#434343}.c75{fill:#363636}.c76{fill:#606060}.c77{fill:#242424}.c78{fill:#acacac}.c79{fill:#9d9d9d}.c80{fill:#949494}.c81{fill:#8f8f8f}.c82{fill:#d7d9e5}.c83{fill:#d0d2df}.c84{fill:#cdcfdc}.c85{fill:#cbcdda}.c86{fill:#00b349}.c87{fill:#2fd06d}.c88{fill:#09cc61}.c89{fill:#70da90}.c90{fill:#00bb4d}.c91{fill:#00b74f}.c92{fill:#00b4f5}.c93{fill:#78cdf7}.c94{fill:#ade4ff}.c95{fill:#89d4f9}.c96{fill:#c1e8fd}.c97{fill:#5dc3f5}.c98{fill:#48bdf3}</style></svg>"
            )
        );

        return svgString;
    }

    /**
     * @dev Hash to metadata function
     */
    function hashToMetadata(string memory _hash)
        public
        view
        returns (string memory)
    {
        string memory metadataString;

        for (uint8 i = 0; i < 2; i++) { 
            uint8 thisTraitIndex = GemsLibrary.parseInt(
                GemsLibrary.substring(_hash, i, i + 1)
            );

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    traitTypes[i][thisTraitIndex].traitType,
                    '","value":"',
                    traitTypes[i][thisTraitIndex].traitName,
                    '"}'
                )
            );

            if (i != 1)
                metadataString = string(abi.encodePacked(metadataString, ","));
        }

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
                    GemsLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Gem #',
                                    GemsLibrary.toString(_tokenId),
                                    '", "description": "The Gems collection serves as the second phase of Ben Baller Did The BlockChain.", "image": "data:image/svg+xml;base64,',
                                    GemsLibrary.encode(
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
     * @dev Returns a hash for a given tokenId
     * @param _tokenId The tokenId to return the hash for.
     */
    function _tokenIdToHash(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        string memory tokenHash = tokenIdToHash[_tokenId];
        //If this is a burned token, override the previous hash
        if (ownerOf(_tokenId) == 0x000000000000000000000000000000000000dEaD) {
            tokenHash = string(
                abi.encodePacked(
                    "1",
                    GemsLibrary.substring(tokenHash, 1, 9)
                )
            );
        }

        return tokenHash;
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

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

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
            traitTypes[_traitTypeIndex].push(
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
     * @dev Sets the ballerbars ERC20 address
     * @param _ballerbarsAddress The ballerbars address
     */

    function setBallerBarsAddress(address _ballerbarsAddress) public onlyOwner {
        ballerbarsAddress = _ballerbarsAddress;
    }

}