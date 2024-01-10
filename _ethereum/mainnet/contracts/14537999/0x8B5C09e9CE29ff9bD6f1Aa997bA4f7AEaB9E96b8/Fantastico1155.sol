// SPDX-License-Identifier: MIT
// Copyright © BlockChain Magic Pte Ltd // MMXXII

/*

███████╗░█████╗░███╗░░██╗████████╗░█████╗░░██████╗████████╗██╗░█████╗░░█████╗░
██╔════╝██╔══██╗████╗░██║╚══██╔══╝██╔══██╗██╔════╝╚══██╔══╝██║██╔══██╗██╔══██╗
█████╗░░███████║██╔██╗██║░░░██║░░░███████║╚█████╗░░░░██║░░░██║██║░░╚═╝██║░░██║
██╔══╝░░██╔══██║██║╚████║░░░██║░░░██╔══██║░╚═══██╗░░░██║░░░██║██║░░██╗██║░░██║
██║░░░░░██║░░██║██║░╚███║░░░██║░░░██║░░██║██████╔╝░░░██║░░░██║╚█████╔╝╚█████╔╝
╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚══╝░░░╚═╝░░░╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░╚═╝░╚════╝░░╚════╝░

███████╗██████╗░░█████╗░░░░░░░░░███╗░░░░███╗░░███████╗███████╗
██╔════╝██╔══██╗██╔══██╗░░░░░░░████║░░░████║░░██╔════╝██╔════╝
█████╗░░██████╔╝██║░░╚═╝█████╗██╔██║░░██╔██║░░██████╗░██████╗░
██╔══╝░░██╔══██╗██║░░██╗╚════╝╚═╝██║░░╚═╝██║░░╚════██╗╚════██╗
███████╗██║░░██║╚█████╔╝░░░░░░███████╗███████╗██████╔╝██████╔╝
╚══════╝╚═╝░░╚═╝░╚════╝░░░░░░░╚══════╝╚══════╝╚═════╝░╚═════╝░
*/
pragma solidity 0.8.12;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155Supply.sol";
import "./Counters.sol";

//import "./console.sol";

contract Fantastico1155 is
    ERC1155,
    AccessControl,
    Pausable,
    ERC1155Supply,
    ReentrancyGuard
{
    event FmCreated(
        address fmCreatorAddress,
        uint256 tokenId,
        uint256 fmMaxSupply,
        string fmURL
    );

    event FmMetadataUpdated(uint256 tokenId, string fmURL, uint256 fmImgHash);

    event FmHidden(uint256 tokenId);
    event FmUnhidden(uint256 tokenId);

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter public fmHiddenCount;

    /**
     * @dev Struct to store the attributes of a Fantastic Moment token
     *
     * - fmCreatorAddress: The address of the creator of the FM
     * - fmURL: The URL of the FM metadata or image
     * - fmImgHash: The hash of the image of the FM
     * - fmSupply: The total supply of the FM
     * - hidden: Whether the FM is hidden or not
     */
    struct FantasticMoment {
        address fmCreatorAddress;
        string fmURL;
        uint16 fmMaxSupply;
        uint256 fmImgHash;
        // Fees on marketplace sales
        // Fantastico
        uint8 mpFantasticoFees;
        // Athlete's chosen charity
        uint8 mpCharityFees;
        // Requested by legal team in case of issues...
        bool fmHidden;
    }

    // * Unique tokenId for each FM
    mapping(uint256 => FantasticMoment) private _fmCollection;
    // * Mapping of the FM image SHA256 hash -> FM tokenId
    mapping(uint256 => uint256) public fmUniqueImgHashList;
    // * Hidden Fms tokenIds
    mapping(uint256 => bool) public fmHiddenList;
    // * Generic URL used for all hidden FMs
    string public fmHiddenURL;
    // * Address of the marketing wallet
    address public fmMarketingWallet;
    // * Value for calculation of % of newly minted FMS sent to
    // * marketing wallet - from 0 to 10 maximum
    uint256 public fmMarketingFees;
    // * Fees amount for external royalties (EIP2981), between 0-15
    uint256 public fmRoyaltyFees;
    // * Value for calculation of % of Fantastico fees
    // * on each marketplace sales - from 0 to 10 maximum
    uint256 public mpFantasticoFees;
    // * Minimum % deducted from Fantastico fees and
    // * sent to charity wallet - from 10 to 100 maximum
    uint256 public minCharityFees;
    // * The maximum amount of FM that can be minted
    // * between 1-2500 max
    uint256 public maxMintAmount;
    // * The contract metadata URI for OpenSea
    string public fmContractURI;
    // * Deactivate the emergency metadata update if true
    bool public killedMetadataUpdate;

    // * Roles for access control
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Constructor
     *
     * @param marketingWallet_ The address of the marketing wallet
     */
    constructor(address marketingWallet_) ERC1155("") {
        require(marketingWallet_ != address(0), "No address(0)");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        /* ****************************************
         * The functions below requires ADMIN_ROLE
         * - setHiddenURL()
         * - pause() / unpause()
         * - hideFm() / unhideFm()
         * - hideFms() / unhideFms()
         * - setMarketingWalletAddress()
         * - setMarketingFees()
         * - setFantasticoFees()
         * - setMinCharityFees()
         * ***************************************
         * The function below requires MANAGER_ROLE
         * - mintForAthlete()
         * ***************************************
         * The function below requires MINTER_ROLE
         * - mintByAthlete()
         * ***************************************/

        maxMintAmount = 2500;

        fmHiddenURL = "";

        fmMarketingWallet = marketingWallet_;
        // * 5% of newly minted FMs sent to Marketing wallet
        // * if minted amount > 20
        fmMarketingFees = 5;
        // 5% of royalty fees
        fmRoyaltyFees = 10;
        // * 5% of marketplace sales proceeds sent to Fantastico wallet
        mpFantasticoFees = 5;
        // * At least 10% of marketplace sales proceeds sent to charity wallet
        minCharityFees = 10;
    }

    /**
     *  @dev Public function to retrieve the contract description for OpenSea
     */
    function contractURI() external view returns (string memory) {
        return fmContractURI;
    }

    /**
     *  @dev Return the token name
     */
    function name() external pure returns (string memory) {
        return "Fantastico";
    }

    /**
     *  @dev Return the token Symbol
     */
    function symbol() external pure returns (string memory) {
        return "TICO";
    }

    /**
     * @dev Modifier to verify that a token exists.
     *
     * @param tokenId_ The tokenId to check.
     */
    modifier onlyIfExists(uint256 tokenId_) {
        require(exists(tokenId_), "No FM with this Id");
        _;
    }

    /**
     *  @dev Set the value of the generic URI returned for hidden tokens.
     *
     *  Default value is empty string "" - initialized in constructor
     *
     *  @param url_ the URI returned for the hidden tokens.
     *
     *  Ex: https://fantastico.ooo/api/v1/metadata/hidden.json
     *
     *  Requirements: ADMIN_ROLE
     */
    function setHiddenURL(string calldata url_) external onlyRole(ADMIN_ROLE) {
        fmHiddenURL = url_;
    }

    /**
     *  @dev Update the value a FM metadata URL and image hash.
     *
     * !! This function is here if problems are discovered
     * !! after the launch, if everything is OK it must be
     * !! permanently deactivated by calling killFmMetadataUpdate()
     *
     *  @param tokenId_ the if of the Fantastic Moment.
     *  @param fmURL_ the full URL to the FM metadata file.
     *  @param fmImgHash_ the SHA256 hash of the FM image.
     *
     *
     *  Requirements: SUPER_ADMIN_ROLE
     */
    function fmMetadataUpdate(
        uint256 tokenId_,
        string calldata fmURL_,
        uint256 fmImgHash_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) onlyIfExists(tokenId_) {
        require(!killedMetadataUpdate, "Permanently deactivated!");
        require(
            fmUniqueImgHashList[fmImgHash_] == 0,
            "Image hash already exists"
        );

        FantasticMoment storage fm = _fmCollection[tokenId_];
        // Delete previous image hash from the mapping
        delete fmUniqueImgHashList[fm.fmImgHash];
        fm.fmURL = fmURL_;
        fm.fmImgHash = fmImgHash_;
        // Save the new image hash
        fmUniqueImgHashList[fm.fmImgHash] = tokenId_;
        // Emit metadata updated event
        emit FmMetadataUpdated(tokenId_, fmURL_, fmImgHash_);
    }

    function killFmMetadataUpdate() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!killedMetadataUpdate, "Permanently deactivated!");
        killedMetadataUpdate = true;
    }

    /**
     *  @dev Pause the Athlete minting and transfers - but not manager minting
     *
     * IMPORTANT - !! MintForAthlete will not be paused !!
     *
     *  Requirements: ADMIN_ROLE
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     *  @dev Unpause the Athlete minting and tokens Transfers
     *
     *  Requirements: ADMIN_ROLE
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Only addresses with MINTER_ROLE can call this function.
     *
     * The owner of the FM will be the sender of the transaction.
     *
     * @param fmURL_ URL of the FM metadata or picture.
     *  Example: "ipfs://QmcFAs7GH9bh6Q11bLVwd5J2/FM.json"
     * @param fmImgHash_ SHA256 hash of the FM image.
     * @param amount_ Total amount of FMs to mint.
     * @param mpCharityFees_ Fees on marketplace sales
     *
     * Requirements: MINTER_ROLE
     */
    function mintByAthlete(
        string calldata fmURL_,
        uint256 fmImgHash_,
        uint256 amount_,
        uint256 mpCharityFees_
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        mint(msg.sender, fmURL_, fmImgHash_, amount_, mpCharityFees_);
    }

    /**
     * @dev Address with MANAGER_ROLE can call this function and mint FMs for
     * athletes, but only for addresses with MINTER_ROLE.
     *
     * The owner of the FM will be the creator address and *NOT* the sender of
     * the transaction.
     *
     * @param fmCreatorAddress_ Wallet address of the creator of the FM
     * @param fmURL_ URL of the FM metadata or picture.
     *  Example: "ipfs://QmcFAs7GH9bh6Q11bLVwd5J2/FM.json"
     * @param fmImgHash_ SHA256 hash of the FM image.
     * @param amount_ Total amount of FMs to mint.
     * @param mpCharityFees_ Fees on marketplace sales
     *
     * Requirements: MANAGER_ROLE
     */
    function mintForAthlete(
        address fmCreatorAddress_,
        string calldata fmURL_,
        uint256 fmImgHash_,
        uint256 amount_,
        uint256 mpCharityFees_
    ) external onlyRole(MANAGER_ROLE) {
        require(fmCreatorAddress_ != address(0), "No address(0)");
        require(fmCreatorAddress_ != msg.sender, "No mint for yourself");

        require(
            hasRole(MINTER_ROLE, fmCreatorAddress_),
            "creator address need MINTER_ROLE!"
        );

        // Creator must already have MINTER_ROLE
        mint(fmCreatorAddress_, fmURL_, fmImgHash_, amount_, mpCharityFees_);
    }

    /**
     * @dev Internal mint function that will mint the FM for the creator.
     *
     * Marketing allocation of newly minted FMs is based on the total supply,
     * the FMs sent to marketing wallet are deducted from the total supply.
     *
     * The marketing percentage allocation can be updated and the  accepted
     * values are between 0-10, with a default of 5 at contract deployment.
     *
     * - If total supply == 1:
     *       0 FM sent to marketing wallet
     *       1 FM sent to creator wallet
     *
     * - If total supply > 1 < 21:
     *       1 FM sent to marketing wallet
     *       (supply - 1) sent to creator wallet
     *
     * - If total supply >= 21:
     *       `fmMarketingFees`% of FMs sent to marketing wallet
     *       (supply - `fmMarketingFees`%) sent to creator wallet
     *
     * @param fmCreatorAddress_ Wallet address of the creator of the FM
     * @param fmURL_ URL of the FM metadata
     *  Example: "ipfs://QmcFAs7GH9bh6Q11bLVwd5J2/FM.json"
     * @param fmImgHash_ SHA256 hash of the FM image.
     * @param amount_ Total amount of FMs to mint.
     * @param mpCharityFees_ Fees on marketplace sales
     *
     * @return The tokenId of the FM
     */
    function mint(
        address fmCreatorAddress_,
        string calldata fmURL_,
        uint256 fmImgHash_,
        uint256 amount_,
        uint256 mpCharityFees_
    ) internal nonReentrant returns (uint256) {
        require(amount_ > 0 && amount_ <= maxMintAmount, "amount > max amount");

        require(
            mpCharityFees_ >= minCharityFees && mpCharityFees_ < 101,
            "not between 10-100!"
        );

        require(
            fmUniqueImgHashList[fmImgHash_] == 0,
            "Image hash already exists"
        );

        // * Total of FMs sent to Marketing wallet, depends on amount minted
        // * 1 FM: 0 | 2-20 FMs: 1 | > 20 FMs: `fmMarketingFees`%
        uint256 amountForMarketing = 0;

        if (fmMarketingFees > 0) {
            amountForMarketing = amount_ < 6 ? 0 : amount_ < 21
                ? 1
                : (amount_ * fmMarketingFees) / 100;
        }

        _tokenIds.increment();
        uint256 _newTokenId = _tokenIds.current();

        // * Add new FM to collection
        _fmCollection[_newTokenId] = FantasticMoment(
            fmCreatorAddress_,
            fmURL_,
            // Total supply
            uint16(amount_),
            fmImgHash_,
            uint8(mpFantasticoFees),
            uint8(mpCharityFees_),
            // Hidden status - default false
            false
        );

        // * Add fmImgHash_ to fmUniqueImgHashList
        fmUniqueImgHashList[fmImgHash_] = _newTokenId;

        // * Mint the FMs to the creator address
        _mint(fmCreatorAddress_, _newTokenId, amount_, "");

        // * Transfer the FMs allocated to the marketing wallet address if any
        // * !! if called by mintForAthlete() then msg.sender address must be
        // * approved or the transfer will fail
        if (amountForMarketing > 0) {
            safeTransferFrom(
                fmCreatorAddress_,
                fmMarketingWallet,
                _newTokenId,
                amountForMarketing,
                ""
            );
        }

        // console.log(
        //     "--> Contract Minting TokenId (%s)",
        //     _newTokenId
        //     // amount_,
        //     // amountForCreator,
        //     // amountForMarketing
        // );

        emit FmCreated(
            fmCreatorAddress_,
            _newTokenId,
            // Max supply
            amount_,
            fmURL_
        );

        return _newTokenId;
    }

    /**
     * @dev This implementation returns the Fantastic Moment URL,l
     * or `fmHiddenURL` if the token is hidden.
     *
     * @param tokenId_ The tokenId of the FM.
     */
    function uri(uint256 tokenId_)
        public
        view
        override
        onlyIfExists(tokenId_)
        returns (string memory)
    {
        // * Return the hiddenFmURL if FM is hidden
        return
            _fmCollection[tokenId_].fmHidden
                ? fmHiddenURL
                : _fmCollection[tokenId_].fmURL;
    }

    /**
     * @dev This implementation returns the Fantastic Moment image hash
     *
     * @param tokenId_ The tokenId of the FM.
     */
    function fmImgHash(uint256 tokenId_) public view returns (uint256) {
        // * Return the hiddenFmURL if FM is hidden
        return _fmCollection[tokenId_].fmImgHash;
    }

    /**
     * @dev Return the creator address of the Fantastic Moment
     * @param tokenId_ The tokenId of the FM.
     *
     * @return address of the creator of the FM
     */
    function fmCreatorAddress(uint256 tokenId_)
        external
        view
        onlyIfExists(tokenId_)
        returns (address)
    {
        return _fmCollection[tokenId_].fmCreatorAddress;
    }

    /**
     * @dev Return the Charity fees taken on Marketplace sales
     * the value is stored in the FM struct.
     *
     * @param tokenId_ The tokenId of the FM.
     *
     * @return Charity fees collected on Marketplace sales
     */
    function fmCharityFees(uint256 tokenId_)
        external
        view
        onlyIfExists(tokenId_)
        returns (uint256)
    {
        return _fmCollection[tokenId_].mpCharityFees;
    }

    /**
     * @dev Return the Fantastico fees taken on Marketplace sales
     * the value is stored in the FM struct.
     *
     * @param tokenId_ The tokenId of the FM.
     *
     * @return Fantastico fees collected on Marketplace sales
     */
    function fmFantasticoFees(uint256 tokenId_)
        external
        view
        onlyIfExists(tokenId_)
        returns (uint256)
    {
        return _fmCollection[tokenId_].mpFantasticoFees;
    }

    /**
     * @dev Hide a FM by setting the FM `hidden` attribute to true if it's value is false
     * !! Otherwise the value is not modified !!
     *
     * It will also:
     * - Add the tokenId to the list of hidden tokens `fmHiddenList`
     * - Increment by one the value of `fmsiddenCount`
     * - Emit an FmHidden event
     *
     * IMPORTANT: when hidden the value of the default generic URL `hiddenFmURL`
     * will be returned by the uri() function instead of the URL stored in
     * the FantasticMoment struct for this tokenId.
     *
     * @param tokenId_ The tokenId of the FM.
     *
     * Requirements: ADMIN_ROLE
     */
    function hideFm(uint256 tokenId_) public onlyRole(ADMIN_ROLE) {
        require(!isHidden(tokenId_), "FM is already hidden");

        //console.log("--> contract: hiding FM (%s)", tokenId_);

        _fmCollection[tokenId_].fmHidden = true;
        fmHiddenList[tokenId_] = true;
        fmHiddenCount.increment();
        emit FmHidden(tokenId_);
    }

    /**
     * @dev Hide multiple FMs at once
     *
     * @param tokenIds_ Array of tokenIds of the FMs to hide
     *
     * Requirements: ADMIN_ROLE
     */
    function hideFms(uint256[] calldata tokenIds_)
        external
        onlyRole(ADMIN_ROLE)
    {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            hideFm(tokenIds_[i]);
        }
    }

    /**
     * @dev Unhide a FM by setting the FM `hidden` attribute to false if it's value is true
     * !! Otherwise the value is not modified !!
     *
     * It will also:
     * - Delete the tokenId to the list of hidden tokens `fmHiddenList`
     * - Decrement by one the value of `fmHiddenCount`
     * - Emit an FmUnhidden event
     *
     * @param tokenId_ The tokenId of the FM.
     *
     * Requirements: ADMIN_ROLE
     */
    function unhideFm(uint256 tokenId_) public onlyRole(ADMIN_ROLE) {
        require(isHidden(tokenId_), "FM is not hidden");

        _fmCollection[tokenId_].fmHidden = false;
        delete fmHiddenList[tokenId_];
        fmHiddenCount.decrement();
        emit FmUnhidden(tokenId_);
    }

    /**
     * @dev Unhide multiple hidden FMs at once
     *
     * @param tokenIds_ Array of tokenIds of the FMs to unhide
     *
     * Requirements: ADMIN_ROLE
     */
    function unhideFms(uint256[] calldata tokenIds_)
        external
        onlyRole(ADMIN_ROLE)
    {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            unhideFm(tokenIds_[i]);
        }
    }

    /**
     * @dev Return true if the FM is hidden
     *
     * @param tokenId_ tokenId of the FM
     *
     * Requirements: ADMIN_ROLE
     */
    function isHidden(uint256 tokenId_)
        public
        view
        onlyIfExists(tokenId_)
        returns (bool)
    {
        return _fmCollection[tokenId_].fmHidden;
    }

    //TODO Write documentation
    function ownedToken(address account_)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = 0;
        uint256 currentTokenId = _tokenIds.current();
        for (uint256 tokenId = 1; tokenId <= currentTokenId; tokenId++) {
            if (balanceOf(account_, tokenId) != 0) {
                count++;
            }
        }
        uint256[] memory tokens = new uint256[](count);
        uint256 idx = 0;
        for (uint256 tokenId = 1; tokenId <= currentTokenId; tokenId++) {
            if (balanceOf(account_, tokenId) != 0) {
                tokens[idx] = tokenId;
                idx++;
            }
        }
        return tokens;
    }

    /**
     * @dev Update the value of the maximum amount of each newly minted FMs
     *
     * values are between 1-2500, with a default of 2500 at contract deployment.

     * @param value_ the maximum amount of each newly minted FMs
     *
     * Requirements: ADMIN_ROLE
     */
    function setMaxMintAmount(uint256 value_) external onlyRole(ADMIN_ROLE) {
        // * value_ must be between 1 and 2500
        require(value_ > 0 && value_ < 2501, "is not between 1-2500!");

        maxMintAmount = value_;
    }

    /**
     * @dev Update the URL of the contract metadata
     *
     * @param contractURI_ the new address of the contract metadata.
     *
     * Requirements: ADMIN_ROLE
     */
    function setContractURI(string calldata contractURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        fmContractURI = contractURI_;
    }

    /**
     * @dev Update the address of the Marketing wallet
     *
     * @param address_ the new address of the Marketing wallet.
     *
     * Requirements: ADMIN_ROLE
     */
    function setMarketingWalletAddress(address address_)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(address_ != address(0), "No address(0)");

        fmMarketingWallet = address_;
    }

    /**
     * @dev Update the percentage of newly minted FMs sent to Marketing wallet.
     *
     * Accepted value from 0 to 10 maximum - Default Value at contract
     * deployment: 5
     *
     * @param value_ the percentage of FMs sent to the Marketing wallet.
     *
     * Requirements: ADMIN_ROLE
     */
    function setMarketingFees(uint256 value_) external onlyRole(ADMIN_ROLE) {
        require(value_ < 11, "is more than 10!");

        fmMarketingFees = value_;
    }

    /**
     * @dev Update the value used for calculation of % of Fantastico fees
     * after each successful sales on the Fantastico marketplace.
     *
     * Accepted value from 0 to 10 maximum - Default Value at contract
     * deployment: 5
     *
     * This value will be stored on the FM data structure at mint time.
     *
     * @param value_ the percentage of FMs sent to Fantastico wallet.
     *
     * Requirements: ADMIN_ROLE
     */
    function setFantasticoFees(uint256 value_) external onlyRole(ADMIN_ROLE) {
        require(value_ < 11, "is more than 10!");

        mpFantasticoFees = value_;
    }

    /**
     * @dev Update the value used for calculation of % of Fantastico fees
     * sent to Charity wallet after each successful sales on the Fantastico
     * marketplace.
     *
     * Accepted value from 0 to 100 maximum - Default Value at contract
     * deployment: 10
     *
     * This value will be stored on the FM data structure at mint time.
     *
     * @param value_ the percentage of FMs sent to the Charity wallet.
     *
     * Requirements: ADMIN_ROLE
     */
    function setMinCharityFees(uint256 value_) external onlyRole(ADMIN_ROLE) {
        // * value_ must be between 10 and 100
        require(value_ > 9 && value_ < 101, "is not between 10-100!");

        minCharityFees = value_;
    }

    // EIP2981 standard royalties return.
    /**
     * @dev Return 2 values, the royalty fees receiver and royaltyAmount
     *
     * This value will be stored on the FM data structure at mint time.
     *
     * @param salePrice_ the percentage of FMs sent to the Charity wallet.
     */
    function royaltyInfo(uint256, uint256 salePrice_)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (fmMarketingWallet, (salePrice_ * fmRoyaltyFees) / 100);
    }

    /**
     * @dev Update Royalty fees for calculating % in royaltyInfo()
     *
     * Accepted value from 0 to 15 maximum - Default Value at contract
     * deployment: 10
     *
     * This value will be stored on fmRoyaltyFees(public variable).
     *
     * @param fees_ the percentage of royalty fees for calculating on royaltyInfo().
     *
     * Requirements: ADMIN_ROLE
     */
    function setRoyaltyFees(uint256 fees_) external onlyRole(ADMIN_ROLE) {
        require(fees_ >= 0 && fees_ < 16, "is not between 0-15!");

        fmRoyaltyFees = fees_;
    }

    /**
     * @dev The following functions are overrides required by Solidity.
     */

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     */
    function _beforeTokenTransfer(
        address operator_,
        address from_,
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator_, from_, to_, ids_, amounts_, data);
    }

    function supportsInterface(bytes4 interfaceId_)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId_);
    }
}
