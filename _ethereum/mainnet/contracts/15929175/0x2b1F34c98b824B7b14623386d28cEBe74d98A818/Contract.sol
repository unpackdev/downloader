// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Pausable.sol";
import "./ERC1155Supply.sol";
import "./ERC1155URIStorage.sol";
import "./IERC1155Receiver.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

/// @title The Pixel Cup
/// @notice A decentralized sticker album
/// @author @guillegette @andrebrener
contract ThePixelCup is
    Ownable,
    IERC1155Receiver,
    ERC1155Burnable,
    ERC1155Pausable,
    ERC1155Supply,
    ERC1155URIStorage,
    ReentrancyGuard
{
    using Counters for Counters.Counter;

    // Constants
    uint256 public constant SALES_TO_POOL_PERCENTAGE = 50;
    uint256 public constant PACK_TOKEN_ID = 1;
    uint256 public constant TOTAL_TYPES = 3;

    // URI
    string private _revealedPath;
    bool private _revealed;
    string private _contractURI;

    // Prize Pool
    uint256 public prizePoolBalance;
    uint256 public ownerBalance;

    // Packs
    uint256 public totalPacks;
    uint256 public stickersPerPack;
    uint256 public packPrice;
    uint256 public mintedPacks;
    bool private _openPacksEnabled;

    // Stickers
    struct Sticker {
        uint256 id;
        uint256 amountRemaining;
    }
    Sticker[] private _stickers;
    uint256 public totalCountries;
    uint256 public stickersAvailable;

    // Random index assignment
    uint256 internal nonce;

    // Trades
    struct Trade {
        address owner;
        uint256 offerId;
        uint256 reqCountry;
        uint256 reqType;
        uint256 reqNumber;
        uint256 index;
    }
    Trade[] private _trades;

    // Winners
    uint256 public maxWinners;
    mapping(address => bool) public winners;
    Counters.Counter private _numWinners;

    // Events
    event PackPriceUpdated(uint256 _price);
    event PackOpened(address indexed _owner, uint256[] _stickers);
    event NewWinner(
        address indexed _owner,
        uint256 _prize,
        uint256[] _stickers
    );

    /// @dev Prevents smart contracts from calling functions
    modifier onlyEoa() {
        require(tx.origin == msg.sender, "Not EOA");
        _;
    }

    constructor(
        string memory baseURI,
        string memory setContractURI,
        uint256 setTotalPacks,
        uint256 packsToMint,
        uint256 setStickersPerPack,
        uint256 setMaxWinners,
        uint256 setTotalCountries,
        uint256 setInitialPackPrice
    ) ERC1155(baseURI) {
        // Set contract variables
        totalPacks = setTotalPacks;
        stickersPerPack = setStickersPerPack;
        maxWinners = setMaxWinners;
        totalCountries = setTotalCountries;
        packPrice = setInitialPackPrice;
        _contractURI = setContractURI;

        // Mint marketing packs
        _mint(msg.sender, PACK_TOKEN_ID, packsToMint, "");
        mintedPacks = packsToMint;
    }

    /// @notice Register available stickers
    /// @dev Each element on the array represents a token ID property,
    ///  so the countryIds[1] has the type typeIds[1], shirtNumber[1] and amounts[1]
    /// @param countryIds Array of country IDs
    /// @param typeIds Array of type IDs
    /// @param shirtNumbers Array of shirt numbers
    /// @param amounts Array of amounts
    function registerStickers(
        uint256[] memory countryIds,
        uint256[] memory typeIds,
        uint256[] memory shirtNumbers,
        uint256[] memory amounts
    ) external onlyOwner {
        require(
            countryIds.length == typeIds.length &&
                typeIds.length == shirtNumbers.length &&
                shirtNumbers.length == amounts.length,
            "All arrays should have same length"
        );
        for (uint256 i = 0; i < countryIds.length; i++) {
            uint256 tokenId = countryIds[i] *
                1000 +
                typeIds[i] *
                100 +
                shirtNumbers[i];
            _stickers.push(Sticker(tokenId, amounts[i]));
            stickersAvailable += amounts[i];
        }
    }

    /// @notice Updates the token URI once base path once the collection has been uploaded
    /// @param path The full ipfs path. It should end with / to later concatenate the token ID
    function setRevealedPath(string memory path) external onlyOwner {
        require(!_revealed, "Reveal path has been set");
        _revealedPath = path;
        _revealed = true;
    }

    /// @notice Updates the pack price
    /// @param value The new price of the pack price
    function setPackPrice(uint256 value) external onlyOwner {
        require(packPrice != value, "Cannot be the same value");
        packPrice = value;
        emit PackPriceUpdated(value);
    }

    /// @notice Enable or disable the ability to open packs and claim prizes
    /// @param enable Set true/false to enable/disable
    function enableOpenPacks(bool enable) external onlyOwner {
        _openPacksEnabled = enable;
    }

    /// @notice Exchange a pack token ID for a random set of stickersPerPack tokens
    /// @dev This funciones calls a random number generator. To prevent manipulation,
    ///  we only allow wallet addresses to call this method
    /// @param amount Number of packs to exchange for stickers
    /// @return totalOpenedPacks An array of all stickers token IDs minted to the wallet
    function openPacks(uint256 amount)
        external
        nonReentrant
        onlyEoa
        returns (uint256[] memory)
    {
        require(_openPacksEnabled, "This function is not yet enabled!");

        _burn(msg.sender, PACK_TOKEN_ID, amount);

        uint256[] memory totalOpenedPacks = new uint256[](
            amount * stickersPerPack
        );
        for (uint256 i = 0; i < amount; i++) {
            uint256[] memory packStickers = new uint256[](stickersPerPack);
            for (uint256 j = 0; j < stickersPerPack; j++) {
                // Get random sticker
                uint256 stickerCount = i * stickersPerPack + j;
                uint256 stickerIndex = randomStickerIndex(
                    stickersAvailable - stickerCount
                );
                // Increment the nonce for the random
                nonce++;
                // Reduce amount on sticker
                uint256 stickerId = _stickers[stickerIndex].id;
                _stickers[stickerIndex].amountRemaining--;
                // Mint an extra amount of the sticker
                _mint(msg.sender, stickerId, 1, "");
                // For the event
                packStickers[j] = stickerId;
                totalOpenedPacks[stickerCount] = stickerId;
            }
            emit PackOpened(msg.sender, packStickers);
        }
        stickersAvailable -= amount * stickersPerPack;
        return totalOpenedPacks;
    }

    /// @notice Mint pack tokens
    /// @dev We increase the prizePoolBalance and ownerBalance
    /// @param to Address to mint packs to
    /// @param amount Amount of packs to mint
    function mintPacks(address to, uint256 amount)
        external
        payable
        nonReentrant
    {
        require((mintedPacks + amount) <= totalPacks, "Not enough packs left");
        require(msg.value >= packPrice * amount, "Insufficient funds");

        mintedPacks += amount;

        if (winnersRemaining() > 0) {
            // Update balances
            ownerBalance +=
                (msg.value * (100 - SALES_TO_POOL_PERCENTAGE)) /
                100;
            prizePoolBalance += (msg.value * SALES_TO_POOL_PERCENTAGE) / 100;
        } else {
            // If there are no more possible winners and somehow we still have
            // packs left, the revenue goes to the team for future proyects
            ownerBalance += msg.value;
        }
        _mint(to, PACK_TOKEN_ID, amount, "");
    }

    /// @notice Allows a wallet to claim the prize by claiming to own all unique stickers
    /// @dev We reduce the prizePoolBalance
    /// @param shirtNumbersProposed The number of shirts the user claim to own. The numbers need to be
    ///  sorted by country and type in increasing order, so shirtNumbersProposed[0] is countryId = 1 and typeId =1
    function claimPrize(uint256[] calldata shirtNumbersProposed)
        external
        nonReentrant
    {
        require(
            shirtNumbersProposed.length == (totalCountries * TOTAL_TYPES),
            "Not the right amount of stickers"
        );
        require(_openPacksEnabled, "This function is not yet enabled!");
        require(winnersRemaining() > 0, "No more winners");

        uint256 shirtNumberIndex;
        uint256[] memory stickersToBurn = new uint256[](
            shirtNumbersProposed.length
        );

        for (uint256 i = 0; i < totalCountries; i++) {
            uint256 countryId = i + 1;
            for (uint256 j = 0; j < TOTAL_TYPES; j++) {
                uint256 typeId = j + 1;

                // Generate the correspondent stickerId with the proposed shirtnumber
                uint256 tokenId = countryId *
                    1000 +
                    typeId *
                    100 +
                    shirtNumbersProposed[shirtNumberIndex];

                // Check ownership & Burn token Id
                stickersToBurn[shirtNumberIndex] = tokenId;
                shirtNumberIndex += 1;
                _burn(msg.sender, tokenId, 1);
            }
        }

        uint256 prizeAmount;
        if (winnersRemaining() == 1) {
            // Send remaining balance to last possible winner
            prizeAmount = prizePoolBalance;
        } else {
            prizeAmount = prizePoolBalance / 2;
        }
        // Send prize
        prizePoolBalance -= prizeAmount;
        _numWinners.increment();
        emit NewWinner(msg.sender, prizeAmount, stickersToBurn);

        payable(msg.sender).transfer(prizeAmount);
    }

    /// @notice Start a trade between 2 stickers
    /// @dev The offered sticker will be transfer to the contract as escrow until
    ///  the trade is completed or cancelled
    /// @param offerId The sticker token ID offered
    /// @param reqCountry The required country ID in exchange for the offer
    /// @param reqType The required type ID in exchange for the offer
    /// @param reqNumber The required number of shirt in exchange for the offer. Use 0 to accept any
    /// @return tradeIndex The ID of the new trade record
    function startTrade(
        uint256 offerId,
        uint256 reqCountry,
        uint256 reqType,
        uint256 reqNumber
    ) external returns (uint256) {
        require(offerId != PACK_TOKEN_ID, "Cannot trade packs");
        require(
            reqCountry > 0 && reqCountry <= totalCountries,
            "Invalid country"
        );
        require(reqType > 0 && reqType <= TOTAL_TYPES, "Invalid type");
        _trades.push(
            Trade(
                msg.sender,
                offerId,
                reqCountry,
                reqType,
                reqNumber,
                _trades.length
            )
        );
        // Keep the sticker on the contract until the trade is completed or cancelled
        safeTransferFrom(msg.sender, address(this), offerId, 1, "");
        return _trades.length - 1;
    }

    /// @notice Completes an existing trade, sending to each wallet their respective sticker
    /// @dev The token in escrow is send to the wallet that completes the trade.
    /// @param tradeIndex The ID of the trade to complete
    /// @param shirtNumber The shirt number of the sticker the third party is giving in exchange
    function completeTrade(uint256 tradeIndex, uint256 shirtNumber)
        external
        nonReentrant
    {
        require(tradeIndex < _trades.length, "Trade does not exist");
        Trade memory trade = _trades[tradeIndex];
        require(trade.owner != address(0), "Trade does not exist");

        if (trade.reqNumber > 0) {
            require(
                trade.reqNumber == shirtNumber,
                "Shirt numbers do not match"
            );
        }
        delete _trades[tradeIndex];
        // Generate the tokenId to complete the trade
        uint256 tokenId = trade.reqCountry *
            1000 +
            trade.reqType *
            100 +
            shirtNumber;
        // Trade owner receives the token
        safeTransferFrom(msg.sender, trade.owner, tokenId, 1, "");
        // Send the sticker hold on escrow
        IERC1155(address(this)).safeTransferFrom(
            address(this),
            msg.sender,
            trade.offerId,
            1,
            ""
        );
    }

    /// @notice Cancel an existing trade
    /// @dev The token in escrow is returned back to the trade owner
    /// @param tradeIndex The ID of the trade to cancel
    function cancelTrade(uint256 tradeIndex) external nonReentrant {
        require(tradeIndex < _trades.length, "Trade does not exist");
        Trade memory trade = _trades[tradeIndex];
        require(trade.owner != address(0), "Trade does not exist");
        require(trade.owner == msg.sender, "Only the trade owner can cancel");
        // You get some gas back for deleting
        delete _trades[tradeIndex];
        // Return the sticker to the owner
        IERC1155(address(this)).safeTransferFrom(
            address(this),
            msg.sender,
            trade.offerId,
            1,
            ""
        );
    }

    /// @notice Allow the owner to withdraw the available balance from the ownerBalance
    /// @dev The ownerBalance is set to 0
    function withdraw() external onlyOwner nonReentrant {
        require(ownerBalance > 0, "No owner balance");
        uint256 balanceToSend = ownerBalance;
        ownerBalance = 0;
        payable(msg.sender).transfer(balanceToSend);
    }

    /// @notice The pack balance of the given address
    /// @param who The address to check for packs balance
    /// @return balance The number of packs
    function packBalance(address who) external view returns (uint256) {
        return balanceOf(who, PACK_TOKEN_ID);
    }

    /// @notice The total number of stickers registered
    /// @return length The number of stickers
    function registeredStickers() external view returns (uint256) {
        return _stickers.length;
    }

    /// @notice A trade details
    /// @param tradeIndex The trade ID
    /// @return trade The trade details
    function tradeDetails(uint256 tradeIndex)
        external
        view
        returns (Trade memory)
    {
        Trade memory trade = _trades[tradeIndex];
        return trade;
    }

    /// @notice Total trades created
    /// @return length Number of trades
    function totalTrades() external view returns (uint256) {
        return _trades.length;
    }

    /// @notice List the trades started by a given address
    /// @dev Because memory arrays need a size, we needed 2 loops to return the filtered data
    /// @param who The address who started the trades
    /// @return trades An array of trades (if any)
    function ownerTrades(address who) external view returns (Trade[] memory) {
        // There is no way to avoid two loops to return a dynamic array
        uint256 activeTrades = totalActiveTrades(who);
        Trade[] memory values = new Trade[](activeTrades);
        uint256 valuesIndex = 0;
        for (uint256 i = 0; i < _trades.length; i++) {
            if (_trades[i].owner == who) {
                Trade memory trade = _trades[i];
                values[valuesIndex] = trade;
                valuesIndex++;
            }
        }

        return values;
    }

    /// @notice Returns the URI to a contract specific metadata
    /// @dev https://docs.opensea.io/docs/contract-level-metadata
    /// @return _contractURI The URL to the metadata
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /// @notice Return the number of possible winners remaining
    /// @return winners The number of remaining winners
    function winnersRemaining() public view returns (uint256) {
        return maxWinners - _numWinners.current();
    }

    /// @notice Return the token metadata URL
    /// @dev The URI depends on the state variable _revealed
    /// @param tokenId The token ID to return the metadata
    function uri(uint256 tokenId)
        public
        view
        virtual
        override(ERC1155, ERC1155URIStorage)
        returns (string memory tokenURI)
    {
        if (_revealed) {
            tokenURI = string.concat(_revealedPath, Strings.toString(tokenId));
        } else {
            tokenURI = super.uri(tokenId);
        }
    }

    /// @notice We need to define this function so we can receive ERC1155 tokens
    /// @dev This is required so we can hold the stickers on escrow during trade
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @notice We need to define this function so we can receive ERC1155 tokens
    /// @dev This is required so we can hold the stickers on escrow during trade
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /// @notice Return the total number of active trades for a wallet
    /// @dev We use this function in ownerTrades()
    /// @param who The wallet of the trade owner
    /// @return count The number of active trades for the user
    function totalActiveTrades(address who) internal view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < _trades.length; i++) {
            if (_trades[i].owner == who) {
                count++;
            }
        }
        return count;
    }

    /// @notice Returns a random sticker index from the available stickers
    /// @dev Used by openPacks().
    /// @param totalSize The upperband of the random number to generate
    /// @return index The index from the array _stickers
    function randomStickerIndex(uint256 totalSize)
        internal
        view
        returns (uint256)
    {
        if (totalSize == 0) return 0;

        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    nonce,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % totalSize;
        // Don't allow a zero index, start counting at 1
        uint256 randomIndex = index + 1;
        uint256 acc = 0;
        uint256 stickerIndex = 0;
        for (uint256 s = 0; s < _stickers.length; s++) {
            acc += _stickers[s].amountRemaining;
            if (randomIndex <= acc) {
                stickerIndex = s;
                break;
            }
        }
        return stickerIndex;
    }

    /// @notice Must haver overrride function for ERC1155
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
