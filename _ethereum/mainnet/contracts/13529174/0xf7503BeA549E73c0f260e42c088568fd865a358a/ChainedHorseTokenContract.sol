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

    // attribute rarities
    uint256[] private maneColorRarities = [
        4000,
        1000,
        1000,
        1000,
        800,
        800,
        500,
        300,
        300,
        200,
        100
    ];
    uint256[] private patternColorRarities = [
        3000,
        1700,
        1350,
        900,
        800,
        800,
        500,
        300,
        200,
        200,
        150,
        100
    ];
    uint256[] private hoofColorRarities = [
        3500,
        1500,
        1100,
        1000,
        1000,
        500,
        500,
        400,
        200,
        200,
        100
    ];
    uint256[] private bodyColorRarities = [
        2900,
        1500,
        1500,
        1500,
        700,
        600,
        500,
        500,
        200,
        100
    ];
    uint256[] private backgroundRarities = [
        1000,
        1000,
        1000,
        1000,
        1000,
        1000,
        1000,
        1000,
        1000,
        1000
    ];
    uint256[] private tailRarities = [
        3000,
        2000,
        1500,
        1200,
        1000,
        750,
        350,
        200
    ];
    uint256[] private maneRarities = [
        3000,
        1800,
        1600,
        900,
        800,
        700,
        600,
        400,
        200
    ];
    uint256[] private patternRarities = [
        2000,
        1500,
        1500,
        1100,
        1000,
        800,
        800,
        500,
        500,
        300
    ];
    uint256[] private headAccessoryRarities = [
        3100,
        1500,
        1000,
        800,
        700,
        700,
        500,
        550,
        250,
        300,
        300,
        150,
        100,
        50
    ];
    uint256[] private bodyAccessoryRarities = [
        2500,
        2300,
        1400,
        1000,
        800,
        800,
        600,
        400,
        200
    ];
    uint256[] private utilityRarities = [
        3700,
        1000,
        900,
        500,
        400,
        500,
        200,
        600,
        900,
        500,
        300,
        250,
        100,
        100,
        50
    ];

    // amount of attributes
    uint8 constant maneColorCount = 11;
    uint8 constant patternColorCount = 12;
    uint8 constant hoofColorCount = 11;
    uint8 constant bodyColorCount = 10;
    uint8 constant backgroundCount = 10;
    uint8 constant tailCount = 8;
    uint8 constant maneCount = 9;
    uint8 constant patternCount = 10;
    uint8 constant headAccessoryCount = 14;
    uint8 constant bodyAccessoryCount = 9;
    uint8 constant utilityCount = 15;

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
     * Save seed for traits for each token
     */
    mapping(uint256 => uint256) public tokenSeed;
    mapping(uint256 => bool) public tokenBurned;

    /**
     * Pretty standard constructor variables, nothing wierd here
     *
     * Mints #0 to the creator
     */
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 _maxTokens,
        address _utilityContract,
        address mintedByOnOldContract
    ) ERC721(tokenName, tokenSymbol) {
        maxTokens = _maxTokens;
        utilityContract = _utilityContract;
        migrateMintedTokensFromOldContract(mintedByOnOldContract);
    }

    /**
     * Mint tokens that have been minted on the old contract and send to minters
     * Set the same seed as the old contract generated for the minted tokens so they get the same properties
     */
    function migrateMintedTokensFromOldContract(address mintedByOnOldContract)
        private
    {
        _safeMint(msg.sender, 0);
        _safeMint(mintedByOnOldContract, 1);
        _safeMint(mintedByOnOldContract, 2);
        _safeMint(mintedByOnOldContract, 3);
        _safeMint(mintedByOnOldContract, 4);
        _safeMint(mintedByOnOldContract, 5);
        tokenSeed[0] = 5544338833776644337733999;
        tokenSeed[1] = 7788333333735555114477799;
        tokenSeed[2] = 1111772266993344221133999;
        tokenSeed[3] = 1155775566117788663333999;
        tokenSeed[4] = 1144222200001111889999799;
        tokenSeed[5] = 5588447788664477885544999;
        mintedTokens += 6;
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
     * Private function so it can be called cheaper from tokenURI and tokenSVG
     */
    function _tokenSVG(uint256 seed) private view returns (string memory) {
        (string memory svg, string memory properties) = getRandomAttributes(
            seed
        );

        return svg;
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
                    _tokenSVG(tokenSeed[tokenId])
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
        if (
            !_exists(tokenId) &&
            (tokenId < mintedTokens ||
                (tokenId < (maxTokens + burnedTokens) && tokenId > maxTokens))
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
        (string memory svg, string memory properties) = getRandomAttributes(
            tokenSeed[tokenId]
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
                            properties,
                            '], "image":"data:image/svg+xml;base64,',
                            svg,
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
            tokenSeed[mintedTokens + i] = uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        mintedTokens + i
                    )
                )
            );
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
        require(!tokenBurned[tokenId1], "Already burned");
        require(!tokenBurned[tokenId2], "Already burned");
        require(msg.value == rebirthPrice, "Not enough ether to rebirth");

        tokenBurned[tokenId1] = true;
        tokenBurned[tokenId2] = true;
        _burn(tokenId1);
        _burn(tokenId2);

        burnedTokens += 2;

        uint256 rebirthTokenId = maxTokens.add(rebirthedTokens);
        tokenSeed[rebirthTokenId] = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    rebirthTokenId
                )
            )
        );
        _safeMint(msg.sender, rebirthTokenId);
        rebirthedTokens++;
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

    /**
     * Use:
     * Get random attributes for each different property of the token
     *
     * Comment:
     * Can only be used by the TokenContract defined by address tokenContract
     */
    function getRandomAttributes(uint256 randomNumber)
        public
        view
        returns (string memory svg, string memory properties)
    {
        uint8[] memory attributes = new uint8[](11);
        attributes[0] = getRandomIndex(
            maneColorRarities,
            maneColorCount,
            randomNumber
        );
        randomNumber = randomNumber / 100;
        attributes[1] = getRandomIndex(
            patternColorRarities,
            patternColorCount,
            randomNumber
        );
        randomNumber = randomNumber / 100;
        attributes[2] = getRandomIndex(
            hoofColorRarities,
            hoofColorCount,
            randomNumber
        );
        randomNumber = randomNumber / 100;
        attributes[3] = getRandomIndex(
            bodyColorRarities,
            bodyColorCount,
            randomNumber
        );
        randomNumber = randomNumber / 100;
        attributes[4] = getRandomIndex(
            backgroundRarities,
            backgroundCount,
            randomNumber
        );
        randomNumber = randomNumber / 100;
        attributes[5] = getRandomIndex(tailRarities, tailCount, randomNumber);
        randomNumber = randomNumber / 100;
        attributes[6] = getRandomIndex(maneRarities, maneCount, randomNumber);
        randomNumber = randomNumber / 100;
        attributes[7] = getRandomIndex(
            patternRarities,
            patternCount,
            randomNumber
        );
        randomNumber = randomNumber / 100;
        attributes[8] = getRandomIndex(
            headAccessoryRarities,
            headAccessoryCount,
            randomNumber
        );
        randomNumber = randomNumber / 100;
        attributes[9] = getRandomIndex(
            bodyAccessoryRarities,
            bodyAccessoryCount,
            randomNumber
        );
        randomNumber = randomNumber / 100;
        attributes[10] = getRandomIndex(
            utilityRarities,
            utilityCount,
            randomNumber
        );
        // render svg
        bytes memory _svg = HorseUtilityContract(utilityContract).renderHorse(
            HorseUtilityContract(utilityContract).renderColors(
                attributes[0],
                attributes[1],
                attributes[2],
                attributes[3]
            ),
            attributes[4],
            attributes[5],
            attributes[6],
            attributes[7],
            attributes[8],
            attributes[9],
            attributes[10]
        );

        svg = Base64.encode(_svg);

        // pack properties
        bytes memory _properties = abi.encodePacked(
            packMetaData(
                "background",
                HorseUtilityContract(utilityContract).getBackground(
                    attributes[4]
                ),
                0
            ),
            packMetaData(
                "tail",
                HorseUtilityContract(utilityContract).getTail(attributes[5]),
                0
            ),
            packMetaData(
                "mane",
                HorseUtilityContract(utilityContract).getMane(attributes[6]),
                0
            ),
            packMetaData(
                "pattern",
                HorseUtilityContract(utilityContract).getPattern(attributes[7]),
                0
            ),
            packMetaData(
                "head accessory",
                HorseUtilityContract(utilityContract).getHeadAccessory(
                    attributes[8]
                ),
                0
            ),
            packMetaData(
                "body accessory",
                HorseUtilityContract(utilityContract).getBodyAccessory(
                    attributes[9]
                ),
                0
            ),
            packMetaData(
                "utility",
                HorseUtilityContract(utilityContract).getUtility(
                    attributes[10]
                ),
                0
            )
        );

        string[] memory colorNames = new string[](4);

        colorNames[0] = HorseUtilityContract(utilityContract).getManeColor(
            attributes[0]
        );
        colorNames[1] = HorseUtilityContract(utilityContract).getPatternColor(
            attributes[1]
        );
        colorNames[2] = HorseUtilityContract(utilityContract).getHoofColor(
            attributes[2]
        );
        colorNames[3] = HorseUtilityContract(utilityContract).getBodyColor(
            attributes[3]
        );

        properties = string(
            abi.encodePacked(
                _properties,
                packMetaData("mane color", colorNames[0], 0),
                packMetaData("pattern color", colorNames[1], 0),
                packMetaData("hoof color", colorNames[2], 0),
                packMetaData("body color", colorNames[3], 1)
            )
        );

        return (svg, properties);
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
     * Use:
     * Get a random attribute using the rarities defined
     */
    function getRandomIndex(
        uint256[] memory attributeRarities,
        uint8 attributeCount,
        uint256 randomNumber
    ) private pure returns (uint8 index) {
        uint256 random10k = randomNumber % 10000;
        uint256 steps = 0;
        for (uint8 i = 0; i < attributeCount; i++) {
            uint256 currentRarity = attributeRarities[i] + steps;
            if (random10k < currentRarity) {
                return i;
            }
            steps = currentRarity;
        }
        return 0;
    }
}
