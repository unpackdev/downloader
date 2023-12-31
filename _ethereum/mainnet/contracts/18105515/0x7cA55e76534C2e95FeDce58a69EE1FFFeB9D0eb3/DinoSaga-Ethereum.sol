// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./NonblockingReceiver.sol";

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX0OOOOOOO0XWMMMX0OOOOOOOO0XWMMMX0OOOOOOOOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.........dWMMWx'.........oNMMWx'........oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.........oNMMWd..........oNMMWx.........lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd....:dxxxoccccoxxxxxxkkkkdlcccokkkkc....lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd....oXNNXo....lXNNNNWWMMWx....lNMMWx....lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd....lKKKKl....l0XKKXNWWWWd....lNWWWx....lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd....:kkkkc....:xkkkk0XNNNd....lXNNNd....lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd....:xkkxc....:xkkkk0XNNXd....lKNNXd....lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd....:xkkkdlllldkkkkk0XNNN0xxxxOXNNNd....lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd....:xkkkkkkkkkkkkkk0XNNNNNNNNNNNNNd....lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd....:dxxxxxxxxxxxxxxOKKKXKKXKKKKKXKo....lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd....;oooooooooooooooxkkkkkkkkkkkkkkc....lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd....;loooooooooooooodkkkkkkkkkkkkkkc....lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.....,,,,,,,,,,,,,,,,;;;;;;;;;;;;;;'....,cllllllllkWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd..................................................lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX00000000000000l''''''''''''''''''''''''''''''''''''''''''''''''''cO000XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd'.............;loooooooooooooodddddddddddddddddddddddddddddddddddc'...lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo..............;odooddddddddoddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxc....cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.........'::::lododdddodoododdddddddxxxxxxxddddddddddddddddddxxxdc....lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.........;oddddooddooodooddodoodddddxxxxxxxxxddodoodddodddoddxxxxc....cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXK00Ol.........;odddxkkkkoc::::c::clodddddxxxxdlllloddddddddddddddollll;....cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd'...',,,,.....;oddd0NWWNl         ,oddoddxxxd:....;dxdxddxxxddxddc.........cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo....',,,,.....;oddd0WMMWl         'odddoddxxd:....;dxxxxxxxxxxxxdc.........cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo....',,,,.....;odod0WMMWl         'oddooddddxoc:::ldxxxxxxxxxxxxxoc:::,....cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo....',,,,.....;oood0WMMWl         'oddoddxxxxxxxxxxxxxdxxdddxxxxxxxxxxc....cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.....'','.....;oddd0WMMWx'........:oddoddxxxxxdxxxxxxxxxxxxxxxxxxxxxxdc....cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo..............;odod0WMMMWNNNNNNNNXOdoodddxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc....cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo..............;oddd0WMMMMMMMMMMMMW0doodddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxc....cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0xxxd;.....'''',,,,;oO0OOOOOOOOOOOOkddddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxc....cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo....',,,,.....;odoooooooooooooodddodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxc....cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.....,,;,.....;oddddooooooodddooddodddddxxxxxdollllllllllllllllll;....cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo....',,,,.....;oddoddoddoooddddddddddddddxxxdc........................cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo....',,,,.....;oddddddddddddddddddddddoddxxxd:........................lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo..............;oddddddddddddddddddddddddl;;;;cdddddddddddddddddddddddx0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo..............;oddddxxxxxxxxxxxxxxxxxxxd:....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.............':ododdxxxxxxxxxxxxxxxxxxxd:....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.........;llllododddxxxxxxxxxxxxxxxxxxxd:....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.........;oddddoddddxxxxxxxxxxxxxxxxxxxd:....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0xddd;....;odooc;,;;;::::::::::::::::::::,....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo....;oddo;.....''''''''''''''''''''.....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXKKKKKKK0o'..':oddo;.....''''''''''''''''''''.....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd,'''''''':ooooododo;.....''''''''''''''''''''.....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.........:dxxxddddo;.....''''''''''''''''''''.....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo....'::::lddddddddo;.....''''''''''''''''''''.....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo....:dxxxdddddddodo;.....''''''''''''''''''''.....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx,,,,:oooooodooddddo:....',,,,'..........',,,,'....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXXXKo....:ododddddoolllloodoo;..........;oodo;....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo....;oddddodddddooddxxxd;..........;dxxd:....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0dddoc;;;;cooodddddddxxxdl:;;;;;;;;:ldxxd:....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo....;ododdxxxxxxxxxxxxxxxxxxxxxxxxd:....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo....;odddddxxxdoooooooooddddddxxxxd:....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo....;oddddxxxd:'........:odddddxxxd:....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo....;oddddxxxd:.........;odddddxxxd:....oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo....';;;;;::::codoo;....';;;;;;::::coood0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo..............dWMMWd...............oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx,'''''''''''',xWMMWx,''''''''''''',dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXXXXKXXXXXXXXXNMMMMNXXXXXXXXXXXXKKXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

// ETHEREUM
contract DinoSaga is Ownable, ERC721, NonblockingReceiver, ReentrancyGuard {
    using Strings for uint256;

    uint256 gasForDestinationLzReceive = 350000;

    // for random seed
    bytes32 private previousBlockHash;

    uint256 private randomNonce;

    struct Path {
        uint8 fill;
        uint8[] pathSet;
    }

    struct RenderPathIndex {
        uint256 startIndex;
        uint256 endIndex;
    }

    string[] CHAINS = ["Ethereum", "Arbitrum", "BNB Smart Chain", "Avalanche", "Polygon", "Optimism", "zkSync Era", "Linea", "Base", "Fantom"];

    string[] CHAIN_COLOR = ["#21325B", "#1CD3F3", "#F8C947", "#E84142", "#91539E", "#FF0420", "#11142B", "#44bde8", "#0052ff", "#337AFE"];

    string[] EYE_STYLE = ["Expressive", "Luminous", "Apathetic", "Enthralling"];

    string[] ROLE_LIST = ["Civilian", "Pirate", "Wizard", "Royalty"];

    string[] private colorSet = ["#382121", "#A04345", "#BC4D4F", "#4B9A27", "#FFF", "#671F1F", "#D8B78F", "#FFD7A8", "#000", "#FFFC40", "#F9A31B", "#FA6A0A", "#FDF7ED", "#D8B78F", "#00E436", "#008751"];

    string[] public pathContent;
    Path[] public pathArray;

    mapping(string => RenderPathIndex) public renderPathIndex;

    mapping(uint256 => string[10]) public dinoGen;
    mapping(uint256 => uint8[10]) public dinoAttr;

    uint256 public constant buddyHatchThreshold = 0.0099 ether;
    uint8 constant CHAIN_INDEX = 0;
    uint256 public nextMintId;
    uint256 public constant MAX_MINT_ETHEREUM = 1288;

    string[] private expansionComponent;

    constructor(address _layerZeroEndpoint) ERC721("Dino Saga", "DINO") {
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);

        nextMintId = 0;

        randomNonce = 0;

        renderPathIndex["body"].startIndex = 0;
        renderPathIndex["body"].endIndex = 68;

        renderPathIndex["crown"].startIndex = 69;
        renderPathIndex["crown"].endIndex = 85;

        renderPathIndex["pirate"].startIndex = 86;
        renderPathIndex["pirate"].endIndex = 86;

        renderPathIndex["wizard"].startIndex = 87;
        renderPathIndex["wizard"].endIndex = 103;

        renderPathIndex["buddy"].startIndex = 104;
        renderPathIndex["buddy"].endIndex = 124;
    }

    // ======== Admin Function ========
    function addExpansionComponent(string memory key, uint256 startIndex, uint256 endIndex) public onlyOwner {
        renderPathIndex[key].startIndex = startIndex;
        renderPathIndex[key].endIndex = endIndex;
        expansionComponent.push(key);
    }

    function removeExpansionComponent(string memory key) public onlyOwner {
        renderPathIndex[key].startIndex = 0;
        renderPathIndex[key].endIndex = 0;
        uint length = expansionComponent.length;
        for (uint i = 0; i < length; i++) {
            if (keccak256(abi.encodePacked(expansionComponent[i])) == keccak256(abi.encodePacked(key))) {
                expansionComponent[i] = expansionComponent[length - 1];
                expansionComponent.pop();
                return;
            }
        }
    }

    function addColor(string[] memory _color) public onlyOwner {
        for (uint i = 0; i < _color.length; i++) {
            colorSet.push(_color[i]);
        }
    }

    function addPath(uint8[] memory _fill, uint8[][] memory _pathSet) public onlyOwner {
        require(_fill.length == _pathSet.length, "Error input");
        for (uint i = 0; i < _fill.length; i++) {
            Path memory newPath = Path({fill: _fill[i], pathSet: _pathSet[i]});
            pathArray.push(newPath);
        }
    }

    function addPathContent(string[] memory _pathContent) public onlyOwner {
        for (uint i = 0; i < _pathContent.length; i++) {
            pathContent.push(_pathContent[i]);
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Dino Saga: Failed to withdraw.");
    }

    // ======== Utils Function ========
    function rangeRandom(uint min, uint max, uint randomSeed, uint tokenId) internal view returns (uint) {
        return (uint(keccak256(abi.encodePacked(blockhash(block.number - 1), previousBlockHash, block.timestamp, block.prevrandao, msg.sender, randomSeed, tokenId, randomNonce))) % (max - min + 1)) + min;
    }

    function toHexDigit(uint value) internal pure returns (bytes1) {
        require(value < 256, "Input value out of range");
        uint8 value8 = uint8(value);
        return bytes1(value8 < 10 ? value8 + 48 : value8 + 87);
    }

    function rgbToHex(uint r, uint g, uint b) internal pure returns (string memory) {
        require(r < 256 && g < 256 && b < 256, "RGB values should be in the range 0-255");
        bytes memory bytesArray = new bytes(7);
        bytesArray[0] = "#";
        bytesArray[1] = toHexDigit(r / 16);
        bytesArray[2] = toHexDigit(r % 16);
        bytesArray[3] = toHexDigit(g / 16);
        bytesArray[4] = toHexDigit(g % 16);
        bytesArray[5] = toHexDigit(b / 16);
        bytesArray[6] = toHexDigit(b % 16);
        return string(bytesArray);
    }

    function hexCharToUint8(bytes1 char) internal pure returns (uint8) {
        if (char >= "0" && char <= "9") {
            return uint8(char) - 48; // ASCII value of '0'
        }
        if (char >= "a" && char <= "f") {
            return uint8(char) - 87; // ASCII value of 'a' - 10
        }
        if (char >= "A" && char <= "F") {
            return uint8(char) - 55; // ASCII value of 'A' - 10
        }
        revert("Invalid hex character");
    }

    function hexToRgb(string memory s) internal pure returns (uint8 r, uint8 g, uint8 b) {
        bytes memory bs = bytes(s);
        require(bs.length == 7, "Invalid length");
        require(bs[0] == "#", "Invalid starting character");

        uint8 redHigh = hexCharToUint8(bs[1]);
        uint8 redLow = hexCharToUint8(bs[2]);
        uint8 greenHigh = hexCharToUint8(bs[3]);
        uint8 greenLow = hexCharToUint8(bs[4]);
        uint8 blueHigh = hexCharToUint8(bs[5]);
        uint8 blueLow = hexCharToUint8(bs[6]);

        r = redHigh * 16 + redLow;
        g = greenHigh * 16 + greenLow;
        b = blueHigh * 16 + blueLow;
    }

    function randomColor(uint maxR, uint maxG, uint maxB, uint seed, uint256 tokenId) internal view returns (uint r, uint g, uint b) {
        return (rangeRandom(0, maxR, seed, tokenId), rangeRandom(0, maxG, seed + 1, tokenId), rangeRandom(0, maxB, seed + 2, tokenId));
    }

    function makePath(uint256 index, uint256 tokenId) internal view returns (string memory) {
        string memory path;
        uint8 fillIndex = pathArray[index].fill;
        uint8[] memory _pathSet = pathArray[index].pathSet;
        for (uint256 ii = 0; ii < _pathSet.length; ii++) {
            path = string.concat(path, " ", pathContent[_pathSet[ii]]);
        }
        return string.concat('<path fill="', setColor(fillIndex, tokenId), '" d="', path, '" />');
    }

    // ======== Internal Function ========
    function hatchDinoBuddy(uint256 tokenId) internal {
        uint randomBuddyR = rangeRandom(0, 255, 85, tokenId);
        uint randomBuddyG = rangeRandom(93, 255, 751, tokenId);
        uint randomBuddyB = rangeRandom(0, 228, 125, tokenId);
        dinoGen[tokenId][3] = rgbToHex(randomBuddyR, randomBuddyG, randomBuddyB);
    }

    function hatchDino(uint256 tokenId) internal {
        // Birth Chain
        dinoAttr[tokenId][0] = CHAIN_INDEX;

        // Skin
        (uint randomBodyR, uint randomBodyG, uint randomBodyB) = randomColor(237, 245, 245, 0, tokenId);

        // Abdomen
        (uint randomAbdomenR, uint randomAbdomenG, uint randomAbdomenB) = randomColor(216, 223, 230, 3, tokenId);

        // DorsalFin
        (uint randomDorsalR, uint randomDorsalG, uint randomDorsalB) = randomColor(255, 255, 255, 6, tokenId);

        uint randomEyeStyle = rangeRandom(0, 99, 7, tokenId);
        // 34%
        if (randomEyeStyle < 34) {
            dinoAttr[tokenId][1] = 0;
            // 20%
        } else if (randomEyeStyle < 54) {
            dinoAttr[tokenId][1] = 1;
            // 12%
        } else if (randomEyeStyle < 66) {
            dinoAttr[tokenId][1] = 2;
            // 34%
        } else {
            dinoAttr[tokenId][1] = 3;
        }

        uint randomRole = rangeRandom(0, 99, 8, tokenId);
        // 70%
        if (randomRole < 70) {
            dinoAttr[tokenId][2] = 0;
            // 11%
        } else if (randomRole < 81) {
            dinoAttr[tokenId][2] = 1;
            // 11%
        } else if (randomRole < 92) {
            dinoAttr[tokenId][2] = 2;
            // 8%
        } else {
            dinoAttr[tokenId][2] = 3;
        }

        dinoGen[tokenId] = [
            // Skin
            rgbToHex(randomBodyR, randomBodyG, randomBodyB),
            // Abdomen
            rgbToHex(randomAbdomenR, randomAbdomenG, randomAbdomenB),
            // DorsalFin
            rgbToHex(randomDorsalR, randomDorsalG, randomDorsalB)
        ];
    }

    // ======== Public Function ========
    function mint(uint8 numTokens) public payable nonReentrant {
        require(numTokens < 3, "Dino Saga: Max 2 Dinos per transaction");
        require(nextMintId + numTokens <= MAX_MINT_ETHEREUM, "Dino Saga: Mint exceeds supply");

        for (uint256 i = 0; i < numTokens; i++) {
            hatchDino(nextMintId);
            _safeMint(msg.sender, nextMintId);
            nextMintId++;
        }

        previousBlockHash = blockhash(block.number - 1);
        randomNonce++;
    }

    function donate() public payable {
        // Thank you!
    }

    function donate(uint256 tokenId) public payable {
        // Thank you!
        // If your donation amount is greater than 0.0099 ETH, you will receive a mysterious buddy!
        // Thank you again!
        if (msg.value >= buddyHatchThreshold && dinoAttr[tokenId][3] == 0) {
            hatchDinoBuddy(tokenId);
            dinoAttr[tokenId][3] = 1;
        }
    }

    // This function transfers the nft from your address on the
    // source chain to the same address on the destination chain
    function traverseChains(uint16 _chainId, uint256 tokenId) public payable {
        require(msg.sender == ownerOf(tokenId), "You must own the token to traverse");
        require(trustedRemoteLookup[_chainId].length > 0, "This chain is currently unavailable for travel");

        // burn NFT, eliminating it from circulation on src chain
        _burn(tokenId);

        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(msg.sender, tokenId, dinoGen[tokenId], dinoAttr[tokenId]);

        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);

        // get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // you will be refunded for extra gas paid
        (uint256 messageFee, ) = endpoint.estimateFees(_chainId, address(this), payload, false, adapterParams);

        require(msg.value >= messageFee, "Dino Saga: msg.value not enough to cover messageFee. Send gas for message fees");

        endpoint.send{value: msg.value}(
            _chainId, // destination chainId
            trustedRemoteLookup[_chainId], // destination address of nft contract
            payload, // abi.encoded()'ed bytes
            payable(msg.sender), // refund address
            address(0x0), // 'zroPaymentAddress' unused for this
            adapterParams // txParameters
        );
    }

    // ======== Rendering Function ========
    function setColor(uint8 colorIndex, uint256 tokenId) internal view returns (string memory) {
        string memory temp;
        if (colorIndex == 1) {
            // Skin 1-2
            temp = dinoGen[tokenId][0];
        } else if (colorIndex == 2) {
            (uint8 r, uint8 g, uint8 b) = hexToRgb(dinoGen[tokenId][0]);
            temp = rgbToHex(r + 18, g + 10, b + 10);
        } else if (colorIndex == 6) {
            // Abdomen 6-7
            temp = dinoGen[tokenId][1];
        } else if (colorIndex == 7) {
            (uint8 r, uint8 g, uint8 b) = hexToRgb(dinoGen[tokenId][1]);
            temp = rgbToHex(r + 39, g + 32, b + 25);
        } else if (colorIndex == 3) {
            // DorsalFin
            temp = dinoGen[tokenId][2];
        } else if (colorIndex == 14) {
            // Buddy 14-15
            (uint8 r, uint8 g, uint8 b) = hexToRgb(dinoGen[tokenId][3]);
            temp = rgbToHex(r, g - 93, b + 27);
        } else if (colorIndex == 15) {
            temp = dinoGen[tokenId][3];
        } else {
            temp = colorSet[colorIndex];
        }
        return temp;
    }

    function dinoRenderer(uint256 tokenId) internal view returns (string memory) {
        string memory output;
        uint8 role = dinoAttr[tokenId][2];
        bool hasBuddy = dinoAttr[tokenId][3] == 1;

        // Body
        for (uint256 i = renderPathIndex["body"].startIndex; i <= renderPathIndex["body"].endIndex; i++) {
            string memory d;
            uint8 fillIndex = pathArray[i].fill;
            uint8[] memory _pathSet = pathArray[i].pathSet;
            uint8 eyeStyle = dinoAttr[tokenId][1];

            if (i == 68) {
                if (eyeStyle == 0) {
                    _pathSet = new uint8[](5);
                    _pathSet[0] = 37;
                    _pathSet[1] = 94;
                    _pathSet[2] = 95;
                    _pathSet[3] = 96;
                    _pathSet[4] = 97;
                } else if (eyeStyle == 1) {
                    _pathSet = new uint8[](7);
                    _pathSet[0] = 37;
                    _pathSet[1] = 98;
                    _pathSet[2] = 99;
                    _pathSet[3] = 100;
                    _pathSet[4] = 101;
                    _pathSet[5] = 102;
                    _pathSet[6] = 103;
                } else if (eyeStyle == 2) {
                    _pathSet = new uint8[](5);
                    _pathSet[0] = 48;
                    _pathSet[1] = 104;
                    _pathSet[2] = 35;
                    _pathSet[3] = 105;
                    _pathSet[4] = 106;
                } else if (eyeStyle == 3) {
                    _pathSet = new uint8[](5);
                    _pathSet[0] = 48;
                    _pathSet[1] = 107;
                    _pathSet[2] = 108;
                    _pathSet[3] = 109;
                    _pathSet[4] = 110;
                }
            }

            // random color
            for (uint256 j = 0; j < _pathSet.length; j++) {
                d = string.concat(d, " ", pathContent[_pathSet[j]]);
            }

            output = string.concat(output, '<path fill="', setColor(fillIndex, tokenId), '" d="', d, '" />');
        }

        // Pirate
        if (role == 1) {
            for (uint256 i = renderPathIndex["pirate"].startIndex; i <= renderPathIndex["pirate"].endIndex; i++) {
                output = string.concat(output, makePath(i, tokenId));
            }
        }

        // Wizard
        if (role == 2) {
            for (uint256 i = renderPathIndex["wizard"].startIndex; i <= renderPathIndex["wizard"].endIndex; i++) {
                output = string.concat(output, makePath(i, tokenId));
            }
        }

        // Royalty
        if (role == 3) {
            for (uint256 i = renderPathIndex["crown"].startIndex; i <= renderPathIndex["crown"].endIndex; i++) {
                output = string.concat(output, makePath(i, tokenId));
            }
        }

        // Buddy
        if (hasBuddy) {
            for (uint256 i = renderPathIndex["buddy"].startIndex; i <= renderPathIndex["buddy"].endIndex; i++) {
                output = string.concat(output, makePath(i, tokenId));
            }
        }

        // Expansion Component
        for (uint256 keyIndex = 0; keyIndex < expansionComponent.length; keyIndex++) {
            for (uint256 i = renderPathIndex[expansionComponent[keyIndex]].startIndex; i <= renderPathIndex[expansionComponent[keyIndex]].endIndex; i++) {
                output = string.concat(output, makePath(i, tokenId));
            }
        }

        return output;
    }

    function genChainIdentifier(uint256 tokenId) internal view returns (string memory) {
        string memory output;
        string memory chainColor = CHAIN_COLOR[dinoAttr[tokenId][0]];
        output = string.concat("<path fill='#382121' d='M4 3h1v1H4zm2 0h1v1H6zM3 4h1v1H3zm2 0h1v1H5zm2 0h1v1H7z'/><path fill='", chainColor, "' d='M4 4h1v1H4zm2 0h1v1H6z'/><path fill='#382121' d='M3 5h1v1H3zm4 0h1v1H7z'/><path fill='", chainColor, "' d='M4 5h1v1H4zm1 0h1v1H5zm1 0h1v1H6z'/><path fill='#382121' d='M4 6h1v1H4zm2 0h1v1H6z'/><path fill='", chainColor, "' d='M5 6h1v1H5z'/><path fill='#382121' d='M5 7h1v1H5z'/>");
        return output;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory output;
        string memory innerSVG;
        string memory x = 'xmlns="http://www.w3.org/2000/svg" version="1.1"';
        bool hasBuddy = dinoAttr[tokenId][3] == 1;
        string memory buddyGene;

        if (hasBuddy) {
            buddyGene = string.concat(',{"trait_type": "Buddy", "value": "Buddy #', Strings.toString(tokenId), '"}');
        }

        innerSVG = string.concat("<svg ", x, ' width="152" height="38" shape-rendering="crispEdges">', dinoRenderer(tokenId), "</svg>");

        output = string.concat("<svg ", x, ' width="304px" height="304px" viewBox="0 0 38 38" shape-rendering="crispEdges"><foreignObject width="38" height="38" style="border: 1px solid ', CHAIN_COLOR[CHAIN_INDEX], ';"><style>@keyframes i {from {background-position-x:0;}to {background-position-x:-152px;}}</style><div xmlns="http://www.w3.org/1999/xhtml"><div xmlns="http://www.w3.org/1999/xhtml" style="animation:i 0.4s steps(4, end) infinite;width:152px;height:38px;background-repeat: no-repeat;background-size:100%;background-position: 0 0;image-rendering: pixelated;background-image:url(\'data:image/svg+xml;base64,', Base64.encode(bytes(innerSVG)), "')\"></div></div></foreignObject>", genChainIdentifier(tokenId), "</svg>");

        string memory json = Base64.encode(bytes(string.concat('{"name":"Dino Saga #', Strings.toString(tokenId), '","image_data":"data:image/svg+xml;base64,', Base64.encode(bytes(output)), '","description":"Experience the revolution in digital collectibles with Dino Saga: seamlessly omnichain(across 10 chains), fully on-chain, vividly animated, and expansively scalable.","attributes": [{"trait_type": "Birth-Chain", "value": "', CHAINS[dinoAttr[tokenId][0]], '"},{"trait_type": "Role", "value": "', ROLE_LIST[dinoAttr[tokenId][2]], '"},{"trait_type": "Eye-Style", "value": "', EYE_STYLE[dinoAttr[tokenId][1]], '"}', hasBuddy ? buddyGene : "", "]}")));
        output = string.concat("data:application/json;base64,", json);
        return output;
    }

    // ------------------
    // Internal Functions
    // ------------------
    function _LzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal override {
        // decode
        (address toAddr, uint256 tokenId, string[10] memory _dinoGene, uint8[10] memory _dinoAttr) = abi.decode(_payload, (address, uint256, string[10], uint8[10]));

        dinoGen[tokenId] = _dinoGene;
        dinoAttr[tokenId] = _dinoAttr;

        // mint the tokens back into existence on destination chain
        _safeMint(toAddr, tokenId);
    }
}
