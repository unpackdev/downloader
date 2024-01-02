// SPDX-License-Identifier: MIT
// Clopr Contracts

pragma solidity 0.8.21;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./ERC2981.sol";
import "./ERC165.sol"; // import for natSpecs
import "./ERC721A.sol";
import "./ECDSA.sol";
import "./IERC2981.sol";
import "./IERC721.sol";
import "./IERC165.sol";
import "./IERC721Metadata.sol";
import "./IERC4906.sol";
import "./IERC721A.sol";
import "./IAccessControl.sol";
import "./ICloprBottles.sol";
import "./IPotionDelegatedFillContract.sol";
import "./IDelegateRegistry.sol";

/**
 * @title CloprBottles
 * @author Pybast.eth - Nefture
 * @custom:lead Antoine Bertin - Clopr
 * @notice This contract serves as the core of the Clopr protocol, managing the CloprBottles NFT collection, including potion-based assets, staking mechanisms, and dynamic metadata.
 */
contract CloprBottles is
    ERC721A,
    AccessControl,
    Ownable,
    ICloprBottles,
    ERC2981,
    IERC4906
{
    uint16 private constant STORY_POTION_ID = 42;

    bytes32 private constant MARKETING_MINT_ROLE =
        keccak256("MARKETING_MINT_ROLE");
    bytes32 private constant GRANT_WHITELIST_ROLE =
        keccak256("GRANT_WHITELIST_ROLE");
    bytes32 private constant MINT_PHASE_ROLE = keccak256("MINT_PHASE_ROLE");

    /// @dev delegate cash V2 contract
    IDelegateRegistry private constant DC =
        IDelegateRegistry(0x00000000000000447e69651d841bD8D104Bed493);

    uint16 public constant CLOPR_BOTTLES_MAX_SUPPLY = 10_000;
    uint16 public constant RESERVED_MARKETING_SUPPLY = 2_000;

    /// @dev minimum number of blocks before a delegate can transfer a token since its last time being emptied
    uint16 public constant NUMBER_OF_BLOCKS_AFTER_EMPTY = 20;

    /// @dev number of tokens reserved for marketing
    uint16 private remainingMarketingSupply;

    /// @dev timestamp of the current season's start
    uint48 private seasonStartTime;

    /// @dev ERC2981 royalty share per thousand unit of price
    uint16 private royaltyPerThousand;
    /// @dev ERC2981 royalty receiver address
    address private royaltyReceiver;

    /// @dev stores each potion's URI
    mapping(uint256 potionId => PotionBaseUri potionBaseUri) private potionUris;

    /// @dev stores bottles onchain metadata
    mapping(uint256 tokenId => BottleInformation bottleInformation)
        private bottles;

    /// @dev stores bottle fill and empty access for each potion type
    mapping(uint256 potionId => address grantee) private fillAccess;
    mapping(uint256 potionId => address grantee) private emptyAccess;

    /// @dev stores each mint phase information
    mapping(uint256 phaseId => MintPhase mintPhaseInformation)
        private mintPhases;

    /// @dev stores the number of tokens minted during a phase
    mapping(uint256 phaseId => mapping(address minter => uint256 numbMinted))
        private numbMintedForPhase;

    constructor() ERC721A("CloprBottles", "CB") {
        royaltyPerThousand = 25;
        royaltyReceiver = 0x89fe24F08ee13f284a9E3c1fE10964250Ad682a1;

        remainingMarketingSupply = RESERVED_MARKETING_SUPPLY;

        _grantRole(
            DEFAULT_ADMIN_ROLE,
            0x799B7627f972dcf97b00bBBC702b2AD1b7546519
        );
        _transferOwnership(0x799B7627f972dcf97b00bBBC702b2AD1b7546519);
    }

    /**
     * ----------- EXTERNAL -----------
     */

    /// @inheritdoc ICloprBottles
    function stake(uint256 tokenId, address vault) external {
        address requester = msg.sender;

        if (vault != address(0)) {
            bool isDelegateValid = DC.checkDelegateForERC721(
                msg.sender,
                vault,
                address(this),
                tokenId,
                ""
            );
            if (!isDelegateValid) revert InvalidDelegateVaultPairing();
            requester = vault;
        }

        if (ownerOf(tokenId) != requester) revert NotBottleOwner();

        // slither-disable-next-line timestamp
        bottles[tokenId].stakingTime = uint48(block.timestamp);

        emit BottleStaked(tokenId, true);
    }

    /// @inheritdoc ICloprBottles
    function unstake(uint256 tokenId, address vault) external {
        address requester = msg.sender;

        if (vault != address(0)) {
            bool isDelegateValid = DC.checkDelegateForERC721(
                msg.sender,
                vault,
                address(this),
                tokenId,
                ""
            );
            if (!isDelegateValid) revert InvalidDelegateVaultPairing();
            requester = vault;
        }

        if (ownerOf(tokenId) != requester) revert NotBottleOwner();

        delete bottles[tokenId].stakingTime;

        emit BottleStaked(tokenId, false);
    }

    /// @inheritdoc ICloprBottles
    function emergencyEmptyBottle(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) revert NotBottleOwner();

        delete bottles[tokenId].filled;
        delete bottles[tokenId].delegatedFillLevel;

        // Don't increment numberDrinks
        emit EmptyBottle(tokenId);
        emit MetadataUpdate(tokenId);
    }

    /// @inheritdoc ICloprBottles
    function mintBottles(
        uint8 quantity,
        uint256 mintPhaseIndex,
        bytes calldata signature
    ) external payable {
        uint256 currentSupply = totalSupply();

        MintPhase memory currentMintPhase = mintPhases[mintPhaseIndex];

        // check if mint has ended
        // slither-disable-next-line timestamp
        if (currentMintPhase.endTimestamp < block.timestamp)
            revert MintPhaseEndedOrDoesntExist();

        // check if mint has started
        // slither-disable-next-line timestamp
        if (currentMintPhase.startTimestamp > block.timestamp)
            revert MintPhaseNotStarted();

        // minter can only mint a limited number of tokens
        bool isMaxMintReached;
        unchecked {
            isMaxMintReached =
                numbMintedForPhase[mintPhaseIndex][msg.sender] +
                    uint256(quantity) >
                currentMintPhase.maxMintPerWallet;
        }
        if (isMaxMintReached) revert MaxMintReached();

        // check if right price
        bool isBadMintPrice;
        unchecked {
            isBadMintPrice = msg.value != currentMintPhase.price * quantity;
        }
        if (isBadMintPrice) revert BadMintPrice();

        // check if mint is sold out
        bool isMintSoldOut;
        unchecked {
            isMintSoldOut =
                currentSupply + quantity >
                CLOPR_BOTTLES_MAX_SUPPLY - remainingMarketingSupply;
        }
        if (isMintSoldOut) revert MintSoldOut();

        // check if minter is whitelisted
        if (!_isWhitelisted(mintPhaseIndex, signature)) revert NotAuthorised();

        if (quantity > currentMintPhase.remainingSupply) revert PhaseSoldOut();

        unchecked {
            mintPhases[mintPhaseIndex].remainingSupply -= quantity;
        }

        unchecked {
            numbMintedForPhase[mintPhaseIndex][msg.sender] += quantity;
        }

        // fill up minted potions
        for (uint256 index = 1; index <= quantity; index++) {
            bottles[currentSupply + index] = BottleInformation({
                potionId: STORY_POTION_ID,
                delegatedFillLevel: false,
                filled: true,
                stakingTime: 0,
                numberDrinks: 0,
                lastEmptyBlock: 0
            });

            // No FillBottle event emission because this behaviour is predictable, all bottles
            // are minted filled up with SP
        }

        _mint(msg.sender, quantity);
    }

    /**
     * ----------- CLOPR PROTOCOL -----------
     */

    /// @inheritdoc ICloprBottles
    function fillBottle(
        uint256 tokenId,
        uint16 potionId,
        bool isDelegatedFillLevel,
        address potentialBottleOwner
    ) external {
        BottleInformation memory bottle = bottles[tokenId];

        if (fillAccess[potionId] != msg.sender) revert FillingUpNotAuthorised();

        if (_getBottleFillLevel(bottle, tokenId) > 0) revert BottleNotEmpty();
        if (ownerOf(tokenId) != potentialBottleOwner) revert NotBottleOwner();
        if (bottle.stakingTime == 0) revert BottleNotStaked();

        if (isDelegatedFillLevel) {
            bottles[tokenId] = BottleInformation({
                potionId: potionId,
                delegatedFillLevel: true,
                filled: false,
                stakingTime: bottle.stakingTime,
                numberDrinks: bottle.numberDrinks,
                lastEmptyBlock: 0
            });
        } else {
            bottles[tokenId] = BottleInformation({
                potionId: potionId,
                delegatedFillLevel: false,
                filled: true,
                stakingTime: bottle.stakingTime,
                numberDrinks: bottle.numberDrinks,
                lastEmptyBlock: 0
            });
        }

        emit FillBottle(tokenId, potionId);
        emit MetadataUpdate(tokenId);
    }

    /// @inheritdoc ICloprBottles
    function emptyBottle(
        uint256 tokenId,
        uint16 potionId,
        address potentialBottleOwner
    ) external {
        BottleInformation memory bottle = bottles[tokenId];

        if (emptyAccess[potionId] != msg.sender) revert EmptyingNotAuthorized();

        if (ownerOf(tokenId) != potentialBottleOwner) revert NotBottleOwner();
        if (bottle.stakingTime == 0) revert BottleNotStaked();

        if (bottle.potionId != potionId) revert InvalidPotion();
        if (_getBottleFillLevel(bottle, tokenId) < 100) revert BottleNotFull();

        unchecked {
            bottles[tokenId] = BottleInformation({
                potionId: potionId,
                delegatedFillLevel: false,
                filled: false,
                stakingTime: bottle.stakingTime,
                numberDrinks: bottle.numberDrinks + 1,
                lastEmptyBlock: uint64(block.number)
            });
        }

        emit EmptyBottle(tokenId);
        emit MetadataUpdate(tokenId);
    }

    /**
     * ----------- ADMIN -----------
     */

    /// @inheritdoc ICloprBottles
    function addNewPotion(
        uint256 potionId,
        address potionFillContract,
        address potionEmptyContract,
        string memory potionBaseUri
    ) external onlyOwner {
        if (potionUris[potionId].exists) revert PotionAlreadyExist();

        if (
            potionFillContract == address(0) ||
            potionEmptyContract == address(0)
        ) revert PotionContractCantBeNull();

        if (bytes(potionBaseUri).length == 0) revert PotionBaseUriCantBeNull();

        potionUris[potionId] = PotionBaseUri({
            baseUri: potionBaseUri,
            exists: true,
            isFrozen: false
        });

        fillAccess[potionId] = potionFillContract;
        emptyAccess[potionId] = potionEmptyContract;

        emit NewPotion(
            potionFillContract,
            potionEmptyContract,
            potionId,
            potionBaseUri
        );
    }

    /// @inheritdoc ICloprBottles
    function createNewMintPhase(
        uint256 phaseIndex,
        uint128 price,
        uint48 startTimestamp,
        uint48 endTimestamp,
        uint8 maxMintPerWallet,
        uint16 phaseSupply
    ) external onlyRole(MINT_PHASE_ROLE) {
        if (mintPhases[phaseIndex].endTimestamp != 0)
            revert MintPhaseAlreadyExist();

        if (startTimestamp == 0) revert InvalidStartTimestamp();

        // purposefully don't check that start < end as this is
        // already verified in the mint function

        mintPhases[phaseIndex].price = price;
        mintPhases[phaseIndex].startTimestamp = startTimestamp;
        mintPhases[phaseIndex].endTimestamp = endTimestamp;
        mintPhases[phaseIndex].maxMintPerWallet = maxMintPerWallet;
        mintPhases[phaseIndex].remainingSupply = phaseSupply;

        emit NewMintPhase(
            phaseIndex,
            price,
            startTimestamp,
            endTimestamp,
            maxMintPerWallet,
            phaseSupply
        );
    }

    /// @inheritdoc ICloprBottles
    function cancelMintPhase(uint256 phaseIndex) external onlyOwner {
        delete mintPhases[phaseIndex];

        emit CancelMintPhase(phaseIndex);
    }

    /// @inheritdoc ICloprBottles
    function marketingMint(
        uint16 quantity,
        address to
    ) external onlyRole(MARKETING_MINT_ROLE) {
        uint256 currentSupply = totalSupply();

        if (quantity > remainingMarketingSupply)
            revert MarketingSupplyReached();

        unchecked {
            remainingMarketingSupply -= quantity;
        }

        // fill up minted potions
        for (uint256 index = 1; index <= quantity; index++) {
            bottles[currentSupply + index] = BottleInformation({
                potionId: STORY_POTION_ID,
                delegatedFillLevel: false,
                filled: true,
                stakingTime: 0,
                numberDrinks: 0,
                lastEmptyBlock: 0
            });

            // No FillBottle event emission because this behaviour is predictable, all bottles
            // are minted filled up with SP
        }

        _mint(to, quantity);
    }

    /// @inheritdoc ICloprBottles
    function setRoyalty(
        uint16 newRoyaltyPerThousand,
        address newRoyaltyReceiver
    ) external onlyOwner {
        if (newRoyaltyReceiver == address(0))
            revert RoyaltyReceiverCantBeZero();
        if (newRoyaltyPerThousand > 1000) revert RoyaltyPerThousandTooHigh();

        royaltyPerThousand = newRoyaltyPerThousand;
        royaltyReceiver = newRoyaltyReceiver;

        emit RoyaltyChange(newRoyaltyPerThousand, newRoyaltyReceiver);
    }

    /// @inheritdoc ICloprBottles
    function changePotionBaseUri(
        uint256 potionId,
        string memory newPotionBaseUri
    ) external onlyOwner {
        if (bytes(newPotionBaseUri).length == 0)
            revert PotionBaseUriCantBeNull();

        PotionBaseUri memory uri = potionUris[potionId];

        if (!uri.exists) revert PotionDoesntExist();
        if (uri.isFrozen) revert PotionUriIsFrozen();

        potionUris[potionId].baseUri = newPotionBaseUri;

        emit NewPotionBaseUri(potionId, newPotionBaseUri);
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    /// @inheritdoc ICloprBottles
    function offchainMetadataUpdate() external onlyOwner {
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    /// @inheritdoc ICloprBottles
    function freezePotionUri(uint256 potionId) external onlyOwner {
        potionUris[potionId].isFrozen = true;

        emit FreezePotionUri(potionId);
    }

    /// @inheritdoc ICloprBottles
    function startSeason() external onlyOwner {
        // slither-disable-next-line timestamp
        seasonStartTime = uint48(block.timestamp);

        emit StartNewSeason(seasonStartTime);
    }

    /// @inheritdoc ICloprBottles
    function withdraw(address receiver) external onlyOwner {
        // slither-disable-next-line incorrect-equality
        if (address(this).balance == 0) revert NothingToWithdraw();
        if (receiver == address(0)) revert CantWithdrawToZeroAddress();

        // slither-disable-next-line low-level-calls
        (bool sent, ) = receiver.call{value: address(this).balance}("");
        if (!sent) revert FailedToWithdraw();
    }

    /**
     * ----------- ENUMERATIONS -----------
     */

    /// @inheritdoc ICloprBottles
    function getMintedMarketingSupply()
        external
        view
        returns (uint16 mintedMarketingSupply)
    {
        unchecked {
            mintedMarketingSupply =
                RESERVED_MARKETING_SUPPLY -
                remainingMarketingSupply;
        }
    }

    /// @inheritdoc ICloprBottles
    function getCurrentSeasonStartTime()
        external
        view
        returns (uint48 seasonStartTime_)
    {
        seasonStartTime_ = seasonStartTime;
    }

    /// @inheritdoc ICloprBottles
    function getMintPhaseInfos(
        uint256 mintPhaseIndex
    ) external view returns (MintPhase memory mintPhase) {
        mintPhase = mintPhases[mintPhaseIndex];
        if (mintPhase.endTimestamp == 0) revert MintPhaseDoesntExist();
    }

    /// @inheritdoc ICloprBottles
    function getMintPrice(
        uint256 mintPhaseIndex
    ) external view returns (uint128 mintPrice) {
        MintPhase memory mintPhase = mintPhases[mintPhaseIndex];

        if (mintPhase.endTimestamp == 0) revert MintPhaseDoesntExist();

        mintPrice = mintPhase.price;
    }

    /// @inheritdoc ICloprBottles
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
        )
    {
        BottleInformation memory bottle = bottles[tokenId];

        potionId = bottle.potionId;
        potionFill = _getBottleFillLevel(bottle, tokenId);
        stakingTime = bottle.stakingTime;
        stakingDuration = _getStakingDuration(bottle.stakingTime);
        numberDrinks = bottle.numberDrinks;
        lastEmptyBlock = bottle.lastEmptyBlock;
    }

    /// @inheritdoc ICloprBottles
    function getStakingTime(
        uint256 tokenId
    ) external view returns (uint48 stakingTime) {
        stakingTime = bottles[tokenId].stakingTime;
    }

    /// @inheritdoc ICloprBottles
    function getStakingDuration(
        uint256 tokenId
    ) external view returns (uint48 stakingDuration) {
        stakingDuration = _getStakingDuration(bottles[tokenId].stakingTime);
    }

    /// @inheritdoc ICloprBottles
    function getBottleFillLevel(
        uint256 tokenId
    ) external view returns (uint8 fillLevel) {
        BottleInformation memory bottle = bottles[tokenId];

        fillLevel = _getBottleFillLevel(bottle, tokenId);
    }

    /// @inheritdoc ICloprBottles
    function getBottleLastEmptyBlock(
        uint256 tokenId
    ) external view returns (uint64 lastEmptyBlock) {
        lastEmptyBlock = bottles[tokenId].lastEmptyBlock;
    }

    /// @notice Get the price of royalties and the receiver's address for a given sale price
    /// @param salePrice the price of the sale in any unit of exchange
    /// @return receiver the return variables of a contract’s function state variable
    /// @return royaltyAmount the return variables of a contract’s function state variable
    /// @inheritdoc	ERC2981
    function royaltyInfo(
        uint256,
        uint256 salePrice
    ) public view override returns (address receiver, uint256 royaltyAmount) {
        receiver = royaltyReceiver;
        royaltyAmount = (royaltyPerThousand * salePrice) / 1000;
    }

    /// @notice Retrieves a token's URI
    /// @param tokenId token ID of the bottle
    /// @return uri the URI of the token
    /// @inheritdoc	ERC721A
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A, IERC721A) returns (string memory uri) {
        require(_exists(tokenId), "ERC721: invalid token ID");

        BottleInformation memory bottle = bottles[tokenId];
        PotionBaseUri memory potionUri = potionUris[bottle.potionId];

        uint8 fill = _getBottleFillLevel(bottle, tokenId);

        uri = string(
            abi.encodePacked(
                potionUri.baseUri,
                _toString(tokenId),
                "/",
                _toString(fill)
            )
        );
    }

    /**
     * ----------- ERC165 -----------
     */

    /// @notice Know if a given interface ID is supported by this contract
    /// @dev This function overrides ERC721A, AccessControl, IERC721A, ERC2981
    /// @param interfaceId ID of the interface
    /// @return supports_ is the interface supported
    /// @inheritdoc	ERC165
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        pure
        override(ERC721A, AccessControl, IERC721A, ERC2981)
        returns (bool supports_)
    {
        supports_ =
            interfaceId == type(IERC721).interfaceId || // ERC165 interface ID for ERC721
            interfaceId == type(IERC721Metadata).interfaceId || // ERC165 interface ID for ERC721Metadata
            interfaceId == type(IERC2981).interfaceId || // ERC165 interface ID for ERC2981
            interfaceId == type(IERC165).interfaceId || // ERC165 interface id for ERC165
            interfaceId == type(IAccessControl).interfaceId || // ERC165 interface id for AccessControl
            interfaceId == type(IERC4906).interfaceId; // ERC165 interface id for ERC4906
    }

    /**
     * ----------- INTERNAL -----------
     */

    /// @dev The staking duration can be affected by the current season's start time
    /// @param stakingTime stakingTime of the bottle
    /// @return stakingDuration the duration the bottle was staked for
    function _getStakingDuration(
        uint48 stakingTime
    ) internal view returns (uint48 stakingDuration) {
        if (stakingTime == 0) {
            stakingDuration = 0;
        }
        // slither-disable-next-line timestamp
        else if (stakingTime > seasonStartTime) {
            unchecked {
                // slither-disable-next-line timestamp
                stakingDuration = uint48(block.timestamp) - stakingTime;
            }
        }
        // slither-disable-next-line timestamp
        else {
            unchecked {
                // slither-disable-next-line timestamp
                stakingDuration = uint48(block.timestamp) - seasonStartTime;
            }
        }
    }

    /// @dev retrieves the bottle's fill level
    /// @param bottle bottle for which to retrieve the fill level
    /// @param tokenId tokenId of the bottle
    function _getBottleFillLevel(
        BottleInformation memory bottle,
        uint256 tokenId
    ) internal view returns (uint8 fillLevel) {
        if (bottle.delegatedFillLevel) {
            uint8 fill = IPotionDelegatedFillContract(
                fillAccess[bottle.potionId]
            ).getFillLevel(tokenId);

            fillLevel = fill;
        } else {
            fillLevel = bottles[tokenId].filled ? 100 : 0;
        }
    }

    /// @dev returns true is the signature grants a whitelist access
    /// @param mintPhaseIndex index of the mint phase
    /// @param signature signature to grant access to the mint phase
    function _isWhitelisted(
        uint256 mintPhaseIndex,
        bytes calldata signature
    ) internal view returns (bool) {
        bytes32 hash_ = ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(msg.sender, mintPhaseIndex))
        );

        return hasRole(GRANT_WHITELIST_ROLE, ECDSA.recover(hash_, signature));
    }

    /// @dev ID of the first CloprBottles token (spoiler: it's 1)
    /// @return startId the ID of the first CloprBottles token
    /// @inheritdoc	ERC721A
    function _startTokenId() internal pure override returns (uint256 startId) {
        startId = 1;
    }

    /// @notice Prevent protocols from transfering bottles if they are staked
    /// @param from owner of the token
    /// @param startTokenId first ID of the transfered token
    /// @param quantity number of consecutive tokens being transfered
    /// @inheritdoc	ERC721A
    function _beforeTokenTransfers(
        address from,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        // quantity is >1 when minting tokens, in this case we don't need to check
        // if the bottle is staked or if it was recently emptied
        if (msg.sender == from || quantity != 1 || from == address(0)) return;

        // check if a protocol is trying to transfer the token
        if (bottles[startTokenId].stakingTime > 0)
            revert CantTransferStakedBottle();

        // bottles' value vary depending on their potion content. If a bottle is emptied, it should have
        // less value compared to if it's full. Observing this, there is a risk for someone to acquire, what
        // he thinks as a filled bottle, and receive an empty one as the owner could technically empty the bottle
        // right before the purchase transaction is added on-chain.
        // To mitigate this risk, we implement a cool down of NUMBER_OF_BLOCKS_AFTER_EMPTY blocks where tokens
        // can't be traded.
        if (
            block.number - bottles[startTokenId].lastEmptyBlock <
            NUMBER_OF_BLOCKS_AFTER_EMPTY
        ) revert CantTransferRecentlyEmptiedBottle();
    }
}
