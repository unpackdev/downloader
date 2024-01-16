// Altura - LootBox contract
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IERC1155Upgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IAlturaNFTV2.sol";

contract AlturaLootboxV2 is ERC1155HolderUpgradeable {
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    /**
     * Round Struct
     */
    struct Round {
        uint256 id; // request id.
        address player; // address of player.
        RoundStatus status; // status of the round.
        uint256 times; // how many times of this round;
        uint256 totalTimes; // total time of an account.
        uint256[20] cards; // Prize card of this round.
        uint256 lastUpdated;
    }

    enum RoundStatus {
        Initial,
        Pending,
        Finished
    } // status of this round
    mapping(address => Round) public gameRounds;

    uint256 public currentRoundIdCount; //until now, the total round of this Lootbox.
    uint256 public totalRoundCount;

    string public boxName;
    string public boxUri;
    IAlturaNFTV2 public collection;
    IERC1155Upgradeable public paymentCollection;
    uint256 public paymentTokenId;
    uint256 public playOncePrice;

    address public owner;
    address public paymentAddress;

    bool public banned = false;

    // This is a set which contains cardKey
    EnumerableSetUpgradeable.UintSet private _cardIndices;

    // This mapping contains cardKey => amount
    mapping(uint256 => uint256) public amountWithId;
    // Prize pool with a random number to cardKey
    mapping(uint256 => uint256) private _prizePool;
    // The amount of cards in this lootbox.
    uint256 public cardAmount;

    uint256 private _salt;
    uint256 public shuffleCount = 3;

    event AddToken(uint256 tokenId, uint256 amount, uint256 cardAmount);
    event AddTokenBatch(uint256[] tokenIds, uint256[] amounts, uint256 cardAmount);
    event AddTokenBatchByMint(uint256 fromTokenId, uint256 count, uint256 supply, uint256 fee);
    event RemoveCard(uint256 card, uint256 removeAmount, uint256 cardAmount);
    event SpinLootbox(address account, uint256 times, uint256 playFee);

    event LootboxLocked(bool locked);

    function initialize(
        string memory _name,
        string memory _uri,
        address _collection,
        address _paymentCollection,
        uint256 _paymentTokenId,
        uint256 _price,
        address _owner
    ) public initializer {
        boxName = _name;
        boxUri = _uri;
        collection = IAlturaNFTV2(_collection);
        paymentCollection = IERC1155Upgradeable(_paymentCollection);
        paymentTokenId = _paymentTokenId;
        playOncePrice = _price;

        owner = _owner;
        paymentAddress = _owner;

        shuffleCount = 3;

        _salt = uint256(keccak256(abi.encodePacked(_paymentCollection, _paymentTokenId, block.timestamp))).mod(10000);
    }

    /**
     * @dev Add tokens which have been minted, and your owned cards
     * @param tokenId. Card id you want to add.
     * @param amount. How many cards you want to add.
     */
    function addToken(uint256 tokenId, uint256 amount) public onlyOwner unbanned {
        require(IAlturaNFTV2(collection).balanceOf(msg.sender, tokenId) >= amount, "You don't have enough Tokens");
        IAlturaNFTV2(collection).safeTransferFrom(msg.sender, address(this), tokenId, amount, "Add Card");

        if (amountWithId[tokenId] == 0) {
            _cardIndices.add(tokenId);
        }

        amountWithId[tokenId] = amountWithId[tokenId].add(amount);
        for (uint256 i = 0; i < amount; i++) {
            _prizePool[cardAmount + i] = tokenId;
        }
        cardAmount = cardAmount.add(amount);
        emit AddToken(tokenId, amount, cardAmount);
    }

    function addTokenBatch(uint256[] memory tokenIds, uint256[] memory amounts) public onlyOwner unbanned {
        require(tokenIds.length > 0 && tokenIds.length == amounts.length, "Invalid Token ids");

        IAlturaNFTV2(collection).safeBatchTransferFrom(msg.sender, address(this), tokenIds, amounts, "Add Cards");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];

            if (amountWithId[tokenId] == 0) {
                _cardIndices.add(tokenId);
            }

            amountWithId[tokenId] = amountWithId[tokenId].add(amount);
            for (uint256 j = 0; j < amount; j++) {
                _prizePool[cardAmount + j] = tokenId;
            }
            cardAmount = cardAmount.add(amount);
        }

        emit AddTokenBatch(tokenIds, amounts, cardAmount);
    }

    function addTokenBatchByMint(
        uint256 count,
        uint256 supply,
        uint256 fee
    ) public onlyOwner unbanned {
        require(count > 0 && supply > 0, "invalid count or supply");

        uint256 fromTokenId = 0;
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = IAlturaNFTV2(collection).addItem(supply, supply, fee);
            if (i == 0) {
                fromTokenId = tokenId;
            }

            if (amountWithId[tokenId] == 0) {
                _cardIndices.add(tokenId);
            }

            amountWithId[tokenId] = amountWithId[tokenId].add(supply);
            for (uint256 j = 0; j < supply; j++) {
                _prizePool[cardAmount + j] = tokenId;
            }
            cardAmount = cardAmount.add(supply);
        }

        emit AddTokenBatchByMint(fromTokenId, count, supply, fee);
    }

    /**
        Spin Lootbox with seed and times
     */
    function spin(uint256 userProvidedSeed, uint256 times) public onlyHuman unbanned {
        require(!banned, "This lootbox is banned.");
        require(cardAmount > 0, "There is no card in this lootbox anymore.");
        require(times > 0, "Times can not be 0");
        require(times <= 20 && times <= cardAmount, "Over times.");

        _createARound(times);

        // get random seed with userProvidedSeed and address of sender.
        uint256 seed = uint256(keccak256(abi.encode(userProvidedSeed, msg.sender)));

        if (cardAmount > shuffleCount) {
            _shufflePrizePool(seed);
        }

        address player = msg.sender;

        for (uint256 i = 0; i < times; i++) {
            // get randomResult with randomness and i.
            uint256 randomResult = _getRandomNumebr(seed, _salt, cardAmount);
            // update random salt.
            _salt = ((randomResult + cardAmount + _salt) * (i + 1) * block.timestamp).mod(cardAmount) + 1;
            // transfer the cards.
            uint256 result = (randomResult * _salt).mod(cardAmount);
            _updateRound(player, result, i);
        }

        totalRoundCount = totalRoundCount.add(times);
        uint256 playFee = playOncePrice.mul(times);
        _transferToken(player, playFee);
        _distributePrize(player);

        emit SpinLootbox(player, times, playFee);
    }

    /**
     * @param amount how much token will be needed and will be burned.
     */
    function _transferToken(address player, uint256 amount) private {
        paymentCollection.safeTransferFrom(player, paymentAddress, paymentTokenId, amount, "Pay for spinning");
    }

    function _distributePrize(address player) private {
        uint256 totalCount = gameRounds[player].times;
        require(totalCount > 0, "zero count");

        uint256[] memory tokenIds = new uint256[](totalCount);
        uint256[] memory amounts = new uint256[](totalCount);

        for (uint256 i = 0; i < gameRounds[player].times; i++) {
            uint256 tokenId = gameRounds[player].cards[i];
            tokenIds[i] = tokenId;
            amounts[i] = 1;
            require(amountWithId[tokenId] > 0, "!enough");

            amountWithId[tokenId] = amountWithId[tokenId].sub(1);
            if (amountWithId[tokenId] == 0) {
                _cardIndices.remove(tokenId);
            }
        }
        IAlturaNFTV2(collection).safeBatchTransferFrom(address(this), player, tokenIds, amounts, "prize");

        gameRounds[player].status = RoundStatus.Finished;
        gameRounds[player].lastUpdated = block.timestamp;
    }

    function _updateRound(
        address player,
        uint256 randomResult,
        uint256 rand
    ) private {
        uint256 tokenId = _prizePool[randomResult];
        _prizePool[randomResult] = _prizePool[cardAmount - 1];
        cardAmount = cardAmount.sub(1);
        gameRounds[player].cards[rand] = tokenId;
    }

    function _getRandomNumebr(
        uint256 seed,
        uint256 salt,
        uint256 mod
    ) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.timestamp,
                        block.difficulty,
                        block.coinbase,
                        blockhash(block.number + 1),
                        seed,
                        salt,
                        block.number
                    )
                )
            ).mod(mod);
    }

    function _createARound(uint256 times) private {
        if (
            gameRounds[msg.sender].status == RoundStatus.Pending &&
            block.timestamp.sub(gameRounds[msg.sender].lastUpdated) >= 10 * 60
        ) {
            gameRounds[msg.sender].status = RoundStatus.Finished;
        }

        require(gameRounds[msg.sender].status != RoundStatus.Pending, "Currently pending now");
        gameRounds[msg.sender].id = currentRoundIdCount + 1;
        gameRounds[msg.sender].player = msg.sender;
        gameRounds[msg.sender].status = RoundStatus.Pending;
        gameRounds[msg.sender].times = times;
        gameRounds[msg.sender].totalTimes = gameRounds[msg.sender].totalTimes.add(times);
        gameRounds[msg.sender].lastUpdated = block.timestamp;
        currentRoundIdCount = currentRoundIdCount.add(1);
    }

    // shuffle the prize pool again.
    function _shufflePrizePool(uint256 seed) private {
        for (uint256 i = 0; i < shuffleCount; i++) {
            uint256 randomResult = _getRandomNumebr(seed, _salt, cardAmount);
            _salt = ((randomResult + cardAmount + _salt) * (i + 1) * block.timestamp).mod(cardAmount);
            _swapPrize(i, _salt);
        }
    }

    function _swapPrize(uint256 a, uint256 b) private {
        uint256 temp = _prizePool[a];
        _prizePool[a] = _prizePool[b];
        _prizePool[b] = temp;
    }

    function cardKeyCount() public view returns (uint256) {
        return _cardIndices.length();
    }

    function cardKeyWithIndex(uint256 index) public view returns (uint256) {
        return _cardIndices.at(index);
    }

    function allCards() public view returns (address[] memory collectionIds, uint256[] memory tokenIds) {
        uint256 cardsCount = cardKeyCount();
        collectionIds = new address[](cardsCount);
        tokenIds = new uint256[](cardsCount);

        for (uint256 i = 0; i < cardsCount; i++) {
            collectionIds[i] = address(collection);
            tokenIds[i] = cardKeyWithIndex(i);
        }
    }

    // ***************************
    // For Admin Account ***********
    // ***************************
    function changePlayOncePrice(uint256 newPrice) public onlyOwner {
        playOncePrice = newPrice;
    }

    function changePaymentCollection(address _collection) external onlyOwner {
        paymentCollection = IERC1155Upgradeable(_collection);
    }

    function changePaymentTokenId(uint256 _tokenId) external onlyOwner {
        paymentTokenId = _tokenId;
    }

    function changePaymentAddress(address _receipt) external onlyOwner {
        require(_receipt != address(0x0), "Payment address cannot Zero address");
        paymentAddress = _receipt;
    }

    function transferOwner(address account) public onlyOwner {
        require(account != address(0), "Ownable: new owner is zero address");
        owner = account;
    }

    function removeOwnership() public onlyOwner {
        owner = address(0x0);
    }

    function changeShuffleCount(uint256 _shuffleCount) public onlyOwner {
        shuffleCount = _shuffleCount;
    }

    function banThisLootbox() public onlyOwner {
        banned = true;
    }

    function unbanThisLootbox() public onlyOwner {
        banned = false;
    }

    function changeLootboxName(string memory name) public onlyOwner {
        boxName = name;
    }

    function changeLootboxUri(string memory _uri) public onlyOwner {
        boxUri = _uri;
    }

    // This is a emergency function. you should not always call this function.
    function emergencyWithdrawCard(
        uint256 tokenId,
        address to,
        uint256 amount
    ) public onlyOwner {
        require(tokenId != 0, "Invalid token id");
        require(amountWithId[tokenId] >= amount, "Insufficient balance");

        IAlturaNFTV2(collection).safeTransferFrom(address(this), to, tokenId, amount, "Reset Lootbox");
        cardAmount = cardAmount.sub(amount);
        amountWithId[tokenId] = amountWithId[tokenId].sub(amount);
    }

    function emergencyWithdrawAllCards() public onlyOwner {
        for (uint256 i = 0; i < cardKeyCount(); i++) {
            uint256 key = cardKeyWithIndex(i);
            if (amountWithId[key] > 0) {
                IAlturaNFTV2(collection).safeTransferFrom(
                    address(this),
                    msg.sender,
                    key,
                    amountWithId[key],
                    "Reset Lootbox"
                );
                cardAmount = cardAmount.sub(amountWithId[key]);
                amountWithId[key] = 0;
            }
        }
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    // Modifiers
    modifier onlyHuman() {
        require(!isContract(address(msg.sender)) && tx.origin == msg.sender, "Only for human.");
        _;
    }

    modifier onlyOwner() {
        require(address(msg.sender) == owner, "Only for owner.");
        _;
    }

    modifier unbanned() {
        require(!banned, "This lootbox is banned.");
        _;
    }
}
