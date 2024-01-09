// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.10;

import "./AggregatorV3Interface.sol";
import "./Ownable.sol";
import "./ERC721.sol";

import "./console.sol";

// CONSTANTS
int256 constant PERCENTAGE_FACTOR = 10_000;

enum Mood {
    TO_THE_MOON,
    BULLISH,
    STABLE,
    PANIC,
    APPLYING_TO_MC_DONALDS
}

contract ETHodlerNft is ERC721, Ownable {
    AggregatorV3Interface public immutable priceFeed;

    mapping(Mood => string) public pfps;
    mapping(uint256 => mapping(Mood => string)) public customPfps;
    mapping(uint256 => bool) hasCustomPfp;

    constructor(address chainlinkOracle, string[] memory defaultPictures)
        ERC721("ETH Hodler Nft", "HODL")
    {
        require(defaultPictures.length == 5, "IPL"); // Incorrect pictures array length
        priceFeed = AggregatorV3Interface(chainlinkOracle);
        for (uint256 i = 0; i < 5; i++) {
            pfps[Mood(i)] = defaultPictures[i];
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
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

        Mood mood = getMarketMood();
        return hasCustomPfp[tokenId] ? customPfps[tokenId][mood] : pfps[mood];
    }

    function customize(
        uint256 tokenId,
        string memory toTheMoon,
        string memory bullish,
        string memory stable,
        string memory panic,
        string memory applyingToMacDonalds
    ) external {
        require(
            msg.sender == ownerOf(tokenId),
            "OCC" // Only owners Could Customize tokens
        );
        require(!hasCustomPfp[tokenId], "TAC"); // Token is already customized
        customPfps[tokenId][Mood.TO_THE_MOON] = toTheMoon;
        customPfps[tokenId][Mood.BULLISH] = bullish;
        customPfps[tokenId][Mood.STABLE] = stable;
        customPfps[tokenId][Mood.PANIC] = panic;
        customPfps[tokenId][Mood.APPLYING_TO_MC_DONALDS] = applyingToMacDonalds;
        hasCustomPfp[tokenId] = true;
    }

    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    /// @dev Returns market mood for the last 24h
    /// @return mood (enum)
    function getMarketMood() public view returns (Mood) {
        int256 priceChange = getPriceChange();
        if (priceChange > 10_00) {
            return Mood.TO_THE_MOON;
        }

        if (priceChange > 3_00) {
            return Mood.BULLISH;
        }

        if (priceChange < -10_00) {
            return Mood.APPLYING_TO_MC_DONALDS;
        }

        if (priceChange < -3_00) {
            return Mood.PANIC;
        }

        return Mood.STABLE;
    }

    /// @dev Calculates ETH / USD price deviations for the last 24h
    /// @return diff - signed change in percentage format (x10.000)
    function getPriceChange() public view returns (int256) {
        (uint80 roundID, int256 priceNow, , uint256 timeStampNow, ) = priceFeed
            .latestRoundData();

        roundID -= 12; // Assuming that ETH price was updated often than each 2 hrs
        while (true) {
            (, int256 price, , uint256 timeStamp, ) = priceFeed.getRoundData(
                roundID
            );

            if (timeStamp + 1 days < timeStampNow) {
                return (PERCENTAGE_FACTOR * (priceNow - price)) / price;
            }

            roundID--;
        }
    }
}
