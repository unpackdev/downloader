// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: TedsLittleDream
/// @animator: Kenson
/// @author: proteinNFT with WestCoastNFT and special thanks to Manifold

import "./Strings.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./DateTime.sol";

bytes32 constant SUPPORT_ROLE = keccak256("SUPPORT");

struct range {
   uint256 min;
   uint256 max;
}

contract LittleRedRidingHood is ERC721Enumerable, AccessControl, ReentrancyGuard, DateTime {

    uint public constant MAX_PUBLIC_MINT = 15;
    uint public constant PRICE_PER_TOKEN = 0.3 ether;
    uint constant REDEMPTION_RATE = 3;
    uint constant REDEMPTION_MAX = 60;
    uint constant MAX_TOKENS = 100;
    
    using Strings for uint;
    using Strings for int;

    bool public burnIsActive;
    bool public saleIsActive;
    
    uint8 constant NUM_WEATHER_CONDITIONS = 6;
    uint8 constant NUM_SEASONS = 4;
    
    string private BASE_URI;

    enum WeatherCondition { Default, Flowers, Rain, Sun, Thunder, Cloudy, Snow, Blizzard }
    enum Season { Spring, Summer, Autumn, Winter }
    enum Hemisphere { Northern, Southern }

    mapping(Season => mapping(WeatherCondition => string)) private weatherConditionStrings;
    mapping(Season => string) private seasonStrings;
    mapping(Hemisphere => string) private hemisphereStrings;

    mapping(Season => mapping(WeatherCondition => uint8)) internal weights;

    mapping(uint => int) public offsets;
    mapping(uint => Hemisphere) public hemispheres;

    mapping(address => range[]) private _approvedTokenRange;

    constructor(string memory _baseURI) ERC721("Little Red Riding Hood v2", "WOLF") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPORT_ROLE, msg.sender);

        BASE_URI = _baseURI;

        weatherConditionStrings[Season.Spring][WeatherCondition.Default] = unicode"風和日麗";
        weatherConditionStrings[Season.Spring][WeatherCondition.Flowers] = unicode"春暖花開";
        weatherConditionStrings[Season.Spring][WeatherCondition.Rain] = unicode"和風細雨";

        weatherConditionStrings[Season.Summer][WeatherCondition.Default] = unicode"鳥語蟬鳴";
        weatherConditionStrings[Season.Summer][WeatherCondition.Sun] = unicode"赤日炎炎";
        weatherConditionStrings[Season.Summer][WeatherCondition.Rain] = unicode"和風細雨";
        weatherConditionStrings[Season.Summer][WeatherCondition.Thunder] = unicode"雷電交加";

        weatherConditionStrings[Season.Autumn][WeatherCondition.Default] = unicode"秋色宜人";
        weatherConditionStrings[Season.Autumn][WeatherCondition.Rain] = unicode"秋雨連綿 ";
        weatherConditionStrings[Season.Autumn][WeatherCondition.Cloudy] = unicode"雲霧迷濛";

        weatherConditionStrings[Season.Winter][WeatherCondition.Default] = unicode"雪花如席";
        weatherConditionStrings[Season.Winter][WeatherCondition.Snow] = unicode"雪飄如絮";
        weatherConditionStrings[Season.Winter][WeatherCondition.Blizzard] = unicode"大雪紛飛";

        seasonStrings[Season.Spring] = unicode"春";
        seasonStrings[Season.Summer] = unicode"夏";
        seasonStrings[Season.Autumn] = unicode"秋";
        seasonStrings[Season.Winter] = unicode"冬";

        hemisphereStrings[Hemisphere.Northern] = "Northern";
        hemisphereStrings[Hemisphere.Southern] = "Southern";

        weights[Season.Spring][WeatherCondition.Default] = 3;
        weights[Season.Spring][WeatherCondition.Flowers] = 1;
        weights[Season.Spring][WeatherCondition.Rain] = 2;

        weights[Season.Summer][WeatherCondition.Default] = 3;
        weights[Season.Summer][WeatherCondition.Sun] = 2;
        weights[Season.Summer][WeatherCondition.Rain] = 2;
        weights[Season.Summer][WeatherCondition.Thunder] = 1;

        weights[Season.Autumn][WeatherCondition.Default] = 2;
        weights[Season.Autumn][WeatherCondition.Rain] = 1;
        weights[Season.Autumn][WeatherCondition.Cloudy] = 1;

        weights[Season.Winter][WeatherCondition.Default] = 5;
        weights[Season.Winter][WeatherCondition.Snow] = 3;
        weights[Season.Winter][WeatherCondition.Blizzard] = 1;
    }

    function setBaseURI(string memory baseURI_) external onlyRole(SUPPORT_ROLE) {
        BASE_URI = baseURI_;
    }

    function setWeatherConditionString(Season season, WeatherCondition wc, string memory s) external onlyRole(SUPPORT_ROLE) {
        weatherConditionStrings[season][wc] = s;
    }
    
    function setSeasonString(Season season, string memory s) external onlyRole(SUPPORT_ROLE) {
        seasonStrings[season] = s;
    }
    
    function setHemisphereString(Hemisphere h, string memory s) external onlyRole(SUPPORT_ROLE) {
        hemisphereStrings[h] = s;
    }
    
    function setWeight(Season season, WeatherCondition wc, uint8 weight) external onlyRole(SUPPORT_ROLE) {
        weights[season][wc] = weight;
    }

    function validOffset(int offset) public pure returns(bool) {
        return (offset >= -14 && offset <= 14);
    }

    function setOffset(uint256 tokenId, int offset) public {
        require(msg.sender == ownerOf(tokenId), "Must be the token owner.");
        require(validOffset(offset), "Invalid offset");
        offsets[tokenId] = offset;
    }

    function setHemisphere(uint256 tokenId, Hemisphere hemisphere) public {
        require(msg.sender == ownerOf(tokenId), "Must be the token owner.");
        hemispheres[tokenId] = hemisphere;
    }

    function randomInt(bytes memory seed, uint _modulus) public pure returns(uint) {
        return uint(keccak256(seed)) % _modulus;
    }

    function getSeed(uint month, uint day, uint year, uint256 tokenId) public pure returns(bytes memory) {
        return abi.encodePacked(month, day, year, tokenId);
    }

    function weightedRandom(bytes memory seed, mapping(WeatherCondition => uint8) storage weights_)
        internal view returns(WeatherCondition) {
        uint num_choices = 0;
        for(uint i = 0; i < NUM_WEATHER_CONDITIONS; i++) {
            num_choices += weights_[WeatherCondition(i)];
        }
        uint rnd = randomInt(seed, num_choices);
        for(uint i = 0; i < NUM_WEATHER_CONDITIONS; i++) {
            if(rnd < weights_[WeatherCondition(i)]) {
                return WeatherCondition(i);
            }
            rnd -= weights_[WeatherCondition(i)];
        }
        return(WeatherCondition.Sun);
    }

    function monthToSeason(Hemisphere hemisphere, uint8 month) public pure returns(Season) {
        if (hemisphere == Hemisphere.Northern) {
            if (month <= 2 || month == 12) return Season.Winter;
            if (month <= 5) return Season.Spring;
            if (month <= 8) return Season.Summer;
            return Season.Autumn;
        } else {
            if (month <= 2 || month == 12) return Season.Summer;
            if (month <= 5) return Season.Autumn;
            if (month <= 8) return Season.Winter;
            return Season.Spring;
        }
    }

    function getWeather(uint8 month, uint8 day, uint16 year, Season season, uint256 tokenId)
        public view returns(WeatherCondition) {
        return weightedRandom(getSeed(month, day, year, tokenId), weights[season]);
    }

    function currentSeason(uint256 tokenId) public view returns(Season) {
        return monthToSeason(hemispheres[tokenId], getMonth(block.timestamp));
    }

    function currentWeather(uint256 tokenId) public view returns(WeatherCondition) {
        uint ts = block.timestamp;
        uint8 month = getMonth(ts);
        uint8 day = getDay(ts);
        uint16 year = getYear(ts);
        Season season = monthToSeason(hemispheres[tokenId], month);
        return getWeather(month, day, year, season, tokenId);
    }

    function setBurnState(bool _active) external onlyRole(SUPPORT_ROLE) {
        burnIsActive = _active;
    }

    function setSaleState(bool _active) external onlyRole(SUPPORT_ROLE) {
        saleIsActive = _active;
    }

    function reserve(uint256 amount) external onlyRole(SUPPORT_ROLE) {
        uint startingIndex = totalSupply();
        for (uint i; i < amount; i++) {
            _safeMint(msg.sender, startingIndex + i);
        }
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function purchase(uint256 amount, Hemisphere hemisphere, int offset) external payable nonReentrant {
        uint ts = totalSupply();
        require(saleIsActive, "Sale must be active to purchase tokens");
        require(amount < MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + amount < MAX_TOKENS, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * amount == msg.value, "Ether value sent is not correct");
        require(validOffset(offset), "Invalid offset");

        for (uint i; i < amount; i++) {
            uint tokenId = ts + i;
            _safeMint(msg.sender, tokenId);
            hemispheres[tokenId] = hemisphere;
            offsets[tokenId] = offset;
        }
    }

    function updateApprovedTokenRanges(address contract_, uint256[] memory minTokenIds, uint256[] memory maxTokenIds) public onlyRole(SUPPORT_ROLE) {
        require(minTokenIds.length == maxTokenIds.length, "Redeem: Invalid input parameters");
        
        uint existingRangesLength = _approvedTokenRange[contract_].length;
        for (uint i = 0; i < existingRangesLength; i++) {
            _approvedTokenRange[contract_][i].min = 0;
            _approvedTokenRange[contract_][i].max = 0;
        }
        
        for (uint i = 0; i < minTokenIds.length; i++) {
            require(minTokenIds[i] < maxTokenIds[i], "Redeem: min must be less than max");
            if (i < existingRangesLength) {
                _approvedTokenRange[contract_][i].min = minTokenIds[i];
                _approvedTokenRange[contract_][i].max = maxTokenIds[i];
            } else {
                _approvedTokenRange[contract_].push(range(minTokenIds[i], maxTokenIds[i]));
            }
        }
    }

    function redeemable(address contract_, uint tokenId) public view returns(bool) {
         if (_approvedTokenRange[contract_].length > 0) {
             for (uint i=0; i < _approvedTokenRange[contract_].length; i++) {
                 if (_approvedTokenRange[contract_][i].max != 0 && tokenId >= _approvedTokenRange[contract_][i].min && tokenId <= _approvedTokenRange[contract_][i].max) {
                     return true;
                 }
             }
         }

         return false;
    }

    function redeem(address[] calldata contracts, uint256[] calldata tokenIds, Hemisphere hemisphere, int offset) external nonReentrant {
        uint ts = totalSupply();
        require(burnIsActive, "Burn is not active");
        require(contracts.length == tokenIds.length, "BurnRedeem: Invalid parameters");
        require(contracts.length == REDEMPTION_RATE, "BurnRedeem: Incorrect number of NFTs being redeemed");
        require(ts + 1 < MAX_TOKENS, "Redemption would exceed max tokens");
        require(validOffset(offset), "Invalid offset");
                
        for (uint i = 0; i < contracts.length; i++) {
            require(redeemable(contracts[i], tokenIds[i]), "redeem: Invalid NFT");

            try IERC721(contracts[i]).ownerOf(tokenIds[i]) returns (address ownerOfAddress) {
                require(ownerOfAddress == msg.sender, "redeem: Caller must own NFTs");
            } catch (bytes memory) {
                revert("redeeem: Bad token contract");
            }

            try IERC721(contracts[i]).transferFrom(msg.sender, address(0xdEaD), tokenIds[i]) {
            } catch (bytes memory) {
                revert("redeem: Burn failure");
            }
        }

        _safeMint(msg.sender, ts);
        hemispheres[ts] = hemisphere;
        offsets[ts] = offset;
    }

    function imageTitle(Season season, WeatherCondition weatherCondition) public view returns(string memory) {
        return string(abi.encodePacked(seasonStrings[season], "-", weatherConditionStrings[season][weatherCondition]));
    }

    function getImageURL(uint256 tokenId) public view returns(string memory) {
        return string(abi.encodePacked(BASE_URI,
                                       "/",
                                       imageTitle(currentSeason(tokenId),
                                                  currentWeather(tokenId)),
                                       ".mp4"));
    }

    function getName(uint256 tokenId) public pure returns(string memory) {
        return string(abi.encodePacked("Little Red Riding Hood v2 ",
                                       (tokenId + 1).toString(),
                                       "/",
                                       MAX_TOKENS.toString()));
    }

    function getDescription() internal pure returns(string memory) {
        return "Little Red Riding Hood v2 is an upgraded NFT from TedsLittleDream's debut drop of the same name in March 2021. Combining art with smart contract, TedsLittleDream (Artist), protein (Smart Contract Developer), and Kenson (Animator), have created an NFT that changes with the passage of time. Collectors can choose which part of the world they'd like their NFT's seasons to track, then sit back and watch as the weather in their NFT changes daily and with the seasons.";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Invalid token id");
        return string(abi.encodePacked(
            'data:application/json;utf8,{"name":"',getName(tokenId),
                                         '", "description":"',getDescription(),
                                         '", "image":"',getImageURL(tokenId),
                                         '", "attributes":[',
                                            _getChangingData(tokenId),
                                            _getStaticData(),
                                         ']',
                                         '}'));
    }

    function _wrapTrait(string memory trait, string memory value) internal pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"',
            value,
            '"}'
        ));
    }

    function _getStaticData() internal pure returns(string memory) {
        return string(abi.encodePacked(
            ',',_wrapTrait("Artist","TedsLittleDream"),
            ',',_wrapTrait("Contract by","West Coast NFT"),
            ',',_wrapTrait("Collection","Little Red Riding Hood")
        ));
    }

    function intToString(int n) public pure returns (string memory) {
        if (n < 0) {
            return string(abi.encodePacked("-", uint(-n).toString()));
        } else {
            return uint(n).toString();
        }
    }

    function _getChangingData(uint256 tokenId) internal view returns(string memory) {
        Season s = currentSeason(tokenId);
        return string(abi.encodePacked(
            _wrapTrait("Weather", weatherConditionStrings[s][currentWeather(tokenId)]),
            ',',_wrapTrait("Season", seasonStrings[s]),
            ',',_wrapTrait("Hour Offset", intToString(offsets[tokenId])),
            ',',_wrapTrait("Hemisphere", hemisphereStrings[hemispheres[tokenId]])
        ));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}