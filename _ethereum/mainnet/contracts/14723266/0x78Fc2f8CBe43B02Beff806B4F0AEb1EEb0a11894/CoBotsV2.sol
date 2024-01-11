// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC721A.sol";
import "./ICoBotsRendererV2.sol";
import "./Schedule.sol";

error BatchLimitExceeded();
error WrongPrice(uint256 paidPrice, uint256 expectedPrice);
error TotalSupplyExceeded();
error AllocationExceeded();
error ToggleMettaCallerNotOwner();
error ChainlinkSubscriptionNotFound();
error TransferFailed();
error MysteryChallengeSenderDoesNotOwnENS();
error MysteryChallengeValueDoesNotMatch();
error FulfillmentAlreadyFulfilled();
error FulfillRequestForNonExistentContest();
error FulfillRequestWithTokenNotOwnedByWinner();
error FulfillRequestWithTokenOutOfBounds();
error RedeemTokenNotOwner();
error RedeemTokenAlreadyRedeemed();
error NoGiveawayToTrigger();
error InsufficientFunds();
error WithdrawalFailed();
error FailSafeWithdrawalNotEnabled();
error FulfillRequestRedrawn();
error NonexistentRenderer();

contract CoBotsV2 is
    ERC721A,
    VRFConsumerBaseV2,
    Ownable,
    ReentrancyGuard,
    Schedule
{
    // Events
    event RendererContractUpdated(address indexed renderer);
    event MettaToggled(uint256 indexed tokenId, bool isMetta);
    event CheckpointDrawn(uint256 indexed requestId, Prize prize);
    event CheckpointFulfilled(
        uint256 indexed requestId,
        Prize prize,
        Winner winner
    );
    event GiveawayFinished();
    event Withdrawal(uint256 amount);
    event DrawBeforeWithdrawal();

    // Data structures
    /** @dev The prize struct contains the data for one single giveaway prize
     *  @param checkpoint the number of minted bots required to unlock the give
     *  @param amount the amount of the prize to be won
     *  @param isContest flag to indicate if the prize is a contest (meme, twitter, etc) and to be drawn randomly
     */
    struct Prize {
        uint16 checkpoint;
        uint72 amount;
        bool isContest;
    }

    /** @dev The mystery challenge is a special giveaway that will not be drawn nor won after founders selection.
     *  It will require to take control of a given ENS name and to send a message to the contract with the address
     *  owning it.
     *  @param ensId the tokenId of the given ENS
     *  @param value the answer to the challenge
     *  @param prizeIndex the index of this prize in the global Prize[] array
     */
    struct MysteryChallenge {
        uint256 ensId;
        uint256 value;
        uint8 prizeIndex;
    }

    /** @dev Global parameters for the project. Non-standards uintN types to ensure struct fits in one slot (256 bits).
     *  @param cobotsV1Discount the discount given when redeeming a CoBot V1. This is a percentage of public price
     *  @param mintOutFoundersWithdrawalDelay the delay between mint out and possible failsafe withdrawal from the founders
     *  @param grandPrizeDelay the delay between mint out and the grand prize draw
     *  @param maxCobots the total supply of CoBots
     *  @param contestDuration after this time, all contest will be turned into random draws
     *  @param mintPublicPrice the public price of one single CoBot.
     */
    struct Parameters {
        uint16 mintOutFoundersWithdrawalDelay;
        uint16 grandPrizeDelay;
        uint16 maxCobots;
        uint24 contestDuration;
        uint72 mintPublicPrice;
        uint72 cobotsV1Discount;
    }

    // Constants
    uint8 public constant MINT_FOUNDERS = 3;
    uint8 public constant MINT_BATCH_LIMIT = 32;
    Parameters public PARAMETERS;
    Prize[] public PRIZES;
    MysteryChallenge private MYSTERY_CHALLENGE;
    IERC721 public immutable ENS;
    IERC721Enumerable public immutable COBOTS_V1;
    address public immutable COBOTS_V1_ADDRESS;

    ////////////////////////////////////////////////////////////////////////
    ////////////////////////// Token ///////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    address public renderingContractAddress;
    ICoBotsRendererV2 public renderer;
    uint8[] public coBotsSeeds;
    mapping(uint256 => bool) public coBotsV1Redeemed;
    uint256 private _redeemedCount;

    function setRenderingContractAddress(address _renderingContractAddress)
        public
        onlyOwner
    {
        renderingContractAddress = _renderingContractAddress;
        renderer = ICoBotsRendererV2(renderingContractAddress);
        emit RendererContractUpdated(renderingContractAddress);
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address _rendererAddress,
        address vrfCoordinator,
        address link,
        bytes32 keyHash,
        Parameters memory _parameters,
        Prize[] memory _prizes,
        address ens,
        address cobotsV1,
        MysteryChallenge memory _mysteryChallenge
    ) ERC721A(name_, symbol_) VRFConsumerBaseV2(vrfCoordinator) {
        setRenderingContractAddress(_rendererAddress);
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        gasKeyHash = keyHash;
        PARAMETERS = _parameters;
        uint256 _prizesLength = _prizes.length;
        for (uint256 i = 0; i < _prizesLength; ) {
            PRIZES.push(_prizes[i]);
            unchecked {
                ++i;
            }
        }
        ENS = IERC721(ens);
        COBOTS_V1_ADDRESS = cobotsV1;
        COBOTS_V1 = IERC721Enumerable(cobotsV1);
        MYSTERY_CHALLENGE = _mysteryChallenge;
    }

    function _mintCoBots(address to, uint256 quantity) internal {
        if (quantity > MINT_BATCH_LIMIT) revert BatchLimitExceeded();
        bytes32 seeds = keccak256(
            abi.encodePacked(
                quantity,
                msg.sender,
                msg.value,
                block.timestamp,
                block.difficulty
            )
        );
        for (uint256 i = 0; i < quantity; ) {
            coBotsSeeds.push(uint8(seeds[i]) << 1); // insure last digit is 0, used for Metta status
            unchecked {
                ++i;
            }
        }

        ERC721A._safeMint(to, quantity);

        if (_currentIndex == PARAMETERS.maxCobots) {
            mintedOutTimestamp = block.timestamp;
        }
    }

    modifier supplyAvailable(uint256 quantity) {
        if (_currentIndex + quantity > PARAMETERS.maxCobots)
            revert TotalSupplyExceeded();
        _;
    }

    /**
     * Mints a batch of Co-Bots to the sender.
     *
     * @dev The tokenIdsV1 parameter can be empty. The call will revert only if the sender pretends to own some
     *      Co-Bots V1 that they actually don't. However it accepts already redeemed token and just ignore them silently.
     *      This is to make it easier for people using etherscan to copy a bunch of token Ids without having to
     *      manually check if they are redeemed or not. However, it is optimal in terms of gas fees to only give
     *      tokenIds if they can actually be redeemed.
     * @param quantity The number of COBOTS to mint.
     * @param tokenIdsV1 A list of V1 Co-Bots token Ids owned by the sender, used to determine the discount.
     */
    function mintPublicSale(uint256 quantity, uint256[] memory tokenIdsV1)
        external
        payable
        whenPublicSaleOpen
        supplyAvailable(quantity)
        nonReentrant
    {
        uint256 price = PARAMETERS.mintPublicPrice * quantity;

        uint256 redeemed = 0;
        uint256 tokenIdsV1Length = tokenIdsV1.length;
        for (uint256 i = 0; i < tokenIdsV1Length; ) {
            if (COBOTS_V1.ownerOf(tokenIdsV1[i]) != _msgSender())
                revert RedeemTokenNotOwner();
            if (!coBotsV1Redeemed[tokenIdsV1[i]] && redeemed < quantity) {
                coBotsV1Redeemed[tokenIdsV1[i]] = true;
                redeemed++;
                price -=
                    PARAMETERS.mintPublicPrice /
                    PARAMETERS.cobotsV1Discount;
            }
            unchecked {
                ++i;
            }
        }
        _redeemedCount += redeemed;
        if (msg.value != price) revert WrongPrice(price, msg.value);

        _mintCoBots(_msgSender(), quantity);
    }

    function mintFounders(address to, uint256 quantity)
        external
        onlyOwner
        supplyAvailable(quantity)
    {
        if (quantity + _currentIndex > MINT_FOUNDERS)
            revert AllocationExceeded();

        _mintCoBots(to, quantity);
    }

    /** @notice Return true if the Co-Bot displays metta screen
     *   @param tokenId The Co-Bot token ID
     */
    function isMettaEnabled(uint256 tokenId) external view returns (bool) {
        return coBotsSeeds[tokenId] & 1 == 1;
    }

    function _toggleMetta(uint256 tokenId) internal {
        if (ERC721A.ownerOf(tokenId) != _msgSender())
            revert ToggleMettaCallerNotOwner();

        coBotsSeeds[tokenId] = coBotsSeeds[tokenId] ^ 1;
    }

    function toggleMetta(uint256[] calldata tokenIds) public nonReentrant {
        uint256 tokenIdsLength = tokenIds.length;
        for (uint256 i = 0; i < tokenIdsLength; ) {
            _toggleMetta(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

        if (renderingContractAddress == address(0)) {
            return "";
        }

        return renderer.tokenURI(_tokenId, coBotsSeeds[_tokenId]);
    }

    function tokenData(uint256 _tokenId)
        public
        view
        returns (TokenData memory)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

        if (renderingContractAddress == address(0)) {
            revert NonexistentRenderer();
        }

        return renderer.tokenData(_tokenId, coBotsSeeds[_tokenId]);
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    receive() external payable {}

    /** @notice At any point in time, founders can withdraw only up to the required balance to insure that the giveaways
     *          will be paid. We take a conservative approach considering that all the remaining discounted bots will be minted
     *          as soon as possible.
     */
    function withdraw() public onlyOwner {
        // Draw eventual remaining giveaways
        if (_shouldDraw()) {
            emit DrawBeforeWithdrawal();
            draw();
        }

        // Start with the current contract's balance
        uint256 balance = address(this).balance;

        // Correct amount with giveaways that are pending fulfillments, typically previously drawn random fulfillments
        uint256 requestIdsLength = requestIds.length;
        for (uint256 i = 0; i < requestIdsLength; ) {
            if (!fulfillments[requestIds[i]].fulfilled) {
                balance -= fulfillments[requestIds[i]].prize.amount;
            }
            unchecked {
                ++i;
            }
        }

        // Use the corrected balance as a base possible withdrawn value
        uint256 value = balance;
        if (value == 0) revert InsufficientFunds();

        // Compute number of remaining discount sales
        uint256 remainingVoucher = COBOTS_V1.totalSupply() - _redeemedCount;
        // Initialize the number of already minted bots for checkpoints
        uint256 previousCheckpoint = _currentIndex;

        // Loop over locked checkpoint to estimate funds and withdrawal capacities
        uint256 prizesLength = PRIZES.length;
        for (uint256 i = requestIds.length; i < prizesLength; ) {
            // to unlock the next checkpoint, remainingBots bots need to be minted
            uint256 remainingBots = PRIZES[i].checkpoint - previousCheckpoint;

            // They will top up the contract's balance, depending on the number of voucher
            if (remainingVoucher > remainingBots) {
                balance +=
                    remainingBots *
                    (PARAMETERS.mintPublicPrice / PARAMETERS.cobotsV1Discount);
                remainingVoucher -= remainingBots;
            } else {
                balance +=
                    remainingVoucher *
                    (PARAMETERS.mintPublicPrice / PARAMETERS.cobotsV1Discount) +
                    (remainingBots - remainingVoucher) *
                    PARAMETERS.mintPublicPrice;
                remainingVoucher = 0;
            }

            // Then the current prize will be paid
            balance -= PRIZES[i].amount;

            // If at some point in the future it's not possible to pay, then the withdraw tx is reverted
            if (balance < 1) {
                revert InsufficientFunds();
            }

            // The possible withdrawal amount is the minimum between the current balance and the contract's balance
            // after each giveaway.
            if (balance < value) {
                value = balance;
            }
            previousCheckpoint = PRIZES[i].checkpoint;

            unchecked {
                ++i;
            }
        }

        (bool success, ) = _msgSender().call{value: value}("");
        if (!success) revert WithdrawalFailed();
        emit Withdrawal(value);
    }

    /** @notice A very basic function to act as a failsafe if the contract has a bug somewhere in the fulfill functions.
     */
    function failsafeWithdraw() public onlyOwner whenMintedOut {
        if (
            block.timestamp <
            (mintedOutTimestamp + PARAMETERS.mintOutFoundersWithdrawalDelay)
        ) {
            revert FailSafeWithdrawalNotEnabled();
        }

        uint256 value = address(this).balance;
        (bool success, ) = _msgSender().call{value: value}("");
        if (!success) revert WithdrawalFailed();
        emit Withdrawal(value);
    }

    ////////////////////////////////////////////////////////////////////////
    ////////////////////////// Raffle //////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    VRFCoordinatorV2Interface public immutable COORDINATOR;
    LinkTokenInterface public immutable LINKTOKEN;
    bytes32 public immutable gasKeyHash;
    uint64 public chainlinkSubscriptionId;

    function createSubscriptionAndFund(uint96 amount) external nonReentrant {
        if (chainlinkSubscriptionId == 0) {
            chainlinkSubscriptionId = COORDINATOR.createSubscription();
            COORDINATOR.addConsumer(chainlinkSubscriptionId, address(this));
        }
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            amount,
            abi.encode(chainlinkSubscriptionId)
        );
    }

    function cancelSubscription() external onlyOwner {
        COORDINATOR.cancelSubscription(chainlinkSubscriptionId, _msgSender());
        chainlinkSubscriptionId = 0;
    }

    struct Winner {
        address winner;
        uint16 tokenId;
    }

    struct Fulfillment {
        Prize prize;
        bool fulfilled;
        Winner winner;
    }

    mapping(uint256 => Fulfillment) public fulfillments;
    uint256[] public requestIds;
    uint256 public drawnAmount;

    /** @notice Use this to retrieve the ordered list of winners with their corresponding prizes and token Id.
     *          Pending fulfillments are included (no winner drawn yet, probably waiting for Chainlink to fulfill).
     */
    function getOrderedFulfillments()
        external
        view
        returns (Fulfillment[] memory)
    {
        Fulfillment[] memory result = new Fulfillment[](requestIds.length);
        for (uint256 i = 0; i < requestIds.length; i++) {
            result[i] = fulfillments[requestIds[i]];
        }
        return result;
    }

    function _shouldDraw() internal view returns (bool) {
        if (requestIds.length == PRIZES.length) {
            return false;
        }
        if (
            (requestIds.length == PRIZES.length - 1) &&
            (block.timestamp < mintedOutTimestamp + PARAMETERS.grandPrizeDelay)
        ) {
            return false;
        }
        if (PRIZES[requestIds.length].checkpoint > _currentIndex) return false;
        return true;
    }

    /** @notice This function is a failsafe in case a Chainlink VRF request does not resolve
     *          (behaviour experimented on rinkeby).
     *          The new draws will override the previous ones.
     */
    function redrawPendingFulfillments() public nonReentrant {
        uint256 requestIdsLength = requestIds.length;
        for (uint256 i = 0; i < requestIdsLength; ) {
            if (
                !fulfillments[requestIds[i]].fulfilled &&
                (!fulfillments[requestIds[i]].prize.isContest ||
                    block.timestamp >
                    publicSaleStartTimestamp + PARAMETERS.contestDuration)
            ) {
                uint256 requestId = COORDINATOR.requestRandomWords(
                    gasKeyHash,
                    chainlinkSubscriptionId,
                    5, // requestConfirmations
                    500_000, // callbackGasLimit
                    1 // numWords
                );
                fulfillments[requestId] = Fulfillment(
                    fulfillments[requestIds[i]].prize,
                    false,
                    Winner(address(0), 0)
                );
                delete fulfillments[requestIds[i]];
                requestIds[i] = requestId;
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice This function can be called at any time by anyone to trigger the unlocked giveaways. It will
     *         revert if there is nothing to unlock to prevent anon from making useless tx. (Usually wallet, e.g.
     *         metamask, warn this before signing).
     *         Giveaways that use Chainlink VRF oracle will be fulfilled automatically by Chainlink. Giveaways that
     *         require founders to unlock will be fulfilled by the founders.
     */
    function draw() public nonReentrant {
        uint256 drawCounts = requestIds.length;
        if (chainlinkSubscriptionId == 0) {
            revert ChainlinkSubscriptionNotFound();
        }
        if (!_shouldDraw()) revert NoGiveawayToTrigger();
        while (PRIZES[drawCounts].checkpoint < _currentIndex + 1) {
            uint256 requestId;
            if (
                (PRIZES[drawCounts].isContest &&
                    block.timestamp <
                    publicSaleStartTimestamp + PARAMETERS.contestDuration) ||
                (drawCounts == MYSTERY_CHALLENGE.prizeIndex)
            ) {
                requestId = _computeRequestId(drawCounts);
            } else {
                requestId = COORDINATOR.requestRandomWords(
                    gasKeyHash,
                    chainlinkSubscriptionId,
                    5, // requestConfirmations
                    500_000, // callbackGasLimit
                    1 // numWords
                );
            }
            drawnAmount += PRIZES[drawCounts].amount;
            fulfillments[requestId] = Fulfillment(
                PRIZES[drawCounts],
                false,
                Winner(address(0), 0)
            );
            emit CheckpointDrawn(requestId, PRIZES[drawCounts]);
            drawCounts++;
            requestIds.push(requestId);
            if (
                (drawCounts == PRIZES.length - 1) &&
                (block.timestamp <
                    mintedOutTimestamp + PARAMETERS.grandPrizeDelay)
            ) {
                return;
            }
            if (drawCounts == PRIZES.length) {
                emit GiveawayFinished();
                return;
            }
        }
    }

    function _computeRequestId(uint256 id) private pure returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(uint8(id % type(uint8).max))));
    }

    function _fulfill(
        uint256 requestId,
        address winnerAddress,
        uint256 selectedToken
    ) internal {
        if (fulfillments[requestId].fulfilled) {
            revert FulfillmentAlreadyFulfilled();
        }
        if (fulfillments[requestId].prize.amount == 0)
            revert FulfillRequestForNonExistentContest();
        if (ERC721A.ownerOf(selectedToken) != winnerAddress) {
            revert FulfillRequestWithTokenNotOwnedByWinner();
        }
        if (selectedToken > fulfillments[requestId].prize.checkpoint - 1) {
            revert FulfillRequestWithTokenOutOfBounds();
        }
        fulfillments[requestId].fulfilled = true;
        Winner memory winner = Winner(winnerAddress, uint16(selectedToken));
        fulfillments[requestId].winner = winner;
        (bool success, ) = winnerAddress.call{
            value: fulfillments[requestId].prize.amount
        }("");
        if (!success) revert TransferFailed();
        emit CheckpointFulfilled(
            requestId,
            fulfillments[requestId].prize,
            winner
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 checkpoint = fulfillments[requestId].prize.checkpoint;
        if (checkpoint == 0) revert FulfillRequestRedrawn();
        uint256 selectedToken = randomWords[0] % checkpoint;
        address winner = ERC721A.ownerOf(selectedToken);
        _fulfill(requestId, winner, selectedToken);
    }

    /**
     * @notice This function lets the owner fulfill a giveaway. If the giveaway has not been unlocked, this will
     *         revert.
     * @param giveawayIndex The index of the giveaway to fulfill, 0 based (the first giveaway is index 0).
     * @param winner The selected winner address.
     * @param selectedToken The selected token to be displayed on the website.
     */
    function fulfillContest(
        uint256 giveawayIndex,
        address winner,
        uint256 selectedToken
    ) external nonReentrant onlyOwner {
        uint256 requestId = _computeRequestId(giveawayIndex);
        _fulfill(requestId, winner, selectedToken);
    }

    /**
     * @notice Call this when, you know, you probably know what you're doing here.
     *         revert.
     * @param value Word biggest mysteries are solved with this single value.
     * @param tokenId The selected token to be displayed on the website. This should be owned by the winner.
     */
    function TheAnswer(uint256 value, uint256 tokenId) external nonReentrant {
        if (ENS.ownerOf(MYSTERY_CHALLENGE.ensId) != _msgSender()) {
            revert MysteryChallengeSenderDoesNotOwnENS();
        }
        if (value != MYSTERY_CHALLENGE.value) {
            revert MysteryChallengeValueDoesNotMatch();
        }
        _fulfill(
            _computeRequestId(MYSTERY_CHALLENGE.prizeIndex),
            _msgSender(),
            tokenId
        );
    }
}
