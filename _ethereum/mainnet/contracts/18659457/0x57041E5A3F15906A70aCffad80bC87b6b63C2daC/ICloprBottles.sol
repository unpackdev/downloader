// SPDX-License-Identifier: MIT
// Clopr Contracts

pragma solidity 0.8.21;

import "./IERC721A.sol";

/**
 * @title ICloprBottles
 * @author Pybast.eth - Nefture
 * @custom:lead Antoine Bertin - Clopr
 * @notice This contract serves as the core of the Clopr protocol, managing the CloprBottles NFT collection, including potion-based assets, staking mechanisms, and dynamic metadata.
 */
interface ICloprBottles is IERC721A {
    /// @notice struct for base URI information
    /// @param baseUri base URI of the potion
    /// @param isFrozen if true, then the baseUri can't be modified
    /// @param exists used to know if a potionBaseUri exists
    struct PotionBaseUri {
        string baseUri;
        bool isFrozen;
        bool exists;
    }

    /// @notice struct for bottles information
    /// @param potionId is the ID of the potion inside the bottle or the ID of the last potion if the bottle is empty
    /// @param filled is the fill status of the bottle from 0 (empty) or 100 (full)
    /// @param delegatedFillLevel if true, then potionFill should be ingored and the fill level calculation should be delegated to the potion contract
    /// @param stakingTime timestamp of the bottle's staking or 0 if the bottle is unstaked
    /// @param numberDrinks number of times the bottle was drunk
    /// @param lastEmptyBlock block number at which the bottle was last emptied
    struct BottleInformation {
        uint16 potionId;
        bool filled;
        bool delegatedFillLevel;
        uint48 stakingTime;
        uint24 numberDrinks;
        uint64 lastEmptyBlock;
    }

    /// @notice struct for mint phase information
    /// @param price is the price of the mint phase
    /// @param startTimestamp is the start timestamp of the mint phase
    /// @param endTimestamp is the end timestamp of the mint phase
    /// @param maxMintPerWallet is the maximum token that can be minted per address
    /// @param remainingSupply is the remaining supply for a mint phase
    struct MintPhase {
        uint128 price;
        uint48 startTimestamp;
        uint48 endTimestamp;
        uint8 maxMintPerWallet;
        uint16 remainingSupply;
    }

    /// @notice thrown if the given vault is not delegated to the caller
    error InvalidDelegateVaultPairing();

    /// @notice thrown if a given potion doesn't exist
    error PotionDoesntExist();

    /// @notice thrown if a potion's URI is frozen
    error PotionUriIsFrozen();

    /// @notice thrown if a potion already exist
    error PotionAlreadyExist();

    /// @notice thrown if an address is not the bottle's owner
    error NotBottleOwner();

    /// @notice thrown if a bottle is not staked
    error BottleNotStaked();

    /// @notice thrown if the marketing supply has been reached
    error MarketingSupplyReached();

    /// @notice thrown if the mint phase already exist
    error MintPhaseAlreadyExist();

    /// @notice thrown if the mint phase doesn't exist
    error MintPhaseDoesntExist();

    /// @notice thrown if the mint phase has ended or if it doesn't exist
    error MintPhaseEndedOrDoesntExist();

    /// @notice thrown if the mint phase has not started yet
    error MintPhaseNotStarted();

    /// @notice thrown if the mint price is not correct
    error BadMintPrice();

    /// @notice thrown if the mint is sold out
    error MintSoldOut();

    /// @notice thrown if the mint phase is sold out
    error PhaseSoldOut();

    /// @notice thrown if the phase's maximum mint has been reached
    error MaxMintReached();

    /// @notice thrown if not authorised to mint
    error NotAuthorised();

    /// @notice thrown if trying to transfer a staked bottle
    error CantTransferStakedBottle();

    /// @notice thrown if trying to transferFrom a bottle that was just emptied
    error CantTransferRecentlyEmptiedBottle();

    /// @notice thrown if trying to fill up a bottle without the authorisation
    error FillingUpNotAuthorised();

    /// @notice thrown if trying to fill up a bottle that is not empty
    error BottleNotEmpty();

    /// @notice thrown if trying to empty a bottle without the authorisation
    error EmptyingNotAuthorized();

    /// @notice thrown if trying to empty a bottle from the wrong potion
    error InvalidPotion();

    /// @notice thrown if trying to empty a bottle that is not full
    error BottleNotFull();

    /// @notice thrown if trying to set the royalties receiver to the zero address
    error RoyaltyReceiverCantBeZero();

    /// @notice thrown if trying to set the royalties amount to a value higher than the maximum of 1000
    error RoyaltyPerThousandTooHigh();

    /// @notice thrown if there is no ether left to withdraw from the contract
    error NothingToWithdraw();

    /// @notice thrown if trying to withdraw to the zero address
    error CantWithdrawToZeroAddress();

    /// @notice thrown if withdrawing has failed
    error FailedToWithdraw();

    /// @notice thrown if trying to set the potionBaseUri as an empty string
    error PotionBaseUriCantBeNull();

    /// @notice thrown if trying to set potionFillContract or potionEmptyContract to address(0)
    error PotionContractCantBeNull();

    /// @notice thrown if trying to set the startTimestamp of a mint phase to zero
    error InvalidStartTimestamp();

    /// @notice emitted when a new potion type is added to the Clopr protocol
    /// @param potionFillContract contract allowed to fill up bottles
    /// @param potionEmptyContract contract allowed to empty bottles
    /// @param potionId new potion's unique ID
    /// @param potionMetadataUri nes potion's metadata URI
    event NewPotion(
        address indexed potionFillContract,
        address indexed potionEmptyContract,
        uint256 indexed potionId,
        string potionMetadataUri
    );

    /// @notice emitted when a potion's base URI is modified
    /// @param potionId potion's ID
    /// @param potionMetadataBaseUri new potion's base URI
    event NewPotionBaseUri(
        uint256 indexed potionId,
        string potionMetadataBaseUri
    );

    /// @notice emitted when a potion's URI is frozen so that it will never be modified
    /// @param potionId ID of the potion subject to a URI freeze
    event FreezePotionUri(uint256 indexed potionId);

    /// @notice emitted when a bottle is staked or unstaked
    /// @param tokenId ID of the bottle
    /// @param staked true if the bottle is being staked, false if it is being unstaked
    event BottleStaked(uint256 indexed tokenId, bool indexed staked);

    /// @notice emitted when a new staking season is started
    /// @param seasonStartTime timestamp of the start of the season
    event StartNewSeason(uint256 indexed seasonStartTime);

    /// @notice emitted when a bottle is filled up with potion
    /// @param tokenId ID of the bottle being filled up
    /// @param potionId ID of the potion filling up the bottle
    event FillBottle(uint256 indexed tokenId, uint256 indexed potionId);

    /// @notice emitted when a bottle is emptied
    /// @param tokenId ID of the bottle being emptied
    event EmptyBottle(uint256 indexed tokenId);

    /// @notice emitted when the ERC2981 royalties are modified
    /// @param royaltyPerThousand royalty amount per thousand
    /// @param royaltyReceiver royalties receiver address
    event RoyaltyChange(uint16 royaltyPerThousand, address royaltyReceiver);

    /// @notice emitted when a new mint phase is created
    /// @param phaseIndex index of the mint phase
    /// @param price price of the mint phase
    /// @param startTimestamp timestamp for the start of the mint phase
    /// @param endTimestamp timestamp for the end of the mint phase
    /// @param maxMintPerWallet maximum number of tokens mintable per wallet
    /// @param phaseSupply maximum token supply for the mint phase
    event NewMintPhase(
        uint256 indexed phaseIndex,
        uint128 price,
        uint48 indexed startTimestamp,
        uint48 indexed endTimestamp,
        uint8 maxMintPerWallet,
        uint16 phaseSupply
    );

    /// @notice emitted when a mint phase is cancelled
    /// @param phaseIndex index of the mint phase
    event CancelMintPhase(uint256 indexed phaseIndex);

    /**
     * ----------- EXTERNAL -----------
     */

    /// @notice Stake a CloprBottles
    /// @dev Emits an event to enable tracking bottle staking status
    /// @param tokenId token ID of the bottle
    function stake(uint256 tokenId, address vault) external;

    /// @notice Unstake a CloprBottles
    /// @dev Emits an event to enable tracking bottle staking status
    /// @param tokenId token ID of the bottle
    function unstake(uint256 tokenId, address vault) external;

    /// @notice Allows the owner of a bottle to empty the content of his bottle
    /// @dev Emits an event to enable tracking bottle contents
    /// @param tokenId token ID of the bottle
    function emergencyEmptyBottle(uint256 tokenId) external;

    /// @notice mint CloprBottless
    /// @param quantity number of tokens being minted
    /// @param mintPhaseIndex index of the mint phase
    /// @param signature ECDSA signature prooving that caller is whitelisted
    function mintBottles(
        uint8 quantity,
        uint256 mintPhaseIndex,
        bytes calldata signature
    ) external payable;

    /**
     * ----------- CLOPR PROTOCOL -----------
     */

    /// @notice Allows permited contracts to fill a CloprBottles with a specified Clopr Potion
    /// @dev Emits an event to enable tracking bottles' content
    /// @param tokenId token ID of the bottle
    /// @param potionId potion ID being filled up
    /// @param potentialBottleOwner said owner of the CloprBottles being filled up
    function fillBottle(
        uint256 tokenId,
        uint16 potionId,
        bool isDelegatedFillLevel,
        address potentialBottleOwner
    ) external;

    /// @notice Allows permited contracts to empty the content a CloprBottles
    /// @dev Emits an event to enable tracking bottles' content
    /// @param tokenId token ID of the bottle
    /// @param potionId potion ID being emptied
    /// @param bottleOwner owner of the CloprBottles being filled up
    function emptyBottle(
        uint256 tokenId,
        uint16 potionId,
        address bottleOwner
    ) external;

    /**
     * ----------- ADMIN -----------
     */

    /// @notice Allows owner to extend the protocol by adding a new potion, a contract allowed to fill bottles with this potion and a contract allowed to empty bottles with this potion
    /// @dev The new potion's ID must be unique
    ///      Emits an event to enable tracking new extensions of the protocol
    /// @param potionId the new potion's ID
    /// @param potionFillContract the contract now allowed to fill bottles with the new potion
    /// @param potionEmptyContract the contract now allowed to empty bottles filled up with the new potion
    /// @param potionBaseUri base URI of the new potion
    function addNewPotion(
        uint256 potionId,
        address potionFillContract,
        address potionEmptyContract,
        string memory potionBaseUri
    ) external;

    /// @notice Allows the creation of mint phases
    /// @dev Emits an event to enable tracking mint phases
    /// @param phaseIndex index of the mint phase
    /// @param price price of the mint phase to create
    /// @param startTimestamp timestamp for the start of the mint phase
    /// @param endTimestamp timestamp for the end of the mint phase
    /// @param maxMintPerWallet maximum number of tokens mintable per wallet
    /// @param phaseSupply maximum token supply for the mint phase
    function createNewMintPhase(
        uint256 phaseIndex,
        uint128 price,
        uint48 startTimestamp,
        uint48 endTimestamp,
        uint8 maxMintPerWallet,
        uint16 phaseSupply
    ) external;

    /// @notice Allows the cancellation of a mint phase
    /// @param phaseIndex index of the mint phase to cancel
    function cancelMintPhase(uint256 phaseIndex) external;

    /// @notice Allows wallets with MARKETING_MINT_ROLE to mint tokens for marketing purposes up to MARKETING_SUPPLY
    /// @param quantity number of tokens being minted
    /// @param to wallet receiving the tokens
    function marketingMint(uint16 quantity, address to) external;

    /// @notice set a new ERC2981 royalty for CloprBottless
    /// @param newRoyaltyPerThousand royalty amount per thousand
    /// @param newRoyaltyReceiver address of the royalties receiver
    function setRoyalty(
        uint16 newRoyaltyPerThousand,
        address newRoyaltyReceiver
    ) external;

    /// @notice Allows owner to change the base URI for a certain potion
    /// @dev Don't forget the trailing slash in the base URI as it will be concatenated with other information.
    ///      Emits an event to enable tracking base URI changes
    /// @param potionId the ID of the potion associated with the new base URI
    /// @param newPotionBaseUri the new base URI of the potion
    function changePotionBaseUri(
        uint256 potionId,
        string memory newPotionBaseUri
    ) external;

    /// @dev Used to emit an ERC-4906 event if the metadata are modified off chain
    function offchainMetadataUpdate() external;

    /// @notice Allows owner to freeze the URI of a particular potion making it immutable
    /// @dev Emits an event to enable tracking URI freezes
    /// @param potionId The potion ID which will have its URI frozen
    function freezePotionUri(uint256 potionId) external;

    /// @notice Allows owner to start a new season, this will reset all staking durations
    /// @dev Emits an event to enable tracking seasons
    function startSeason() external;

    /// @notice allows owner to withdraw contract's ether to an arbitrary account
    /// @param receiver receiver of the funds
    function withdraw(address receiver) external;

    /**
     * ----------- ENUMERATIONS -----------
     */

    /// @notice get the number of tokens which were minted for marketing
    /// @return mintedMarketingSupply the number of tokens which were minted for marketing
    function getMintedMarketingSupply()
        external
        view
        returns (uint16 mintedMarketingSupply);

    /// @notice Get the timestamp at which the current season was started
    /// @return seasonStartTime_ the timestamp at which the current season was started
    function getCurrentSeasonStartTime()
        external
        view
        returns (uint48 seasonStartTime_);

    /// @notice Get the information of a mint phase
    /// @param mintPhaseIndex index of the mint phase
    /// @return mintPhase mint phase object
    function getMintPhaseInfos(
        uint256 mintPhaseIndex
    ) external view returns (MintPhase memory mintPhase);

    /// @notice Get the mint price of CloprBottless for a specific mint phase
    /// @param mintPhaseIndex index of the mint phase
    /// @return mintPrice the mintPhase's price of CloprBottless
    function getMintPrice(
        uint256 mintPhaseIndex
    ) external view returns (uint128 mintPrice);

    /// @notice Retrieve the information of a bottle
    /// @param tokenId token ID of the bottle
    /// @return potionId the potion ID filling up the bottle
    /// @return potionFill the amount of potion filling up the bottle from 0 (empty) to 100 (full)
    /// @return stakingTime the timestamp at which the bottle was staked
    /// @return stakingDuration the timestamp at which the bottle was staked
    /// @return numberDrinks the number of times the bottle was staked
    function getBottleInformation(
        uint256 tokenId
    )
        external
        view
        returns (
            uint16 potionId,
            uint8 potionFill,
            uint48 stakingTime,
            uint48 stakingDuration,
            uint24 numberDrinks,
            uint64 lastEmptyBlock
        );

    /// @notice Get the time at which a bottle was staked
    /// @param tokenId token ID of the bottle
    /// @return stakingTime the timestamp at which the bottle was staked
    function getStakingTime(
        uint256 tokenId
    ) external view returns (uint48 stakingTime);

    /// @notice Get the staking duration of a bottle
    /// @dev The staking duration can be affected by the current season's start time
    /// @param tokenId token ID of the bottle
    /// @return stakingDuration the duration the bottle was staked for
    function getStakingDuration(
        uint256 tokenId
    ) external view returns (uint48 stakingDuration);

    /// @notice Get the fill level of a bottle
    /// @param tokenId token ID of the bottle
    /// @return fillLevel the bottle's fill level from 0 (empty) to 100 (full)
    function getBottleFillLevel(
        uint256 tokenId
    ) external view returns (uint8 fillLevel);

    /// @notice get the block number at which the bottle was emptied
    /// @param tokenId token ID of the bottle
    /// @return lastEmptyBlock block number at which the bottle was emptied
    function getBottleLastEmptyBlock(
        uint256 tokenId
    ) external view returns (uint64 lastEmptyBlock);
}
