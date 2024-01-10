// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Counters.sol";
import "./ERC721.sol";
import "./Ownable.sol";

import "./Encoding.sol";

import "./DegenFetcherInterface.sol";
import "./Metadata.sol";
import "./SVG.sol";
import "./BokkyPooBahsDateTimeContract.sol";

contract DegenBlues is ERC721, Ownable {
    enum Coin{ ETH, BTC }
    struct FeedInfo {
        address feed;
        uint dataPointsToFetchPerDay;
    }

    uint80 constant MEASURES = 3;
    uint80 constant PERPETUAL_JAM_DAYS = 2;

    BokkyPooBahsDateTimeContract dates;
    Metadata metadata;
    DegenFetcherInterface fetcher;
    SVG svg;
    uint80 constant SECONDS_PER_DAY = 3600*24;
    uint mintPrice = 0.15 * 10**18; 
    bool publicMintingAllowed = false;
    FeedInfo priceFeedETH;
    FeedInfo priceFeedBTC;
    mapping(address => uint8) private allowList;


    constructor(address dateTimeAddress, address priceFeedAddressETH, address priceFeedAddressBTC, address fetcherAddress) ERC721("Degen Blues", "DGB") {
        fetcher = DegenFetcherInterface(address(fetcherAddress));
        dates = BokkyPooBahsDateTimeContract(address(dateTimeAddress));
        // dates = new BokkyPooBahsDateTimeContract();
        priceFeedETH = FeedInfo(
            address(priceFeedAddressETH),
            8*MEASURES
        );
        priceFeedBTC = FeedInfo(
            address(priceFeedAddressBTC),
            4*MEASURES
        );
        metadata = new Metadata(dates);
        svg = new SVG(metadata);

        // Mint Edition Zero
        _safeMint(msg.sender, 0);
    }

    // Determines whether members of the public can mint
    function setPublicMintingAllowed(bool _allow) onlyOwner external {
        publicMintingAllowed = _allow;
    }

    function getPublicMintingAllowed() external view returns (bool) {
        return publicMintingAllowed;
    }

    /* Returns 0 if sender is not specifically whitelisted
     * otherwise returns the number of mints allowed */
    function getMyMintingQuota() external view returns (int) {
        return int256(int8(allowList[msg.sender]));
    }

    /* Returns 0 if sender is not specifically whitelisted
     * otherwise returns the number of mints allowed */
    function getMintingQuotaFor(address addr) external view returns (int) {
        return int256(int8(allowList[addr]));
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function getFeedInfoForCoin(Coin coin) internal view returns (FeedInfo memory) {
        if (coin == Coin.ETH) {
            return priceFeedETH;
        } else {
            return priceFeedBTC;
        }
    }

    function getStartOfDay(uint timestamp) internal view returns (uint) {
        uint year = dates.getYear(timestamp);
        uint month = dates.getMonth(timestamp);
        uint day = dates.getDay(timestamp);
        return dates.timestampFromDate(year,month,day);
    }

	function getNFTPrice() public view returns (uint) /*wei*/ {
		return mintPrice; 
	}

    function setNFTPrice(uint newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function withdraw() public onlyOwner payable {
        payable(owner()).transfer(payable(address(this)).balance);
    }

    uint constant EPOCH_DATE = 1601942400; /* Oct 6, 2020 */

    function mint(uint fromTimestamp) public payable returns (uint256) {
        return mintTo(fromTimestamp, msg.sender);
    }

    function mintTo(uint fromTimestamp, address recipient) public payable returns (uint256) {
        if (msg.sender != owner()) {
            require(getNFTPrice() <= msg.value, "Not enough ether sent");
            require((allowList[msg.sender] > 0) || publicMintingAllowed, "Minting disabled");
        }

        if (fromTimestamp > 0) {
            // Verify that fromTimestamp is the beginning of a day between EPOCH_DATE and yesterday
            require(fromTimestamp == getStartOfDay(fromTimestamp));
            require(fromTimestamp + SECONDS_PER_DAY < block.timestamp);
            require(fromTimestamp >= EPOCH_DATE);
        } 

        if (!publicMintingAllowed && (allowList[msg.sender] > 0)) {
            allowList[msg.sender] -= 1;
        }

        uint256 newItemId = tokenIdForDate(fromTimestamp);

        _safeMint(recipient, newItemId);
        return newItemId;
    }

    function fetchCoinPriceData(uint256 fromTimestamp, uint80 daysToFetch, Coin coin) internal view returns (int32[] memory) {
        FeedInfo memory feedInfo = getFeedInfoForCoin(coin);
        return fetcher.fetchPriceDataForFeed(feedInfo.feed, fromTimestamp, daysToFetch, feedInfo.dataPointsToFetchPerDay);
    }    

    function perpetualDataStartTime() internal view returns (uint256) {
        return (block.timestamp - PERPETUAL_JAM_DAYS*SECONDS_PER_DAY);
    }

    // Will fetch perpetual data if tokenId is zero
    function getPriceDataForCoin(uint256 tokenId, Coin coin) internal view returns (int32[] memory) {
        uint256 fromTimestamp = dateForTokenId(tokenId);
        uint80 daysToFetch;
        if (tokenId == 0) {
            daysToFetch = PERPETUAL_JAM_DAYS;
        } else {
            daysToFetch = 1;
        }
        return fetchCoinPriceData(fromTimestamp, daysToFetch, coin);
    }

    struct DayData {
        uint fromTimestamp;
        address owner;
        uint256 tokenId;
        string ethData;
        string btcData;
        string ethStats;
    }

    function getAllDataForDays(uint256[] memory fromTimestamps) external view returns (DayData[] memory) {
        DayData[] memory dayData = new DayData[](fromTimestamps.length);
        for (uint i = 0; i < fromTimestamps.length; i++) {
            dayData[i] = getAllDataForDay(fromTimestamps[i]);
        }
        return dayData;
    }

    function getAllDataForGoldMaster() public view returns (DayData memory) {
        int32[] memory ethData = getPriceDataForCoin(0, Coin.ETH);
        int32[] memory btcData = getPriceDataForCoin(0, Coin.BTC);
        string memory ethDataString = Encoding.encode(ethData);
        string memory btcDataString = Encoding.encode(btcData);
        
        address owner = _exists(0) ? ownerOf(0) : address(0);

        return DayData(0, owner, 0, ethDataString, btcDataString, '');

    }

    function tokenIdForDate(uint256 fromTimestamp) internal pure returns (uint256 tokenId) {
        if (fromTimestamp == 0) {
            return 0;
        } else {
            return 1 + (fromTimestamp - EPOCH_DATE)/SECONDS_PER_DAY;
        }
    }

    function dateForTokenId(uint256 tokenId) internal view returns (uint256 fromTimestamp) {
        if (tokenId == 0) {
            return perpetualDataStartTime();
        } else {
            return EPOCH_DATE + SECONDS_PER_DAY*(tokenId - 1);
        }
    }

    function getAllDataForDay(uint256 fromTimestamp) public view returns (DayData memory) {
        require(fromTimestamp == getStartOfDay(fromTimestamp));
        require(fromTimestamp > 0);

        int32[] memory ethData = fetchCoinPriceData(fromTimestamp, 1, Coin.ETH);
        int32[] memory btcData = fetchCoinPriceData(fromTimestamp, 1, Coin.BTC);
        string memory ethDataString = Encoding.encode(ethData);
        string memory btcDataString = Encoding.encode(btcData);
        string memory ethStats = metadata.getAttributes(ethData, fromTimestamp);

        uint256 tokenId = tokenIdForDate(fromTimestamp);
        address owner = _exists(tokenId) ? ownerOf(tokenId) : address(0);

        return DayData(fromTimestamp, owner, tokenId, ethDataString, btcDataString, ethStats);
    }


    function getSVGImageWith(uint256 tokenId, int32[] memory ethPriceData) internal view returns (string memory) {
        return tokenId == 0 ? svg.masterImageWith() : svg.printImageWith(ethPriceData, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory name = metadata.getNameForTokenId(tokenId);
        uint fromTimestamp = dateForTokenId(tokenId);
        string memory description = metadata.descriptionForTokenId(tokenId, fromTimestamp);
        string memory svgImage;
        string memory attributesStr;

        string memory animationUrl;
        {
            int32[] memory ethPriceData = getPriceDataForCoin(tokenId, Coin.ETH);
            int32[] memory btcPriceData = getPriceDataForCoin(tokenId, Coin.ETH);
            string memory ethPriceDataString = Encoding.encode(ethPriceData);
            svgImage = getSVGImageWith(tokenId, ethPriceData);
            attributesStr = metadata.getAttributes(ethPriceData, fromTimestamp);
            animationUrl = metadata.getAnimationUrl(ethPriceDataString, Encoding.encode(btcPriceData));
        }

        return string(
            abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                abi.encodePacked(
                    '{',
                    '"description":"', description,
                    '"',
                    unicode', "name":"', name,
                    '"',
                    ', "external_url":"',
                    'https://degenblues.xyz/?t=',
                    Encoding.uint2str(tokenId),
                    '"',
                    ', "image":"',
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(svgImage)),
                    '"',
                    ', "animation_url":"',
                    animationUrl,
                    '"',
                    ', "attributes": ', attributesStr,
                    '}'
                )
                )
            )
            )
        );
    }


    function contractURI() external pure returns (string memory) {
        return 'ar://9Ss1lqwIUVtl_WXqp-bDfx-C4fK6O--DP9Ac0sf6ewM';
        // Arweave version of 'https://degenblues.xyz/projects/degen-blues/contract.json';
    }
}
