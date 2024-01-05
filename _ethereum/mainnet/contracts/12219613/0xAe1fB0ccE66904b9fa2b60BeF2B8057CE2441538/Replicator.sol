// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MDJ Replicator
/// @author: manifold.xyz

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                        //
//                                                                                                                                                        //
//      ####    ####    ####################### ######          #######   ##################                 ###### ###############    ####    ####       //
//      ####    ####    ###################### #######        ########   ####################               ###### ################    ####    ####       //
//  ####    ####    ####    ################# ########      #########   ######         ######              ###### #############    ####    ####    ####   //
//  ####    ####    ####    ################ #########    ##########   ######         ######              ###### ##############    ####    ####    ####   //
//      ####    ####    ################### ##########  ###########   ######         ######              ###### ###################    ####    ####       //
//      ####    ####    ################## ########### ###########   ######         ######              ###### ####################    ####    ####       //
//  ####    ####    ####    ############# #######################   ######         ######   ######     ###### #################    ####    ####    ####   //
//  ####    ####    ####    ############ ######  #######  ######   ######         ######   ######     ###### ##################    ####    ####    ####   //
//      ####    ####    ####    ####### ######   #####   ######   ####################    ################# ###############    ####    ####    ####       //
//      ####    ####    ####    ###### ######           ######   ##################       ############### #################    ####    ####    ####       //
//                                                                                                                                                        //
//                                                                                                                                                        //
//       ############     ############  ###########      #####       #####      #########         #######  ###############   ##########     ###########   //
//      ##############   ############  ##############   #####       #####   ##############      #########  ############# ###############   #############  //
//     ######   ######  ######        #######   ###### #####       #####  ######     #####    ##### #####    #######   ######      #####  ######   #####  //
//    ###############  ############  ###############  #####       ##### ######             ######  ######   ######    ######      ###### ##############   //
//   #############    ######        #############   ######       ##### #####     #####   ################  ######    #######     ###### ############      //
//  ##############   ############# ######          ###########  #####   ############## ################## ######     ##############    ###### #####       //
// ######   ####### ############# #####           ###########  #####      ########    ################### #####         ########      #####    #####      //
//                                                                                                                                                        //
//                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ReplicatorInterface.sol";

contract Replicator is ReentrancyGuard, ERC721Enumerable, Ownable, ReplicatorInterface {
    using Strings for uint256;

    // Mapping from token ID to next print
    mapping (uint256 => uint256) private _tokenNextPrintTime;
    // Mapping from token ID to remaining prints
    mapping (uint256 => uint8) private _tokenPrintsRemaining;
    // Mapping from token ID to generation
    mapping (uint256 => uint8) private _tokenGeneration;
    // Mapping from token ID to variant
    mapping (uint256 => uint8) private _tokenVariant;

    // Count of all prints
    uint256 private _totalPrintCount = 0;
    
    // Array with all token ids that are replicators (i.e. non-jammed NFT's)
    uint256[] private _allReplicators;

    /*
     *     bytes4(keccak256('setTokenURI(uint256,string)')) == 0x162094c4
     *     bytes4(keccak256('originReplicator(uint256)')) == 0x9c7a4b7a
     *     bytes4(keccak256('replicators()')) == 0xabc23a11
     *     bytes4(keccak256('canPrint(uint256)')) == 0x80e6b1cc
     *     bytes4(keccak256('nextPrintTime(uint256)')) == 0x26307ae0
     *     bytes4(keccak256('remainingPrints(uint256)')) == 0x1fc2b15b
     *     bytes4(keccak256('print(uint256)')) == 0x6bb0ae10
     *
     *     => 0x162094c4 ^ 0x9c7a4b7a ^ 0xabc23a11 ^ 0x80e6b1cc ^ 0x26307ae0 ^ 0x1fc2b15b ^ 0x6bb0ae10 == 0xf33c31c8
     */

    // Replicator configuration
    uint256 private _printInterval;
    // Only 16 supported generations max
    uint8 private _maxGenerations;
    // Array of generation print limits
    uint8[] private _generationPrintLimits;
    // Array of number of jam variants
    uint8[] private _generationJamVariants;
    // Array of jam probabilities (0-100)
    uint8[] internal _generationJamProbabilities;

    // Mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;
    // Base URI
    string private constant _baseTokenURI = "https://api.maddogjones.com/replicator/";
    
    event Print(address indexed owner, uint256 tokenId, uint256 indexed originReplicator, uint8 indexed generation, uint8 variant, uint8 printNumber, uint256 internalPrintTime);

    constructor (string memory _name, string memory _symbol, uint256 firstPrintTime, uint256 printInterval, uint8 maxGenerations, uint8[] memory generationPrintLimits, uint8[] memory generationJamVariants, uint8[] memory generationJamProbabilities) ERC721(_name, _symbol)
    {
        require(generationJamVariants.length == maxGenerations && generationJamProbabilities.length == maxGenerations &&
                generationPrintLimits.length == maxGenerations, "Bad generation configuration");
        require(maxGenerations <= 15, "Only up to 15 generations supported");
        for (uint i = 0; i < generationJamProbabilities.length; i++) {
            require(generationJamProbabilities[i] <= 100, "Bad jam configuration. Values must be between 0 and 100.");
        }

        _printInterval = printInterval;
        _maxGenerations = maxGenerations;
        _generationJamVariants = generationJamVariants;
        _generationJamProbabilities = generationJamProbabilities;
        _generationPrintLimits = generationPrintLimits;
        _generationPrintLimits.push(0);
    
        // Mint the first token
        uint256 tokenId = 1;
        uint8 generation = 0;
        _print(firstPrintTime, msg.sender, tokenId, generation, 0, _generationPrintLimits[generation]);

        emit Print(msg.sender, tokenId, 0, generation, 0, 1, firstPrintTime-_printInterval);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721Enumerable) returns (bool) {
        return interfaceId == type(ReplicatorInterface).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            return _tokenURIs[tokenId];
        }
        return string(abi.encodePacked(_baseTokenURI, uint256(_tokenGeneration[tokenId]).toString(), "/", uint256(_tokenVariant[tokenId]).toString(), "/", tokenId.toString()));
    }

    function _burn(uint256 tokenId) internal virtual override {
         ERC721._burn(tokenId);
         // Clear metadata (if any)
         if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /**
     * @dev Sets `uri` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external override onlyOwner {
        require(_exists(tokenId), "Nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Returns the tokenId of the replicator that printed the the given tokenId
     */
    function originReplicator(uint256 tokenId) external view override returns (uint256) {
        require(tokenId > 2**uint256(16), "No origin Replicator");
        return (tokenId & (2**uint256(16*_tokenGeneration[tokenId]) - 1));
    }

    /**
     * @dev Returns list of all tokens that can print.
     */
    function replicators() external view override returns (uint256[] memory) {
        uint256[] memory activeReplicators = new uint[](_allReplicators.length);
        uint256 activeReplicatorsCount = 0;
        for (uint i = 0; i < _allReplicators.length; i++) {
            uint256 tokenId = _allReplicators[i];
            if (_tokenPrintsRemaining[tokenId] > 0) {
                activeReplicators[activeReplicatorsCount] = tokenId;
                activeReplicatorsCount += 1;
            }
        }
        uint256[] memory activeReplicatorsOnly = new uint[](activeReplicatorsCount);
        for (uint i = 0; i < activeReplicatorsCount; i++) {
            activeReplicatorsOnly[i] = activeReplicators[i];
        }
        return activeReplicatorsOnly;
    }

    /**
     * @dev Returns True if tokenId can print, False otherwise.
     */
    function canPrint(uint256 tokenId) public view override returns (bool) {
        require(_exists(tokenId), "Nonexistent token");
        return (_tokenPrintsRemaining[tokenId] > 0 && _tokenNextPrintTime[tokenId] > 0 &&
               block.timestamp >= _tokenNextPrintTime[tokenId] && _tokenGeneration[tokenId] + 1 <= _maxGenerations);
    }

    /**
     * @dev Returns next print time of tokenId.  Errors if it cannot print.
     */
    function nextPrintTime(uint256 tokenId) external view override returns (uint256) {
        require(_exists(tokenId), "Nonexistent token");
        require(_tokenPrintsRemaining[tokenId] > 0 && _tokenNextPrintTime[tokenId] > 0 && _tokenGeneration[tokenId] + 1 <= _maxGenerations, "Cannot give print");
        return _tokenNextPrintTime[tokenId];
    }

    /**
     * @dev Returns remaining prints that a tokenId can make.  Errors if it cannot print.
     */
    function remainingPrints(uint256 tokenId) external view override returns (uint8) {
        require(_exists(tokenId), "Nonexistent token");
        require(_tokenVariant[tokenId] == 0, "Jam token");
        return _tokenPrintsRemaining[tokenId];
        
    }

    /**
     * @dev Creates a print NFT from the given tokenId if possible.  Errors otherwise.
     */
    function print(uint256 tokenId) external nonReentrant override {
        // check token can give print
        require(canPrint(tokenId), "Cannot print");

        uint256 printTime = _tokenNextPrintTime[tokenId];
        _tokenPrintsRemaining[tokenId]--;
        _tokenNextPrintTime[tokenId] += _printInterval;

        // generate print
        address tokenOwner = ownerOf(tokenId);
        uint8 tokenGeneration = _tokenGeneration[tokenId];
        uint8 printGeneration = tokenGeneration+1;
        uint8 printVariant = 0;
        uint8 printLimit = 0;

        uint8 randomNumber = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, _totalPrintCount)))%100);
        if (randomNumber < _generationJamProbabilities[tokenGeneration]) {
            // Jam, pick jam variant
            printVariant = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, _totalPrintCount)))%_generationJamVariants[tokenGeneration])+1;
        } else {
            printLimit = _generationPrintLimits[printGeneration];
        }

        uint8 printNumber = _generationPrintLimits[tokenGeneration] - _tokenPrintsRemaining[tokenId];
        uint256 printTokenId = tokenId | uint256(printNumber)*2**uint256((printGeneration)*16);

        _print(_tokenNextPrintTime[tokenId], tokenOwner, printTokenId, printGeneration, printVariant, printLimit);

        emit Print(tokenOwner, printTokenId, tokenId, printGeneration, printVariant, printNumber, printTime);
    }

    function _print(uint256 tokenNextPrintTime, address to, uint256 tokenId, uint8 generation, uint8 variant, uint8 printLimit) internal {
        require(!_exists(tokenId), "Duplicate token id");
        _tokenGeneration[tokenId] = generation;
        _tokenVariant[tokenId] = variant;
        _tokenPrintsRemaining[tokenId] = printLimit;
        if (variant == 0) {
            _tokenNextPrintTime[tokenId] = tokenNextPrintTime;
            _allReplicators.push(tokenId);
        }
        _totalPrintCount++;
        _safeMint(to, tokenId);
    }

}