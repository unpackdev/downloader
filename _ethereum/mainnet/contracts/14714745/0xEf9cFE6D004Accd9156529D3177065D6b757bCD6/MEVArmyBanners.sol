// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @title: MEV Army On-Chain Banners
/// @author: x0r

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./IERC1155CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";
import "./IASCIIGenerator.sol";
import "./IMEVArmyTraitData.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    .............+*****;;*+..........+*****;.*+....;******;.***********+...;******+............*******............    //
//    .............@#####;;#&;........;@####@;+#@....+##&###+;&######&#&#%...;&#####&;..........!#&####?............    //
//    .............@#####;;&#!........!#####*.$&@....+##&###+;&##########%....!######?.........;&#&&##@;............    //
//    .............@#&&#&;;&#&;......;&####@.*##@....+##&&&#+.!??????????*.....$######+........?######+.............    //
//    .............@####&;;###?......?#####*.$##@....+#&@###+..................+######%.......+######?..............    //
//    .............@#&#&&;;###&;....;&####$.*##&@....+######+.!!?????????*......?######+......%#####@;..............    //
//    .............@##&#&;;#&&#?....?#####+.@#&&@....+######+;@&##&&&&###%......;@#####$.....+######+...............    //
//    .............@##&#&;;#####;..;&####%.*####@....+###&&#+;&###@###&##%.......+######*....@#####?................    //
//    .............@#&@#&;;&####%..%#####+.@###&@....+######+.***********+........?#####@;..!#####@;................    //
//    .............@####&;.%#####+;&@###%.;&####@....+######+.....................;&#####!.;&#####*.................    //
//    .............@##&&&;.;&####%%#&&#&;.;&####@....+######+......................*###&#@;*#####?..................    //
//    .............@####&;..?####&@&#&#?..;&####@....+######+.......................$#####!.@###@;..................    //
//    .............@####&;..;&###@&###&;..;&####@....+######+.!!!!!!!!!!?*..........;&#&@#&;*###*...................    //
//    .............@####&;...?###&&###!...;&####@....+######+;&##########%...........!#####?.$#%....................    //
//    .............@####&;...;&##@$$#&;...;&####@....+######+;&#####&##&#%............@#####++@;....................    //
//    .............+*****.....+****+*+.....*****+....;******;.***********+............;!***!;.;.....................    //
//    ..............................................................................................................    //
//    .................;!!!...............+!!!!!!!*+;...........;!!!!;...;!!!!;.........+!!*.....;!!!;..............    //
//    .................$###?..............%###&&&###@+..........;####%...!####!.........;@##?...+&##*...............    //
//    ................?##@##*.............%##*...;!##$..........;##&##+..@#&##!..........;%##%.+&#&+................    //
//    ...............+##%;&#&;............%##?+++*%##?..........;##%@#%.*##?##!............?##$&#@;.................    //
//    ..............;@#&;.*##$............%#######&$*...........;##%!##;@#$*##!.............!###$;..................    //
//    ..............%###&&&###?...........%##!;*$##%;...........;##%;&#@##+*##!..............$##+...................    //
//    .............!##$?????&##+..........%##*...?##&+..........;##%.?###@.*##!..............$##+...................    //
//    ............+&#&;.....+##@;.........%##*....!##&*.........;##%.;&##*.*##*..............$##+...................    //
//    ............;++;.......+++;.........;++;.....;+++..........++;..+++..;++;..............+++;...................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract MEVArmyBanners is Ownable, Pausable, ICreatorExtensionTokenURI {
    using Strings for uint256;

    IERC721 public constant MEVArmyNFT = IERC721(0x99cd66b3D67Cd65FbAfbD2fD49915002d4a2E0F2);
    IMEVArmyTraitData public constant MEVArmyTraitData = IMEVArmyTraitData(0xDa10ec807c17A489Ebd1DD9Bd5AAC118C2a43169);
    address public constant creatorContract = 0x645c99a7BF7eA97B772Ac07A12Cf1B90C9F3b09E;

    IASCIIGenerator public ASCIIGenerator;

    string[] public legionNames = [
        "",
        "Generalized Frontrunner",
        "Searcher",
        "Time Bandit",
        "Sandwicher",
        "Backrunner",
        "Liquidator"
    ];

    string[] public colors = ["white", "#ff0909", "#4bff00", "dodgerblue"]; // [white, red, green, blue]
    mapping(uint256 => uint256) public legionToColorIndex;
    mapping(uint256 => string) public legionToChar;

    mapping(uint256 => bool) public isTokenUsed;

    event LegionCharChanged(uint256 indexed legion, uint256 indexed char);
    event LegionColorChanged(uint256 indexed legion, uint256 indexed colorIndex);


    constructor(
        address _ASCIIGenerator
    ) {
        ASCIIGenerator = IASCIIGenerator(_ASCIIGenerator);

        // init fill char to 0
        legionToChar[1] = "0";
        legionToChar[2] = "0";
        legionToChar[3] = "0";
        legionToChar[4] = "0";
        legionToChar[5] = "0";
        legionToChar[6] = "0";
    }


    modifier onlyInLegion(uint256 _legion) {
        require(
            IERC1155(creatorContract).balanceOf(msg.sender, _legion) > 0,
            "not in legion"
        );
        _;
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }


    /**
     * @notice Mint a single legion banner based on the provided MEV Army tokenId
     * @param _tokenId of a MEV Army NFT
     */
    function mint(uint256 _tokenId) public whenNotPaused {
        _mint(_tokenId);
    }


    /**
     * @notice Batch mint multiple legion banners
     * @param _tokenIds of MEV Army NFTs you want to mint legion banners for
     */
    function batchMint(uint256[] calldata _tokenIds) public whenNotPaused {
        for (uint256 i; i < _tokenIds.length; i++) {
            _mint(_tokenIds[i]);
        }
    }


    /**
     * @notice Internal mint a single legion banner
     */
    function _mint(uint256 _tokenId) internal {
        require(!isTokenUsed[_tokenId], "already minted");

        require(MEVArmyNFT.ownerOf(_tokenId) == msg.sender, "not owner");

        uint256 legion = MEVArmyTraitData.getLegionIndex(_tokenId);

        isTokenUsed[_tokenId] = true;

        address[] memory to = new address[](1);
        to[0] = msg.sender;

        uint256[] memory token = new uint256[](1);
        token[0] = legion;

        uint256[] memory amount = new uint256[](1);
        amount[0] = 1;

        IERC1155CreatorCore(creatorContract).mintExtensionExisting(to, token, amount);
    }


    /**
     * @notice check if a MEV Army tokenId has been used to claim a legion Banner
     * @param _tokenId to check
     */
    function isTokenIdClaimed(uint256 _tokenId) external view returns (bool) {
        require(_tokenId > 0 && _tokenId < 10000, "token does not exist");
        return isTokenUsed[_tokenId];
    }


    /**
     * @notice return the on-chain metadata for this NFT
     * @param _creator to check the correct creator contract
     * @param _tokenId of the NFT you want the metadata for
     */
    function tokenURI(address _creator, uint256 _tokenId) public view override returns (string memory) {
        require(_creator == creatorContract);

        string memory name = legionNames[_tokenId];

        string memory color = colors[legionToColorIndex[_tokenId]];
        string memory fillChar = legionToChar[_tokenId];

        string memory metadata = ASCIIGenerator.generateMetadata(
            name,
            _tokenId,
            fillChar,
            color
        );

        return metadata;
    }


    //================== UPDATE BANNER COLOR AND ASCII CHAR FUNCTIONS ==================


    /**
     * @notice set the fill character for a legion banner
     * @param _legion ID you want to update
     * @param _fillChar number you want to use as the main character in the ASCII banner
     */
    function setFillChar(uint256 _legion, uint256 _fillChar) public onlyInLegion(_legion) {
        require(_fillChar >= 0 && _fillChar < 10, "char not allowed");

        legionToChar[_legion] = _fillChar.toString();

        emit LegionCharChanged(_legion, _fillChar);
    }


    /**
     * @notice set the ASCII text color for a legion banner
     * @param _legion ID you want to update
     * @param _colorIndex in the colors array you want to use as the text color in the ASCII banner.
     */
    function setASCIIColor(uint256 _legion, uint256 _colorIndex) public onlyInLegion(_legion) {
        require(
            _colorIndex >= 0 && _colorIndex < colors.length,
            "color not allowed"
        );

        legionToColorIndex[_legion] = _colorIndex;

        emit LegionColorChanged(_legion, _colorIndex);
    }


    /**
     * @notice set the ASCII text color and fill character for a legion banner
     * @param _legion ID you want to update
     * @param _colorIndex in the colors array you want to use as the text color in the ASCII banner.
     * @param _fillChar number you want to use as the main character in the ASCII banner
     */
    function setASCIIColorAndFillChar(
        uint256 _legion,
        uint256 _colorIndex,
        uint256 _fillChar
    ) external onlyInLegion(_legion) {
        setASCIIColor(_legion, _colorIndex);
        setFillChar(_legion, _fillChar);
    }


    /**
     * @notice get the fill character and the text color string of a legion banner
     * @param _legion banner 
     */
    function getLegionBannerCharAndColor(uint256 _legion) external view returns (string memory, string memory) {
        require(_legion > 0 && _legion < 7, "legion does not exist");
        return (legionToChar[_legion], colors[legionToColorIndex[_legion]]);
    }


    //================== ADMIN FUNCTIONS ==================


    /**
     * @notice mint initial banners / create the 1155 tokens on the Manifold creator contract
     */
    function mintInitialBanners() external onlyOwner {
        address[] memory to = new address[](1);
        to[0] = owner();

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        string[] memory uris = new string[](1);
        uris[0] = "";

        for (uint256 i; i < 6; i++) {
            IERC1155CreatorCore(creatorContract).mintExtensionNew(to, amounts, uris);
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }


    function setColorByIndex(uint256 _index, string memory _colorHexString) external onlyOwner {
        colors[_index] = _colorHexString;
    }


    function appendColor(string memory _colorHexString) external onlyOwner {
        colors.push(_colorHexString);
    }


    function setASCIIGenerator(address _ASCIIGenerator) external onlyOwner {
        ASCIIGenerator = IASCIIGenerator(_ASCIIGenerator);
    }
}
