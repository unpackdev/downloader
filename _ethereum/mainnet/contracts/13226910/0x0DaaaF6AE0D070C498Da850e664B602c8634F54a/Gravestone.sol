// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./AccessControl.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./IERC165.sol";
import "./IGravestone.sol";
import "./IGravestoneAdornment.sol";

contract Gravestone is AccessControl, ERC721, ERC721Enumerable, IGravestone {
    struct GravestoneAttributes {
        /**
            Year number where 4714 BC (Gregorian proleptic) is 1
            Valid range (0, uint24.max]
            0 is unset
         */
        uint24 birthYear;
        uint24 deathYear;
        /**
            Day number within year where January 1 is 1
            Valid range (0, 366]
            0 is unset
            Mutually exclusive with *Month since
                ordinal day implies month
         */
        uint16 birthOrdinalDay;
        uint16 deathOrdinalDay;
        /**
            Month number within year where January is 1
            Valid range (0, 12]
            0 is unset
            Mutually exclusive with *OrdinalDay since
                ordinal day implies month
         */
        uint8 birthMonth;
        uint8 deathMonth;
        /**
            Latitude is floor(100000 * Latitude in decimal) + 9000000
            Valid range (0, 18000000)
            0 is unset
         */
        uint32 latitude;
        /**
            Longitude is floor(100000 * Longitude in decimal) + 18000000
            Valid range (0, 36000000]
            0 is unset
         */
        uint32 longitude;
        uint256 adornmentId; // 0 is the empty adornment
        string name;
        string epitaph;
        /**
            Most likely in the form ipfs://<cid>, though generic
            This is the only mutable attribute
         */
        string tokenURI;
    }

    struct MintVars {
        bool hasLocation;
        bool hasNoLocation;
        uint128 location;
        uint256 tokenId;
    }

    uint24 private constant YEAR_UNSET = 0;
    uint16 private constant ORDINAL_DAY_UNSET = 0;
    uint16 private constant ORDINAL_DAY_MAX = 366;
    uint8 private constant MONTH_UNSET = 0;
    uint8 private constant MONTH_MAX = 12;
    uint32 private constant LATLONG_UNSET = 0;
    uint32 private constant LATLONG_MIN = 1;
    uint32 private constant LATITUDE_MAX = 17999999;
    uint32 private constant LONGITUDE_MAX = 36000000;

    bytes32 public constant MINTER_ROLE = keccak256("M");

    IGravestoneAdornment private _gravestoneAdornment;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    mapping(uint256 => GravestoneAttributes) private _attributesByTokenId;
    mapping(uint128 => uint256) private _tokenIdByLocation;

    constructor(address gravestoneAdornment_) ERC721("Gravestone", "GRAVE") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);

        require(
            IERC165(gravestoneAdornment_).supportsInterface(
                type(IGravestoneAdornment).interfaceId
            )
        );
        _gravestoneAdornment = IGravestoneAdornment(gravestoneAdornment_);

        _tokenIdTracker.increment(); // Start IDs at 1
    }

    function mint(
        address to_,
        string calldata name_,
        uint24[2] calldata birthDeathYear_,
        uint8[2] calldata birthDeathMonth_,
        uint16[2] calldata birthDeathOrdinalDay_,
        uint256 adornmentId_,
        string calldata epitaph_,
        uint32[2] calldata latitudeLongitude_,
        string calldata tokenURI_
    ) external override returns (uint256) {
        require(hasRole(MINTER_ROLE, msg.sender), "auth");

        require(
            (birthDeathMonth_[0] == MONTH_UNSET &&
                birthDeathOrdinalDay_[0] == ORDINAL_DAY_UNSET) ||
                birthDeathYear_[0] != YEAR_UNSET,
            "(m|od)&^y"
        );
        require(
            birthDeathMonth_[0] == MONTH_UNSET ||
                birthDeathOrdinalDay_[0] == ORDINAL_DAY_UNSET,
            "m&od"
        );
        require(birthDeathMonth_[0] <= MONTH_MAX, "m");
        require(birthDeathOrdinalDay_[0] <= ORDINAL_DAY_MAX, "od");

        require(
            (birthDeathMonth_[1] == MONTH_UNSET &&
                birthDeathOrdinalDay_[1] == ORDINAL_DAY_UNSET) ||
                birthDeathYear_[1] != YEAR_UNSET,
            "(m|od)&^y"
        );
        require(
            birthDeathMonth_[1] == MONTH_UNSET ||
                birthDeathOrdinalDay_[1] == ORDINAL_DAY_UNSET,
            "m&od"
        );
        require(birthDeathMonth_[1] <= MONTH_MAX, "m");
        require(birthDeathOrdinalDay_[1] <= ORDINAL_DAY_MAX, "od");

        MintVars memory vars;

        vars.hasLocation =
            latitudeLongitude_[0] >= LATLONG_MIN &&
            latitudeLongitude_[0] <= LATITUDE_MAX &&
            latitudeLongitude_[1] >= LATLONG_MIN &&
            latitudeLongitude_[1] <= LONGITUDE_MAX;
        vars.hasNoLocation =
            latitudeLongitude_[0] == LATLONG_UNSET &&
            latitudeLongitude_[1] == LATLONG_UNSET;

        require(vars.hasLocation || vars.hasNoLocation, "lat|long");

        if (vars.hasLocation) {
            vars.location =
                (uint128(latitudeLongitude_[0]) << 64) |
                uint128(latitudeLongitude_[1]);
            require(_tokenIdByLocation[vars.location] == 0, "lat&long");
        }

        vars.tokenId = _tokenIdTracker.current();

        _attributesByTokenId[vars.tokenId] = GravestoneAttributes(
            birthDeathYear_[0],
            birthDeathYear_[1],
            birthDeathOrdinalDay_[0],
            birthDeathOrdinalDay_[1],
            birthDeathMonth_[0],
            birthDeathMonth_[1],
            latitudeLongitude_[0],
            latitudeLongitude_[1],
            adornmentId_,
            name_,
            epitaph_,
            tokenURI_
        );

        if (vars.hasLocation) {
            _tokenIdByLocation[vars.location] = vars.tokenId;
            emit Place(vars.tokenId, vars.location);
        }
        _tokenIdTracker.increment();

        require(_gravestoneAdornment.valid(adornmentId_), "aId");
        _safeMint(to_, vars.tokenId);
        return vars.tokenId;
    }

    function burn(uint256 tokenId_) external override {
        require(_isApprovedOrOwner(msg.sender, tokenId_), "auth");
        uint64 latitude = _attributesByTokenId[tokenId_].latitude;
        uint64 longitude = _attributesByTokenId[tokenId_].longitude;
        bool hasLocation = latitude >= LATLONG_MIN &&
            latitude <= LATITUDE_MAX &&
            longitude >= LATLONG_MIN &&
            longitude <= LONGITUDE_MAX;
        if (hasLocation) {
            uint128 location = (uint128(latitude) << 64) | uint128(longitude);
            delete _tokenIdByLocation[location];
            emit Remove(tokenId_, location);
        }
        delete _attributesByTokenId[tokenId_];
        _burn(tokenId_);
    }

    function updateTokenURI(uint256 tokenId_, string calldata tokenURI_)
        external
        override
    {
        require(_isApprovedOrOwner(msg.sender, tokenId_), "auth");
        _attributesByTokenId[tokenId_].tokenURI = tokenURI_;
        emit UpdateTokenURI(tokenId_, tokenURI_);
    }

    function gravestone(uint256 tokenId_)
        external
        view
        override
        returns (
            string memory name_,
            uint24 birthYear_,
            uint8 birthMonth_,
            uint16 birthOrdinalDay_,
            uint24 deathYear_,
            uint8 deathMonth_,
            uint16 deathOrdinalDay_,
            uint256 adornmentId_,
            string memory epitaph_,
            uint32 latitude_,
            uint32 longitude_,
            string memory tokenURI_
        )
    {
        require(_exists(tokenId_), "tId");

        GravestoneAttributes
            storage gravestoneAttributes = _attributesByTokenId[tokenId_];

        return (
            gravestoneAttributes.name,
            gravestoneAttributes.birthYear,
            gravestoneAttributes.birthMonth,
            gravestoneAttributes.birthOrdinalDay,
            gravestoneAttributes.deathYear,
            gravestoneAttributes.deathMonth,
            gravestoneAttributes.deathOrdinalDay,
            gravestoneAttributes.adornmentId,
            gravestoneAttributes.epitaph,
            gravestoneAttributes.latitude,
            gravestoneAttributes.longitude,
            gravestoneAttributes.tokenURI
        );
    }

    function gravestoneAdornment(uint256 tokenId_)
        external
        view
        override
        returns (bytes32[] memory)
    {
        require(_exists(tokenId_), "tId");

        uint256 adornmentId = _attributesByTokenId[tokenId_].adornmentId;
        return _gravestoneAdornment.gravestoneAdornment(adornmentId);
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId_), "tId");

        return _attributesByTokenId[tokenId_].tokenURI;
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from_, to_, tokenId_);
    }

    function supportsInterface(bytes4 interfaceId_)
        public
        view
        override(AccessControl, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId_ == type(IGravestone).interfaceId ||
            super.supportsInterface(interfaceId_);
    }
}
