pragma solidity 0.6.6;

import "ERC721.sol";
import "Ownable.sol";
import "DateTimeLibrary.sol";


/** @title Chronotoken */
contract Chronotoken is ERC721, Ownable {
    /*
    #############
    # Variables #
    #############
    */
    // Global
    uint256 internal randomnessFee;
    uint256 public tokenCounter;
    uint256 internal rc;

    uint internal lastDayMinted;
    uint16 public mintsToday;
    
    uint256 constant MINT_START_PRICE = 2 * 10 ** 17; // 0.2 ETH
    uint256 constant MINT_END_PRICE = 2 * 10 ** 16; // 0.02 ETH

    // Configurable
    bool public confMintActive;
    uint16 public confMaxDailyMints;

    /*
    #########
    # Types #
    #########
    */
    enum Rarity{DIAMOND, GOLD, SILVER, BRONZE}
    enum Effect{NONE, CONFETTI, FLAME, LIGHTNING, PAINT, PLASMA, SMOKE, VINES}
    enum Texture{NONE, CIRCUIT, CRACKED, FUR, KNIT, PAPER, SCALES, WOOD}

    struct Chronotoken {
        Rarity rarity;
        uint16 year;
        uint8 month;
        uint8 day;
        uint32 index;
        Effect effect;
        Texture texture;
        bool shiny;
    }

    struct RequestMintData {
        address sender;
        uint16 dailyMint;
        uint256 timestamp;
        uint256 tokenId;
    }

    /*
    ##################
    # Token Mappings #
    ##################
    */
    mapping(uint256 => Chronotoken) public tokenIdToChronotoken;
    mapping(uint256 => mapping(uint8 => uint32)) internal dateToRarityCount;

    /*
    ##########
    # Events #
    ##########
    */
    event requestedToken(bytes32 indexed requestId); 

    /*
    ##################
    # Random Chances #
    ##################
    */

    // Rarity: out of 100
    uint constant CHANCE_RARITY_DIAMOND = 2;   // 2%
    uint constant CHANCE_RARITY_GOLD = 20;     // 18%
    uint constant CHANCE_RARITY_SILVER = 54;   // 34%
    uint constant CHANCE_RARITY_BRONZE = 100;  // 46%

    uint constant CHANCE_RARITY_DIAMOND_BOOST_FIRST_OR_LAST = 10;   // 10%

    // Decade: out of 1000
    uint constant CHANCE_YEAR_SUB_9_DECADE = 5;     // 0.5%
    uint constant CHANCE_YEAR_SUB_8_DECADE = 16;    // 1.1%
    uint constant CHANCE_YEAR_SUB_7_DECADE = 39;    // 2.3%
    uint constant CHANCE_YEAR_SUB_6_DECADE = 80;    // 4.1%
    uint constant CHANCE_YEAR_SUB_5_DECADE = 145;   // 6.5%
    uint constant CHANCE_YEAR_SUB_4_DECADE = 240;   // 9.5%
    uint constant CHANCE_YEAR_SUB_3_DECADE = 361;   // 12.1%
    uint constant CHANCE_YEAR_SUB_2_DECADE = 524;   // 16.3%
    uint constant CHANCE_YEAR_SUB_1_DECADE = 735;   // 21.1%
    uint constant CHANCE_YEAR_SUB_0_DECADE = 1000;  // 26.5%

    // Effects and Textures: out of 100
    uint8 constant CHANCE_HAS_EFFECT = 2;                  // 2%
    uint8 constant CHANCE_HAS_EFFECT_FIRST_OR_LAST = 20;   // 20%
    uint8 constant CHANCE_HAS_TEXTURE = 4;                 // 4%
    uint8 constant CHANCE_HAS_TEXTURE_FIRST_OR_LAST = 30;  // 30%

    // The chance that if one effect/texture occurs, the other gets added: out of 100
    uint constant CHANCE_ADDS_TEXTURE_IF_EFFECT_EXISTS = 20;  // 20%
    uint constant CHANCE_ADDS_EFFECT_IF_TEXTURE_EXISTS = 15;  // 15%

    // Each effect: out of 100
    uint8 constant CHANCE_HAS_EFFECT_FLAME = 7;       // 7%
    uint8 constant CHANCE_HAS_EFFECT_PLASMA = 18;     // 11%
    uint8 constant CHANCE_HAS_EFFECT_PAINT = 32;      // 14%
    uint8 constant CHANCE_HAS_EFFECT_CONFETTI = 49;   // 17%
    uint8 constant CHANCE_HAS_EFFECT_LIGHTNING = 66;  // 17%
    uint8 constant CHANCE_HAS_EFFECT_VINES = 83;      // 17%
    uint8 constant CHANCE_HAS_EFFECT_SMOKE = 100;     // 17%

    // Each texture: out of 100
    uint8 constant CHANCE_HAS_TEXTURE_CIRCUIT = 7;   // 7%
    uint8 constant CHANCE_HAS_TEXTURE_SCALES = 18;   // 11%
    uint8 constant CHANCE_HAS_TEXTURE_WOOD = 32;     // 14%
    uint8 constant CHANCE_HAS_TEXTURE_PAPER = 49;    // 17%
    uint8 constant CHANCE_HAS_TEXTURE_KNIT = 66;     // 17%
    uint8 constant CHANCE_HAS_TEXTURE_CRACKED = 83;  // 17%
    uint8 constant CHANCE_HAS_TEXTURE_FUR = 100;     // 17%


    /*
    ##################
    # Modifiers #
    ##################
    */
    modifier whenMintActive() {
        require(confMintActive, "Minting is not available");
        _;
    }

    constructor() public ERC721("Chronotoken", "CTKN")
    {
        tokenCounter = 0;
        rc = 0;
        randomnessFee = 0.1 * 10 ** 18;
        confMintActive = false;
    }

    /*
    #########################
    # Configuration Setters #
    #########################
    */
    
    function setDailyMax(uint16 newDailyMax) public onlyOwner {
        confMaxDailyMints = newDailyMax;
    }

    function setPublicMintActive(bool isActive) public onlyOwner {
        confMintActive = isActive;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    /*
    ##########################
    # Contract Functionality #
    ##########################
    */

    /**
      * @notice The core minting function. Will mint a random rarity coin on today's date with a random year.
      * @notice A random effect and texture of the coin is possible!
      * @param numberOfTokens The number of desired dates to mint.
      */
    function mint(uint16 numberOfTokens)
        external
        payable
        whenMintActive
    {
        require(
            numberOfTokens > 0, 
            "Must mint at least one date"
        );

        require(
            numberOfTokens <= getAllowedMintCount(),
            "Minting would exceed allowed minted dates per day"
        );

        uint256 costToMint = getMintPrice() * numberOfTokens;
        require(
            costToMint <= msg.value, 
            "Ether sent is not sufficient"
        );

        uint256 timestamp = now;

        // If we haven't minted yet today, set mintsToday to 0
        if (DateTimeLibrary.getDay(timestamp) != lastDayMinted) {
            lastDayMinted = DateTimeLibrary.getDay(timestamp);
            mintsToday = 0;
        }

        // Increment counters first
        mintsToday += numberOfTokens;
        tokenCounter += numberOfTokens;

        // Mint the tokens requested
        for (uint16 i = 0; i < numberOfTokens; i++) {
            // requestRandomness calls back to fulfillRandomness, which mints the token
            uint256 pseudoRandomNumber = getPseudoRandomNumber(msg.sender, now, tokenCounter - numberOfTokens + i);
            RequestMintData memory mintData = RequestMintData({
                sender: msg.sender,
                timestamp: timestamp,
                dailyMint: mintsToday - numberOfTokens + i + 1,
                tokenId: tokenCounter - numberOfTokens + i
            });

            completeMint(mintData, pseudoRandomNumber);
        }

        // Send remainder back
        if (msg.value > costToMint) {
            Address.sendValue(payable(msg.sender), msg.value - costToMint);
        }
    }

    /**
      * @notice Gets the number of mints allowed today for a given address.
      * @return uint16 The number of mints left.
      */
    function getAllowedMintCount() public view whenMintActive returns (uint16) {
        // If it's a new day but counters haven't reset yet, then just return the limit
        if (DateTimeLibrary.getDay(now) != lastDayMinted) {
            return confMaxDailyMints;
        } else {
            return confMaxDailyMints - mintsToday;
        }
    }

    /**
      * @notice Gets a random number given the current accessible variables.
      * @param sender The address of the sender.
      * @param timestamp The timestamp when mint was executed.
      * @param tokenId The token ID for the random number.
      * @return uint256 A random number.
      */
    function getPseudoRandomNumber(address sender, uint256 timestamp, uint256 tokenId) private returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encode(blockhash(block.number - 1), timestamp, sender, tokenId, rc)));
        rc = rc + randomNumber % 100;
        return randomNumber;
    }

    /**
      * @notice Gets the number of seconds left until the dutch auction reset.
      * @return uint The number of seconds left.
      */
    function secondsUntilAuctionReset() public view whenMintActive returns (uint32) {
        uint totalSecondsInADay = 60 * 60 * 24;
        uint secondsPassedToday = now % totalSecondsInADay;

        return uint32(totalSecondsInADay - secondsPassedToday);
    }

    /**
      * @notice Gets the current price of minting a date using a dutch auction method.
      * @return uint The price in ether of minting a date.
      */
    function getMintPrice() public view whenMintActive returns (uint256) {
        uint totalSecondsInADay = 60 * 60 * 24;
        uint startEndPriceDifference = MINT_START_PRICE - MINT_END_PRICE;
        uint precision = 100000;
        
        uint percentage = ((secondsUntilAuctionReset() * precision) / (totalSecondsInADay));
        return MINT_END_PRICE + ((startEndPriceDifference * percentage) / precision);
    }

    /**
      * @notice Sets the tokenURI of a given tokenID. 
      * @param tokenId The token ID to set the URI for.
      * @param _tokenURI The new tokenURI.
      */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
      * @notice The actual method that generates the token and assigns random properties.
      * @param mintData The data for the current mint request.
      * @param randomNumber The oracle's generated random number.
      */
    function completeMint(RequestMintData memory mintData, uint256 randomNumber) internal {
        _safeMint(mintData.sender, mintData.tokenId);

        // Get date
        uint16 year = 0;
        uint8 month = 0;
        uint8 day = 0;
        (year, month, day, randomNumber) = getDateAndRandomYear(mintData.timestamp, randomNumber);

        bool shiny = false;

        // If this is the first mint, set it to shiny
        if (mintData.dailyMint == 1) {
            shiny = true;
        }

        uint dateKey = (year * 10 ** 6 + month * 10 ** 2 + day);
        
        // Get rarity
        Rarity rarity = Rarity.BRONZE;
        uint32 index = 0;
        (rarity, index, randomNumber) = getRandomRarity(mintData.dailyMint, dateKey, randomNumber);

        // Get effect and texture
        Effect effect = Effect.NONE;
        Texture texture = Texture.NONE;
        (effect, texture, randomNumber) = getRandomEffectAndTexture(mintData.dailyMint, randomNumber);
        
        // Add to chain
        tokenIdToChronotoken[mintData.tokenId] = Chronotoken({
            rarity: rarity,
            year: year,
            month: month,
            day: day,
            index: index,
            effect: effect,
            texture: texture,
            shiny: shiny
        });
    }

    /*
    #########################
    # Generation Methods #
    #########################
    */

    /**
      * @notice Given a multiple of 10 and an existing random number, return a random number between 0 and that magnitude. 
      * @dev This function takes the last N digits of the random number and returns a new number to use for the next call.
      * @dev There is some assumption here that our random number is big enough to be used here multiple times, but it
      * @dev  saves us calls to an oracle.
      * @param magnitude The multiple of 10 to use for this random number
      * @param randomNumber The current "pointer" for the random number
      * @return uint The desired random number
      * @return uint256 A "pointer" of the random number to utilize next call
      */
    function getSegmentedRandom(uint magnitude, uint256 randomNumber) private returns (uint, uint256) {
        uint desiredRandom = randomNumber % magnitude;
        randomNumber /= magnitude;
        return (desiredRandom, randomNumber);
    }

    /**
      * @notice Get a weighted random decade (0-9) to subtract based on constants defined above.
      * @param randomNumber The current "pointer" for the random number
      * @return uint The decade to subtract
      * @return uint256 A "pointer" of the random number to utilize next call
      */
    function getRandomDecadeToSubtract(uint256 randomNumber) private returns (uint, uint256) {
        // Random number between 0 and 999, inclusive
        uint randomDecadeNumber = 0;
        (randomDecadeNumber, randomNumber) = getSegmentedRandom(1000, randomNumber);
        
        // Find the decade count to subtract
        uint decadeToSub = 0;
        if (randomDecadeNumber < CHANCE_YEAR_SUB_9_DECADE) {
            decadeToSub = 9;
        } else if (randomDecadeNumber < CHANCE_YEAR_SUB_8_DECADE) {
            decadeToSub = 8;
        } else if (randomDecadeNumber < CHANCE_YEAR_SUB_7_DECADE) {
            decadeToSub = 7;
        } else if (randomDecadeNumber < CHANCE_YEAR_SUB_6_DECADE) {
            decadeToSub = 6;
        } else if (randomDecadeNumber < CHANCE_YEAR_SUB_5_DECADE) {
            decadeToSub = 5;
        } else if (randomDecadeNumber < CHANCE_YEAR_SUB_4_DECADE) {
            decadeToSub = 4;
        } else if (randomDecadeNumber < CHANCE_YEAR_SUB_3_DECADE) {
            decadeToSub = 3;
        } else if (randomDecadeNumber < CHANCE_YEAR_SUB_2_DECADE) {
            decadeToSub = 2;
        } else if (randomDecadeNumber < CHANCE_YEAR_SUB_1_DECADE) {
            decadeToSub = 1;
        }

        return (decadeToSub, randomNumber);
    }

    /**
      * @notice Get a random year within a certain decade being subtracted from the current year.
      * @param thisYear The current year
      * @param decadeToSub The decade subtracted from thisYear to find a random year within
      * @param randomNumber The current "pointer" for the random number
      * @return uint The random year within the decade subtracted from this year
      * @return uint256 A "pointer" of the random number to utilize next call
      */
    function getRandomYearWithinDecade(uint thisYear, uint decadeToSub, uint256 randomNumber) private returns (uint, uint256) {
        // Random number between 0 and 9, inclusive
        uint randomYearNumber = 0;
        (randomYearNumber, randomNumber) = getSegmentedRandom(10, randomNumber);

        // Find actual year we want to return
        uint yearsToSub = (decadeToSub * 10 + randomYearNumber);
        uint year = thisYear - yearsToSub;
        
        return (year, randomNumber);
    }

    /**
      * @notice Get today's date on a random, weighted year. Will only return valid dates.
      * @param randomNumber The current "pointer" for the random number
      * @return uint The random year
      * @return uint Today's month
      * @return uint Today's day of the month
      * @return uint256 A "pointer" of the random number to utilize next call
      */
    function getDateAndRandomYear(uint256 timestamp, uint256 randomNumber) private returns (uint16, uint8, uint8, uint256) {
        // Get date
        uint thisYear = DateTimeLibrary.getYear(timestamp);
        uint month = DateTimeLibrary.getMonth(timestamp);
        uint day = DateTimeLibrary.getDay(timestamp);

        // decadeToSub isn't actually a "decade", but just a multiple of 10 to subtract from this year
        uint decadeToSub = 0;
        (decadeToSub, randomNumber) = getRandomDecadeToSubtract(randomNumber);

        // Find a year within (thisYear - (decadeToSub * 10 + 9)) and (thisYear - (decadeToSub * 10))
        //   i.e. current year is 2021, decade to sub is 5
        //        result would be a year between 1962 and 1971, inclusive
        uint year = 0;
        (year, randomNumber) = getRandomYearWithinDecade(thisYear, decadeToSub, randomNumber);
        while (!DateTimeLibrary.isValidDate(year, month, day)) {
            (year, randomNumber) = getRandomYearWithinDecade(thisYear, decadeToSub, randomNumber);
        }

        return (uint16(year), uint8(month), uint8(day), randomNumber);
    }

    /**
      * @notice Get a random rarity and that rarity's current count for the given dateKey.
      * @param dailyMint The number mint this token is for the day
      * @param dateKey The dateKey for the given date/year
      * @param randomNumber The current "pointer" for the random number
      * @return Rarity The random rarity
      * @return uint The rarity's current count for the given dateKey
      * @return uint256 A "pointer" of the random number to utilize next call
      */
    function getRandomRarity(uint16 dailyMint, uint dateKey, uint256 randomNumber) private returns (Rarity, uint32, uint256) {
        // Random number between 0 and 99, inclusive
        uint randomRarityNumber = 0;
        uint chanceBoost = 0;
        (randomRarityNumber, randomNumber) = getSegmentedRandom(100, randomNumber);

        // First and last mint have elevated chances of diamond
        if (dailyMint == 1 || dailyMint == confMaxDailyMints) {
            chanceBoost = CHANCE_RARITY_DIAMOND_BOOST_FIRST_OR_LAST;
        }

        // Find the rarity
        Rarity rarity = Rarity.BRONZE;
        if (randomRarityNumber < CHANCE_RARITY_DIAMOND + chanceBoost) {
            rarity = Rarity.DIAMOND;
        } else if (randomRarityNumber < CHANCE_RARITY_GOLD + chanceBoost) {
            rarity = Rarity.GOLD;
        } else if (randomRarityNumber < CHANCE_RARITY_SILVER + chanceBoost) {
            rarity = Rarity.SILVER;
        }

        uint32 index = dateToRarityCount[dateKey][uint8(rarity)] + 1;
        dateToRarityCount[dateKey][uint8(rarity)] = index;

        return (rarity, index, randomNumber);
    }

    /**
      * @notice Get the effect for the given randomNumber100 and the chanceOfEffect.
      * @param chanceOfEffect The percent chance that an effect should occur.
      * @param randomNumber The current "pointer" for the random number
      * @return Effect The desired effect.
      */
    function getEffectFromRandomNumber(uint chanceOfEffect, uint randomNumber) private returns (Effect, uint256) {
        Effect effect = Effect.NONE;

        uint randomNumber100 = 0;
        (randomNumber100, randomNumber) = getSegmentedRandom(100, randomNumber);

        if (randomNumber100 < chanceOfEffect) {
            (randomNumber100, randomNumber) = getSegmentedRandom(100, randomNumber);

            if (randomNumber100 < CHANCE_HAS_EFFECT_FLAME) {
                effect = Effect.FLAME;
            } else if (randomNumber100 < CHANCE_HAS_EFFECT_PLASMA) {
                effect = Effect.PLASMA;
            } else if (randomNumber100 < CHANCE_HAS_EFFECT_PAINT) {
                effect = Effect.PAINT;
            } else if (randomNumber100 < CHANCE_HAS_EFFECT_CONFETTI) {
                effect = Effect.CONFETTI;
            } else if (randomNumber100 < CHANCE_HAS_EFFECT_LIGHTNING) {
                effect = Effect.LIGHTNING;
            } else if (randomNumber100 < CHANCE_HAS_EFFECT_VINES) {
                effect = Effect.VINES;
            } else if (randomNumber100 < CHANCE_HAS_EFFECT_SMOKE) {
                effect = Effect.SMOKE;
            } 
        }

        return (effect, randomNumber);
    }

    /**
      * @notice Get the texture for the given randomNumber100 and the chanceOfTexture.
      * @param chanceOfTexture The percent chance that a texture should occur.
      * @param randomNumber The current "pointer" for the random number
      * @return Texture The desired texture.
      */
    function getTextureFromRandomNumber(uint chanceOfTexture, uint randomNumber) private returns (Texture, uint256) {
        Texture texture = Texture.NONE;
        
        uint randomNumber100 = 0;
        (randomNumber100, randomNumber) = getSegmentedRandom(100, randomNumber);

        if (randomNumber100 < chanceOfTexture) {
            (randomNumber100, randomNumber) = getSegmentedRandom(100, randomNumber);

            if (randomNumber100 < CHANCE_HAS_TEXTURE_CIRCUIT) {
                texture = Texture.CIRCUIT;
            } else if (randomNumber100 < CHANCE_HAS_TEXTURE_SCALES) {
                texture = Texture.SCALES;
            } else if (randomNumber100 < CHANCE_HAS_TEXTURE_WOOD) {
                texture = Texture.WOOD;
            } else if (randomNumber100 < CHANCE_HAS_TEXTURE_PAPER) {
                texture = Texture.PAPER;
            } else if (randomNumber100 < CHANCE_HAS_TEXTURE_KNIT) {
                texture = Texture.KNIT;
            } else if (randomNumber100 < CHANCE_HAS_TEXTURE_CRACKED) {
                texture = Texture.CRACKED;
            } else if (randomNumber100 < CHANCE_HAS_TEXTURE_FUR) {
                texture = Texture.FUR;
            }
        }

        return (texture, randomNumber);
    }

    /**
      * @notice Get a random effect and texture.
      * @param dailyMint The number mint this token is for the day
      * @param randomNumber The current "pointer" for the random number
      * @return Effect The random effect
      * @return Texture The random texture
      * @return uint256 A "pointer" of the random number to utilize next call
      */
    function getRandomEffectAndTexture(uint16 dailyMint, uint256 randomNumber) private returns (Effect, Texture, uint256) {
        uint chanceOfEffect = CHANCE_HAS_EFFECT;
        uint chanceOfTexture = CHANCE_HAS_TEXTURE;

        // First and last mint have elevated chances
        if (dailyMint == 1 || dailyMint == confMaxDailyMints) {
            chanceOfEffect = CHANCE_HAS_EFFECT_FIRST_OR_LAST;
            chanceOfTexture = CHANCE_HAS_TEXTURE_FIRST_OR_LAST;
        }

        Effect effect = Effect.NONE;
        (effect, randomNumber) = getEffectFromRandomNumber(chanceOfEffect, randomNumber);
 
        // Increase the chances of getting a texture if an effect is set
        if (effect != Effect.NONE) {
            chanceOfTexture = CHANCE_ADDS_TEXTURE_IF_EFFECT_EXISTS;
        }

        Texture texture = Texture.NONE;
        (texture, randomNumber) = getTextureFromRandomNumber(chanceOfTexture, randomNumber);

        // Increase the chances of getting an effect if a texture is set
        if (texture != Texture.NONE && effect == Effect.NONE) {
            chanceOfEffect = CHANCE_ADDS_EFFECT_IF_TEXTURE_EXISTS;
            (effect, randomNumber) = getEffectFromRandomNumber(chanceOfEffect, randomNumber);
        }

        return (effect, texture, randomNumber);
    }
}
