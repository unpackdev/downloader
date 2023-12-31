// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721Royalty.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

/**
 * @title Matto's Fine Art v3.6.4
 * @notice This is an extended and composable ERC-721 contract (ERC-721-ExC) for Matto's Fine Art.
 * @author Matto AKA MonkMatto
 * @custom:experimental This contract is experimental.
 * @custom:security-contact info@substratum.art
 */
contract Mattos_Fine_Art is ERC721Royalty, Ownable {
    using Counters for Counters.Counter;
    using Strings for string;

    struct Attribute {
        string traitType;
        string value;
    }

    struct TokenData {
        string name; // The name of the artwork.
        string mediaImage; // The image corresponding to the token.
        string mediaAnimation; // The animation corresponding to the token.
        string description; // The token's description.
        string externalUrl; // If data is stored in this field, it will override baseExternalUrl/tokenId in tokenDataOf. To access this dynamic field, use the public function externalUrl().
        string additionalData; // Additional data that can get added to the token description by the API.
        string artistNameOverride; // Lets the artist set a custom artist name(s) for a token.
        string licenseOverride; // Lets the artist set a custom license for a token.
        uint256 tokenEntropy; // Seed for random number generation or image creation.
        uint256 unlockBlock; // If set, the token is locked until the block number exceeds this value.
        uint256 transferCount; // If countTransfers is true, this is the number of times the token has been transferred.
        uint256 lastBlockTransferred; // If countTransfers is true, this is the block number of the last transfer.
        address royaltyAddressOverride; // Lets the artist set a custom royalty address for a token.
        uint8 mediaType; // Defaults to 0 for decentralized storage. 1 denotes directly stored data. 2 denotes generated from script. 204 denotes media accessible elsewhere in smart contract.
        uint8 widthRatio; // The media's aspect ratio: widthRatio/heightRatio. Defaults to 1.
        uint8 heightRatio; // The media's aspect ratio: widthRatio/heightRatio. Defaults to 1.
        bool countTransfers; // If true, the token will count transfers and update transferCount and lastBlockTransferred.
        bool frozen; // If true, the token's crucial data cannot be updated.
    }

    Counters.Counter public tokensMinted;
    uint256 public maxSupply = 10 ** 12;
    uint96 public royaltyBPS;
    bool public mintActive;
    string public baseURI;
    string public baseExternalUrl;
    string public collectionNotes;
    string public collection;
    string public collectionDescription;
    string public defaultArtistName;
    string public defaultLicense;
    string public projectWebsite;
    address public artistAddress;
    address public minterAddress;
    address public platformAddress;
    address public defaultRoyaltyAddress;
    mapping(uint256 => TokenData) tokenData;
    mapping(uint256 => Attribute[]) private attributes;

    constructor() ERC721("Mattos Fine Art", "MFA") {}

    // CUSTOM EVENTS
    // These events are watched by the substratum.art platform.
    // These will be monitored by the custom backend. They will trigger
    // updating the API with data returned by the tokenDataOf() function.

    /**
     * @notice The TokenUpdated event is emitted from multiple functions that
     * that affect the rendering of traits/image of the token.
     * @param tokenId is the token that is being updated.
     */
    event TokenUpdated(uint256 tokenId);

    /**
     * @notice The TokenLocked event is emitted when a token is locked.
     * @param tokenId is the token that is being locked.
     * @param unlockBlock is the block number when the token will be unlocked.
     */
    event TokenLocked(uint256 indexed tokenId, uint256 unlockBlock);

    // MODIFIERS
    // These are reusable code blocks to control function execution.

    /**
     * @notice onlyArtist restricts functions to the artist.
     */
    modifier onlyArtist() {
        require(msg.sender == artistAddress);
        _;
    }

    /**
     * @notice notFrozen ensures that a token is not frozen.
     */
    modifier notFrozen(uint256 _tokenId) {
        require(tokenData[_tokenId].frozen == false);
        _;
    }

    // OVERRIDE FUNCTIONS
    // These functions are declared as overrides because functions of the
    // same name exist in imported contracts.
    // 'super.<overridden function>' calls the overridden function.

    /**
     * @notice _baseURI is an internal function that returns a state value.
     * @dev This override is needed when using a custom baseURI.
     * @return baseURI, which is a state value.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice _beforeTokenTransfer is an override function that is called
     * before a token is transferred.
     * @dev This override is needed to check if a token is locked, and if token counts transfers.
     * @param _from is the address the token is being transferred from.
     * @param _to is the address the token is being transferred to.
     * @param _tokenId is the token being transferred.
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        require(
            ownerOf(_tokenId) == artistAddress || !isTokenLocked(_tokenId),
            "Token is locked"
        );
        if (tokenData[_tokenId].countTransfers) {
            tokenData[_tokenId].transferCount++;
            tokenData[_tokenId].lastBlockTransferred = block.number;
            emit TokenUpdated(_tokenId);
        }
        super._transfer(_from, _to, _tokenId);
    }

    /**
     * @notice this override checks if a token has a specific royalty address set.
     * @dev as a mapping, if a token does not have an address set, it returns the
     * zero address, so a catch must be used to reset the returned address to the
     * contract's default address.
     * @param _tokenId is the token to check its royalty information.
     * @param _salePrice is the price to calculate the royalty with.
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) public view virtual override returns (address, uint256) {
        address royaltyReceiver = tokenData[_tokenId].royaltyAddressOverride ==
            address(0)
            ? defaultRoyaltyAddress
            : tokenData[_tokenId].royaltyAddressOverride;
        return (royaltyReceiver, (_salePrice * royaltyBPS) / 10000);
    }

    // CUSTOM VIEW FUNCTIONS
    // These are custom view functions implemented for efficiency.

    /**
     * @notice additionalDataOf returns the additional data for a token.
     * @dev This function returns the additional data for a token.
     * If the contents are shorter than 13 bytes, the content is converted into an integer.
     * If the conversion is successful and the integer is less than the total number of tokens minted,
     * the integer is treated like a tokenId and additionalData is returned from that tokenId.
     * @param _tokenId is the token whose additional data will be returned.
     * @return additionalData is the additional data for the token or referenced token.
     */
    function additionalDataOf(
        uint256 _tokenId
    ) public view returns (string memory) {
        string memory additionalData = tokenData[_tokenId].additionalData;
        if (bytes(additionalData).length == 0) {
            return "";
        }
        if (bytes(additionalData).length < 13) {
            (uint256 targetId, bool success) = _strToUint(additionalData);
            if (success && targetId < tokensMinted.current() + 1) {
                return tokenData[targetId].additionalData;
            }
        }
        return additionalData;
    }

    /**
     * @notice externalUrl returns the external URL for a token.
     * @dev This function returns the external URL for a token by either using the tokenData.externalUrl field (priority) or the baseExternalUrl with tokenId appended.
     * @param _tokenId is the token whose external URL will be returned.
     * @return externalUrl is the external URL for the token.
     */
    function externalUrl(uint256 _tokenId) public view returns (string memory) {
        if (bytes(tokenData[_tokenId].externalUrl).length > 0) {
            return tokenData[_tokenId].externalUrl;
        }
        return
            string(
                abi.encodePacked(baseExternalUrl, Strings.toString(_tokenId))
            );
    }

    /**
     * @notice getAttributeTuples returns the attribute data for a token.
     * @dev This function returns the attribute data for a token.
     * @param _tokenId is the token whose traits will be returned.
     * @return attributes is the array of trait - tuples for the token.
     */
    function getAttributeTuples(
        uint256 _tokenId
    ) external view returns (Attribute[] memory) {
        return attributes[_tokenId];
    }

    /**
     * @notice getDescription returns the description for a token.
     * @dev This function returns the description for a token as a string,
     * allowing for it to be used composably in other contracts.
     * @param _tokenId is the token whose description will be returned.
     * @return description is the description for the token.
     */
    function getDescription(uint256 _tokenId) external view returns (string memory) {
        return tokenData[_tokenId].description;
    }

    /**
     * @notice attributesOf returns the attribute data for a token in JSON format.
     * @dev This function returns the attribute data for a token in JSON format.
     * @param _tokenId is the token whose traits will be returned.
     * @return attributesJSON is a string of traits for the token in JSON format.
     */
    function attributesOf(
        uint256 _tokenId
    ) public view returns (string memory) {
        string memory attributesJSON;
        uint256 traitCount = attributes[_tokenId].length;
        if (traitCount == 0) {
            return '"attributes":[]';
        } else {
            for (uint256 i = 0; i < traitCount; i++) {
                if (i == 0) {
                    attributesJSON = string(
                        abi.encodePacked(
                            '"attributes":[{"trait_type":"',
                            attributes[_tokenId][i].traitType,
                            '","value":"',
                            attributes[_tokenId][i].value,
                            '"}'
                        )
                    );
                } else {
                    attributesJSON = string(
                        abi.encodePacked(
                            attributesJSON,
                            ',{"trait_type":"',
                            attributes[_tokenId][i].traitType,
                            '","value":"',
                            attributes[_tokenId][i].value,
                            '"}'
                        )
                    );
                }
            }
            attributesJSON = string(abi.encodePacked(attributesJSON, "]"));
            return attributesJSON;
        }
    }

    /**
     * @notice tokenDataOf returns the input data necessary for the generative
     * script to create/recreate a Mattos_Fine_Art token.
     * @dev For any given token, this function returns all its on-chain data.
     * @dev entropyString is set outside of the return to standardize this code.
     * @param _tokenId is the token whose inputs will be returned.
     * @return tokenData is returned in JSON format.
     */
    function tokenDataOf(uint256 _tokenId) public view returns (string memory) {
        TokenData memory token = tokenData[_tokenId];
        string memory externalUrlString = externalUrl(_tokenId);
        string memory entropyString = Strings.toString(token.tokenEntropy);
        string memory artistName = bytes(token.artistNameOverride).length == 0
            ? defaultArtistName
            : token.artistNameOverride;
        string memory license = bytes(token.licenseOverride).length == 0
            ? defaultLicense
            : token.licenseOverride;
        address royaltyReceiver = token.royaltyAddressOverride == address(0)
            ? defaultRoyaltyAddress
            : token.royaltyAddressOverride;
        string memory transferData;
        if (token.countTransfers) {
            transferData = string(
                abi.encodePacked(
                    '","transfer_count":"',
                    Strings.toString(token.transferCount),
                    '","last_transfer_block":"',
                    Strings.toString(token.lastBlockTransferred)
                )
            );
        } else {
            transferData = '","transfer_count":"","last_transfer_block":"';
        }
        string memory isFrozen = token.frozen ? "true" : "false";
        string memory allTokenData = string(
            abi.encodePacked(
                '{"collection":"',
                collection,
                '","name":"',
                token.name,
                '","description":"',
                token.description,
                '","artist":"',
                artistName
            )
        );
        allTokenData = string(
            abi.encodePacked(
                allTokenData,
                '","image":"',
                token.mediaImage,
                '","animation":"',
                token.mediaAnimation,
                '","width_ratio":"',
                Strings.toString(token.widthRatio),
                '","height_ratio":"',
                Strings.toString(token.heightRatio),
                '","media_type":"',
                Strings.toString(token.mediaType),
                '","token_data_frozen":"',
                isFrozen,             
                '","license":"',
                license
            )
        );
        allTokenData = string(
            abi.encodePacked(
                allTokenData,
                '","token_entropy":"',
                entropyString,
                transferData,
                '","additional_data":"',
                additionalDataOf(_tokenId),
                '","website":"',
                projectWebsite,
                '","external_url":"',
                externalUrlString,
                '","royalty_address":"',
                Strings.toHexString(uint160(royaltyReceiver), 20),
                '","royalty_bps":"',
                Strings.toString(royaltyBPS),
                '",'
            )
        );
        allTokenData = string(
            abi.encodePacked(allTokenData, attributesOf(_tokenId), "}")
        );
        return allTokenData;
    }

    /**
     * @notice isTokenLocked returns whether a token is locked.
     * @dev This function returns whether a token is locked. If the current
     * block is less than the unlockBlock value, the token is locked.
     * @param _tokenId is the token to check.
     */
    function isTokenLocked(uint256 _tokenId) public view returns (bool) {
        return block.number < tokenData[_tokenId].unlockBlock;
    }

    /**
     * @notice getRemainingLockupBlocks returns the number of blocks remaining
     * until a token is unlocked.
     * @dev The token automatically unlocks once the block number exceeds the
     * unlockBlock value.
     * @param _tokenId is the token to check.
     */
    function getRemainingLockupBlocks(
        uint256 _tokenId
    ) public view returns (uint256) {
        if (block.number >= tokenData[_tokenId].unlockBlock) {
            return 0;
        }
        return tokenData[_tokenId].unlockBlock - block.number;
    }

    // ARTIST CONTROLS
    // These functions have various levels of artist-only control
    // mechanisms in place.
    // All functions should use onlyArtist modifier.

    /**
     * @notice changeMaxSupply allows changes to the maximum iteration count,
     * a value that is checked against during mint.
     * @dev This function will only update the maxSupply variable if the
     * submitted value is greater than or equal to the current number of minted
     * tokens. maxSupply is used in the internal _minter function to cap the
     * number of mintable tokens.
     * @param _maxSupply is the new maximum supply.
     */
    function changeMaxSupply(uint256 _maxSupply) external onlyArtist {
        require(_maxSupply >= tokensMinted.current());
        maxSupply = _maxSupply;
    }

    /**
     * @notice setArtistName allows the artist to update their name.
     * @dev This function is used to update the defaultArtistName variable.
     * @param _defaultArtistName is the new artist name.
     */
    function setDefaultArtistName(
        string memory _defaultArtistName
    ) external onlyArtist {
        defaultArtistName = _defaultArtistName;
    }

    /**
     * @notice setDefaultLicense allows the artist to update the default license.
     * @dev This function is used to update the defaultLicense variable.
     * @param _defaultLicense is the new default license.
     */
    function setDefaultLicense(
        string memory _defaultLicense
    ) external onlyArtist {
        defaultLicense = _defaultLicense;
    }

    /**
     * @notice setCollection allows the artist to update the collection name.
     * @dev This function is used to update the collection variable.
     * @param _collection is the new collection name.
     */
    function setCollection(string memory _collection) external onlyArtist {
        collection = _collection;
    }

    /**
     * @notice Updates the collection description.
     * @dev This is separate from other update functions because the collection description
     * size may be large and thus expensive to update.
     * @param _collectionDescription is the new collection description.
     */
    function setCollectionDescription(
        string memory _collectionDescription
    ) external onlyArtist {
        collectionDescription = _collectionDescription;
    }

    /**
     * @notice Updates the base external URL.
     * @dev If this is set, and no data is written to the token's externalUrl field, baseExternalUrl/tokenId will be returned from tokenDataOf.
     * If this is not set or if any data is written to the token's externalUrl field, the token's externalUrl field will be returned from tokenDataOf.
     * @param _baseExternalUrl is the new external base URL. It should end with a slash.
     */
    function setBaseExternalUrl(
        string memory _baseExternalUrl
    ) external onlyArtist {
        baseExternalUrl = _baseExternalUrl;
    }

    /**
     * @notice Updates the collection notes, which are general and collection-wide.
     * @dev This is separate from other update functions because it's unlikely to change.
     * @param _collectionNotes new collection notes.
     */
    function setCollectionNotes(
        string memory _collectionNotes
    ) external onlyArtist {
        collectionNotes = _collectionNotes;
    }

    /**
     * @notice setProjectWebsite allows the artist to update the website.
     * @dev This function is used to update the projectWebsite variable.
     * @param _projectWebsite is the new website.
     */
    function setProjectWebsite(
        string memory _projectWebsite
    ) external onlyArtist {
        projectWebsite = _projectWebsite;
    }

    /**
     * @notice setTokenData fills in data required to actualize a token with custom data.
     * @dev this is separated from MINT functions to allow flexibility in sales or
     * token distribution. Platform is allowed to access this function to assist
     * artists and to replace URI's as needed if decentralized storage fails.
     * Token must already be minted. tokensMinted.current() is always the last token's Id
     * (tokens start at index 1).
     * @param _tokenId is the token who's data is being set
     * @param _name is the name of the token
     * @param _mediaImage is the token mediaImage (additionalData may be used for more info)
     * @param _mediaType is the type of media (additionalData may be used for more info)
     * 0 for decentralized storage link(s) (eg. IPFS or Arweave)
     * 1 for directly stored data (eg. escaped or base64 encoded SVG)
     * 2 for generated from script (eg. javascript code)
     * (additional types may supported in the future)
     * 204 for media accessible elsewhere in smart contract (eg. standard / non-escaped SVG code)
     * @param _description is the description of the NFT content.
     * @param _additionalData is any on-chain data specific to the token.
     * @param _externalUrl is the external URL for the token.
     * @param _attributesArray is the token's attributes in one-dimensional string array,
     * eg. ["color", "red", "size", "large"]
     * @param _dimensions is a uint8 array of widthRatio and heightRatio data.
     */
    function setTokenData(
        uint256 _tokenId,
        string memory _name,
        string memory _mediaImage,
        string memory _mediaAnimation,
        uint8 _mediaType,
        string memory _description,
        string memory _additionalData,
        string memory _externalUrl,
        string[] memory _attributesArray,
        uint8[] memory _dimensions
    ) external onlyArtist notFrozen(_tokenId) {
        // require(_tokenId < tokensMinted.current() + 1);
        TokenData storage updateToken = tokenData[_tokenId];
        if (bytes(_name).length > 0) updateToken.name = _name;
        if (bytes(_mediaImage).length > 0) updateToken.mediaImage = _mediaImage;
        if (bytes(_mediaAnimation).length > 0)
            updateToken.mediaAnimation = _mediaAnimation;
        if (_mediaType != updateToken.mediaType)
            updateToken.mediaType = _mediaType;
        if (bytes(_description).length > 0)
            updateToken.description = _description;
        if (bytes(_additionalData).length > 0)
            updateToken.additionalData = _additionalData;
        if (_attributesArray.length > 0) {
            _addAttributes(_tokenId, _attributesArray);
        }
        if (bytes(_externalUrl).length > 0)
            updateToken.externalUrl = _externalUrl;
        if (_dimensions.length > 0) {
            updateToken.widthRatio = _dimensions[0];
            updateToken.heightRatio = _dimensions[1];
        } else if (updateToken.widthRatio == 0) {
            updateToken.widthRatio = 1;
            updateToken.heightRatio = 1;
        }
        emit TokenUpdated(_tokenId);
    }

    /**
     * @notice setTokenOverrides fills in override data for a token.
     * @dev This function is used to update the tokenData struct for a token.
     * @param _tokenId is the token who's data is being set
     * @param _licenseOverride is the new license override.
     * @param _artistNameOverride is the new artist name override.
     * @param _royaltyAddressOverride is the new royalty address override.
     */
    function setTokenOverrides(
        uint256 _tokenId,
        string memory _licenseOverride,
        string memory _artistNameOverride,
        address _royaltyAddressOverride
    ) external onlyArtist notFrozen(_tokenId) {
        TokenData storage updateToken = tokenData[_tokenId];
        if (bytes(_licenseOverride).length > 0)
            updateToken.licenseOverride = _licenseOverride;
        if (bytes(_artistNameOverride).length > 0)
            updateToken.artistNameOverride = _artistNameOverride;
        if (_royaltyAddressOverride != address(0))
            updateToken.royaltyAddressOverride = _royaltyAddressOverride;
        emit TokenUpdated(_tokenId);
    }

    /**
     * @notice setCountTransferBool sets whether a token counts transfers.
     * @dev This function is used to update the tokenData struct for a token.
     * @param _tokenId is the token who's data is being set
     * @param _countTransfers is the new countTransfers bool.
     */
    function setCountTransferBool(
        uint256 _tokenId,
        bool _countTransfers
    ) external onlyArtist notFrozen(_tokenId) {
        tokenData[_tokenId].countTransfers = _countTransfers;
        emit TokenUpdated(_tokenId);
    }

    /**
     * @notice Adds a token attribute pair to a token's traits array.
     * @dev Each tuple is a attribute type and value, eg. "color" and "red".
     * @param _tokenId is the token to update.
     * @param _traitType is the attribute type.
     * @param _value is the attribute value.
     */
    function pushTokenTrait(
        uint256 _tokenId,
        string memory _traitType,
        string memory _value
    ) external onlyArtist notFrozen(_tokenId) {
        Attribute memory newTrait = Attribute(_traitType, _value);
        attributes[_tokenId].push(newTrait);
        emit TokenUpdated(_tokenId);
    }

    /**
     * @notice Locks a token for a specified number of blocks.
     * @dev This function is used to lock a token for a specified number of blocks.
     * Only the artist can lock a token if owned, and for a maximum period of 2,000,000 blocks.
     * @param _tokenId is the token to update.
     * @param _lockPeriodInBlocks is the number of blocks to lock the token for.
     */
    function setTokenLock(
        uint256 _tokenId,
        uint256 _lockPeriodInBlocks
    ) external onlyArtist {
        require(ownerOf(_tokenId) == artistAddress, "Artist must own token");
        require(_lockPeriodInBlocks <= 2000000, "Lockup period too long");
        _lockToken(_tokenId, _lockPeriodInBlocks);
    }

    /**
     * @notice Updates a token lock.
     * @dev This function is used to shorten the lock period of a currently locked token.
     * @param _tokenId is the token to update.
     * @param _lockPeriodInBlocks is the number of blocks to lock the token for.
     */
    function updateTokenLock(
        uint256 _tokenId,
        uint256 _lockPeriodInBlocks
    ) external onlyArtist {
        require(isTokenLocked(_tokenId));
        require(
            _lockPeriodInBlocks < getRemainingLockupBlocks(_tokenId),
            "Lockup period too long"
        );
        _lockToken(_tokenId, _lockPeriodInBlocks);
    }

    /**
     * @notice Updates a token trait pair in a token's attributes array.
     * @dev Index can be ascertained from the public getter function for attributes.
     * @param _tokenId is the token to update.
     * @param _attributeIndex is the index of the attribute to update.
     * @param _traitType is the attribute type.
     * @param _value is the attribute value.
     */
    function updateTokenTrait(
        uint256 _tokenId,
        uint256 _attributeIndex,
        string memory _traitType,
        string memory _value
    ) external onlyArtist notFrozen(_tokenId) {
        attributes[_tokenId][_attributeIndex].traitType = _traitType;
        attributes[_tokenId][_attributeIndex].value = _value;
        emit TokenUpdated(_tokenId);
    }

    /**
     * @notice Removes a token trait pair from a token's attributes array.
     * @dev Index can be ascertained from the public getter function for attributes.
     * @param _tokenId is the token to update.
     * @param _attributeIndex is the index of the attribute to remove.
     */
    function removeTokenTrait(
        uint256 _tokenId,
        uint256 _attributeIndex
    ) external onlyArtist notFrozen(_tokenId) {
        uint256 lastAttributeIndex = attributes[_tokenId].length - 1;
        attributes[_tokenId][_attributeIndex] = attributes[_tokenId][
            lastAttributeIndex
        ];
        attributes[_tokenId].pop();
        emit TokenUpdated(_tokenId);
    }

    /** Updates the name of a token.
     * @param _tokenId is the token to update.
     * @param _name is the new name.
     */
    function updateTokenName(
        uint256 _tokenId,
        string memory _name
    ) external onlyArtist notFrozen(_tokenId) {
        tokenData[_tokenId].name = _name;
        emit TokenUpdated(_tokenId);
    }

    /** Updates the mediaImage of a token.
     * @param _tokenId is the token to update.
     * @param _mediaImage is the new mediaImage.
     */
    function updateTokenMediaImage(
        uint256 _tokenId,
        string memory _mediaImage
    ) external onlyArtist notFrozen(_tokenId) {
        tokenData[_tokenId].mediaImage = _mediaImage;
        emit TokenUpdated(_tokenId);
    }

    /** Updates the mediaAnimation of a token.
     * @param _tokenId is the token to update.
     * @param _mediaAnimation is the new mediaAnimation.
     */
    function updateTokenMediaAnimation(
        uint256 _tokenId,
        string memory _mediaAnimation
    ) external onlyArtist notFrozen(_tokenId) {
        tokenData[_tokenId].mediaAnimation = _mediaAnimation;
        emit TokenUpdated(_tokenId);
    }

    /** Updates the description of a token.
     * @param _tokenId is the token to update.
     * @param _description is the new description.
     */
    function updateTokenDescription(
        uint256 _tokenId,
        string memory _description
    ) external onlyArtist notFrozen(_tokenId) {
        tokenData[_tokenId].description = _description;
        emit TokenUpdated(_tokenId);
    }

    /** Updates the externalUrl of a token.
     * @param _tokenId is the token to update.
     * @param _externalUrl is the new externalUrl.
     */
    function updateTokenExternalUrl(
        uint256 _tokenId,
        string memory _externalUrl
    ) external onlyArtist {
        tokenData[_tokenId].externalUrl = _externalUrl;
        emit TokenUpdated(_tokenId);
    }

    /**
     * @notice Updates the royalty address per token.
     * @dev This updates a mapping that is used by royaltyInfo().
     * @param _tokenId is the token to update.
     * @param _royaltyAddressOverride is the address for that token.
     */
    function updateRoyaltyAddressOverride(
        uint256 _tokenId,
        address _royaltyAddressOverride
    ) external onlyArtist {
        tokenData[_tokenId].royaltyAddressOverride = _royaltyAddressOverride;
        emit TokenUpdated(_tokenId);
    }

    /** @notice Updates the additionalData of a token.
     * @param _tokenId is the token to update.
     * @param _additionalData is the new additionalData.
     */
    function updateTokenAdditionalData(
        uint256 _tokenId,
        string memory _additionalData
    ) external onlyArtist notFrozen(_tokenId) {
        tokenData[_tokenId].additionalData = _additionalData;
        emit TokenUpdated(_tokenId);
    }

    /** Updates the artistNameOverride of a token.
     * @param _tokenId is the token to update.
     * @param _artistNameOverride is the new artistNameOverride.
     */
    function updateArtistNameOverride(
        uint256 _tokenId,
        string memory _artistNameOverride
    ) external onlyArtist notFrozen(_tokenId) {
        tokenData[_tokenId].artistNameOverride = _artistNameOverride;
        emit TokenUpdated(_tokenId);
    }

    /**
     * @notice Allows manual setting tokenEntropy for a token.
     * @dev This is used for curated generative mints.
     * @param _tokenId is the token to update.
     * @param _tokenEntropy is the new tokenEntropy.
     */
    function updateTokenEntropy(
        uint256 _tokenId,
        uint256 _tokenEntropy
    ) external onlyArtist notFrozen(_tokenId) {
        tokenData[_tokenId].tokenEntropy = _tokenEntropy;
        emit TokenUpdated(_tokenId);
    }

    /** Updates the mediaType of a token.
     * @param _tokenId is the token to update.
     * @param _mediaType is the new mediaType.
     */
    function updateTokenMediaType(
        uint256 _tokenId,
        uint8 _mediaType
    ) external onlyArtist notFrozen(_tokenId) {
        tokenData[_tokenId].mediaType = _mediaType;
        emit TokenUpdated(_tokenId);
    }

    /** Updates the dimensions of a token.
     * @param _tokenId is the token to update.
     * @param _dimensions is a uint8 array of widthRatio and heightRatio data.
     */
    function updateTokenDimensions(
        uint256 _tokenId,
        uint8[] memory _dimensions
    ) external onlyArtist notFrozen(_tokenId) {
        tokenData[_tokenId].widthRatio = _dimensions[0];
        tokenData[_tokenId].heightRatio = _dimensions[1];
        emit TokenUpdated(_tokenId);
    }

    /**
     * @notice toggleMint pauses and unpauses mint.
     */
    function toggleMint() external onlyArtist {
        mintActive = !mintActive;
    }

    /**
     * @notice freezeToken freezes a token's data.
     */
    function freezeToken(uint256 _tokenId) external onlyArtist {
        tokenData[_tokenId].frozen = true;
    }

    // MINTER CONTROLS
    // These functione can only be called by the minter or artist.

    /**
     * @notice mintToAddress can only be called by the artist and the minter
     * account, and it mints to a specified address.
     * @dev Variation of a mint function that uses a submitted address as the
     * account to mint to. The artist account can bypass the mintActive requirement.
     * @param _to is the address to send the token to.
     */
    function mintToAddress(address _to) external {
        require(msg.sender == artistAddress || msg.sender == minterAddress);
        require(mintActive || msg.sender == artistAddress);
        _minter(_to);
    }

    // OWNER CONTROLS
    // These are contract-level controls.
    // All should use the onlyOwner modifier.

    /**
     * @notice ownerPauseMint pauses minting.
     * @dev onlyOwner modifier gates access.
     */
    function ownerPauseMint() external onlyOwner {
        mintActive = false;
    }

    /**
     * @notice ownerSetMinterAddress sets/updates the project's approved minting address.
     * @dev minter can be any type of account.
     * @param _minterAddress is the new account to be set as the minter.
     */
    function ownerSetMinterAddress(address _minterAddress) external onlyOwner {
        minterAddress = _minterAddress;
    }

    /**
     * @notice ownerSetAddresses sets authorized addresses.
     * @dev This must be set prior to executing many other functions.
     * @param _artistAddress is the new artist address.
     * @param _platformAddress is the new platform address.
     */
    function ownerSetAddresses(
        address _artistAddress,
        address _platformAddress
    ) external onlyOwner {
        artistAddress = _artistAddress;
        platformAddress = _platformAddress;
    }

    /**
     * @notice ownerSetRoyaltyData updates the royalty address and BPS for the project.
     * @dev This function allows changes to the payments address and secondary sale
     * royalty amount. After setting values, _setDefaultRoyalty is called in
     * order to update the imported EIP-2981 contract functions.
     * @param _defaultRoyaltyAddress is the new payments address.
     * @param _royaltyBPS is the new projet royalty amount, measured in
     * base percentage points.
     */
    function ownerSetRoyaltyData(
        address _defaultRoyaltyAddress,
        uint96 _royaltyBPS
    ) external onlyOwner {
        defaultRoyaltyAddress = _defaultRoyaltyAddress;
        royaltyBPS = _royaltyBPS;
        _setDefaultRoyalty(_defaultRoyaltyAddress, _royaltyBPS);
    }

    /**
     * @notice ownerSetBaseURI sets/updates the project's baseURI.
     * @dev baseURI is appended with tokenId and is returned in tokenURI calls.
     * @dev _newBaseURI is used instead of _baseURI because an override function
     * with that name already exists.
     * @param _newBaseURI is the API endpoint base for tokenURI calls.
     */
    function ownerSetBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    // INTERNAL FUNCTIONS
    // These are helper functions that can only be called from within this contract.

    /**
     * @notice _minter is the internal function that generates mints.
     * @dev Minting function called by the public 'mintToAddress' function.
     * The artist can bypass the payment requirement.
     * @param _to is the address to send the token to.
     */
    function _minter(address _to) internal {
        require(tokensMinted.current() < maxSupply, "All minted.");
        tokensMinted.increment();
        uint256 tokenId = tokensMinted.current();
        _assignDecimalEntropy(tokenId);
        _safeMint(_to, tokenId);
    }

    /** 
     * @notice _addAttributes adds attributes to a token.
     * @dev This function is used to add attributes to a token.
     * @param _tokenId is the token to update.
     * @param _attributesArray is the token's attributes in one-dimensional string array,
     */
    function _addAttributes(uint256 _tokenId, string[] memory _attributesArray) internal {
            for (uint256 i = 0; i < _attributesArray.length; i += 2) {
                Attribute memory newAttribute = Attribute(
                    _attributesArray[i],
                    _attributesArray[i + 1]
                );
                attributes[_tokenId].push(newAttribute);
            }
    }

    /**
     * @notice Internal function to execute token locking logic.
     * @param _tokenId is the token to update.
     * @param _lockPeriodInBlocks is the number of blocks to lock the token for.
     */
    function _lockToken(
        uint256 _tokenId,
        uint256 _lockPeriodInBlocks
    ) internal {
        uint256 unlockBlock = block.number + _lockPeriodInBlocks;
        tokenData[_tokenId].unlockBlock = unlockBlock;
        emit TokenLocked(_tokenId, unlockBlock);
    }

    /**
     * @notice _assignDecimalEntropy generates the token's decimal entropy.
     * @dev This creates a series of digits used as token entropy, created
     * from various data inputs. Even with concurrent mints in a single block,
     * each _tokenId will be unique, resulting in unique hashes.
     * @param _tokenId is the token that the data will get assigned to.
     */
    function _assignDecimalEntropy(uint256 _tokenId) internal {
        tokenData[_tokenId].tokenEntropy = uint256(
            keccak256(
                abi.encodePacked(
                    _tokenId,
                    block.number,
                    collection,
                    block.basefee,
                    _tokenId ** 2,
                    block.timestamp
                )
            )
        );
    }

    /**
     * @notice _strToUint converts a string to a uint.
     * @dev This function is called if a tokenId reference is likely, in the additionalData storage.
     * If the string is not a number, the conversion will not be accurate and the function will return false.
     * @param _str is the string to convert.
     * @return res is the converted uint.
     * @return success is whether the conversion was successful.
     */
    function _strToUint(
        string memory _str
    ) internal pure returns (uint256 res, bool success) {
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if (
                (uint8(bytes(_str)[i]) - 48) < 0 ||
                (uint8(bytes(_str)[i]) - 48) > 9
            ) {
                return (0, false);
            }
            res +=
                (uint8(bytes(_str)[i]) - 48) *
                10 ** (bytes(_str).length - i - 1);
        }
        return (res, true);
    }
}
