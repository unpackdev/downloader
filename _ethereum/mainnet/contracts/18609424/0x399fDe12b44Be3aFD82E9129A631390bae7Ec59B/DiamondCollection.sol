// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Carbon21.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./IERC2981.sol";
import "./IERC20.sol";
import "./ERC20Burnable.sol";
import "./Strings.sol";

contract DiamondCollection is ERC1155Supply, Ownable, IERC2981 {
    using Strings for uint256;

    // Tokens
    address public carbon21Address;
    address public tokenAddress;

    // Roles
    address public minter;
    address public scientists;

    //collection details
    string public name;
    string public externalURI;
    string public symbol;
    uint256 public lockPercentage;
    uint256 public burnAmount = 0;
    string public imageURI;
    uint256 public minLockDuration = 172800; // 30 days
    uint256 public maxLockDuration = 1051200; // 6 months
    uint256 public cardMaxSupply = 100001;
    uint256 public cardMinSupply = 20;
    bool public isDirectory = true;
    uint256 public maxRoyalty = 500;

    enum ValidationStatus { Waiting, Accepted, Refused }
    
    struct Blueprint {
        uint256 nftId;
        address creator;
        string creatorName;
        uint256 maxSupply;
        uint256 minted;
        string name;
        string description;
        string fileExtension;
        string animationFileExtension;
        bool locked;
    }

    struct BlueprintProperties {
        uint256 startDate;
        uint256 endDate;
        uint256 creationDate;
        uint256 ruleSetId;
        uint256 price;
        uint256 royaltyFee;
        address royaltyRecipient;
        ValidationStatus validationStatus;
    }

    struct BlueprintAttributes {
        mapping(string => string) attributes;
        mapping(string => uint256) numericAttributes;
        mapping(string => string) numericDisplayTypes;
        mapping(string => uint256) numericMaxValues;
        string[] attributeKeys;
        string[] numericAttributeKeys;
    }

    mapping(uint256 => Blueprint) public blueprints;
    mapping(uint256 => BlueprintProperties) public blueprintProperties;
    mapping(uint256 => BlueprintAttributes) private blueprintAttributes;
    mapping(uint256 => uint256) public tokenIdToBlueprintId;
    uint256 public blueprintCount = 0;
    uint256 public nftCount = 0;

    event BlueprintCreated(uint256 blueprintId, address creator, uint256 price, uint256 maxSupply);
    event BlueprintUpdated(uint256 indexed _blueprintId);
    event BlueprintValidated(uint256 blueprintId, uint256 nftId, ValidationStatus status);
    event BlueprintRefused(uint256 blueprintId, ValidationStatus status);
    event NFTMinted(address indexed to, uint256 tokenId, uint256 amount);
    event PermanentURI(string _uri, uint256 indexed _tokenId);

    modifier onlyMinter() {
        require(msg.sender == minter, "Caller is not the minter");
        _;
    }

    modifier onlyScientists() {
        require(msg.sender == scientists, "Caller is not the scientists");
        _;
    }

    modifier isUnlocked(uint256 blueprintId) {
        require(blueprints[blueprintId].locked == false, "Blueprint is locked and can't be changed");
        _;
    }

    constructor(address _tokenAddress, string memory _imageURI, uint256 _lockPercentage, string memory _name, string memory _symbol) ERC1155("") {
        tokenAddress = _tokenAddress;
        lockPercentage = _lockPercentage;
        name = _name;
        symbol = _symbol;
        imageURI = _imageURI;
        externalURI = "https://carbon21.io/collection/original/";
        carbon21Address = 0x2C642Cd3beD9b4e4EEEc493611779f13efB502F1;

        // Initiate Minter and Scientists Roles to contract deployer
        minter = msg.sender;
        scientists = msg.sender;

        // Initiate the Genesis Card without the mapping
        blueprints[0].nftId = 0;
        blueprints[0].creator = 0x082e8a9dA4397bc24ac22FAD57CD7063DC1cd58B;
        blueprints[0].creatorName = "Onigiri";
        blueprints[0].maxSupply = type(uint256).max;
        blueprints[0].minted = 1;
        blueprints[0].name = "The Community";
        blueprints[0].description = "A memecoin is defined by its community. This card allows owners to become scientist and accept blueprints in the directory.";
        blueprints[0].fileExtension = ".jpg";
        blueprints[0].animationFileExtension = '';
        blueprints[0].locked = false;
        
        // Properties
        blueprintProperties[0].price = 0;
        blueprintProperties[0].ruleSetId = 0;
        blueprintProperties[0].creationDate = block.timestamp;
        blueprintProperties[0].startDate = 1700514000;
        blueprintProperties[0].endDate = type(uint256).max;
        blueprintProperties[0].royaltyFee = 0;
        blueprintProperties[0].royaltyRecipient = 0x082e8a9dA4397bc24ac22FAD57CD7063DC1cd58B;
        blueprintProperties[0].validationStatus = ValidationStatus.Accepted;

        // Now set the attributes for the Genesis Card
        blueprintAttributes[0].attributes["Type"] = "Genesis";
        blueprintAttributes[0].attributeKeys.push("Type");

        tokenIdToBlueprintId[0] = 0;
        _mint(msg.sender, 0, 1, "");
    }

    function setLockPercentage(uint256 _lockPercentage) external onlyScientists {
        lockPercentage = _lockPercentage;
    }

    function createBlueprint(
        address _creator,
        string memory _creatorName,
        uint256 _price,
        uint256 _maxSupply,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _ruleSetId,
        string memory _name,
        string memory _description,
        string memory _fileExtension
    ) external {
        require(_startDate < _endDate || _endDate == 0, "Start date should be before end date");
        require( _maxSupply < cardMaxSupply && _maxSupply > cardMinSupply, "Supply should be in the collection range");

        if (_creator != address(0)) {
            _creator = msg.sender;
        }

        blueprintCount++;
        uint256 id = blueprintCount;

        Blueprint storage newBlueprint = blueprints[id];
        newBlueprint.creator = _creator;
        newBlueprint.creatorName = _creatorName;
        newBlueprint.maxSupply = _maxSupply;
        newBlueprint.name = _name;
        newBlueprint.description = _description;
        newBlueprint.fileExtension = _fileExtension;
        newBlueprint.animationFileExtension = _fileExtension;
        newBlueprint.locked = false;
        
        BlueprintProperties storage properties = blueprintProperties[id];
        properties.ruleSetId = _ruleSetId;
        properties.startDate = _startDate == 0 ? block.timestamp : _startDate;
        properties.endDate = _endDate == 0 ? type(uint256).max : _endDate;
        properties.creationDate = block.timestamp;
        properties.price = _price;
        properties.royaltyRecipient = _creator;
        properties.validationStatus = ValidationStatus.Waiting;

        if (burnAmount > 0) {
            Carbon21 carbonContract = Carbon21(carbon21Address);
            carbonContract.burnFrom(msg.sender, burnAmount);
        }

        emit BlueprintCreated(blueprintCount, _creator, _price, _maxSupply);
    }

    function lockBlueprint(uint256 _blueprintId) external {
        require(_blueprintId <= blueprintCount, "Blueprint does not exist");
        require(blueprintProperties[_blueprintId].validationStatus == ValidationStatus.Accepted, "Can't lock a non-validated blueprint");
        require(blueprints[_blueprintId].locked == false, "Blueprint already locked");
        require(msg.sender == blueprints[_blueprintId].creator, "Only the creator can lock the blueprint");

        blueprints[_blueprintId].locked = true;
        emit PermanentURI(uri(blueprints[_blueprintId].nftId), blueprints[_blueprintId].nftId);
    }

    function updateBlueprintSupply(uint256 _blueprintId, uint256 _maxSupply) external isUnlocked(_blueprintId) {
        checkBlueprintRequirementsForUpdate(_blueprintId, false, false);
        blueprints[_blueprintId].maxSupply = _maxSupply;
        emitBlueprintUpdated(_blueprintId);
    }

    function updateBlueprintMintRules(uint256 _blueprintId, uint256 _ruleSetId) external isUnlocked(_blueprintId) {
        checkBlueprintRequirementsForUpdate(_blueprintId, true, false);
        blueprintProperties[_blueprintId].ruleSetId = _ruleSetId;
        emitBlueprintUpdated(_blueprintId);
    }

    function updateMintTime(uint256 _blueprintId, uint256 _startDate, uint256 _endDate) external isUnlocked(_blueprintId) {
        checkBlueprintRequirementsForUpdate(_blueprintId, true, false);
        if(_startDate != 0) blueprintProperties[_blueprintId].startDate = _startDate;
        if(_endDate != 0) blueprintProperties[_blueprintId].endDate = _endDate;
        emitBlueprintUpdated(_blueprintId);
    }

    function updateBlueprintPrice(uint256 _blueprintId, uint256 _price) external isUnlocked(_blueprintId) {
        checkBlueprintRequirementsForUpdate(_blueprintId, false, false);
        blueprintProperties[_blueprintId].price = _price;
        emitBlueprintUpdated(_blueprintId);
    }

    function updateBlueprintInfo(uint256 _blueprintId, string memory _name, string memory _description, string memory _fileExtension, string memory _animationFileExtension) external isUnlocked(_blueprintId) {
        checkBlueprintRequirementsForUpdate(_blueprintId, false, true);
        blueprints[_blueprintId].name = _name;
        blueprints[_blueprintId].description = _description;
        blueprints[_blueprintId].fileExtension = _fileExtension;
        blueprints[_blueprintId].animationFileExtension = _animationFileExtension;
        emitBlueprintUpdated(_blueprintId);
    }

    function setRoyalty(uint256 tokenId, address recipient, uint256 amount) public {
        uint256 _blueprintId = getBlueprintId(tokenId);
        checkBlueprintRequirementsForUpdate(_blueprintId, false, true);
        require(amount <= maxRoyalty, "Royalty fee will exceed salePrice");
        require(recipient != address(0), "Recipient should be present");

        blueprintProperties[_blueprintId].royaltyFee = amount;
        blueprintProperties[_blueprintId].royaltyRecipient = recipient;
    }

    function setBlueprintAttributes(
        uint256 _blueprintId,
        string[] memory stringAttributeKeys,
        string[] memory attributeValues,
        string[] memory numericAttributeKeys,
        uint256[] memory numericAttributeValues,
        uint256[] memory numericAttributeMaxValues,
        string[] memory numericAttributeDisplayTypes
    ) external isUnlocked(_blueprintId) {
        checkBlueprintRequirementsForUpdate(_blueprintId, false, true);
        require(stringAttributeKeys.length == attributeValues.length, "String keys and values mismatch");
        require(numericAttributeKeys.length == numericAttributeValues.length, "Numeric keys and values mismatch");
        require(numericAttributeKeys.length == numericAttributeDisplayTypes.length, "Display types mismatch");
        require(numericAttributeKeys.length == numericAttributeMaxValues.length, "Max values mismatch");

        BlueprintAttributes storage attributes = blueprintAttributes[_blueprintId];
        // Clear existing attributes if they exist
        if (attributes.attributeKeys.length > 0 || attributes.numericAttributeKeys.length > 0) {
            for (uint i = 0; i < attributes.attributeKeys.length; i++) {
                delete attributes.attributes[attributes.attributeKeys[i]];
            }
            delete attributes.attributeKeys;

            for (uint i = 0; i < attributes.numericAttributeKeys.length; i++) {
                delete attributes.numericAttributes[attributes.numericAttributeKeys[i]];
                delete attributes.numericDisplayTypes[attributes.numericAttributeKeys[i]];
                delete attributes.numericMaxValues[attributes.numericAttributeKeys[i]];
            }
            delete attributes.numericAttributeKeys;
        }

        // Set or update string attributes
        for (uint i = 0; i < stringAttributeKeys.length; i++) {
            attributes.attributes[stringAttributeKeys[i]] = attributeValues[i];
            attributes.attributeKeys.push(stringAttributeKeys[i]);
        }

        // Set or update numeric attributes
        for (uint i = 0; i < numericAttributeKeys.length; i++) {
            attributes.numericAttributes[numericAttributeKeys[i]] = numericAttributeValues[i];
            attributes.numericDisplayTypes[numericAttributeKeys[i]] = numericAttributeDisplayTypes[i];
            attributes.numericMaxValues[numericAttributeKeys[i]] = numericAttributeMaxValues[i];
            attributes.numericAttributeKeys.push(numericAttributeKeys[i]);
        }
        emitBlueprintUpdated(_blueprintId);
    }

    function checkBlueprintRequirementsForUpdate(uint256 _blueprintId, bool scientistsAllowed, bool allowedAfterValidation) internal view {
        require(_blueprintId <= blueprintCount, "Blueprint does not exist");
        if (scientistsAllowed == false) {
            require((msg.sender == blueprints[_blueprintId].creator), "Only the creator can modify blueprint");
        } else {
            require((msg.sender == blueprints[_blueprintId].creator) || (msg.sender == scientists), "Only the creator or scientists can modify blueprint");
        }
        if (allowedAfterValidation) {
            require(blueprintProperties[_blueprintId].validationStatus != ValidationStatus.Refused, "Can't modify a refused blueprint");
        } else {
            require(blueprintProperties[_blueprintId].validationStatus == ValidationStatus.Waiting, "Can only be changed for blueprints in validation process");
        }
    }

    function emitBlueprintUpdated(uint256 _blueprintId) internal {
        emit BlueprintUpdated(_blueprintId);
        
        if (blueprintProperties[_blueprintId].validationStatus == ValidationStatus.Accepted) {
            uint256 tokenId = blueprints[_blueprintId].nftId;
            string memory newUri = uri(blueprints[_blueprintId].nftId);
            emit URI(newUri, tokenId);
        }
    }

    function validateBlueprint(uint256 _blueprintId) external onlyScientists {
        require(_blueprintId <= blueprintCount, "Blueprint does not exist");
        require(blueprintProperties[_blueprintId].validationStatus == ValidationStatus.Waiting, "Blueprint is not pending approval");

        nftCount++;
        blueprints[_blueprintId].nftId = nftCount;
        tokenIdToBlueprintId[nftCount] = _blueprintId;

        blueprintProperties[_blueprintId].validationStatus = ValidationStatus.Accepted;
        emit BlueprintValidated(_blueprintId, blueprints[_blueprintId].nftId, ValidationStatus.Accepted);
    }

    function refuseBlueprint(uint256 _blueprintId) external onlyScientists {
        require(_blueprintId <= blueprintCount, "Blueprint does not exist");
        require(blueprintProperties[_blueprintId].validationStatus == ValidationStatus.Waiting, "Blueprint is not pending approval");

        blueprintProperties[_blueprintId].validationStatus = ValidationStatus.Refused;
        emit BlueprintRefused(_blueprintId, ValidationStatus.Refused);
    }

    function getBlueprint(uint256 _blueprintId) external view returns (
        address creator,
        uint256 price,
        uint256 maxSupply,
        uint256 startDate,
        uint256 endDate,
        uint256 minted,
        uint256 ruleSetId,
        ValidationStatus validationStatus
    ) {
        require(_blueprintId <= blueprintCount, "Blueprint does not exist");
        Blueprint memory blueprint = blueprints[_blueprintId];
        BlueprintProperties memory properties = blueprintProperties[_blueprintId];
        return (
            blueprint.creator,
            properties.price,
            blueprint.maxSupply,
            properties.startDate,
            properties.endDate,
            blueprint.minted,
            properties.ruleSetId,
            properties.validationStatus
        );
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address, uint256)
    {
        uint256 _blueprintId = getBlueprintId(tokenId);
        uint256 royaltyAmount = (salePrice * blueprintProperties[_blueprintId].royaltyFee) / 10000;
        return (blueprintProperties[_blueprintId].royaltyRecipient, royaltyAmount);
    }

    function mint(address to, uint256 tokenId, uint256 amount) external onlyMinter {
        uint256 _blueprintId = getBlueprintId(tokenId);
        require(blueprintProperties[_blueprintId].validationStatus == ValidationStatus.Accepted, "TokenId does not correspond to an accepted blueprint");
        require((block.timestamp >= blueprintProperties[_blueprintId].startDate) && (block.timestamp <= blueprintProperties[_blueprintId].endDate), "Minting period not active");
        require(blueprints[_blueprintId].minted + amount <= blueprints[_blueprintId].maxSupply, "Exceeds max supply");

        blueprints[_blueprintId].minted += amount;

        _mint(to, tokenId, amount, "");
        emit NFTMinted(to, tokenId, amount);
        emit BlueprintUpdated(_blueprintId);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        uint256 blueprintId = getBlueprintId(tokenId);

        string memory baseURI = string(abi.encodePacked(imageURI, blueprintId.toString(), blueprints[blueprintId].fileExtension));
        
        return string(abi.encodePacked(
            '{"name": "', blueprints[blueprintId].name,
            '", "description": "', blueprints[blueprintId].description,
            '", "image": "', baseURI,
            getAnimation(blueprintId),
            '", "external_url": "', externalURI, tokenId.toString(),
            '", "attributes": [',
            getAttributes(blueprintId),
            getSeriesAndCard(tokenId),
            getSupplyInfo(blueprintId, tokenId),
            getImportantDates(blueprintId),
            '{"trait_type":"Artist","value":"', blueprints[blueprintId].creatorName,'"}'
            ']}'
        ));
    }

    function getImportantDates(uint256 blueprintId) internal view returns (string memory) {
        string memory importantDates = '';
        if (blueprintProperties[blueprintId].endDate != type(uint256).max && blueprintProperties[blueprintId].endDate > block.timestamp) {
            importantDates = string(abi.encodePacked(importantDates, '{"trait_type":"Minting Ends","display_type": "date","value":', blueprintProperties[blueprintId].endDate.toString(),'},'));
        }
        importantDates = string(abi.encodePacked(importantDates, '{"trait_type":"Creation","display_type": "date","value":', blueprintProperties[blueprintId].creationDate.toString(),'},'));
        return importantDates;
    }

    function getSupplyInfo(uint256 blueprintId, uint256 tokenId) internal view returns (string memory) {
        string memory supplyInformations = '';
        supplyInformations =  string(abi.encodePacked(supplyInformations,'{"trait_type":"Supply","value":"', totalSupply(tokenId).toString(),'"},'));
        if (blueprintId == 0) {
            return string(abi.encodePacked(supplyInformations,'{"trait_type":"Max Supply","value":"Infinite"},'));
        }
        return string(abi.encodePacked(supplyInformations, '{"trait_type":"Minted","display_type":"number","value":', blueprints[blueprintId].minted.toString(),',"max_value":', blueprints[blueprintId].maxSupply.toString(),'},'));
    }

    function getAnimation(uint256 blueprintId) internal view returns (string memory) {
        string memory animationURI = '';
        if (bytes( blueprints[blueprintId].animationFileExtension).length > 0) {
            animationURI = string(abi.encodePacked('", "animation_url": "', imageURI, blueprintId.toString(),  blueprints[blueprintId].animationFileExtension));
        }
        return animationURI;
    }

    function getAttributes(uint256 blueprintId) public view returns (string memory) {
        string memory attributes = '';
        for (uint i = 0; i < blueprintAttributes[blueprintId].attributeKeys.length; i++) {
            string memory key = blueprintAttributes[blueprintId].attributeKeys[i];
            string memory value = blueprintAttributes[blueprintId].attributes[key];
            attributes = string(abi.encodePacked(attributes, '{"trait_type":"', key, '","value":"', value, '"},'));
        }
        for (uint i = 0; i < blueprintAttributes[blueprintId].numericAttributeKeys.length; i++) {
            string memory key = blueprintAttributes[blueprintId].numericAttributeKeys[i];
            uint256 value = blueprintAttributes[blueprintId].numericAttributes[key];
            string memory displayType = blueprintAttributes[blueprintId].numericDisplayTypes[key];
            uint256 maxValue = blueprintAttributes[blueprintId].numericMaxValues[key];
            attributes = string(abi.encodePacked(attributes, '{"trait_type":"', key, '","value":', value.toString(), ',"max_value":', maxValue.toString(),  ',"display_type":"', displayType, '"},'));
        }
        return attributes;
    }

    function getSeriesAndCard(uint256 tokenId) internal view returns (string memory) {
        if (tokenId == 0 || isDirectory == false) {
            return "";
        }

        uint256 series = (tokenId - 1) / 50 + 1;
        uint256 card = (tokenId - 1) % 50 + 1;

        // Convert the numbers to strings
        string memory seriesStr = series.toString();
        string memory cardStr = card.toString();
        if(bytes(seriesStr).length == 1) seriesStr = string(abi.encodePacked('0', seriesStr));
        if(bytes(cardStr).length == 1) cardStr = string(abi.encodePacked('0', cardStr));

        return string(abi.encodePacked('{"trait_type":"Series","value":"', seriesStr,'"}, {"trait_type":"Card","value":"', cardStr, '"},'));
    }

    function getBlueprintId(uint256 tokenId) public view returns (uint256) {
        if (tokenId == 0) {
            return 0;
        }
        require(tokenIdToBlueprintId[tokenId] != 0, "Invalid tokenId or blueprintId not set");
        return tokenIdToBlueprintId[tokenId];
    }

    // Scientists setters functions
    function activateDirectory(bool _isDirectory) external onlyScientists {
        isDirectory = _isDirectory;
    }
    function changeLockDuration(uint256 _maxLockDuration, uint256 _minLockDuration) external onlyScientists {
        require(_maxLockDuration > _minLockDuration, "Max lock duration should be greater than min lock duration");
        maxLockDuration = _maxLockDuration;
        minLockDuration = _minLockDuration;
    }
    function setSupplyBoundaries(uint256 _cardMinSupply, uint256 _cardMaxSupply) external onlyScientists {
        require(_cardMaxSupply > _cardMinSupply, "Max supply should be greater than min supply");
        cardMaxSupply = _cardMaxSupply;
        cardMinSupply = _cardMinSupply;
    }
    function setURIs(string memory _imageURI, string memory _externalURI) external onlyScientists {
        imageURI = _imageURI;
        externalURI = _externalURI;
    }
    function setBurnAmount(uint256 _burnAmount) external onlyScientists {
        burnAmount = _burnAmount;
    }
    function setMaxRoyalty(uint256 _maxRoyalty) external onlyScientists {
        require(_maxRoyalty <= 10000, "Max royalty should be lower than 10000");
        maxRoyalty = _maxRoyalty;
    }

    // Owner setters functions
    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }
    function setScientists(address _scientists) external onlyOwner {
        scientists = _scientists;
    }
}