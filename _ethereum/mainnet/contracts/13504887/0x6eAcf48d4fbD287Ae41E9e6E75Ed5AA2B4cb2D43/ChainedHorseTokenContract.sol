pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./HorseUtilityContract.sol";
import "./base64.sol";

//
//   ____ _           _                _   _   _                       _   _ _____ _____
//  / ___| |__   __ _(_)_ __   ___  __| | | | | | ___  _ __ ___  ___  | \ | |  ___|_   _|
// | |   | '_ \ / _` | | '_ \ / _ \/ _` | | |_| |/ _ \| '__/ __|/ _ \ |  \| | |_    | |
// | |___| | | | (_| | | | | |  __/ (_| | |  _  | (_) | |  \__ \  __/ | |\  |  _|   | |
//  \____|_| |_|\__,_|_|_| |_|\___|\__,_| |_| |_|\___/|_|  |___/\___| |_| \_|_|     |_|
//
//
//
//                                                 ,,  //
//                                              .//,,,,,,,,,
//                                              .//,,,,@@,,,,,,,
//                                            /////,,,,,,,,,,,,,
//                                            /////,,,,,,
//                                            /////,,,,,,
//                                          ///////,,,,,,
//                                      ///////////,,,,,,
//                        /////,,,,,,,,,,,,,,,,,,,,,,,,,,
//                      /////,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                      /////,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                      /////,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                    ////   ,,  //                ,,  //
//                    ////   ,,  //                ,,  //
//                    ////   ,,  //                ,,  //
//                    //     ,,  //                ,,  //
//                           @@  @@                @@  @@
//
// ** ChainedHorseNFT: ChainedHorseTokenContract.sol **
// Written and developed by: Moonfarm
// Twitter: @spacesh1pdev
// Discord: Moonfarm#1138
//

contract ChainedHorseTokenContract is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    /**
     * Structure of tokens traits
     */
    struct TokenTraits {
        uint8 maneColor;
        uint8 patternColor;
        uint8 hoofColor;
        uint8 bodyColor;
        uint8 background;
        uint8 tail;
        uint8 mane;
        uint8 pattern;
        uint8 headAccessory;
        uint8 bodyAccessory;
        uint8 utility;
        bool burned;
    }

    /**
     * Define the utility contract address so we know where to fetch svgs from
     */
    address public utilityContract = 0x0000000000000000000000000000000000000001;

    /**
     * Pretty standard NFT contract variables
     */
    uint256 public maxTokens = 10000;
    uint256 public mintedTokens = 0;
    uint256 public burnedTokens = 0;
    uint256 public rebirthedTokens = 0;
    uint256 public mintPrice = 0.02 ether;
    uint256 public rebirthPrice = 0.01 ether;
    uint8 public claimableTokensPerAddress = 20;
    uint8 public maxTokensPerTxn = 5;
    bool public saleActive = false;

    /**
     * Whitelist info
     */
    uint256 public whitelistTokensUnlocksAtBlockNumber = 0;
    uint256 public whitelistAddressCount = 0;

    /**
     * Burned horse base64-image
     */
    string ashes =
        "data:image/svg+xml;base64,PHN2ZyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHZpZXdCb3g9JzAgMCAzMiAzMic+PHBhdGggZmlsbD0nI2QxZDNkNCcgZD0nTTAgMGgzMnYzMkgweicvPjxwYXRoIGZpbGw9JyM1ODU5NWInIGQ9J00xMCAyN0g5di0xaDF6bTEwIDBoLTF2LTFoMXptMiAwaC0xdi0xaDF6Jy8+PHBhdGggZmlsbD0nIzIzMWYyMCcgZD0nTTIzIDI3aC0xdi0xaDF6Jy8+PHBhdGggZmlsbD0nIzU4NTk1YicgZD0nTTI0IDI3aC0xdi0xaDF6bTEgMGgtMXYtMWgxem0tMTQgMGgtMXYtMWgxem0xIDBoLTF2LTFoMXptMSAwaC0xdi0xaDF6bTEgMGgtMXYtMWgxem0xIDBoLTF2LTFoMXptMSAwaC0xdi0xaDF6bTEgMGgtMXYtMWgxeicvPjxwYXRoIGZpbGw9JyM4MDgyODUnIGQ9J00xOCAyN2gtMXYtMWgxeicvPjxwYXRoIGZpbGw9JyM1ODU5NWInIGQ9J00xOSAyN2gtMXYtMWgxem0yIDBoLTF2LTFoMXptMC0xaC0xdi0xaDF6bS0xIDBoLTF2LTFoMXptLTEgMGgtMXYtMWgxem0tMSAwaC0xdi0xaDF6bS0xIDBoLTF2LTFoMXonLz48cGF0aCBmaWxsPScjMjMxZjIwJyBkPSdNMTYgMjZoLTF2LTFoMXonLz48cGF0aCBmaWxsPScjNTg1OTViJyBkPSdNMTUgMjZoLTF2LTFoMXptMS0xaC0xdi0xaDF6bTEgMGgtMXYtMWgxeicvPjxwYXRoIGZpbGw9JyMyMzFmMjAnIGQ9J00xOCAyNWgtMXYtMWgxeicvPjxwYXRoIGZpbGw9JyM1ODU5NWInIGQ9J00xOSAyNWgtMXYtMWgxem0xIDBoLTF2LTFoMXptLTEtMWgtMXYtMWgxeicvPjxwYXRoIGZpbGw9JyM4MDgyODUnIGQ9J00xNyAyNGgtMXYtMWgxeicvPjxwYXRoIGZpbGw9JyM1ODU5NWInIGQ9J00xOCAyNGgtMXYtMWgxem0tNCAyaC0xdi0xaDF6Jy8+PHBhdGggZmlsbD0nIzgwODI4NScgZD0nTTEzIDI2aC0xdi0xaDF6Jy8+PHBhdGggZmlsbD0nIzU4NTk1YicgZD0nTTEyIDI2aC0xdi0xaDF6Jy8+PC9zdmc+";

    /**
     * Amount of tokens a specific whitelist address has left to mint
     *
     * Always starts at 20 for each address added
     */
    mapping(address => uint256) public whitelistedAddressMintsLeft;

    /**
     * Save traits for each token
     */
    mapping(uint256 => TokenTraits) public traits;

    /**
     * Pretty standard constructor variables, nothing wierd here
     *
     * Mints #0 to the creator
     */
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 _maxTokens,
        address _utilityContract
    ) ERC721(tokenName, tokenSymbol) {
        maxTokens = _maxTokens;
        utilityContract = _utilityContract;
        mint(1);
    }

    /**
     * 1) Sets whitelisted tokens to be available for public mint in
     *    40320 blocks from the block this function was called (approximately a week)
     * 2) Starts the sale
     */
    function startSale() public onlyOwner {
        whitelistTokensUnlocksAtBlockNumber = block.number + 40320; // approximately a week
        saleActive = true;
    }

    /**
     * Standard withdraw function
     */
    function withdraw() public onlyOwner {
        uint256 balance = payable(address(this)).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * Bundle metadata so it follows the standard
     */
    function packMetaData(
        string memory name,
        string memory svg,
        uint256 last
    ) private pure returns (bytes memory) {
        string memory comma = ",";
        if (last > 0) comma = "";
        return
            abi.encodePacked(
                '{"trait_type": "',
                name,
                '", "value": "',
                svg,
                '"}',
                comma
            );
    }

    /**
     * Private function so it can be called cheaper from tokenURI and tokenSVG
     */
    function _tokenSVG(uint256 tokenId) private view returns (string memory) {
        TokenTraits memory _traits = traits[tokenId];

        bytes memory _horseColors = HorseUtilityContract(utilityContract)
            .renderColors(
                _traits.maneColor,
                _traits.patternColor,
                _traits.hoofColor,
                _traits.bodyColor
            );

        return
            Base64.encode(
                HorseUtilityContract(utilityContract).renderHorse(
                    _horseColors,
                    _traits.background,
                    _traits.tail,
                    _traits.mane,
                    _traits.pattern,
                    _traits.headAccessory,
                    _traits.bodyAccessory,
                    _traits.utility
                )
            );
    }

    /**
     * Get the svg for a token in base64 format
     *
     * Comment:
     * Uses the UtilityContract to get svg-information for each attribute
     */
    function tokenSVG(uint256 tokenId) public view returns (string memory) {
        bool lessThanMinted = tokenId < mintedTokens;
        bool lessThanMintedRebirthOrMoreThanStartOfRebirth = tokenId <
            (maxTokens + burnedTokens) &&
            tokenId > maxTokens;
        if (
            !_exists(tokenId) &&
            (lessThanMinted || lessThanMintedRebirthOrMoreThanStartOfRebirth)
        ) {
            return ashes;
        }

        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    _tokenSVG(tokenId)
                )
            );
    }

    /**
     * Get the metadata for a token in base64 format
     *
     * Comment:
     * Uses the UtilityContract to get svg-information for each attribute
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        bool lessThanMinted = tokenId < mintedTokens;
        bool lessThanMintedRebirthOrMoreThanStartOfRebirth = tokenId <
            (maxTokens + burnedTokens) &&
            tokenId > maxTokens;
        if (
            !_exists(tokenId) &&
            (lessThanMinted || lessThanMintedRebirthOrMoreThanStartOfRebirth)
        ) {
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(
                            abi.encodePacked(
                                '{"name":"Burned Chained Horse #',
                                uint2str(tokenId),
                                '", "description": "A horse that lives on the ethereum blockchain.", "attributes": [',
                                packMetaData("status", "burned", 1),
                                '], "image":"',
                                ashes,
                                '"}'
                            )
                        )
                    )
                );
        }
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        TokenTraits memory _traits = traits[tokenId];

        bytes memory _properties = abi.encodePacked(
            packMetaData(
                "background",
                HorseUtilityContract(utilityContract).getBackground(
                    _traits.background
                ),
                0
            ),
            packMetaData(
                "tail",
                HorseUtilityContract(utilityContract).getTail(_traits.tail),
                0
            ),
            packMetaData(
                "mane",
                HorseUtilityContract(utilityContract).getMane(_traits.mane),
                0
            ),
            packMetaData(
                "pattern",
                HorseUtilityContract(utilityContract).getPattern(
                    _traits.pattern
                ),
                0
            ),
            packMetaData(
                "head accessory",
                HorseUtilityContract(utilityContract).getHeadAccessory(
                    _traits.headAccessory
                ),
                0
            ),
            packMetaData(
                "body accessory",
                HorseUtilityContract(utilityContract).getBodyAccessory(
                    _traits.bodyAccessory
                ),
                0
            ),
            packMetaData(
                "utility",
                HorseUtilityContract(utilityContract).getUtility(
                    _traits.utility
                ),
                0
            )
        );

        _properties = abi.encodePacked(
            _properties,
            packMetaData(
                "mane color",
                HorseUtilityContract(utilityContract).getManeColor(
                    traits[tokenId].maneColor
                ),
                0
            ),
            packMetaData(
                "pattern color",
                HorseUtilityContract(utilityContract).getPatternColor(
                    traits[tokenId].patternColor
                ),
                0
            ),
            packMetaData(
                "hoof color",
                HorseUtilityContract(utilityContract).getHoofColor(
                    traits[tokenId].hoofColor
                ),
                0
            ),
            packMetaData(
                "body color",
                HorseUtilityContract(utilityContract).getBodyColor(
                    traits[tokenId].bodyColor
                ),
                1
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"Chained Horse #',
                            uint2str(tokenId),
                            '", "description": "A horse that lives on the ethereum blockchain.", "attributes": [',
                            _properties,
                            '], "image":"data:image/svg+xml;base64,',
                            _tokenSVG(tokenId),
                            '"}'
                        )
                    )
                )
            );
    }

    /**
     * A claim function for whitelisted addresses until claim-period is over
     */
    function claim(uint256 amount) public {
        require(
            whitelistedAddressMintsLeft[msg.sender] >= amount,
            "Exceeded amount of claims left on address"
        );
        require(
            whitelistTokensUnlocksAtBlockNumber > block.number,
            "Claim period is over"
        );
        mint(amount);
        whitelistedAddressMintsLeft[msg.sender] -= amount;
    }

    /**
     * A mint function for anyone
     */
    function publicMint(uint256 amount) public payable {
        require(
            amount.add(mintedTokens) <=
                maxTokens -
                    (whitelistAddressCount * claimableTokensPerAddress) ||
                block.number > whitelistTokensUnlocksAtBlockNumber,
            "Tokens left are for whitelist"
        );
        require(mintPrice.mul(amount) <= msg.value, "Not enough ether to mint");
        require(saleActive, "Sale has not started");
        mint(amount);
    }

    /**
     * Mint with requirements that both claim and publicMint needs to follow
     */
    function mint(uint256 amount) private {
        require(
            amount <= maxTokensPerTxn,
            "Trying to mint more than allowed tokens"
        );
        require(
            amount.add(mintedTokens) <= maxTokens,
            "Amount exceeded max tokens"
        );
        for (uint256 i = 0; i < amount; i++) {
            generateTraits(mintedTokens + i);
            _safeMint(msg.sender, mintedTokens + i);
        }
        mintedTokens += amount;
    }

    /**
     * Rebirth a horse by burning two horses owned by the caller
     */
    function rebirth(uint256 tokenId1, uint256 tokenId2) public payable {
        require(tokenId1 != tokenId2, "Not different tokens");
        require(ownerOf(tokenId1) == msg.sender, "Not owner of token");
        require(ownerOf(tokenId2) == msg.sender, "Not owner of token");
        require(!traits[tokenId1].burned, "Already burned");
        require(!traits[tokenId2].burned, "Already burned");
        require(msg.value == rebirthPrice, "Not enough ether to rebirth");

        traits[tokenId1].burned = true;
        traits[tokenId2].burned = true;
        _burn(tokenId1);
        _burn(tokenId2);

        burnedTokens += 2;

        uint256 rebirthTokenId = maxTokens.add(rebirthedTokens);
        generateTraits(rebirthTokenId);
        _safeMint(msg.sender, rebirthTokenId);
        rebirthedTokens++;
    }

    function generateTraits(uint256 tokenId) private {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, tokenId)
            )
        );
        (
            uint8 maneColor,
            uint8 patternColor,
            uint8 hoofColor,
            uint8 bodyColor,
            uint8 background,
            uint8 tail,
            uint8 mane,
            uint8 pattern,
            uint8 headAccessory,
            uint8 bodyAccessory,
            uint8 utility
        ) = HorseUtilityContract(utilityContract).getRandomAttributes(
                randomNumber
            );
        traits[tokenId] = TokenTraits(
            maneColor,
            patternColor,
            hoofColor,
            bodyColor,
            background,
            tail,
            mane,
            pattern,
            headAccessory,
            bodyAccessory,
            utility,
            false
        );
    }

    /**
     * Add an address to the whitelist
     */
    function addWhitelistAddresses(address[] memory newWhitelistMembers)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < newWhitelistMembers.length; i++) {
            whitelistedAddressMintsLeft[
                newWhitelistMembers[i]
            ] = claimableTokensPerAddress;
            whitelistAddressCount++;
        }
    }

    /**
     * Small function to convert uint to string
     */
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
