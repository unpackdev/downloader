pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./Ownable.sol";
import "./SafeTransferLib.sol";
import "./ERC2981.sol";
import "./IDelegationRegistry.sol";
import "./BytecodeStorage.sol";

// errors
error NotAllowListed();
error NotDelegate();
error PriceIncorrect();
error MintSupplyExceeded();
error MaxMintExceeded();
error NotAllowListPhase();
error NotPublicMintPhase();

error IndexOutOfRange();
error CodeFrozen();

contract NaturalStatic is ERC721A, Ownable, ERC2981 {
    using BytecodeStorage for string;

    event Minted(uint256 tokenId, uint256 seed);

    enum PHASE {
        NOT_ACTIVE,
        ALLOW_LIST,
        PUBLIC_MINT
    }

    // constants
    uint256 public constant MINT_SUPPLY = 416;
    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public constant ALLOWLIST_MINT_PRICE = 0.1 ether;

    address private constant _DELEGATION_REGISTRY = 0x00000000000076A84feF008CDAbe6409d2FE638B;
    string private constant _DESCRIPTION =
        "Natural Static is a generative NFT series that feeds video of natural motion into a pixel-based water simulation, creating representations of physical motion that are highly digital and deeply analog. Jonathan Chomko, 2023.";

    string[] private VIDEO_SPEEDS = ["Normal", "Half"];
    string[] private FEEDBACK_MODE = ["Increment", "Decrement", "RGBIncrement", "RGBDecrement"];
    string[] private COLOUR_MODES = [
        "Gold",
        "RedBlue",
        "Blue",
        "Dark",
        "Light",
        "Gray",
        "Actual",
        "RGBRedBlue",
        "RGBLight",
        "RGBGold",
        "RGBDark",
        "RGBBlue",
        "RGBGray"
    ];

    string public baseURI = "https://arweave.net/OxlirWSVjrnevbd2CmZStX7BnWcKJx_mrQzDd8kVNhI";
    bytes32 public merkleRoot = 0x53980f941adfd166a42bf508a6ea690541eb1096e6db49a28c86461dc84c4cc1;
    address public fundsRecipient = 0x1A3E3367A39BEc5c710095f0F81fC5ED422860B1;

    mapping(uint256 => uint256) private _artworkSeeds;

    bool public isCodeFrozen = false;
    mapping(uint256 => address) public projectScriptChunks;

    uint8 public phase = uint8(PHASE.NOT_ACTIVE);

    constructor() ERC721A("Natural Static", "NS") {
        _setDefaultRoyalty(fundsRecipient, 1000);
    }

    // script writing and reading
    function addProjectScript(string memory script, uint256 index) external onlyOwner {
        if (isCodeFrozen) revert CodeFrozen();
        address scriptChunk = script.writeToBytecode();
        projectScriptChunks[index] = scriptChunk;
    }

    function readProjectScript(uint256 index) external view returns (string memory) {
        return BytecodeStorage.readFromBytecode(projectScriptChunks[index]);
    }

    function freezeCode() external onlyOwner {
        isCodeFrozen = true;
    }

    // setters
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setFundsRecipient(address _fundsRecipient) external onlyOwner {
        fundsRecipient = _fundsRecipient;
    }

    function setDefaultRoyalty(address _royaltyRecipient, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_royaltyRecipient, _feeNumerator);
    }

    function setPhase(uint256 newPhase) external onlyOwner {
        phase = uint8(newPhase);
    }

    // mint
    function mintAllowList(uint256 _quantity, bytes32[] calldata _proof)
        external
        payable
        onlyWhenAllowlistPhase
        isBelowOrEqualsMintSupply(_quantity)
    {
        if (_quantity > 5) revert MaxMintExceeded();
        if (!isAllowListed(msg.sender, _proof)) revert NotAllowListed();

        uint256 totalPrice = ALLOWLIST_MINT_PRICE * _quantity;
        if (msg.value != totalPrice) revert PriceIncorrect();

        _adminMint(msg.sender, _quantity);
    }

    function mintAllowListAsDelegate(uint256 _quantity, address vault, bytes32[] calldata _proof)
        external
        payable
        onlyWhenAllowlistPhase
        isBelowOrEqualsMintSupply(_quantity)
    {
        if (_quantity > 5) revert MaxMintExceeded();
        if (!IDelegationRegistry(_DELEGATION_REGISTRY).checkDelegateForAll(msg.sender, vault)) revert NotDelegate();
        if (!isAllowListed(vault, _proof)) revert NotAllowListed();

        uint256 totalPrice = ALLOWLIST_MINT_PRICE * _quantity;
        if (msg.value != totalPrice) revert PriceIncorrect();

        _adminMint(msg.sender, _quantity);
    }

    function mint(uint256 _quantity) external payable onlyWhenPublicMintPhase isBelowOrEqualsMintSupply(_quantity) {
        if (_quantity > 5) revert MaxMintExceeded();

        uint256 totalPrice = MINT_PRICE * _quantity;
        if (msg.value != totalPrice) revert PriceIncorrect();

        _adminMint(msg.sender, _quantity);
    }

    function adminMint(address _to, uint256 _quantity) external onlyOwner isBelowOrEqualsMintSupply(_quantity) {
        _adminMint(_to, _quantity);
    }

    function _adminMint(address _to, uint256 _quantity) internal {
        uint256 newTokenId;

        for (uint256 i = 0; i < _quantity; i++) {
            newTokenId = _totalMinted() + i;
            _createArtworkSeed(newTokenId);
            emit Minted(newTokenId, _artworkSeeds[newTokenId]);
        }

        _mint(_to, _quantity);
    }

    function isAllowListed(address _wallet, bytes32[] calldata _proof) public view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(_wallet)));
    }

    // metadata
    function _createArtworkSeed(uint256 tokenId) internal {
        _artworkSeeds[tokenId] = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId)));
    }

    function getArtworkSeed(uint256 tokenId) external view returns (uint256) {
        return _artworkSeeds[tokenId];
    }

    function generateValueFromSeed(uint256 seed, uint8 index, uint256 range) internal pure returns (uint256) {
        if (index > 31) revert IndexOutOfRange();
        return ((seed >> (index * 8)) & 0xFF) % range;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return generateURIFromBase(tokenId, baseURI);
    }

    function generateURIFromBase(uint256 tokenId, string memory _baseURI) public view virtual returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        uint256 seed = _artworkSeeds[tokenId];

        string memory animationUrl = string(
            abi.encodePacked(_baseURI, "/index.html?hash=", Strings.toString(seed), "&videobase=", _baseURI, "/videos")
        );
        string memory imageUrl = string(abi.encodePacked(_baseURI, "/thumbnails/", Strings.toString(tokenId), ".gif"));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Natural Static #',
                        Strings.toString(tokenId),
                        '", "description": "',
                        _DESCRIPTION,
                        "\\n \\nFullscreen: ",
                        animationUrl,
                        "\\n \\nVideo Info: ",
                        getVideoInfo(tokenId),
                        '", "image": "',
                        imageUrl,
                        '", "animation_url": "',
                        animationUrl,
                        '", ',
                        _generateTraits(tokenId),
                        "}"
                    )
                )
            )
        );

        string memory output = string(abi.encodePacked("data:application/json;base64,", json));
        return output;
    }

    function getVideoInfo(uint256 tokenId) public view virtual returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return string(abi.encodePacked(baseURI, "/video-info/", Strings.toString(tokenId), ".json"));
    }

    function _generateTraits(uint256 tokenId) internal view returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        uint256 seed = _artworkSeeds[tokenId];
        string[5] memory traits = ["Video", "Video Speed", "Feedback Direction", "Feedback Speed", "Colour Mode"];
        uint256[5] memory traitValues = _generateTraitValues(seed);

        string[5] memory traitStrings;
        // video id
        traitStrings[0] = Strings.toString(traitValues[0]);
        // video speed
        traitStrings[1] = VIDEO_SPEEDS[traitValues[1]];
        // feedback direction
        traitStrings[2] = FEEDBACK_MODE[traitValues[2]];
        // feedback speed
        traitStrings[3] = Strings.toString(traitValues[3]);
        // colour mode
        traitStrings[4] = COLOUR_MODES[traitValues[4]];

        string memory output = string(abi.encodePacked('"attributes": ['));
        for (uint256 i = 0; i < traits.length; i++) {
            if (i > 0) {
                output = string(abi.encodePacked(output, ","));
            }
            output = string(abi.encodePacked(output, _generateTrait(traits[i], traitStrings[i])));
        }
        output = string(abi.encodePacked(output, "]"));
        return output;
    }

    function _generateTraitValues(uint256 seed) internal view returns (uint256[5] memory) {
        uint256[5] memory traitValues;
        uint256 feedbackMode = generateValueFromSeed(seed, 2, FEEDBACK_MODE.length);
        uint256 colorMode;
        uint256 feedbackSpeed;

        if (feedbackMode == 0) {
            colorMode = generateValueFromSeed(seed, 3, 9);
        } else if (feedbackMode == 1) {
            colorMode = generateValueFromSeed(seed, 3, 9);
        } else if (feedbackMode == 2) {
            colorMode = generateValueFromSeed(seed, 3, 7) + 5;
        } else if (feedbackMode == 3) {
            colorMode = generateValueFromSeed(seed, 3, 5) + 7;
        }

        if (feedbackMode < 2) {
            feedbackSpeed = generateValueFromSeed(seed, 5, 3) + 2;
        } else {
            feedbackSpeed = generateValueFromSeed(seed, 5, 4) + 2;
        }

        traitValues[0] = generateValueFromSeed(seed, 0, 208);
        traitValues[1] = generateValueFromSeed(seed, 1, VIDEO_SPEEDS.length);
        traitValues[2] = feedbackMode;
        traitValues[3] = feedbackSpeed;
        traitValues[4] = colorMode;

        return traitValues;
    }

    function _generateTrait(string memory traitType, string memory value) internal pure returns (string memory) {
        return string(abi.encodePacked('{"trait_type": "', traitType, '", "value": "', value, '"}'));
    }

    // withdraw
    function withdraw() external payable onlyOwner {
        uint256 balance = address(this).balance;
        SafeTransferLib.forceSafeTransferETH(fundsRecipient, balance);
    }

    // modifiers
    modifier isBelowOrEqualsMintSupply(uint256 _amount) {
        if ((_totalMinted() + _amount) > MINT_SUPPLY) revert MintSupplyExceeded();
        _;
    }

    modifier onlyWhenAllowlistPhase() {
        if (phase != uint8(PHASE.ALLOW_LIST)) revert NotAllowListPhase();
        _;
    }

    modifier onlyWhenPublicMintPhase() {
        if (phase != uint8(PHASE.PUBLIC_MINT)) revert NotPublicMintPhase();
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}
