/*
      \  |                     _)                     _ \    _|      |     _)   _|                    
     |\/ |   _ \   _` |  __ \   |  __ \    _` |      |   |  |        |      |  |     _ \              
     |   |   __/  (   |  |   |  |  |   |  (   |      |   |  __|      |      |  __|   __/              
    _|  _| \___| \__,_| _|  _| _| _|  _| \__, |     \___/  _|       _____| _| _|   \___|              
                                         |___/
   ___|         |  |                       |       ___|                |                      |       
  |      |   |  |  __|  |   |   __|  _` |  |      |       _ \   __ \   __|   __|  _` |   __|  __|     
  |      |   |  |  |    |   |  |    (   |  |      |      (   |  |   |  |    |    (   |  (     |       
 \____| \__,_| _| \__| \__,_| _|   \__,_| _|     \____| \___/  _|  _| \__| _|   \__,_| \___| \__|     

by maciej wisniewski                                                                                                                   
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./base64.sol";

/**
 * @dev Required interface of a CulturalContract compliant contract.
 */
interface ICulturalContract {
    /**
     * @dev Returns cRNA number, cRNA length and cRNA unit length.
     *
     * cRNA defines the attributes of the ERC721 token.
     * cRNA is divided in equal length units. Every unit defines a set of attributes.
     * cRNAs can be easily manipulated using simple mathematical operations providing
     * many creative possibilities for remixes and mashups.
     *
     */
    function culturalRNA(uint256 tokenId)
        external
        returns (
            uint256 cRNA,
            uint256 numberLength,
            uint256 unitLength
        );

    /**
     * @dev Remixes the ERC721 token based on the `input`.
     */
    function remix(uint256 tokenId, string memory input) external;

    /**
     * @dev Returns mashup result of ERC721 token from a given `mashupAddress`.
     */
    function mashup(uint256 tokenId, address payable mashupAddress)
        external
        payable
        returns (string memory);

    /**
     * @dev Returns `mashupFee` from `mashupAddress`.
     */
    function mashupFee(address mashupAddress) external returns (uint256);
}

/**
 * @dev Optional interface of a CulturalContract compliant contract.
 */
interface ICulturalContractMetadata {
    /**
     * @dev Returns the CulturalContract name.
     */
    function ccName() external view returns (string memory);

    /**
     * @dev Returns the CulturalContract symbol.
     */
    function ccSymbol() external view returns (string memory);

    /**
     * @dev Returns the CulturalContract author.
     */
    function ccAuthor() external view returns (string memory);
}

abstract contract CulturalContract is
    ICulturalContract,
    ICulturalContractMetadata,
    ERC721Enumerable,
    ReentrancyGuard,
    Ownable
{
    event MashedUp(uint256 indexed tokenId);
    event Remixed(uint256 indexed tokenId);

    struct CulturalRNA_Unit {
        uint256 numberLength;
        uint256 unitLength;
    }

    /**
     * @dev Helper function. Returns cRNA unit array for a given cRNA number.
     */
    function decode(
        uint256 number,
        uint256 numberLength,
        uint256 unitLength
    ) internal pure returns (uint256[] memory) {
        uint256[] memory units = new uint256[](numberLength / unitLength);
        uint256 i;
        uint256 counter = 0;
        for (i = 0; i < numberLength / unitLength; i++) {
            units[i] =
                ((number % (10**(numberLength - counter))) /
                    (10**(numberLength - (counter + unitLength)))) %
                10**unitLength;
            counter = counter + unitLength;
        }
        return units;
    }

    /**
     * @dev Helper function. Returns cRNA number for a given cRNA unit array.
     */
    function encode(uint256[] memory numbers, uint256 unitLength)
        internal
        pure
        returns (uint256)
    {
        uint256 encodedNumber = numbers[0];
        uint256 i;
        for (i = 0; i < numbers.length - 1; i++) {
            encodedNumber = encodedNumber * 10**unitLength + numbers[i + 1];
        }
        return encodedNumber;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Note: the ERC-165 identifier for ICulturalContract interface is 0xf9ae973e
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(ICulturalContract).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Helper function. Returns ICulturalContract interface identifier.
     */
    function getICCinterface() public pure returns (bytes4) {
        return type(ICulturalContract).interfaceId;
    }
}

contract MeaningOfLife is CulturalContract {
    event SalePaused(bool paused);

    string public constant DESCRIPTION =
        "Meaning-of-Life is an artwork created by Maciej Wisniewski in 2002 for the Whitney Museum of American Art and made available by the artist as a CulturalContract in 2022. CulturalContracts are NFTs that can be remixed and mashed up.";

    CulturalRNA_Unit public cRNA_U =
        CulturalRNA_Unit({numberLength: 35, unitLength: 5});

    mapping(uint256 => uint256) private tokenCRNA;
    mapping(string => uint256) private propertyIndex;
    mapping(uint256 => bool) private isRemixed;
    mapping(uint256 => string) private remixValue;
    mapping(uint256 => bool) private isMashedUp;
    mapping(uint256 => string) private mashupValue;
    mapping(uint256 => address) private mashedUpBy;
    mapping(address => bool) private inMashupRegistry;
    mapping(address => uint256) private mashupRanking;
    mapping(address => uint256) private mashupPrice;
    mapping(address => string) private mashupName;
    mapping(address => string) private mashupSymbol;
    mapping(address => string) private mashupAuthor;
    mapping(address => uint256) private allMashupsIndex;
    mapping(address => uint256) private latestMashupTokenId;

    uint256 public constant MAX_TOKENS = 12000;
    uint256 public constant MAX_RESERVED_TOKENS = 480;
    uint256 public price = 100000000000000000; //0.1 ETH

    address[] private allMashups;
    uint256 private numRemixMashups = 0;
    bool private paused = false;
    string private author = "maciej wisniewski";
    uint256 private tokenCounter = 0;
    uint256 private reservedTokenCounter = 0;

    string[] private locations = [
        "Acapulco",
        "Aklavik",
        "Algiers",
        "Almaty",
        "Anadyr",
        "Anchorage",
        "Yerevan",
        "Asuncion",
        "Atlanta",
        "Bandung",
        "Bangkok",
        "Beijing",
        "Bogota",
        "Boston",
        "Brasilia",
        "Brisbane",
        "Buenos Aires",
        "Canberra",
        "Caracas",
        "Casablanca",
        "Chicago",
        "Chongquing",
        "Denpasar",
        "Denver",
        "Detroit",
        "Dublin",
        "Edmonton",
        "Pyongyang",
        "Guatemala City",
        "Hangzhou",
        "Hanoi",
        "Harare",
        "Harrisburg",
        "Havana",
        "Hong Kong",
        "Honiara",
        "Honolulu",
        "Houston",
        "Indianapolis",
        "Iqaluit",
        "Istanbul",
        "Jakarta",
        "Kamchatka",
        "Kingston",
        "Kingstown",
        "Kiritimati",
        "Kolonia",
        "Kuala Lumpur",
        "Kuwait City",
        "La Paz",
        "Lagos",
        "Lima",
        "Lisbon",
        "London",
        "Los Angeles",
        "Malang",
        "Managua",
        "Manila",
        "Mataram",
        "Medan",
        "Melbourne",
        "Mexicali",
        "Mexico City",
        "Minneapolis",
        "Montgomery",
        "Montreal",
        "Moscow",
        "Nagoya",
        "Nairobi",
        "Nassau",
        "New Orleans",
        "New York City",
        "Noumea",
        "Novosibirsk",
        "Odessa",
        "Omsk",
        "Ottawa",
        "Palembang",
        "Perth",
        "Philadelphia",
        "Phnom Penh",
        "Phoenix",
        "Prague",
        "Reykjavik",
        "Rio de Janeiro",
        "Chiang Mai",
        "San Francisco",
        "San Juan",
        "San Salvador",
        "Santiago",
        "Santo Domingo",
        "Sao Paulo",
        "Seattle",
        "Semarang",
        "Seoul",
        "Shanghai",
        "Singapore",
        "St. Paul",
        "Stockholm",
        "Surabaya",
        "Surakarta",
        "Suva",
        "Sydney",
        "Taipei",
        "Tangshan",
        "Tegucigalpa",
        "The Settlement",
        "Tianjin",
        "Tijuana",
        "Tokyo",
        "Toronto",
        "Qingdao",
        "Ulaanbaatar",
        "Vancouver",
        "Vientiane",
        "Vladivostok",
        "Warsaw",
        "Washington DC",
        "Wellington",
        "Winnipeg",
        "Aden",
        "Aleppo",
        "Alexandria",
        "Amman",
        "Ankara",
        "Athens",
        "Baghdad",
        "Beirut",
        "Belgrade",
        "Bethlehem",
        "Bruges",
        "Cairo",
        "Cape Town",
        "Colombo",
        "Damascus",
        "Delhi",
        "Fez",
        "Florence",
        "Hyderabad",
        "Jaffa",
        "Jaffna",
        "Jerusalem",
        "Kandahar",
        "Kathmandu",
        "Kotor",
        "Lahore",
        "Lesbos",
        "Lhasa",
        "Ljubljana",
        "Madurai",
        "Mecca",
        "Minsk",
        "Mombasa",
        "Monte Carlo",
        "Mumbai",
        "Muscat",
        "Nicosia",
        "Peshawar",
        "Plovdiv",
        "Quito",
        "Riga",
        "Riyadh",
        "Sarajevo",
        "Sofia",
        "Split",
        "Srinagar",
        "Tallinn",
        "Tashkent",
        "Tbilisi",
        "Teheran",
        "Thessaloniki",
        "Timbuktu",
        "Tirana",
        "Tripoli",
        "Varanasi",
        "Venice",
        "Vienna",
        "Vilnius",
        "Yangon",
        "Zurich",
        "Agartha",
        "Amaravati",
        "Amaurotum",
        "Arcadia",
        "Arkham",
        "Asgard",
        "Atlantis",
        "Ayodhya",
        "Aztlan",
        "Brahmaloka",
        "Camelot",
        "Casterbridge",
        "Diyu",
        "Duat",
        "El Dorado",
        "Elsinore",
        "Emerald City",
        "Erewhon",
        "Gorias",
        "Jotunheim",
        "Kunlun",
        "Lorbrulgrud",
        "Mayberry",
        "Mildendo",
        "Pandaemonium",
        "Riverdale",
        "Shambala",
        "Shangri La",
        "Springfield",
        "Takamagahara",
        "Elysium",
        "Themiscyra",
        "Valhalla",
        "Xanadu",
        "Z",
        "Oslo",
        "Copenhagen",
        "Helsinki",
        "Tel Aviv",
        "Milanowek"
    ];

    string[] private timeOfDayColors = [
        "whitesmoke",
        "lightgray",
        "darkgray",
        "dimgray",
        "darkgray",
        "lightgray"
    ];
    string[] private timeOfDay = [
        "During the day of ",
        "In the early evening on ",
        "On the evening of ",
        "During the night of ",
        "In the early morning on ",
        "On the morning of "
    ];

    string[] private timeOfDayMeta = [
        "Day",
        "Early Evening",
        "Evening",
        "Night",
        "Early Morning",
        "Morning"
    ];

    string[] private months = [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December"
    ];

    constructor() ERC721("MeaningOfLife CC", "MLCC") Ownable() {
        propertyIndex["time"] = 0;
        propertyIndex["year"] = 1;
        propertyIndex["month"] = 2;
        propertyIndex["day"] = 3;
        propertyIndex["location"] = 4;
        propertyIndex["remix"] = 5;
        propertyIndex["mashup"] = 6;
    }

    /**
     * @dev Returns a pseudorandom number.
     */
    function mix(uint256 numberLength, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        uint256 mixedNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId))
        ) % 10**numberLength;
        return mixedNumber;
    }

    /**
     * @dev Returns true if the given year is a leap year.
     *
     * Helper calendar function.
     */
    function isLeapYear(uint256 year) internal pure returns (uint256) {
        if (year == 1900) {
            return 1;
        } else {
            return year % 4;
        }
    }

    /**
     * @dev Returns the number of days in a given month.
     *
     * Helper calender function.
     */
    function numberOfDays(uint256 month, uint256 year)
        internal
        pure
        returns (uint256)
    {
        if (month == 3 || month == 5 || month == 8 || month == 10) {
            return 30;
        } else if (month == 1) {
            if (isLeapYear(year) == 0) {
                return 29;
            } else {
                return 28;
            }
        } else {
            return 31;
        }
    }

    /**
     * @dev Returns the unit number for a given attribute set.
     */
    function getCode(uint256 tokenId, uint256 index)
        internal
        view
        returns (uint256)
    {
        uint256 cRNAnumber = tokenCRNA[tokenId];
        uint256 arraySize = cRNA_U.numberLength / cRNA_U.unitLength;
        uint256[] memory codeArray = new uint256[](arraySize);
        codeArray = decode(cRNAnumber, cRNA_U.numberLength, cRNA_U.unitLength);
        return codeArray[index];
    }

    /**
     * @dev Adds the remix value to the cRNA.
     */
    function getRemixCRNA(uint256 tokenId, uint256 remixCRNA)
        internal
        view
        returns (uint256)
    {
        uint256 cRNAnumber = tokenCRNA[tokenId];
        uint256 arraySize = cRNA_U.numberLength / cRNA_U.unitLength;
        uint256[] memory codeArray = new uint256[](arraySize);
        codeArray = decode(cRNAnumber, cRNA_U.numberLength, cRNA_U.unitLength);
        codeArray[propertyIndex["remix"]] = remixCRNA;
        return encode(codeArray, cRNA_U.unitLength);
    }

    /**
     * @dev Adds the mashup value to the cRNA.
     */
    function getMashupCRNA(uint256 tokenId, uint256 mashupCRNA)
        internal
        view
        returns (uint256)
    {
        uint256 cRNAnumber = tokenCRNA[tokenId];
        uint256 arraySize = cRNA_U.numberLength / cRNA_U.unitLength;
        uint256[] memory codeArray = new uint256[](arraySize);
        codeArray = decode(cRNAnumber, cRNA_U.numberLength, cRNA_U.unitLength);
        codeArray[propertyIndex["mashup"]] = mashupCRNA;
        return encode(codeArray, cRNA_U.unitLength);
    }

    /**
     * @dev Returns the time of the day.
     *
     * @dev Helper calender function.
     */
    function getTimeOfDay(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        uint256 time = getCode(tokenId, propertyIndex["time"]) %
            timeOfDay.length;
        return string(abi.encodePacked(timeOfDay[time]));
    }

    /**
     * @dev Returns the time of the day meta data.
     */
    function getTimeOfDayMeta(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        uint256 time = getCode(tokenId, propertyIndex["time"]) %
            timeOfDayMeta.length;
        return string(abi.encodePacked(timeOfDayMeta[time]));
    }

    /**
     * @dev Returns the background color based on the time of the day.
     */
    function getColor(uint256 tokenId) internal view returns (string memory) {
        uint256 time = getCode(tokenId, propertyIndex["time"]) %
            timeOfDayColors.length;
        return string(abi.encodePacked(timeOfDayColors[time]));
    }

    /**
     * @dev Returns the year.
     */
    function getYear(uint256 tokenId) internal view returns (uint256) {
        return (getCode(tokenId, propertyIndex["year"]) % 150) + 1900;
    }

    /**
     * @dev Returns the month.
     */
    function getMonth(uint256 tokenId) internal view returns (string memory) {
        uint256 month = getCode(tokenId, propertyIndex["month"]) %
            months.length;
        return string(abi.encodePacked(months[month]));
    }

    /**
     * @dev Returns the location.
     */
    function getLocation(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        uint256 location = getCode(tokenId, propertyIndex["location"]) %
            locations.length;
        return string(abi.encodePacked(locations[location]));
    }

    /**
     * @dev Returns the month index.
     */
    function getMonthIndex(uint256 tokenId) internal view returns (uint256) {
        return getCode(tokenId, propertyIndex["month"]) % months.length;
    }

    /**
     * @dev Returns a day for a given month and year.
     */
    function getDay(uint256 tokenId) internal view returns (uint256) {
        uint256 year = getYear(tokenId);
        uint256 month = getMonthIndex(tokenId);
        uint256 numberDays = numberOfDays(month, year);
        return (getCode(tokenId, propertyIndex["day"]) % numberDays) + 1;
    }

    /**
     * @dev Returns the cRNA number.
     */
    function getTokenCRNA(uint256 tokenId) internal view returns (uint256) {
        return tokenCRNA[tokenId];
    }

    /**
     * @dev Returns the text for a given token including the remix if available.
     */
    function getText(uint256 tokenId) internal view returns (string memory) {
        string[11] memory textString;
        textString[0] = getTimeOfDay(tokenId);
        textString[1] = " ";
        textString[2] = getMonth(tokenId);
        textString[3] = " ";
        textString[4] = Strings.toString(getDay(tokenId));
        textString[5] = ", ";
        textString[6] = Strings.toString(getYear(tokenId));
        textString[7] = " in ";
        textString[8] = getLocation(tokenId);
        textString[9] = getRemixed(tokenId);

        string memory textCombined = string(
            abi.encodePacked(
                textString[0],
                textString[1],
                textString[2],
                textString[3],
                textString[4],
                textString[5]
            )
        );
        textCombined = string(
            abi.encodePacked(
                textCombined,
                textString[6],
                textString[7],
                textString[8],
                textString[9]
            )
        );
        return textCombined;
    }

    /**
     * @dev Returns the title of a given token.
     */
    function getName(uint256 tokenId) internal view returns (string memory) {
        string[11] memory textString;
        textString[0] = getMonth(tokenId);
        textString[1] = " ";
        textString[2] = Strings.toString(getDay(tokenId));
        textString[3] = ", ";
        textString[4] = Strings.toString(getYear(tokenId));
        string memory textCombined = string(
            abi.encodePacked(
                textString[0],
                textString[1],
                textString[2],
                textString[3],
                textString[4]
            )
        );
        return textCombined;
    }

    /**
     * @dev Returns the remix value.
     */
    function getRemixed(uint256 tokenId) internal view returns (string memory) {
        string memory remixedString;

        if (isRemixed[tokenId]) {
            uint256 remixIndex = getCode(tokenId, propertyIndex["remix"]);
            remixedString = string(
                abi.encodePacked(
                    '<tspan x="5" y="330">',
                    remixValue[remixIndex],
                    "</tspan>"
                )
            );
        } else {
            remixedString = string(abi.encodePacked("... "));
        }

        return remixedString;
    }

    /**
     * @dev Returns the mashup value.
     */
    function getMashedUp(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string memory mashupString;

        if (isMashedUp[tokenId]) {
            uint256 mashupIndex = getCode(tokenId, propertyIndex["mashup"]);
            mashupString = string(abi.encodePacked(mashupValue[mashupIndex]));
        } else {
            mashupString = string(abi.encodePacked(""));
        }

        return mashupString;
    }

    /**
     * @dev Returns token metadata.
     */
    function getMetaData(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string[15] memory metaInfo;
        metaInfo[0] = '[{"trait_type": "Remix", "value": "';
        if (isRemixed[tokenId]) {
            metaInfo[1] = "Yes";
        } else {
            metaInfo[1] = "No";
        }
        metaInfo[2] = '"},{"trait_type": "Mashup", "value": "';
        if (isMashedUp[tokenId]) {
            metaInfo[3] = mashupSymbol[mashedUpBy[tokenId]];
        } else {
            metaInfo[3] = "No";
        }
        metaInfo[4] = '"},{"trait_type": "Time Of Day", "value": "';
        metaInfo[5] = getTimeOfDayMeta(tokenId);
        metaInfo[6] = '"},{"trait_type": "Month", "value": "';
        metaInfo[7] = getMonth(tokenId);
        metaInfo[8] = '"},{"trait_type": "Day", "value": "';
        metaInfo[9] = Strings.toString(getDay(tokenId));
        metaInfo[10] = '"},{"trait_type": "Year", "value": "';
        metaInfo[11] = Strings.toString(getYear(tokenId));
        metaInfo[12] = '"},{"trait_type": "Location", "value": "';
        metaInfo[13] = getLocation(tokenId);
        metaInfo[14] = '"}]';

        string memory metaCombined = string(
            abi.encodePacked(
                metaInfo[0],
                metaInfo[1],
                metaInfo[2],
                metaInfo[3],
                metaInfo[4],
                metaInfo[5],
                metaInfo[6],
                metaInfo[7]
            )
        );
        metaCombined = string(
            abi.encodePacked(
                metaCombined,
                metaInfo[8],
                metaInfo[9],
                metaInfo[10],
                metaInfo[11],
                metaInfo[12],
                metaInfo[13],
                metaInfo[14]
            )
        );

        return metaCombined;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string[7] memory svgString;

        svgString[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style type="text/css">.txt{fill: black;font-family: "Open Sans", sans-serif; font-size: 0.75em;}</style><rect width="100%" height="100%" fill="';
        svgString[1] = getColor(tokenId);
        svgString[2] = '"/>';
        svgString[3] = getMashedUp(tokenId);
        svgString[4] = '<text x="5" y="310" class="txt">';
        svgString[5] = getText(tokenId);
        svgString[6] = "</text></svg>";

        string memory svgFile = string(
            abi.encodePacked(
                svgString[0],
                svgString[1],
                svgString[2],
                svgString[3],
                svgString[4],
                svgString[5],
                svgString[6]
            )
        );

        string memory jsonFile = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        getName(tokenId),
                        '", "description": "',
                        DESCRIPTION,
                        '", "attributes": ',
                        getMetaData(tokenId),
                        ', "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svgFile)),
                        '"}'
                    )
                )
            )
        );
        return
            string(abi.encodePacked("data:application/json;base64,", jsonFile));
    }

    /**
     * @dev See {ICulturalContract-culturalRNA}.
     */
    function culturalRNA(uint256 tokenId)
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (tokenCRNA[tokenId], cRNA_U.numberLength, cRNA_U.unitLength);
    }

    /**
     * @dev Pauses/Unpauses sale.
     *
     * Emits a {SalePaused} event.
     */
    function setSalePaused(bool isPaused) external onlyOwner {
        paused = isPaused;
        emit SalePaused(paused);
    }

    function getSalePaused() external view returns (bool) {
        return paused;
    }

    /**
     * @dev Mints token.
     *
     * Note: On Rinkeby Testnet MAX_TOKENS has no limit. See the commented out code below.
     */
    function mintToken(uint256 numberTokens)
        public
        payable
        nonReentrant
        returns (uint256[] memory tokenIDs)
    {
        require(!paused, "Sale paused");
        
        require(
            totalSupply() + MAX_RESERVED_TOKENS - reservedTokenCounter <
                MAX_TOKENS + numRemixMashups,
            "Sold out"
        );
        
        require(
            numberTokens > 0 && numberTokens <= 12,
            "Incorrect number of tokens"
        );
        
        require(
            totalSupply() + numberTokens <=
                MAX_TOKENS -
                    MAX_RESERVED_TOKENS +
                    reservedTokenCounter +
                    numRemixMashups,
            "Requested too many tokens"
        );
        
        require(msg.value >= price * numberTokens, "Incorrect amount");
        uint256 mintCost = price * numberTokens;
        uint256 refund = msg.value - mintCost;
        if (refund > 0) {
            Address.sendValue(payable(msg.sender), refund);
        }

        tokenIDs = new uint256[](numberTokens);

        for (uint256 i = 0; i < numberTokens; i++) {
            uint256 mintIndex = tokenCounter++;
            tokenCRNA[mintIndex] =
                mix(cRNA_U.numberLength - 2 * cRNA_U.unitLength, mintIndex) *
                10**(2 * cRNA_U.unitLength);
            tokenIDs[i] = mintIndex;
            _safeMint(_msgSender(), mintIndex);
        }
        return tokenIDs;
    }

    /**
     * @dev Burns a specific ERC721 token.
     * @param tokenId uint256 id of the ERC721 token to be burned.
     */
    function burn(uint256 tokenId) public nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not the token owner");
        _burn(tokenId);

        if (isRemixed[tokenId] || isMashedUp[tokenId]) {
            numRemixMashups--;
        }

        delete tokenCRNA[tokenId];
        delete isRemixed[tokenId];
        delete remixValue[tokenId];
        delete isMashedUp[tokenId];
        delete mashupValue[tokenId];

        address mashupAddress = mashedUpBy[tokenId];
        uint256 timesMashedUp = mashupRanking[mashupAddress];
        if (timesMashedUp > 0) {
            mashupRanking[mashupAddress] = timesMashedUp - 1;
        }
        delete mashedUpBy[tokenId];
    }

    /**
     * @dev Sets token price.
     *
     * Note: Cannot be changed if sale active.
     */
    function setPrice(uint256 _newPrice) public onlyOwner {
        require(paused, "Price cannot be changed");
        price = _newPrice;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    /**
     * @dev Mints reserved token.
     */
    function ownerMintToken(uint256 numberTokens)
        public
        nonReentrant
        onlyOwner
    {
        require(reservedTokenCounter < MAX_RESERVED_TOKENS, "Sold out");
        require(
            reservedTokenCounter + numberTokens <= MAX_RESERVED_TOKENS,
            "Requested too many tokens"
        );

        for (uint256 i = 0; i < numberTokens; i++) {
            uint256 mintIndex = tokenCounter++;
            reservedTokenCounter++;
            tokenCRNA[mintIndex] =
                mix(cRNA_U.numberLength - 2 * cRNA_U.unitLength, mintIndex) *
                10**(2 * cRNA_U.unitLength);
            _safeMint(_msgSender(), mintIndex);
        }
    }

    /**
     * @dev See {ICulturalContract-remix}.
     */
    function remix(uint256 tokenId, string memory remixInput)
        public
        override
        nonReentrant
    {
        require(ERC721.ownerOf(tokenId) == _msgSender(), "Not the token owner");
        require(!isRemixed[tokenId], "Remixed token");
        uint256 remixTokenId = tokenCounter++;
        uint256 remixCRNA = mix(cRNA_U.unitLength, tokenId);
        remixValue[remixCRNA] = remixInput;

        tokenCRNA[remixTokenId] = getRemixCRNA(tokenId, remixCRNA);
        if (isMashedUp[tokenId]) {
            isMashedUp[remixTokenId] = true;
        }
        isRemixed[remixTokenId] = true;
        numRemixMashups++;
        _safeMint(_msgSender(), remixTokenId);
        emit Remixed(remixTokenId);
    }

    /**
     * @dev See {ICulturalContract-mashupFee}.
     */
    function mashupFee(address mashupAddress)
        public
        override
        returns (uint256)
    {
        ICulturalContract cContract = ICulturalContract(mashupAddress);
        uint256 mashupCharge = cContract.mashupFee(mashupAddress);
        mashupPrice[mashupAddress] = mashupCharge;
        return mashupCharge;
    }

    /**
     * @dev See {ICulturalContract-mashup}.
     */
    function mashup(uint256 tokenId, address payable mashupAddress)
        public
        payable
        override
        nonReentrant
        returns (string memory)
    {
        require(ERC721.ownerOf(tokenId) == _msgSender(), "Not the token owner");
        require(!isMashedUp[tokenId], "Mashed up token");
        require(msg.value == mashupFee(mashupAddress), "Incorrect amount");
        uint256 mashupTokenId = tokenCounter++;
        uint256 mashupCRNA = mix(cRNA_U.unitLength, tokenId);
        ICulturalContract cContract = ICulturalContract(mashupAddress);
        mashupValue[mashupCRNA] = string(
            abi.encodePacked(cContract.mashup(tokenId, payable(address(this))))
        );
        tokenCRNA[mashupTokenId] = getMashupCRNA(tokenId, mashupCRNA);
        if (isRemixed[tokenId]) {
            isRemixed[mashupTokenId] = true;
        }
        isMashedUp[mashupTokenId] = true;
        mashedUpBy[mashupTokenId] = mashupAddress;
        numRemixMashups++;
        _safeMint(_msgSender(), mashupTokenId);
        Address.sendValue(payable(mashupAddress), msg.value);
        addToRegistry(mashupAddress);
        latestMashupTokenId[mashupAddress] = mashupTokenId;
        ICulturalContractMetadata ccMetadata = ICulturalContractMetadata(
            mashupAddress
        );
        mashupName[mashupAddress] = ccMetadata.ccName();
        mashupSymbol[mashupAddress] = ccMetadata.ccSymbol();
        mashupAuthor[mashupAddress] = ccMetadata.ccAuthor();
        emit MashedUp(mashupTokenId);
        return "";
    }

    /**
     * @dev Provides preview for a given mashup
     */
    function mashupURI(address mashupAddress)
        public
        view
        returns (string memory)
    {
        uint256 tokenId = 0;
        tokenId = latestMashupTokenId[mashupAddress];

        string
            memory svgFilePrev = '<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style type="text/css">.txt {fill: white;font-family: "Open Sans", sans-serif;font-size: 3em;}</style><rect width="100%" height="100%" fill="lightgray" /><text x="90" y="150" class="txt">Mashup</text><text x="90" y="210" class="txt">Preview</text></svg>';
        string[7] memory svgString;

        svgString[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style type="text/css">.txt{fill: black;font-family: "Open Sans", sans-serif; font-size: 0.75em;}</style><rect width="100%" height="100%" fill="';
        svgString[1] = getColor(tokenId);
        svgString[2] = '"/>';
        svgString[3] = getMashedUp(tokenId);
        svgString[4] = '<text x="5" y="310" class="txt">';
        svgString[5] = getText(tokenId);
        svgString[6] = "</text></svg>";

        string memory svgFile = string(
            abi.encodePacked(
                svgString[0],
                svgString[1],
                svgString[2],
                svgString[3],
                svgString[4],
                svgString[5],
                svgString[6]
            )
        );
        if (tokenId > 0 && _exists(tokenId)) {
            return string(abi.encodePacked(Base64.encode(bytes(svgFile))));
        } else {
            return string(abi.encodePacked(Base64.encode(bytes(svgFilePrev))));
        }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev See {ICulturalContractMetadata-ccName}.
     */
    function ccName() public view virtual override returns (string memory) {
        return ERC721.name();
    }

    /**
     * @dev See {ICulturalContractMetadata-ccSymbol}.
     */
    function ccSymbol() public view virtual override returns (string memory) {
        return ERC721.symbol();
    }

    /**
     * @dev See {ICulturalContractMetadata-ccAuthor}.
     */
    function ccAuthor() public view virtual override returns (string memory) {
        return author;
    }

    /**
     * @dev Returns true if token has been remixed.
     */
    function getIsRemixed(uint256 tokenId) public view returns (bool) {
        return isRemixed[tokenId];
    }

    /**
     * @dev Returns true if token has been mashed up.
     */
    function getIsMashedUp(uint256 tokenId) public view returns (bool) {
        return isMashedUp[tokenId];
    }

    /**
     * @dev Returns number of mashups in registry.
     */
    function numMashupsInRegistry() public view returns (uint256) {
        return allMashups.length;
    }

    /**
     * @dev Returns number of mashups plus remixes.
     */
    function totalRemixMashups() public view returns (uint256) {
        return numRemixMashups;
    }

    /**
     * @dev Returns number of minted reserved tokens.
     */
    function reservedTokensMinted() public view returns (uint256) {
        return reservedTokenCounter;
    }

    /**
     * @dev Returns mashup address.
     */
    function getMashupAddress(uint256 atIndex) public view returns (address) {
        return allMashups[atIndex];
    }

    /**
     * @dev Returns number of mashups created by `mashupAddress`.
     */
    function getMashupRanking(address mashupAddress)
        public
        view
        returns (uint256)
    {
        return mashupRanking[mashupAddress];
    }

    /**
     * @dev Returns mashup price for a given `mashupAddress`.
     */
    function getMashupFee(address mashupAddress) public view returns (uint256) {
        return mashupPrice[mashupAddress];
    }

    /**
     * @dev Returns mashup name for a given `mashupAddress`.
     */
    function getMashupName(address mashupAddress)
        public
        view
        returns (string memory)
    {
        return mashupName[mashupAddress];
    }

    /**
     * @dev Returns mashup symbol for a given `mashupAddress`.
     */
    function getMashupSymbol(address mashupAddress)
        public
        view
        returns (string memory)
    {
        return mashupSymbol[mashupAddress];
    }

    /**
     * @dev Returns mashup author for a given `mashupAddress`.
     */
    function getMashupAuthor(address mashupAddress)
        public
        view
        returns (string memory)
    {
        return mashupAuthor[mashupAddress];
    }

    /**
     * @dev Adds `mashupAddress` to Mashup Registry.
     */
    function addToRegistry(address mashupAddress) internal {
        if (!inMashupRegistry[mashupAddress]) {
            allMashups.push(mashupAddress);
            allMashupsIndex[mashupAddress] = allMashups.length - 1;
            inMashupRegistry[mashupAddress] = true;
            mashupRanking[mashupAddress] = 1;
        } else {
            uint256 timesMinted = mashupRanking[mashupAddress];
            mashupRanking[mashupAddress] = timesMinted + 1;
        }
    }

    /**
     * @dev Removes `mashupAddress` from Mashup Registry.
     */
    function removeFromRegistry(address mashupAddress) external onlyOwner {
        if (inMashupRegistry[mashupAddress]) {
            uint256 lastMashupIndex = allMashups.length - 1;
            uint256 mashupIndex = allMashupsIndex[mashupAddress];
            address lastMashupAddress = allMashups[lastMashupIndex];
            allMashups[mashupIndex] = lastMashupAddress;
            allMashupsIndex[lastMashupAddress] = mashupIndex;
            delete allMashupsIndex[mashupAddress];
            allMashups.pop();
            inMashupRegistry[mashupAddress] = false;
        }
    }
}
