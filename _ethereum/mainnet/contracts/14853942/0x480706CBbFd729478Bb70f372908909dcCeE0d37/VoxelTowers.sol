// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./Base64.sol";
import "./IPropertyStore.sol";


/**
 * @title  Official VoxelTowers contract
 * @author The VoxelTowers crew
 * @notice The VoxelTowers contract implements updatable NFTs where each NFT represents ownership of an Apartment
 *         within the Voxel Towers (see https://www.voxel-towers.com)
 */
contract VoxelTowers is ERC721, ERC2981, Ownable, IPropertyStore {
    struct BasePropsParams {
        uint256 id;
        string properties;
        string imageLink;
    }

    struct BaseProps {
        uint256 tower;
        uint256 floor;
        string type_;
        string size;
        string view_;
        string direction;
        string balcony;
        string area;
        string ownership;
        string maisonette;
    }


    uint96 private royaltyPercentage = 1000; // 10.00%
    mapping(uint256 => IPropertyStore.Property[]) private tokensProps;
    mapping(uint256 => string) private tokensImage;
    mapping(address => bool) private propertySetters;


    constructor() ERC721("VoxelTowers", "VTO") {
        _setDefaultRoyalty(owner(), royaltyPercentage);
        mintTokens();
    }

    /**
     * @notice Mints all VTO tokens for all towers
     */
    function mintTokens() private {
        uint16[46] memory t1Apartments = getTower1TokenIds();
        for (uint256 i = 0; i < t1Apartments.length; i++) {
            _mint(owner(), t1Apartments[i]);
        }

        uint16[34] memory t2Apartments = getTower2TokenIds();
        for (uint256 i = 0; i < t2Apartments.length; i++) {
            _mint(owner(), t2Apartments[i]);
        }

        uint16[64] memory t3Apartments = getTower3TokenIds();
        for (uint256 i = 0; i < t3Apartments.length; i++) {
            _mint(owner(), t3Apartments[i]);
        }
    }

    /**
     * @notice Returns the token Ids of the tower 1 apartments
     * @return the tower 1 token Ids
     */
    function getTower1TokenIds() private pure returns (uint16[46] memory) {
        uint16[46] memory apartmentIds = [
            /* ids -> d[4]: tower, d[2-3]: floor, d[0-1]: apartment */
            // Floor 1
            10101, 10102, 10103, 10104,
            // Floor 2
            10201, 10202, 10203, 10204,
            // Floor 3
            10301, 10302, 10303, 10304,
            // Floor 4 (Lobby)
            10401, 10402,
            // Floor 5
            10501, 10502, 10503,
            // Floor 6
            10601, 10602, 10603,
            // Floor 7
            10701, 10702, 10703,
            // Floor 8
            10801, 10802, 10803,
            // Floor 9
            10901, 10902, 10903,
            // Floor 10
            11001, 11002, 11003,
            // Floor 11
            11101, 11102, 11103,
            // Floor 12
            11201, 11202, 11203,
            // Floor 13
            11301, 11302, 11303,
            // Floor 14
            11401, 11402, 11403,
            // Floor 15
            11501,
            // Floor 16
            11601
        ];
        return apartmentIds;
    }

    /**
     * @notice Returns the token Ids of the tower 2 apartments
     * @return the tower 2 token Ids
     */
    function getTower2TokenIds() private pure returns (uint16[34] memory) {
        uint16[34] memory apartmentIds = [
            /* ids -> d[4]: tower, d[2-3]: floor, d[0-1]: apartment */
            // Floor 1
            20101, 20102, 20103, 20104,
            // Floor 2
            20201, 20202, 20203, 20204,
            // Floor 3
            20301, 20302, 20303, 20304,
            // Floor 4 (Lobby)
            20401, 20402,
            // Floor 5
            20501, 20502, 20503,
            // Floor 6
            20601, 20602, 20603,
            // Floor 7
            20701, 20702, 20703,
            // Floor 8
            20801, 20802, 20803,
            // Floor 9
            20901, 20902, 20903,
            // Floor 10
            21001, 21002, 21003,
            // Floor 11
            21101,
            // Floor 12
            21201
        ];
        return apartmentIds;
    }

    /**
     * @notice Returns the token Ids of the tower 3 apartments
     * @return the tower 3 token Ids
     */
    function getTower3TokenIds() private pure returns (uint16[64] memory) {
        uint16[64] memory apartmentIds = [
            /* ids -> d[4]: tower, d[2-3]: floor, d[0-1]: apartment */
            // Floor 0 (Groundfloor)
            30001,
            // Floor 1
            30101, 30102, 30103, 30104, 30105, 30106, 30107, 30108, 30109, 30110, 30111, 30112,
            // Floor 2
            30201, 30202, 30203, 30204, 30205, 30206, 30207, 30208, 30209, 30210, 30211, 30212,
            // Floor 3
            30301, 30302, 30303, 30304, 30305, 30306, 30307, 30308, 30309, 30310, 30311, 30312,
            // Floor 4 (Lobby)
            30401, 30402, 30403, 30404,
            // Floor 5
            30501, 30502, 30503, 30504, 30505, 30506, 30507, 30508,
            // Floor 6
            30601, 30602, 30603, 30604, 30605, 30606, 30607, 30608,
            // Floor 7
            30701, 30702, 30703, 30704,
            // Floor 8
            30801, 30802,
            // Floor 9
            30901
        ];
        return apartmentIds;
    }


    /**
     * @notice Updates the image link of multiple tokens
     * @dev    Only the contract owner is allowed to update the image links
     * @param  tokenIds - the token Ids of the tokens
     * @param  imageLink - the new image link
     */
    function updateImageLink(uint256[] memory tokenIds, string memory imageLink) public onlyOwner {
        for (uint256 i = 0 ; i < tokenIds.length ; i++) {
            require(_exists(tokenIds[i]), "VoxelTowers: operator query for nonexistent token");
            tokensImage[tokenIds[i]] = imageLink;
        }
    }


    /**
     * @notice Sets base properties for all tokens in a tower
     * @dev    Only the contract owner is allowed to set the base properties. 
     *         This is a one time call for each tower
     * @param  tower - the tower Id
     * @param  basePropsParams - the base property parameters
     */
    function setBaseProperties(uint256 tower, BasePropsParams[] calldata basePropsParams) public onlyOwner {
        require(
            tower == 1 ? basePropsParams.length == 46 :
            tower == 2 ? basePropsParams.length == 34 :
            tower == 3 ? basePropsParams.length == 64 : false,
            "VoxelTowers: invalid parameter length"
        );
        
        for (uint256 i = 0; i < basePropsParams.length; i++) {
            require(_exists(basePropsParams[i].id), "VoxelTowers: operator query for nonexistent token");
            require(tokensProps[basePropsParams[i].id].length == 0, "VoxelTowers: initial properties already set");

            tokensProps[basePropsParams[i].id].push(IPropertyStore.Property("baseProps", basePropsParams[i].properties));
            tokensImage[basePropsParams[i].id] = basePropsParams[i].imageLink;
        }
    }


    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    /**
     * @notice Returns the token URI of a token
     * @param  tokenId - the token Id of the token
     * @return the token URI of the given token Id
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "VoxelTowers: operator query for nonexistent token");
        BaseProps memory baseProps = getBaseProps(tokenId);

        bytes memory attributes = abi.encodePacked(
            '[',
                byteifyBaseProps(baseProps),
                byteifyAdditionalProps(tokenId),
            ']'
        );

        string memory json = Base64.encode(abi.encodePacked(
            '{'
                '"name":' '"', createTitle(tokenId, baseProps), '",'
                '"description":' '"', createDescription(tokenId, baseProps), '",'
                '"image":' '"', tokensImage[tokenId], '",'
                '"external_url":' '"', createLink(tokenId), '",'
                '"attributes":', attributes,
            '}'
        ));

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    /**
     * @notice Returns the base properties for a token
     * @param  tokenId - the token Id of the token
     * @return the base properties
     */
    function getBaseProps(uint256 tokenId) private view returns (BaseProps memory) {
        BaseProps memory props;
        props.tower = tokenId / 10000;
        props.floor = (tokenId / 100) % 100;
        
        string memory baseProps = tokensProps[tokenId][0].value;
        string[7] memory sizeProps = getSizeDerivedProps(tokenId, props.tower, props.floor, substring(baseProps, 0, 1));

        props.type_ = sizeProps[0];
        props.size = sizeProps[1];
        props.area = sizeProps[2];
        props.balcony = sizeProps[3];
        props.ownership = sizeProps[4];
        props.maisonette = sizeProps[5];
        props.view_ = sizeProps[6];
        props.direction = getDirection(substring(baseProps, 1, 2));

        return props;
    }

    /**
     * @notice Converts a string into a substring
     * @dev    See https://ethereum.stackexchange.com/questions/31457/substring-in-solidity
     * @param  str - the string
     * @param  startIndex - start index
     * @param  endIndex - end index
     * @return the substring
     */
    function substring(string memory str, uint256 startIndex, uint256 endIndex) private pure returns (string memory ) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    /**
     * @notice Returns room size derived properties
     * @param  tokenId - the token Id
     * @param  tower - the tower Id
     * @param  floor - the floor number
     * @param  sizeStr - the size string
     * @return the size derived properties
     */
    function getSizeDerivedProps(uint256 tokenId, uint256 tower, uint256 floor, string memory sizeStr) private pure returns (string[7] memory) {
        // return [ <type>, <size>, <area>, <balcony>, <ownership>, <maisonette>, <view> ]
        string memory notAvailableString = "N/A";
        if (isSameString(sizeStr, "S")) {
            return [
                "Studio Apartment",
                "XS",
                "125",
                "No",
                "0.3",
                "No",
                "Standard"
            ];
        }
        if (isSameString(sizeStr, "s")) {
            if (tokenId == 10401 || tokenId == 20401) {
                return [
                    "Commercial",
                    "S",
                    "175",
                    "No",
                    "0",
                    "No",
                    notAvailableString
                ];
            } else if (tokenId == 10402 || tokenId == 20402) {
                return [
                    "Community",
                    "S",
                    "175",
                    "No",
                    "0",
                    "No",
                    notAvailableString
                ];
            } else {
                return [
                    "Corner Apartment",
                    "S",
                    "175",
                    "No",
                    "0.5",
                    "No",
                    "90"
                ];
            }
        }
        if (isSameString(sizeStr, "M")) {
            if (tower == 3 && floor == 4) {
                return [
                    "Community",
                    "XM",
                    "200",
                    "No",
                    "0",
                    "No",
                    notAvailableString
                ];
            } else {
                return [
                    "Superior Apartment",
                    "XM",
                    "200",
                    "1 Small",
                    "0.5",
                    "Yes",
                    "Standard"
                ];
            }
        }
        if (isSameString(sizeStr, "m")) {
            return [
                "Junior Suite",
                "M",
                "250",
                "1 Medium",
                "0.7",
                "Yes",
                "90"
            ];
        }
        if (isSameString(sizeStr, "l")) {
            if (tower == 3 && floor == 0) {
                return [
                    "Commercial",
                    "L",
                    "1000",
                    "No",
                    "0",
                    "No",
                    notAvailableString
                ];
            } else {
                return [
                    "Executive Suite",
                    "L",
                    "500",
                    "1 Large",
                    "1.3",
                    "Yes",
                    "180"
                ];
            }
        }
        if (isSameString(sizeStr, "o")) {
            return [
                tower == 1 ? "The Voxel Loft" :
                tower == 2 ? "The Parcel Loft" :
                tower == 3 ? "The $SAND Loft" : "",
                "Loft",
                "1000",
                "2 Large",
                "2.6",
                "Yes",
                "360"
            ];
        }
        if (isSameString(sizeStr, "p")) {
            return [
                tower == 1 ? "The Arthur Penthouse" :
                tower == 2 ? "The Borget Penthouse" : "",
                "Penthouse",
                "1250",
                "2 Large",
                "3.3",
                "Yes",
                "360"
            ];
        }
        return ["", "", "", "", "", "", ""];
    }

    /**
     * @notice Checks if two strings are the same
     * @dev See https://ethereum.stackexchange.com/questions/30912/how-to-compare-strings-in-solidity
     * @param  str1 - string 1
     * @param  str2 - string 2
     * @return true if strings are the same, false if not
     */
    function isSameString(string memory str1, string memory str2) private pure returns (bool) {
        return keccak256(bytes(str1)) == keccak256(bytes(str2));
    }

    /**
     * @notice Concats two strings
     * @param  baseStr - base string
     * @param  appendStr - append string
     * @return the concatinated string
     */
    function concatString(string memory baseStr, string memory appendStr) private pure returns (string memory) {
        return string(abi.encodePacked(baseStr, appendStr));
    }

    /**
     * @notice Returns the room direction
     * @param  directionStr - the direction string
     * @return the room direction
     */
    function getDirection(string memory directionStr) private pure returns (string memory) {
        if (isSameString(directionStr, "c")) {
            return "Center";
        }
        if (isSameString(directionStr, "o")) {
            return "Outside";
        }
        if (isSameString(directionStr, "p")) {
            return "Panorama";
        }
        return "N/A";
    }

     /**
     * @notice Formats and byteifies the provided base properties
     * @param  baseProps - the base properties
     * @return the byteified base properties
     */
    function byteifyBaseProps(BaseProps memory baseProps) private pure returns (bytes memory) {
        bytes memory propsBytes = abi.encodePacked(
            '{'
                '"trait_type":' '"Tower",'
                '"value":' '"', Strings.toString(baseProps.tower), '"'
            '},'
        );
        propsBytes = abi.encodePacked(propsBytes, abi.encodePacked(
            '{'
                '"trait_type":' '"Floor",'
                '"value":' '"', Strings.toString(baseProps.floor), '"'
            '},'
        ));
        propsBytes = abi.encodePacked(propsBytes, abi.encodePacked(
            '{'
                '"trait_type":' '"Type",'
                '"value":' '"', baseProps.type_, '"'
            '},'
        ));
        propsBytes = abi.encodePacked(propsBytes, abi.encodePacked(
            '{'
                '"trait_type":' '"Size",'
                '"value":' '"', baseProps.size, '"'
            '},'
        ));
        propsBytes = abi.encodePacked(propsBytes, abi.encodePacked(
            '{'
                '"trait_type":' '"Area [m2]",'
                '"value":' '"', baseProps.area, '"'
            '},'
        ));
        propsBytes = abi.encodePacked(propsBytes, abi.encodePacked(
            '{'
                '"trait_type":' '"Maisonette",'
                '"value":' '"', baseProps.maisonette, '"'
            '},'
        ));
        propsBytes = abi.encodePacked(propsBytes, abi.encodePacked(
            '{'
                '"trait_type":' '"Balcony",'
                '"value":' '"', baseProps.balcony, '"'
            '},'
        ));
        propsBytes = abi.encodePacked(propsBytes, abi.encodePacked(
            '{'
                '"trait_type":' '"View [deg]",'
                '"value":' '"', baseProps.view_, '"'
            '},'
        ));
        propsBytes = abi.encodePacked(propsBytes, abi.encodePacked(
            '{'
                '"trait_type":' '"Direction",'
                '"value":' '"', baseProps.direction, '"'
            '},'
        ));
        propsBytes = abi.encodePacked(propsBytes, abi.encodePacked(
            '{'
                '"trait_type":' '"Location",'
                '"value":' '"LAND (147, 96)"'
            '},'
        ));
        propsBytes = abi.encodePacked(propsBytes, abi.encodePacked(
            '{'
                '"trait_type":' '"Metaverse",'
                '"value":' '"The Sandbox"'
            '},'
        ));
        propsBytes = abi.encodePacked(propsBytes, abi.encodePacked(
            '{'
                '"trait_type":' '"Land Ownership [%]",'
                '"value":' '"', baseProps.ownership, '"'
            '}'
        ));

        return propsBytes;
    }

    /**
     * @notice Formats and byteifies the additional properties
     * @param  tokenId - the token Id
     * @return the byteified additional properties
     */
    function byteifyAdditionalProps(uint256 tokenId) private view returns (bytes memory) {
        bytes memory propsBytes = "";

        for (uint256 i = 1 ; i < tokensProps[tokenId].length ; i++) {
            propsBytes = abi.encodePacked(propsBytes, abi.encodePacked(
                ',{'
                    '"trait_type":' '"', tokensProps[tokenId][i].key, '",'
                    '"value":' '"', tokensProps[tokenId][i].value, '"'
                '}'
            ));
        }

        return propsBytes;
    }

    /**
     * @notice Creates the title of a token
     * @param  tokenId - the token Id
     * @param  baseProps - the base properties
     * @return the title of the token
     */
    function createTitle(uint256 tokenId, BaseProps memory baseProps) private pure returns (string memory) {
        // Corner Apartment #10101 (Tower 1, Floor 1)
        return string(abi.encodePacked(
            baseProps.type_,
            ' #',
            Strings.toString(tokenId),
            ' (Tower ',
            Strings.toString(baseProps.tower),
            ', Floor ',
            Strings.toString(baseProps.floor),
            ')'
        ));
    }

    /**
     * @notice Creates the description of a token
     * @param  tokenId - the token Id
     * @param  baseProps - the base properties
     * @return the description of the token
     */
    function createDescription(uint256 tokenId, BaseProps memory baseProps) private pure returns (string memory) {
        // This NFT represents ownership of Corner Apartment #10101 in the Voxel Towers.
        return string (abi.encodePacked(
            'This NFT represents ownership of ',
            baseProps.type_,
            ' #',
            Strings.toString(tokenId),
            ' in the Voxel Towers.'
        ));
    }

    /**
     * @notice Returns the link of a token
     * @param  tokenId - the token Id
     * @return the link of the token
     */
    function createLink(uint256 tokenId) private pure returns (string memory) {
        // https://www.voxel-towers.com/apartment/?tokenId=10101
        return string (abi.encodePacked(
            'https://www.voxel-towers.com/apartment/?tokenId=',
            Strings.toString(tokenId)
        ));
    }


    /**
     * @notice Updates an address to permit/deny to set additional properties
     * @dev    This function is only allowed to be called by the contract owner.
     *         Per default every address is denied to add properties.
     *         To permit an address, call this function to toggle between permit/deny states.
     * @param  address_ - the address
     */
    function updatePropertySetters(address address_) public onlyOwner {
        propertySetters[address_] = !propertySetters[address_];
    }


    /**
     * @notice Checks if an address is permitted to set additional properties
     * @param  address_ - the address
     * @return true if address is permitted, false if not
     */
    function isPropertySetter(address address_) public view returns (bool) {
        return propertySetters[address_];
    }


    /// @inheritdoc IPropertyStore
    function addProperty(uint256 tokenId, IPropertyStore.Property calldata property) public virtual override {
        require(_exists(tokenId), "VoxelTowers: operator query for nonexistent token");
        require(propertySetters[msg.sender], "VoxelTowers: sender not whitelisted");

        for (uint256 i = 0; i < tokensProps[tokenId].length; i++) {
            require(!isSameString(tokensProps[tokenId][i].key, property.key), "VoxelTowers: property already set");
        }
        tokensProps[tokenId].push(property);
    }


    /// @inheritdoc IPropertyStore
    function getProperties(uint256 tokenId) public view virtual override returns (IPropertyStore.Property[] memory) {
        require(_exists(tokenId), "VoxelTowers: operator query for nonexistent token");
        return tokensProps[tokenId];
    }
}