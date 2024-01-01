// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";

import "./IDelegationRegistry.sol";
import "./IHotWalletProxy.sol";

//            .,,/.*/*,
//          , ,    *(****,                &
//        ..  .    .#*(/.,/               &WoWoWoWoW
//        ,..   .   .  /**(               %     ...
//        * .        . //(*              .#
//         , (,     .,*(**               &&&
//            / ...*,(/                (&,%/#,
//                                    #//.(*#,/
//                                  %.#& ,/ #% &*
//                                (*.&%  //%.## /(/
//                            . */ ,(%   /*% *##. @@#
//                            %#  /*#,   **.. ,//* ,(#(
//                         ,%#  .#(#%   **//*  ,/*%. (#/%.
//                       (%( , ,#&(/    ,*/*/   (#*(#  .//#*
//                    #./( ,  #(/((     **((#    *//(&*.. #*&%
//                ,%/#(,.   %/(##*     **//**     /,///# .. *(#&%/
//            .##(/#(...  (##((*/      (***///     ,*(***#.   ,#(#%//.
//        .##&#//*,,. . /(#/%(%,      ,**,/**(      ,#/((/(( .   #*/###*.
//        ,&%#**      &&#%%(&/        /(***#**,       (%/%/#%.  ,*  /%&(/( &
//         ((#&&&(*//((%%(#/,        #,,******%        ,*(,(#(#&  .*#%%%&&, .
//         /#*###,. .   ((////,(%,,,,,,,#(%#%##%#%///#**(##*%(#(  ...#%(#@*
//         (##%%(., ..  */*(/%///*((**(&@&&#(**/%%(%*/ ..#/*%(/%    .&/#(#*
//    ..  .###%&#,*,  , *(&((#/ . .,&&%&&&&&&%% .. ..    ,/#(((# .. *#*/%&/
//        ,*%#%&%,*  .. (*,/(/#   %%&%%%&&&%&&&@. .(     ((/(*(&.,. ,((%%#&.. ,.
//    . .... ../&#,...  /(##(#(,.(*(#%(%%//(&#/,/ *      #/(%&#%.   ,#&%,,,,,
//     .  ..,,.    ..,, .%%####*#*/((**.**,.,../,(&      ##/(%#(#(/***,
//                 .   .,,   ,/.   *. .,,        ,*. * .*(.**
//                                   ...

/**
 * Prefix "TOKEN_" is used for token related eligiblity, no need for a wallet address to be retrieved
 * Prefix "WALLET_" is used for wallet related eligiblity, need a wallet address to be retrieved
 */
enum Eligibility {
    TOKEN_SUPPLY_EXHAUSTED,
    WALLET_NOT_ALLOWED,
    TOKEN_MINT_CLOSE,
    TOKEN_MINT_OPEN,
    WALLET_ALREADY_MINTED,
    WALLET_ELIGIBLE
}

struct Season {
    // Art pieces
    uint256 nbArtPieces; // Exact number of art pieces
    mapping(uint256 => uint256) artPieceOrderNumbers; // ArtPieceId => orderNumber, used to order art pieces for the artfest
    // Schedule
    uint256 startDate; // Season start date (in seconds, since unix epoch)
    uint256 duration; // Season duration (in seconds)
    uint256 durationBetweenSales; // Duration between each art piece claim start date (in seconds)
    // Supply
    mapping(uint256 => uint256) artPieceSupplies; // ArtPieceId => Supply
    mapping(uint256 => uint256) artPieceMintedSupplies; // ArtPieceId => MintedSupply
    mapping(uint256 => mapping(address => bool)) artPieceMintFlags; // ArtPieceId => mapping(Wallet => MintedFlag)
    // Merkle tree
    mapping(uint256 => bytes32) artPieceMerkleRoots; // ArtPieceId => MerkleRoot
    address royaltyAddress; // Will be a Payment Splitter Contract
    mapping(uint256 => uint256) artPiecePrices; // ArtPieceId => Price
}

error NoDelegation();
error MintNotAllowed();
error IdTooBig();
error NbArtPiecesNotSet();
error InputTooBig();
error FailedWithdraw();
error SeasonIdTooLow();
error ArtPieceAlreadySet();
error ForbiddenPaidClaim();
error ArtPieceNotForSale();
error ValueTooLarge();
error FreeClaimOnly();

/**
 * @title ArtFest
 * @author WoW Studio LTD
 */
contract ArtFest is
    Initializable,
    ERC1155Upgradeable,
    DefaultOperatorFiltererUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    ERC2981Upgradeable
{
    address public constant DC_ADDR = 0x00000000000076A84feF008CDAbe6409d2FE638B;

    address public constant WARM_ADDR = 0xC3AA9bc72Bd623168860a1e5c6a4530d3D80456c;

    uint256 public constant FREE_CLAIM_ONLY_WINDOW = 12 hours;

    uint256 public currentSeasonId;
    mapping(uint256 => Season) public seasons;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory uri_,
        address royaltyAddress,
        uint96 royaltyFee
    ) public initializer {
        __ERC1155_init(uri_);
        __Ownable_init();
        __Pausable_init();
        __DefaultOperatorFilterer_init();
        __ERC2981_init();
        __UUPSUpgradeable_init();

        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function _checkDelegateCash(address addr) internal view returns (bool) {
        IDelegationRegistry dc = IDelegationRegistry(DC_ADDR);
        return dc.checkDelegateForAll(_msgSender(), addr);
    }

    function _checkWarmXyz(address addr) internal view virtual returns (bool) {
        IHotWalletProxy hotWalletProxy = IHotWalletProxy(WARM_ADDR);
        return hotWalletProxy.getHotWallet(addr) == _msgSender();
    }

    ////////////////////////////
    // Mint
    ////////////////////////////

    /**
     * @notice Mint 1 ArtPiece to an Addr
     *
     * @param addr The account which will receive the tokens
     * @param artPieceId ArtPiece ID
     * @param merkleProof Merkle proof
     *
     */
    function mint(
        address addr,
        uint256 artPieceId,
        bytes32[] calldata merkleProof
    ) external whenNotPaused payable {
        Season storage currentSeason = seasons[currentSeasonId];
        bool isEligible = getArtPieceEligibility(addr, currentSeasonId, artPieceId, merkleProof) == Eligibility.WALLET_ELIGIBLE;
        uint256 price = seasons[currentSeasonId].artPiecePrices[artPieceId];

        if (_msgSender() != addr && !_checkDelegateCash(addr) && !_checkWarmXyz(addr)) {
            revert NoDelegation();
        }

        if (!isEligible) {
            if (!_isFreeClaimOnlyWindowEnded(currentSeasonId, artPieceId)) revert FreeClaimOnly();
            if (price == 0) revert ArtPieceNotForSale();
            if (!_hasEnoughSupply(currentSeasonId, artPieceId)) revert MintNotAllowed();
            if (msg.value < price) revert MintNotAllowed();
            if (msg.value > price) revert ValueTooLarge();
        } else {
            if (msg.value > 0) revert ForbiddenPaidClaim();
        }

        uint256 tokenId = _getTokenId(currentSeasonId, artPieceId);

        currentSeason.artPieceMintFlags[artPieceId][addr] = true;
        unchecked {
            ++currentSeason.artPieceMintedSupplies[artPieceId];
        }

        _mint(addr, tokenId, 1, "");
    }

    ////////////////////////////
    // Mint batch
    ////////////////////////////

    /**
     * @notice Mint multiple ArtPieces to an Addr
     *
     * @param addr The account which will receive the tokens
     * @param artPieceIds ArtPiece IDs
     * @param merkleProofs Merkle proofs
     *
     */
    function mintBatch(
        address addr,
        uint256[] calldata artPieceIds,
        bytes32[][] calldata merkleProofs
    ) external whenNotPaused {
        Season storage currentSeason = seasons[currentSeasonId];

        if (_msgSender() != addr && !_checkDelegateCash(addr) && !_checkWarmXyz(addr)) {
            revert NoDelegation();
        }

        uint256[] memory tokenIds = new uint256[](artPieceIds.length);
        uint256[] memory amounts = new uint256[](artPieceIds.length);

        for (uint256 i = 0; i < artPieceIds.length; i++) {
            uint256 artPieceId = artPieceIds[i];

            if (
                getArtPieceEligibility(addr, currentSeasonId, artPieceId, merkleProofs[i]) !=
                Eligibility.WALLET_ELIGIBLE
            ) revert MintNotAllowed();

            uint256 tokenId = _getTokenId(currentSeasonId, artPieceId);

            currentSeason.artPieceMintFlags[artPieceId][addr] = true;

            unchecked {
                ++currentSeason.artPieceMintedSupplies[artPieceId];
            }

            tokenIds[i] = tokenId;
            amounts[i] = 1;
        }

        _mintBatch(addr, tokenIds, amounts, "");
    }

    ////////////////////////////
    // Eligibility
    ////////////////////////////

    /**
     * @notice Check if an address can mint a set of ArtPieces for a specific Season
     *
     * @param addr Address checked for eligibility
     * @param seasonId Season ID
     * @param artPieceIds List of ArtPieces IDs
     * @param merkleProofs List of Merkle proofs
     *
     * @dev
     * - We check that the address is in all the requested token current season's merkle proof.
     * - We check that none of the artPiece for the address has already been minted
     */
    function getArtPieceEligibilities(
        address addr,
        uint256 seasonId,
        uint256[] calldata artPieceIds,
        bytes32[][] calldata merkleProofs
    ) external view returns (Eligibility[] memory output) {
        output = new Eligibility[](artPieceIds.length);

        for (uint256 i = 0; i < artPieceIds.length; i++) {
            output[i] = getArtPieceEligibility(addr, seasonId, artPieceIds[i], merkleProofs[i]);
        }

        return output;
    }

    /**
     * @notice Check if an address can mint an ArtPiece for a specific Season
     *
     * @param addr Address checked for eligibility
     * @param seasonId Season ID
     * @param artPieceId ArtPiece ID
     * @param merkleProof Merkle proof
     *
     * @dev
     * - We check that the address is in all the requested token current season's merkle proof.
     * - We check that none of the artPiece for the address has already been minted
     */
    function getArtPieceEligibility(
        address addr,
        uint256 seasonId,
        uint256 artPieceId,
        bytes32[] calldata merkleProof
    ) public view returns (Eligibility) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));

        if (artPieceId >= seasons[seasonId].nbArtPieces) revert IdTooBig();

        if (_hasMinted(seasonId, artPieceId, addr)) {
            return Eligibility.WALLET_ALREADY_MINTED;
        }

        if (!_hasEnoughSupply(seasonId, artPieceId)) {
            return Eligibility.TOKEN_SUPPLY_EXHAUSTED;
        }

        if (!_isAllowed(seasonId, artPieceId, merkleProof, leaf)) {
            return Eligibility.WALLET_NOT_ALLOWED;
        }

        if (!_isMintOpen(seasonId, artPieceId)) {
            return Eligibility.TOKEN_MINT_CLOSE;
        }

        return Eligibility.WALLET_ELIGIBLE;
    }

    /**
     * @notice Check if the festival is open or close
     */
    function isFestOpen() external view returns (bool) {
        return _isFestOpen();
    }

    function _isFestOpen() private view returns (bool) {
        Season storage currentSeason = seasons[currentSeasonId];
        uint256 startDate = currentSeason.startDate;
        if (startDate == 0) {
            // Season start date missing
            return false;
        }

        uint256 endDate = startDate + currentSeason.duration;
        uint256 ts = block.timestamp;

        return ts >= startDate && ts <= endDate;
    }

    /**
     * @notice check if a token can be minted
     *
     * @param artPieceId ArtPiece ID
     */
    function isMintOpen(uint256 artPieceId) external view returns (bool) {
        return _isMintOpen(currentSeasonId, artPieceId);
    }

    function _isMintOpen(uint256 seasonId, uint256 artPieceId) private view returns (bool) {
        Season storage currentSeason = seasons[seasonId];
        uint256 startDate = currentSeason.startDate;
        if (startDate == 0) {
            // Season start date missing
            return false;
        }

        uint256 artPieceOrderNumbersIndex = seasons[seasonId].artPieceOrderNumbers[artPieceId];
        uint256 artPieceStartDate = startDate +
            currentSeason.durationBetweenSales *
            artPieceOrderNumbersIndex;
        uint256 endDate = startDate + currentSeason.duration;
        uint256 ts = block.timestamp;

        return ts >= artPieceStartDate && ts <= endDate;
    }

    function _isFreeClaimOnlyWindowEnded(uint256 seasonId, uint256 artPieceId) private view returns (bool) {
        Season storage currentSeason = seasons[seasonId];
        uint256 artPieceOrderNumbersIndex = seasons[seasonId].artPieceOrderNumbers[artPieceId];
        uint256 artPieceFreeClaimOnlyWindowEndDate = currentSeason.startDate +
            currentSeason.durationBetweenSales *
            artPieceOrderNumbersIndex + uint256(FREE_CLAIM_ONLY_WINDOW);
        return block.timestamp >= artPieceFreeClaimOnlyWindowEndDate;
    }

    /**
     * @notice check if a user has minted a token
     *
     * @param artPieceId ArtPiece ID
     * @param addr User address
     */
    function hasMinted(uint256 artPieceId, address addr) external view returns (bool) {
        return _hasMinted(currentSeasonId, artPieceId, addr);
    }

    function _hasMinted(
        uint256 seasonId,
        uint256 artPieceId,
        address addr
    ) private view returns (bool) {
        return seasons[seasonId].artPieceMintFlags[artPieceId][addr];
    }

    /**
     * @notice check if an art piece has supply left (> 0) for the current season
     *
     * @param artPieceId ArtPiece ID
     */
    function hasEnoughSupply(uint256 artPieceId) external view returns (bool) {
        return _hasEnoughSupply(currentSeasonId, artPieceId);
    }

    function _hasEnoughSupply(uint256 seasonId, uint256 artPieceId) private view returns (bool) {
        return
            seasons[seasonId].artPieceMintedSupplies[artPieceId] <
            seasons[seasonId].artPieceSupplies[artPieceId];
    }

    /**
     * @notice check if a Leaf is in the Merkle Proof (is a user is allowed to mint)
     *
     * @param artPieceId ArtPiece ID
     * @param merkleProof Merkle proof
     * @param leaf Merkle leaf (wallet address)
     */
    function isAllowed(
        uint256 artPieceId,
        bytes32[] memory merkleProof,
        bytes32 leaf
    ) external view returns (bool) {
        return _isAllowed(currentSeasonId, artPieceId, merkleProof, leaf);
    }

    function _isAllowed(
        uint256 seasonId,
        uint256 artPieceId,
        bytes32[] memory merkleProof,
        bytes32 leaf
    ) private view returns (bool) {
        bytes32 currentArtPieceMerkleRoot = seasons[seasonId].artPieceMerkleRoots[artPieceId];
        return MerkleProof.verify(merkleProof, currentArtPieceMerkleRoot, leaf);
    }

    ////////////////////////////
    // Getters/Setters
    ////////////////////////////

    /**
     * @notice Get the season information as a JSON
     *
     * @return string A JSON  like {'is-festival-open': bool, 'art-pieces': { hexString: uint, ... }}
     */
    function getSeasonInformation(uint256 seasonId) external view returns (string memory) {
        Season storage season = seasons[seasonId];
        bytes memory isFestOpenJSON;
        if (_isFestOpen()) {
            isFestOpenJSON = abi.encodePacked('"is-festival-open":true');
        } else {
            isFestOpenJSON = abi.encodePacked('"is-festival-open":false');
        }

        bytes memory artPieces = abi.encodePacked('"art-pieces":{');
        for (uint256 i = 0; i < season.nbArtPieces; i++) {
            uint256 id = _getTokenId(seasonId, i);

            artPieces = abi.encodePacked(
                artPieces,
                '"',
                Strings.toHexString(id, 32),
                '":',
                Strings.toString(uint256(_getArtPieceStatus(seasonId, i)))
            );

            if (i != season.nbArtPieces - 1) {
                artPieces = abi.encodePacked(artPieces, ",");
            }
        }
        artPieces = abi.encodePacked(artPieces, "}");

        // prettier-ignore
        return string(
            abi.encodePacked(
                "{",
                    isFestOpenJSON, ",",
                    artPieces,
                "}"
            )
        );
    }

    /**
     * @notice Returns all the queried ArtPieces statuses (open / supply left / closed)
     *
     * @param seasonId Season ID
     * @param artPieceIds array ArtPiece ID
     */
    function getArtPieceStatuses(
        uint256 seasonId,
        uint256[] calldata artPieceIds
    ) external view returns (Eligibility[] memory output) {
        output = new Eligibility[](artPieceIds.length);

        for (uint256 i = 0; i < artPieceIds.length; i++) {
            output[i] = _getArtPieceStatus(seasonId, artPieceIds[i]);
        }

        return output;
    }

    /**
     * @notice Return the Status of an ArtPiece (open / supply left / closed)
     *
     * @param seasonId Season ID
     * @param artPieceId ArtPiece ID
     */
    function _getArtPieceStatus(
        uint256 seasonId,
        uint256 artPieceId
    ) internal view returns (Eligibility) {
        if (artPieceId >= seasons[seasonId].nbArtPieces) revert IdTooBig();

        if (!_hasEnoughSupply(seasonId, artPieceId)) {
            return Eligibility.TOKEN_SUPPLY_EXHAUSTED;
        }

        if (!_isMintOpen(currentSeasonId, artPieceId)) {
            return Eligibility.TOKEN_MINT_CLOSE;
        }

        return Eligibility.TOKEN_MINT_OPEN;
    }

    /**
     * @notice Set a current season with all the required data about art pieces
     *
     * @param nbArtPieces Number of ArtPieces
     * @param artPieceIds List of ArtPieces IDs
     * @param artPieceOrderNumbers List of art piece order numbers
     * @param artPieceSupplies List of art piece supplies
     * @param merkleRoots List of Merkle roots
     */
    function setCurrentSeasonArtPieceData(
        uint256 nbArtPieces,
        uint256[] calldata artPieceIds,
        uint256[] calldata artPieceOrderNumbers,
        uint256[] calldata artPieceSupplies,
        bytes32[] calldata merkleRoots,
        uint256[] calldata artPiecePrices
    ) external onlyOwner {
        // ArtPieces
        setNbArtPieces(nbArtPieces);
        setArtPieceOrderNumbers(artPieceIds, artPieceOrderNumbers);
        setArtPieceSupplies(artPieceIds, artPieceSupplies);
        setArtPiecePrices(artPieceIds, artPiecePrices);

        // Set Merkle Root
        setMerkleRoots(artPieceIds, merkleRoots);
    }

    /**
     * @notice Set current season time data
     *
     * @param timestampStartDate Season start date as a UNIX number in seconds
     * @param duration Sale duration in seconds
     * @param durationBetweenSales Duration between sales in seconds;
     */
    function setCurrentSeasonTimeData(
        uint256 timestampStartDate,
        uint256 duration,
        uint256 durationBetweenSales
    ) external onlyOwner {
        // Duration of the Season
        setStartDate(timestampStartDate);
        setDuration(duration);
        setDurationBetweenSales(durationBetweenSales);
    }

    /**
     * @notice Increment the current season id
     *
     */
    function incCurrentSeasonIndex() public onlyOwner {
        unchecked {
            ++currentSeasonId;
        }
    }

    /**
     * @notice Set the number of ArtPieces of the current season
     *
     * @param nbArtPieces Number of ArtPieces
     */
    function setNbArtPieces(uint256 nbArtPieces) public onlyOwner {
        if (nbArtPieces > type(uint16).max) revert InputTooBig();

        Season storage currentSeason = seasons[currentSeasonId];
        currentSeason.nbArtPieces = nbArtPieces;
    }

    /**
     * @notice Get tokens total supply
     *
     * @param seasonId Season ID
     * @param artPieceIds List of ArtPieces IDs
     */
    function getArtPieceOrderNumbers(
        uint256 seasonId,
        uint256[] calldata artPieceIds
    ) external view returns (uint256[] memory) {
        uint256[] memory _artPieceOrderNumbers = new uint256[](artPieceIds.length);
        for (uint256 i = 0; i < artPieceIds.length; i++) {
            uint256 artPieceId = artPieceIds[i];
            if (artPieceId >= seasons[seasonId].nbArtPieces) revert IdTooBig();

            _artPieceOrderNumbers[i] = seasons[seasonId].artPieceOrderNumbers[artPieceId];
        }

        return _artPieceOrderNumbers;
    }

    /**
     * @notice Set the current season startDate
     *
     * @param artPieceIds List of ArtPieces IDs
     * @param artPieceOrderNumbers List of art piece order numbers
     */
    function setArtPieceOrderNumbers(
        uint256[] calldata artPieceIds,
        uint256[] calldata artPieceOrderNumbers
    ) public onlyOwner {
        Season storage currentSeason = seasons[currentSeasonId];

        for (uint256 i = 0; i < artPieceIds.length; i++) {
            uint256 artPieceId = artPieceIds[i];
            uint256 artPieceIdx = artPieceOrderNumbers[i];

            currentSeason.artPieceOrderNumbers[artPieceId] = artPieceIdx;
        }
    }

    /**
     * @notice Set the current season startDate
     *
     * @param timestamp Season start date as a UNIX number in seconds
     */
    function setStartDate(uint256 timestamp) public onlyOwner {
        seasons[currentSeasonId].startDate = timestamp;
    }

    /**
     * @notice Set the sale duration
     *
     * @param duration Sale duration in seconds
     */
    function setDuration(uint256 duration) public onlyOwner {
        seasons[currentSeasonId].duration = duration;
    }

    /**
     * @notice Set the duration between sales
     *
     * @param durationBetweenSales Duration between sales in seconds;
     */
    function setDurationBetweenSales(uint256 durationBetweenSales) public onlyOwner {
        seasons[currentSeasonId].durationBetweenSales = durationBetweenSales;
    }

    /**
     * @notice Get tokens total supply
     *
     * @param seasonId Season ID
     * @param artPieceIds List of ArtPieces IDs
     */
    function getArtPieceSupplies(
        uint256 seasonId,
        uint256[] calldata artPieceIds
    ) external view returns (uint256[] memory) {
        uint256[] memory artPieceSupplies = new uint256[](artPieceIds.length);
        for (uint256 i = 0; i < artPieceIds.length; i++) {
            uint256 artPieceId = artPieceIds[i];
            if (artPieceId >= seasons[seasonId].nbArtPieces) revert IdTooBig();

            artPieceSupplies[i] = seasons[seasonId].artPieceSupplies[artPieceId];
        }

        return artPieceSupplies;
    }

    /**
     * @notice Get tokens prices
     *
     * @param seasonId Season ID
     * @param artPieceIds List of ArtPieces IDs
     */
    function getArtPiecePrices(
        uint256 seasonId,
        uint256[] calldata artPieceIds
    ) external view returns (uint256[] memory) {
        uint256[] memory artPiecePrices = new uint256[](artPieceIds.length);
        for (uint256 i = 0; i < artPieceIds.length; i++) {
            uint256 artPieceId = artPieceIds[i];
            if (artPieceId >= seasons[seasonId].nbArtPieces) revert IdTooBig();

            artPiecePrices[i] = seasons[seasonId].artPiecePrices[artPieceId];
        }

        return artPiecePrices;
    }

    /**
     * @notice Set the total supply for current season art pieces
     *
     * @param artPieceIds List of ArtPieces IDs
     * @param artPieceSupplies List of art piece supplies
     */
    function setArtPieceSupplies(
        uint256[] calldata artPieceIds,
        uint256[] calldata artPieceSupplies
    ) public onlyOwner {
        Season storage currentSeason = seasons[currentSeasonId];

        if (currentSeason.nbArtPieces == 0) revert NbArtPiecesNotSet();
        if (artPieceIds.length > type(uint16).max) revert InputTooBig();

        for (uint256 i = 0; i < artPieceIds.length; i++) {
            uint256 artPieceId = artPieceIds[i];
            if (artPieceId >= currentSeason.nbArtPieces) revert IdTooBig();

            currentSeason.artPieceSupplies[artPieceId] = artPieceSupplies[i];
        }
    }

    /**
     * @notice Set the price of art pieces for current season
     *
     * @param artPieceIds List of ArtPieces IDs
     * @param artPiecePrices List of art piece prices
     */
    function setArtPiecePrices(
        uint256[] calldata artPieceIds,
        uint256[] calldata artPiecePrices
    ) public onlyOwner {
        Season storage currentSeason = seasons[currentSeasonId];

        if (currentSeason.nbArtPieces == 0) revert NbArtPiecesNotSet();
        if (artPieceIds.length > type(uint16).max) revert InputTooBig();

        for (uint256 i = 0; i < artPieceIds.length; i++) {
            uint256 artPieceId = artPieceIds[i];
            if (artPieceId >= currentSeason.nbArtPieces) revert IdTooBig();

            currentSeason.artPiecePrices[artPieceId] = artPiecePrices[i];
        }
    }

    /**
     * @notice Get tokens total supply left
     *
     * @param seasonId Season ID
     */
    function getNbTokenLeft(uint256 seasonId) external view returns (uint256[] memory nbTokenLeft) {
        uint256 nbSeasonArtpiece = seasons[seasonId].nbArtPieces;
        nbTokenLeft = new uint256[](nbSeasonArtpiece);
        for (uint256 i = 0; i < nbSeasonArtpiece; i++) {
            nbTokenLeft[i] =
                seasons[seasonId].artPieceSupplies[i] -
                seasons[seasonId].artPieceMintedSupplies[i];
        }

        return nbTokenLeft;
    }

    /**
     * @notice Get tokens minted supply
     *
     * @param seasonId Season ID
     * @param artPieceIds List of ArtPieces IDs
     */
    function getMintedSupplies(
        uint256 seasonId,
        uint256[] calldata artPieceIds
    ) external view returns (uint256[] memory mintedSupplies) {
        mintedSupplies = new uint256[](artPieceIds.length);
        for (uint256 i = 0; i < artPieceIds.length; i++) {
            uint256 artPieceId = artPieceIds[i];
            if (artPieceId >= seasons[seasonId].nbArtPieces) revert IdTooBig();

            mintedSupplies[i] = seasons[seasonId].artPieceMintedSupplies[artPieceId];
        }

        return mintedSupplies;
    }

    /**
     * @notice Set the merkle root for current season artPieces
     *
     * @param seasonId Season ID
     * @param artPieceIds List of ArtPieces IDs
     */
    function getMerkleRoots(
        uint256 seasonId,
        uint256[] calldata artPieceIds
    ) external view returns (bytes32[] memory merkleRoots) {
        Season storage currentSeason = seasons[seasonId];

        merkleRoots = new bytes32[](artPieceIds.length);
        for (uint256 i = 0; i < artPieceIds.length; i++) {
            uint256 artPieceId = artPieceIds[i];
            if (artPieceId >= seasons[seasonId].nbArtPieces) revert IdTooBig();

            merkleRoots[i] = currentSeason.artPieceMerkleRoots[artPieceId];
        }

        return merkleRoots;
    }

    /**
     * @notice Set the merkle root for current season artPieces
     *
     * @param artPieceIds List of ArtPieces IDs
     * @param merkleRoots List of Merkle roots
     */
    function setMerkleRoots(
        uint256[] calldata artPieceIds,
        bytes32[] calldata merkleRoots
    ) public onlyOwner {
        Season storage currentSeason = seasons[currentSeasonId];

        if (currentSeason.nbArtPieces == 0) revert NbArtPiecesNotSet();

        for (uint256 i = 0; i < artPieceIds.length; i++) {
            uint256 artPieceId = artPieceIds[i];
            if (artPieceId >= currentSeason.nbArtPieces) revert IdTooBig();

            currentSeason.artPieceMerkleRoots[artPieceId] = merkleRoots[i];
        }
    }

    /**
     * @notice Return the ERC1155 token ID
     *
     * @param seasonId Season ID
     * @param artPieceId The ArtPiece ID
     */
    function getTokenId(
        uint256 seasonId,
        uint256 artPieceId
    ) external view returns (uint256 tokenId) {
        return _getTokenId(seasonId, artPieceId);
    }

    function _getTokenId(
        uint256 seasonId,
        uint256 artPieceId
    ) internal view returns (uint256 tokenId) {
        if (artPieceId >= seasons[seasonId].nbArtPieces) revert IdTooBig();

        tokenId = (seasonId << 16) | uint16(artPieceId);

        return tokenId;
    }

    /**
     * @notice Returns the suppply of tokens for next season, given a Supply Coefficient
     *
     * @param seasonId Season ID
     * @param supplyCoefficient By how much the supply will be increased/decreased (in base precisionCoeff (10^6) so 125000 = 12.5%)
     *
     * @dev The formula used to compute next supplies is the one used to increase/decrease Ethereum base fee
     */
    function getNextSupplies(
        uint256 seasonId,
        int256 supplyCoefficient
    ) external view returns (int256[] memory newSupplies) {
        int256 precisionCoeff = 10 ** 6;
        uint256 nbSeasonArtpiece = seasons[seasonId].nbArtPieces;
        newSupplies = new int256[](nbSeasonArtpiece);
        for (uint256 i = 0; i < nbSeasonArtpiece; i++) {
            int256 ts = int256(seasons[seasonId].artPieceSupplies[i]);
            int256 ms = int256(seasons[seasonId].artPieceMintedSupplies[i]);

            if (ts == 0) {
                newSupplies[i] = 0;
            } else {
                int256 a = supplyCoefficient * ((2 * (ms * precisionCoeff)) / ts - precisionCoeff);
                newSupplies[i] = ts + (ts * a) / precisionCoeff ** 2;
            }
        }

        return newSupplies;
    }

    /**
     * @notice Set the _uri parameter
     *
     * @param newuri A global uri for all the tokens Following EIP-1155, should contain `{id}`
     */
    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    /**
     * @notice Pause the minting of tokens for current season
     */
    function pauseCurrentSeason() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the minting of tokens for current season
     */
    function unpauseCurrentSeason() external onlyOwner {
        _unpause();
    }

    /**
     * @inheritdoc IERC2981Upgradeable
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) public view virtual override returns (address, uint256) {
        (address receiver, uint256 royaltyAmount) = super.royaltyInfo(_tokenId, _salePrice);

        // Get the 240 first bits of the _tokenId
        uint256 seasonId = _tokenId >> 16;
        // We check if the season has a royalty address set, otherwise we keep the default royalty address
        if (seasons[seasonId].royaltyAddress != address(0)) {
            receiver = seasons[seasonId].royaltyAddress;
        }

        return (receiver, royaltyAmount);
    }

    /**
     * @notice Change the royalty fee for the collection
     *
     * @param newRoyaltyAddress new Address that will receive the royalties
     * @param feeNumerator new Fee for the Royalties
     */
    function setRoyaltyInfo(address newRoyaltyAddress, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(newRoyaltyAddress, feeNumerator);
    }

    /**
     * @notice Set Royalty Address for a season. We want to be able to change this address even for past seasons in case
     * a Payee loses access to their wallet
     *
     * @param seasonId Season ID
     * @param paymentSplitterAddress Address of the Payment Splitter
     */
    function setRoyaltyAddress(uint256 seasonId, address paymentSplitterAddress) public onlyOwner {
        if (seasonId > currentSeasonId) revert IdTooBig();
        Season storage season = seasons[seasonId];
        season.royaltyAddress = paymentSplitterAddress;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155Upgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Allow withdrawing funds to the withdrawAddress
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        (bool sent, ) = _msgSender().call{value: balance}("");
        if (!sent) revert FailedWithdraw();
    }

    /**
     * @notice Owner-only method: add a new Artpiece to a specific season
     *
     * @param seasonId Season ID
     */
    function addArtPieceToSeason(uint256 seasonId) external onlyOwner {
        Season storage season = seasons[seasonId];

        // Increment the number of ArtPieces in the season
        season.nbArtPieces++;
        uint256 newArtPieceId = season.nbArtPieces - 1;

        // We are setting an artPieceOrderNumber bigger than the 15 first ArtPieces
        season.artPieceOrderNumbers[newArtPieceId] = newArtPieceId;
    }

    /**
     * @notice Owner-only method: airdrop a specific artpiece to a list of addresses
     *
     * @param seasonId Season ID
     * @param artPieceId ArtPiece ID
     * @param addresses List of addresses to airdrop to
     * @param amounts List of amounts to airdrop to each address
     */
    function airdropArtPiece(
        uint256 seasonId,
        uint256 artPieceId,
        address[] memory addresses,
        uint256[] memory amounts
    ) external onlyOwner {
        Season storage season = seasons[seasonId];

        if (artPieceId >= season.nbArtPieces) revert IdTooBig();

        uint256 tokenId = _getTokenId(seasonId, artPieceId);
        uint256 addedSupply = 0;

        for (uint256 i = 0; i < addresses.length; i++) {
            season.artPieceMintFlags[artPieceId][addresses[i]] = true;
            addedSupply += amounts[i];
            _mint(addresses[i], tokenId, amounts[i], "");
        }

        season.artPieceSupplies[artPieceId] += addedSupply;
        season.artPieceMintedSupplies[artPieceId] += addedSupply;
    }

    /**
     * @dev See {UUPSUpgradeable-_authorizeUpgrade}.
     */
    function _authorizeUpgrade(address) internal override onlyOwner {} // solhint-disable-line

    /**
     * @dev Operator Filter registry
     */

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}
