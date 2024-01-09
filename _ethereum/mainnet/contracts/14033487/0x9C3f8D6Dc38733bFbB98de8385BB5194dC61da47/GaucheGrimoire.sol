// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "./GaucheBase.sol";
import "./LibGauche.sol";
import "./Strings.sol";

// Price is .0777e per mint
// Max mint is 10
// Price for a max mint is .777e
//                    ,@
//               #@@       @                                  @@
//              @@             @    @@  @@@  @@%   @@    .@@  @@,  @@    @@@*   @
//             @@@  %@@@%%@@@     @@@@  @@@  @@% @@@       @  @@   @@  @@@@@@@@@@@
//             @@@      @ @@&  @@@,  @  @@@  @@% @@           @@   @@  @@
//              @@@       @@& @@@    @  @@@  @@% @@@          @@   @@  @@@
//      @@@@@      @@(   @@@& (@@@ @@@  @@@ %@@%   @@@   @@@  @@   @@    @@@   @@@
//  @@@       @           @                                @
// @@.            @@@  @       @@@  @@@  @@@   @@@@@@@@         @@   @  #@@@    @@
//&@@     @, @@@  @@@     @@@  @@@  @@@  @@@ @@  @@@@  @@  @@@  @@     @@@@@@@@@@@
// @@      @ @@@  @@@     @@@  @@@  @@@  @@@ @@ @@@@@@ @@  @@@  @@     @@
//  @@       @@@  @@@     @@@  @@@  @@@  @@@  @@      @@.  @@@  @@      @@
//    (@@@*@@@@@ @@@@     @@@@ @@@*.@@@ @@@@    @@@@@@    @@@@ @@@@       @@@ @@@
//
//                       [[               ####
//                       [[[[        ########
//                       [[[[[      [[#######
//               %@#(#@@@@@(##     [[[@@#(%@@@@@
//              (([*.*[((@@@@#(   ([[(([*.*[(#@@@*
//             @([*   *[(@@@@(#   ##@([.   *((@@@@
//              @((([(((@@@@@##  ###[@((([(((@@@@*
//               %@@@@@@@@@(#######[[[@@@@@@@@@@
//                       [######[[[[[[[[[[[[[*
//                      [[[[[[[[[[[[[[#########
//        %%%%%%%%%%%#([[[[[[[[[[[[[(############[[[[[[
//        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(#[[[[
//          %%%%%@@@,,,@@@@,,%@@@*,,@@@@,,,,,%%%%[[[[[[[[[[[
//             %%%%%#,,,@[,,,,,@,[[[[[@,,,,,,%%%#[[[
//              [[%%%%%%%%,,[[[[[[[[[[[[[[%%%%%[[[[[[[#####([[[
//                 [[[(%%%%%%%%%%%%%%%%%%%%%%[[[[[[#####
//              .[[[[[#######((#%%%%%%([[[[[[[[[[[###########
//           [[[[[[[[[##############[[[[[[[[[[[[[[#############[[[
//          [[[[[[[[[[[############[[[[[[[[[[[[[[[[###########[[[[[[[[
//          [[[[[[[[[[[[[[######[[[[[[[[[[[[[[[[[[[[[(#####([[[[[[[[[[
//         #####(   [[[[[[ [[[[[[[[[[[#### ####([[[[[[[     *[[[[[######,
//       ####      ##  [  [[[[[[[[[[(#####     #    [[[[           ########
//      [                 [[[[[[[[[[#######            ,[                ####
//                       .[[[[[[[[[[########
//                       [[[[[[[[[[[[[#######
//                       [(#####[[[[[[[[[[[[[
//                      .## #######[[[   [[[[[
//                      ##                 [[[

/// @title A contract that implements the Gauche protocol.
/// @author Yuut - Soc#0903
/// @notice This contract implements minting of tokens and implementation of new projects for extending a single token into owning multiple generative works.
contract GaucheGrimoire is GaucheBase {

    /// @notice This keeps the max level of the project constrained to our offsets overflow value.
    uint256 constant internal MAX_LEVEL = 255;

    /// @notice This event fires when a word is added to the registry, enabling it to express a new form of art.
    /// @param tokenId The token which leveled up.
    /// @param wordHash The hash of the word we inserted.
    /// @param offsetSlot The storage offset of the word in tokenHashes
    /// @param level The project that the word is associated with.
    event WordAdded(uint256 indexed tokenId, bytes32 wordHash, uint256 offsetSlot, uint256 level);

    /// @notice This event fires when a token is created, and when a token has its reality changed.
    /// @param tokenId The token which leveled up.
    /// @param hash The hash of the word we inserted.
    event HashUpdated(uint256 indexed tokenId, bytes32 hash);

    /// @notice This event fires when a project is added.
    /// @param projectId The project # which was added.
    /// @param project GaucheLevel(uint8 wordPrice, uint64 price, address artistAddress, string baseURI)
    event ProjectAdded(uint256 indexed projectId, GaucheLevel project);

    /// @notice This event fires when a level has its properties changed.
    /// @param projectId The project # which was changed
    /// @param project GaucheLevel(uint8 wordPrice, uint64 price, address artistAddress, string baseURI)
    event ProjectUpdated(uint256 indexed projectId, GaucheLevel project);

    /// @notice This event fires when token is burned.
    /// @param tokenId The token that was burned
    event TokenBurned(uint256 indexed tokenId);

    /// @notice This mapping persists all of the token hashes and any hashes they own as a result of leveling up.
    mapping(uint256 => bytes32) public tokenHashes; // Offset of tokenId + wordId. Tracked by spent total in gaucheToken

    /// @notice This array persists all of the projects added to the contract.
    GaucheLevel[] public gaucheLevels;

    /// @notice ERC721a does not allow burn to 0. This is a workaround because I don't wanna touch their contract.
    address constant internal burnAddress = 0x000000000000000000000000000000000000dEaD;

    /// @notice When instantiating the contract we need to update the first level (0) as everyone starts with that as their base identity.
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseURI,
        uint64 _pricePerToken,
        address _accessTokenAddress,
        address _artistAddress,
        address _developerAddress
    ) GaucheBase(_tokenName, _tokenSymbol, _pricePerToken, _accessTokenAddress, _artistAddress, _developerAddress) {
        gaucheLevels.push(GaucheLevel(1, _pricePerToken, artistAddress, "https://neophorion.art/api/projects/GaucheGrimoire/metadata/"));
    }

    /**
     * @dev Ensures that we arent inserting 0x0 as a hash. Users can pick their hash on submission.
     *  The contract only provides verification for words that are keccak256(string).
     *  No confirmation is done of what the hash is when inserted, because we want to keep it a secret only the user knows.
     */
    modifier notNullWord(bytes32 _wordHash) {
        checkNotNullWord(_wordHash);
        _;
    }

    /**
     * @dev Cannot go above the max level.
     */
    modifier mustBeBelowMaxLevel(uint256 _tokenId) {
        checkMaxLevel(_tokenId);
        _;
    }

    /**
     * @dev Tokens gotta exist to be queried, so we check that the token exists.
     */
    modifier tokenExists(uint256 _tokenId) {
        checkTokenExists(_tokenId);
        _;
    }

    /**
     * @notice This is the way to retrieve project details after they are added to the blockchain.
     * This is useful for front ends that may want to display the project details live.
     * @param _projectId The project to get the details from
     * @return _project GaucheLevel(uint8 wordPrice, uint64 price, address artistAddress, string baseURI)
     */
    function getProjectDetails(uint256 _projectId) public view returns (GaucheLevel memory _project) {
        require(_projectId < gaucheLevels.length, "GG: Must be in range of projects");
        _project = gaucheLevels[_projectId];
        return _project;
    }

    /**
     * @notice Current max level of art works ownable
     * @return A number 255 or less.
     */
    function getProjectLevel() public view returns (uint256) {
        return gaucheLevels.length;
    }

    /**
     * @notice Adds a project to the registry.
     * @param _wordPrice The price in levels, if there is one.
     * @param _price The price in ETH to mint, if there is one.
     * @param _artistAddress The artists ethereum address
     * @param _tokenURI The tokenURI, without a tokenId
     */
    function addProject(uint8 _wordPrice, uint64 _price, address _artistAddress, string memory _tokenURI)  onlyOwner public {
        require(gaucheLevels.length < MAX_LEVEL, "GG: Max 255");
        GaucheLevel memory project = GaucheLevel(_wordPrice, _price, _artistAddress, _tokenURI);
        emit ProjectAdded(gaucheLevels.length, project);
        gaucheLevels.push(project);
    }

    /**
     * @notice Allows an existing project to be updated. EX: Centralized host -> IPFS migration
     * @param _projectId The project to get the details from
     * @param _wordPrice The price in levels, if there is one.
     * @param _price The price in ETH to mint, if there is one.
     * @param _artistAddress The artists ethereum address
     * @param _tokenURI The tokenURI, without a tokenId
     */
    function editProject(uint256 _projectId, uint8 _wordPrice, uint64 _price, address _artistAddress, string memory _tokenURI) onlyOwner public {
        require( _projectId < gaucheLevels.length, "GG: Must be in range");
        GaucheLevel memory project = GaucheLevel(_wordPrice, _price, _artistAddress, _tokenURI);
        emit ProjectUpdated(_projectId, project);
        gaucheLevels[_projectId] = project;
    }

    /**
     * @notice Allows a token to insert a hash to gain a level and access to a new work of art
     * @param _tokenToChange The token we are adding state to
     * @param _wordHash The keccak256(word) hash generated off chain by the user. NO VALIDATION IS DONE HERE.
     */
    function spendRealityChange(uint256 _tokenToChange, bytes32 _wordHash)
        onlyIfTokenOwner(_tokenToChange)
        isNotMode(SalesState.Finalized)
        notNullWord(_wordHash)
        mustBeBelowMaxLevel(_tokenToChange)
    public payable {
        uint256 tokenLevel = getLevel(_tokenToChange);
        GaucheLevel memory project = gaucheLevels[tokenLevel];
        require(getFree(_tokenToChange) >= project.wordPrice, "GG: No free lvl");
        require(msg.value >= project.price, "GG: Too cheap");

        _changeReality(_tokenToChange, _wordHash, tokenLevel, project.wordPrice);
    }

    /**
     * @notice Allows a token to be burnt into another token, confering its free levels + 1 for its life
     * @param _tokenToBurn The token we are burning, moving its free levels +1 into the _tokenToChange.
     * @param _tokenToChange The token we are adding state to
     */
    function burnIntoToken(uint256 _tokenToBurn, uint256 _tokenToChange)
        onlyIfTokenOwner(_tokenToBurn)
        onlyIfTokenOwner(_tokenToChange)
        mustBeBelowMaxLevel(_tokenToChange)
        isMode(SalesState.Maintenance)
    public {
        uint256 burntTokenFree = getFree(_tokenToBurn);
        uint256 tokenTotalFreeLevels = getFree(_tokenToChange);
        require(tokenTotalFreeLevels + burntTokenFree + 1 <= 255, "GG: Max 255");

        bytes32 newHash = bytes32((uint256(tokenHashes[_tokenToChange]) + uint(0x01) + burntTokenFree));
        tokenHashes[_tokenToChange] = newHash;
        emit HashUpdated(_tokenToChange, newHash);

        _burn(msg.sender, _tokenToBurn);
    }

    /**
     * @notice Allows for a tokens hash to be verified without revealing it on chain.
     * @param _tokenId The token we are checking
     * @param _level The level we want to verify against.
     * @param _word The plain text word we are submitting. NEVER call this from a contract transaction as it will leak your word!
     */
    function verifyTruth(uint256 _tokenId, uint256 _level, string calldata _word)
        tokenExists(_tokenId)
     public view returns (bool answer) {
        require(_level < tokenLevel(_tokenId) && _level != 0, "GG: Word slot out of bounds");
        bytes32 word = tokenHashes[getShifted(_tokenId) + _level];
        bytes32 assertedTruth = keccak256(abi.encodePacked(_word));

        return (word == assertedTruth);
    }

    /**
     * @notice Returns the completed token URI for base token. We use this even though we have a projectURI for entry 0 as its standard and only costs dev gas.
     * @param tokenId The token we are checking.
     * @return string tokenURI
     */
    function tokenURI(uint256 tokenId)
        tokenExists(tokenId)
     public view virtual override returns (string memory) {
        GaucheLevel memory project = gaucheLevels[0];
        require(bytes(project.baseURI).length != 0, "GG: No base URI");
        return string(abi.encodePacked(project.baseURI, Strings.toString(tokenId)));
    }

    /**
     * @notice Returns the completed token URI for a project hosted in the contract
     * @param _tokenId The token we are checking.
     * @param _projectId The project we are checking.
     * @return tokenURI string with qualified url
     */
    function tokenProjectURI(uint256 _tokenId, uint256 _projectId)
        tokenExists(_tokenId)
    public view returns (string memory tokenURI) {
        require(_projectId < gaucheLevels.length, "GG: Must be within project range");
        require(tokenHashes[_tokenId] != 0, "GG: Token not found");
        require(_projectId < getLevel(_tokenId) , "GG: Level too low");
        tokenURI = string(abi.encodePacked(gaucheLevels[_projectId].baseURI, Strings.toString(_tokenId)));
        return tokenURI;
    }

    /**
     * @notice Returns the full decoded data as a struct for the token. This is the only way to get the state of a burned token.
     * @param _tokenId The token we are checking.
     * @return token GaucheToken( uint256 tokenId, uint256 free, uint256 spent, bool burned, bytes32[] ownedHashes )
     */
    function tokenFullData(uint256 _tokenId)
    public view returns (GaucheToken memory token) {
        return  GaucheToken(_tokenId, getFree(_tokenId), getLevel(_tokenId), getBurned(_tokenId), getOwnedHashes(_tokenId));
    }

    /**
     * @notice Returns the completed token URI for a project hosted in the contract
     * @param _tokenId The token we are checking.
     * @return bytes32 base tokenhash for the token
     */
    function tokenHash(uint256 _tokenId)
        tokenExists(_tokenId)
    public view returns (bytes32) {
        return tokenHashes[_tokenId];
    }

    /**
     * @notice Returns the completed token URI for a project hosted in the contract
     * @param _tokenId The token we are checking.
     * @param _level The token we are checking.
     * @return bytes32 project tokenHash for the token for a given project level.
     */
    function tokenProjectHash(uint256 _tokenId, uint256 _level)
        tokenExists(_tokenId)
    public view returns (bytes32) {
        require(_level != 0, "GG: Level must be non-zero");
        require(getLevel(_tokenId) > _level , "GG: Level too low");
        return tokenHashes[getShifted(_tokenId) + _level];
    }

    /**
     * @notice Checks if the token has been burnt.
     * @param _tokenId The token we are checking.
     * @return _burned bool. only true if the token has been burned
     */
    function tokenBurned(uint256 _tokenId) public view returns (bool _burned) {
        return getBurned(_tokenId);
    }

    /**
     * @notice Gets the hashes for each level a token has achieved.
     * @param _tokenId The token we are checking.
     * @return ownedHashes bytes32[] Full list of hashes owned by the token
     */
    function tokenHashesOwned(uint256 _tokenId)
        tokenExists(_tokenId)
    public view returns (bytes32[] memory ownedHashes) {
        return getOwnedHashes(_tokenId);
    }

    /**
     * @notice Gets the hashes for each level a token has achieved
     * @param _tokenId The token we are checking.
     * @return uint How many free levels the token has
     */
    function tokenFreeChanges(uint256 _tokenId)
        tokenExists(_tokenId)
    public view returns (uint) {
        return getFree(_tokenId);
    }

    /**
     * @notice Gets the tokens current level
     * @param _tokenId The token we are checking.
     * @return uint  How many levels the token has
     */
    function tokenLevel(uint256 _tokenId)
        tokenExists(_tokenId)
    public view returns (uint) {
        return getLevel(_tokenId);
    }

    function getBurnedCount() public view returns(uint256) {
        return balanceOf(burnAddress);
    }

    function getTotalSupply() public view returns(uint256) {
        return totalSupply() - getBurnedCount();
    }

    // We use this function to shift the tokenid 16bits to the left, since we use the last 8bits to store injected hashes
    // Example: Token 0x03e9 (1001) becomes 0x03e90000 . With 0x0000 storing the traits, and 0x0001+ storing new hashes
    // Overflow within this schema is impossible as there is 65535 entries between tokens in this schema and our max level is 255
    function getShifted(uint256 _tokenId) internal view returns(uint256) {
        return (_tokenId << 16);
    }

    // Internal functions used for modifiers and such.
    function checkNotNullWord(bytes32 _wordHash) internal view {
        require(_wordHash != 0x0, "GG: Cannot insert a null word");
    }

    function checkMaxLevel(uint256 _tokenId) internal view {
        require(getLevel(_tokenId) < gaucheLevels.length , "GG: Max level reached");
    }

    function getFree(uint256 _tokenId) internal view returns(uint256) {
        uint256 free = uint256(tokenHashes[_tokenId]) & 0xFF;
        return free;
    }

    function getLevel(uint256 _tokenId) internal view returns(uint256) {
        uint256 level = uint256(tokenHashes[_tokenId]) & 0xFF00;
        return level >> 8;
    }

    function getBurned(uint256 _tokenId) internal view returns(bool) {
        return (ownerOf(_tokenId) == burnAddress ? true : false);
    }

    function getOwnedHashes(uint256 _tokenId) internal view returns(bytes32[] memory ownedHashes) {
        uint256 tokenShiftedId = getShifted(_tokenId);
        uint256 tokenLevel = getLevel(_tokenId);
        ownedHashes = new bytes32[](tokenLevel);
        ownedHashes[0] = tokenHashes[_tokenId];

        for (uint256 i = 1; i < tokenLevel; i++) {
            ownedHashes[i] = tokenHashes[tokenShiftedId + i];
        }
        return ownedHashes;
    }

    /**
     * @dev This goes with the modifier tokenExists
     */
    function checkTokenExists(uint256 _tokenId) internal view returns (bool) {
        require(_exists(_tokenId) && ownerOf(_tokenId) != burnAddress, "GG: Token does not exist");
    }

    function _mintToken(address _toAddress, uint256 _count, bool _batch) internal override returns (uint256[] memory _tokenIds) {
        uint256 currentSupply = totalSupply();

        if (_batch) {
            _safeMint(_toAddress, _count);
            _tokenIds = new uint256[](_count);
        } else {
            _safeMint(_toAddress, 1);
            _tokenIds = new uint256[](1);
        }
        // This is ugly buts its kinda peak performance. We use the final two bytes of the hash to store free uses
        // Then we use the two bytes preceeding that for the level.
        // We also bitshift the tokenid so we can use the hashes mapping to store words

        for(uint256 i = 0; i < _count; i++) {
            uint256 tokenId = currentSupply + i;
            bytes32 level0hash = bytes32( ( uint256(keccak256(abi.encodePacked(block.number, _msgSender(), tokenId)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000) + uint(0x0100) + ( _batch ? uint(0x01) : _count) ) );
            tokenHashes[tokenId] = level0hash;
            emit HashUpdated(tokenId, level0hash); // This is to inform frontend services that we have new properties in hash 0
            _tokenIds[i] = tokenId;
            if(!_batch) {
                break;
            }
        }

        return _tokenIds;
    }

    function _changeReality(uint256 _tokenId, bytes32 _wordHash, uint256 _newSlot, uint256 _levelWordPrice) internal  {
        uint256 wordSlot = getShifted(_tokenId) +_newSlot;
        // Store the incoming word
        tokenHashes[wordSlot] = _wordHash;

        bytes32 levelZeroHash = bytes32((((uint256(tokenHashes[_tokenId]) + uint(0x0100) )- _levelWordPrice)));

        tokenHashes[_tokenId] = levelZeroHash;
        emit WordAdded(_tokenId, _wordHash, _newSlot, wordSlot);
        emit HashUpdated(_tokenId, levelZeroHash); // This is to inform frontend services that we have new properties in hash 0
    }

    function _burn(address owner, uint256 tokenId) internal virtual {
        transferFrom(owner, burnAddress, tokenId);
        emit TokenBurned(tokenId);
    }

}