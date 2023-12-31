// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "./ERC1155.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./IUniswapV2Router02.sol";
import "./IFloridaManCard.sol";
import "./IFloridaManCardStaking.sol";

contract FloridaManCard is ERC1155, Ownable, IFloridaManCard {
    using SafeMath for uint256;

    struct Card {
        uint256 id;
        uint256 price;
        uint256 totalSupply;
        uint256 maxOwnable;
        uint256 level;
    }

    struct Season {
        uint256 id;
        uint256 level1Probability;
        uint256 level2Probability;
        uint256 level3Probability;
        uint256 level4Probability;
        uint256 level5Probability;
        uint256 mysteryPack1Price;
        uint256 mysteryPack5Price;
        uint256 mysteryPack10Price;
        uint256[] cardIds;
    }

    string public name = "Florida Man Card";
    string public symbol = "FMANCARD";

    address payable private _developerAddress;
    address internal _tokenAddress = 0xD56990D60A7Abf3a7945F0565A98A708234b802C;
    address internal _wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal _usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal _stakingAddress = address(0);

    // Can we mint or nah?
    bool internal _mintingActive = false;

    // Hold lists of seasons and cards
    uint256[] internal _cardIds;
    uint256[] internal _seasonIds;

    mapping(uint256 => Card) internal _cardMap;
    mapping(uint256 => Season) internal _seasonMap;

    // Hold minted supply of each card
    mapping(uint256 => uint256) internal _cardSupply;

    // Hold mint droppable bool of each card
    mapping(uint256 => bool) internal _mintDroppableMap;

    modifier onlyDeveloper() {
        require(_developerAddress == _msgSender(), "Caller is not the developer");
        _;
    }

    modifier onlyOwnerOrDeveloper() {
        require(owner() == _msgSender() || _developerAddress == _msgSender(), "Caller is not owner or developer");
        _;
    }

    event CreateCard(address indexed _firom, uint256 indexed _id, uint256 _level);
    event CreateSeason(address indexed _from, uint256 indexed _id, uint256[] _cardIds);
    event Purchase(address indexed _from, uint256 _amount, string _token);
    event SeasonProbabilitesUpdate(
        address indexed _from,
        uint256 indexed _id,
        uint256 _level1Probability,
        uint256 _level2Probability,
        uint256 _level3Probability,
        uint256 _level4Probability,
        uint256 _level5Probability
    );
    event SeasonPackPricesUpdate(
        address indexed _from, uint256 indexed _id, uint256 _pack1Price, uint256 _pack5Price, uint256 _pack10Price
    );
    event SeasonCardsUpdate(address indexed _from, uint256 indexed _id, uint256[] _cardIds);

    constructor(address __developerAddress, address __tokenAddress) ERC1155("https://nft.floridamantoken.com/jsons/") {
        _developerAddress = payable(__developerAddress);
        _tokenAddress = __tokenAddress;
    }

    // /////////////////////////////////////////////
    // PUBLIC - OWNER ONLY
    // /////////////////////////////////////////////

    function setDeveloperAddress(address payable newAddress) external onlyDeveloper {
        _developerAddress = newAddress;
    }

    function setTokenAddress(address newTokenAddress) external onlyOwner {
        _tokenAddress = newTokenAddress;
    }

    function setUsdcAddress(address newAddress) external onlyOwner {
        _usdcAddress = newAddress;
    }

    function setRouterAddress(address newRouterAddress) external onlyOwner {
        _routerAddress = newRouterAddress;
    }

    function setMintingActive(bool newState) external onlyOwner {
        _mintingActive = newState;
    }

    function setMintDroppable(uint256 _cardId, bool droppable) external onlyOwner {
        require(isCardValid(_cardId), "Card does not exist");

        _mintDroppableMap[_cardId] = droppable;
    }

    function createCard(uint256 _id, uint256 _priceUSD, uint256 _totalSupply, uint256 _maxOwnable, uint256 _level)
        external
        onlyOwner
    {
        require(!isCardValid(_id), "Card with id already exists");
        require(_totalSupply >= 1, "Total available must be > 0");
        require(_maxOwnable >= 1, "Max ownable must be > 0");
        require(_level >= 1 && _level <= 5, "Level must be between 1 & 5");

        Card memory newCard =
            Card({id: _id, price: _priceUSD, totalSupply: _totalSupply, maxOwnable: _maxOwnable, level: _level});
        _cardMap[_id] = newCard;
        _cardIds.push(_id);

        emit CreateCard(_msgSender(), _id, _level);
    }

    function updateCard(uint256 _id, uint256 _priceUSD, uint256 _totalSupply, uint256 _maxOwnable, uint256 _level)
        external
        onlyOwner
    {
        require(isCardValid(_id), "Card does not exist");
        require(_totalSupply >= 1, "Total available must be > 0");
        require(_totalSupply >= _cardSupply[_id], "Total available must be more than minted supply");
        require(_maxOwnable >= 1, "Max ownable must be > 0");
        require(_level >= 1 && _level <= 5, "Level must be between 1 & 5");

        Card storage fetchedCard = _cardMap[_id];
        fetchedCard.price = _priceUSD;
        fetchedCard.totalSupply = _totalSupply;
        fetchedCard.maxOwnable = _maxOwnable;
        fetchedCard.level = _level;
    }

    function createSeason(
        uint256 _id,
        uint256[] memory __cardIds,
        uint256 _level1Probability,
        uint256 _level2Probability,
        uint256 _level3Probability,
        uint256 _level4Probability,
        uint256 _level5Probability,
        uint256 _mysteryPack1PriceUSD,
        uint256 _mysteryPack5PriceUSD,
        uint256 _mysteryPack10PriceUSD
    ) external onlyOwner {
        require(!_seasonExists(_id), "Season with id already exists");
        require(
            _level1Probability + _level2Probability + _level3Probability + _level4Probability + _level5Probability
                == 100,
            "Probabilities must equal 100"
        );
        Season storage season = _seasonMap[_id];
        season.id = _id;
        for (uint256 i = 0; i < __cardIds.length; i++) {
            uint256 _cardId = __cardIds[i];
            require(isCardValid(_cardId), "Card does not exist");
            season.cardIds.push(_cardId);
        }
        season.level1Probability = _level1Probability;
        season.level2Probability = _level2Probability;
        season.level3Probability = _level3Probability;
        season.level4Probability = _level4Probability;
        season.level5Probability = _level5Probability;
        season.mysteryPack1Price = _mysteryPack1PriceUSD;
        season.mysteryPack5Price = _mysteryPack5PriceUSD;
        season.mysteryPack10Price = _mysteryPack10PriceUSD;
        _seasonIds.push(_id);

        emit CreateSeason(_msgSender(), _id, _cardIds);
    }

    function updateSeasonProbabilities(
        uint256 _id,
        uint256 _level1Probability,
        uint256 _level2Probability,
        uint256 _level3Probability,
        uint256 _level4Probability,
        uint256 _level5Probability
    ) external onlyOwner {
        require(_seasonExists(_id), "Season does not exist");
        require(
            _level1Probability + _level2Probability + _level3Probability + _level4Probability + _level5Probability
                == 100,
            "Probabilities must equal 100"
        );
        Season storage season = _seasonMap[_id];
        season.level1Probability = _level1Probability;
        season.level2Probability = _level2Probability;
        season.level3Probability = _level3Probability;
        season.level4Probability = _level4Probability;
        season.level5Probability = _level5Probability;

        emit SeasonProbabilitesUpdate(
            _msgSender(),
            _id,
            _level1Probability,
            _level2Probability,
            _level3Probability,
            _level4Probability,
            _level5Probability
        );
    }

    function updateSeasonPackPrices(
        uint256 _id,
        uint256 _mysteryPack1PriceUSD,
        uint256 _mysteryPack5PriceUSD,
        uint256 _mysteryPack10PriceUSD
    ) external onlyOwner {
        require(_seasonExists(_id), "Season does not exist");
        Season storage season = _seasonMap[_id];
        season.mysteryPack1Price = _mysteryPack1PriceUSD;
        season.mysteryPack5Price = _mysteryPack5PriceUSD;
        season.mysteryPack10Price = _mysteryPack10PriceUSD;

        emit SeasonPackPricesUpdate(
            _msgSender(), _id, _mysteryPack1PriceUSD, _mysteryPack5PriceUSD, _mysteryPack10PriceUSD
        );
    }

    function updateSeasonCards(uint256 _id, uint256[] memory __cardIds) external onlyOwner {
        require(_seasonExists(_id), "Season does not exist");
        Season storage season = _seasonMap[_id];
        season.cardIds = new uint256[](__cardIds.length);
        for (uint256 i = 0; i < __cardIds.length; i++) {
            uint256 _cardId = __cardIds[i];
            require(isCardValid(_cardId), "Card does not exist");

            Card memory fetchedCard = _cardMap[_cardId];
            // solhint-disable-next-line reason-string
            require(_cardSupply[_cardId] < fetchedCard.totalSupply, "Card supply exhausted, update card's totalSupply");

            season.cardIds[i] = _cardId;
        }

        emit SeasonCardsUpdate(_msgSender(), _id, __cardIds);
    }

    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _amounts) public onlyOwner {
        _mintBatch(_to, _ids, _amounts, "0x");

        for (uint256 i = 0; i < _ids.length; i++) {
            _cardSupply[_ids[i]] = _cardSupply[_ids[i]].add(_amounts[i]);
        }
    }

    function mintStakeBatch(address _for, uint256[] memory _ids, uint256[] memory _amounts) external onlyOwner {
        require(_stakingAddress != address(0), "Staking contract address not set");

        mintBatch(_for, _ids, _amounts);

        IFloridaManCardStaking(payable(address(_stakingAddress))).stakeBatch(_for, _ids, _amounts);
    }

    function withdrawFMAN() public onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));

        require(IERC20(_tokenAddress).transfer(owner(), balance), "Failed to withdraw to owner");
    }

    function withdrawETH() public onlyOwner {
        uint256 balance = address(this).balance;

        uint256 developerBalance = balance.mul(1000).div(10000);
        uint256 ownerBalance = balance.sub(developerBalance);

        payable(_developerAddress).transfer(developerBalance);
        payable(owner()).transfer(ownerBalance);
    }

    // /////////////////////////////////////////////
    // PUBLIC - ALL
    // /////////////////////////////////////////////

    function uri(uint256 _id) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }

    function isCardValid(uint256 _id) public view returns (bool) {
        Card memory fetchedCard = _cardMap[_id];
        if (fetchedCard.id > 0) {
            return true;
        }

        return false;
    }

    function isSeasonValid(uint256 _id) public view returns (bool) {
        Season memory fetchedSeason = _seasonMap[_id];
        if (fetchedSeason.id > 0) {
            return true;
        }

        return false;
    }

    function isMintingActive() external view returns (bool active) {
        return _mintingActive;
    }

    function isMintDroppable(uint256 _cardId) external view returns (bool droppable) {
        require(isCardValid(_cardId), "Card does not exist");

        return _mintDroppableMap[_cardId];
    }

    function getMintedSupply(uint256 _cardId) external view returns (uint256 supply) {
        require(isCardValid(_cardId), "Card does not exist");

        return _cardSupply[_cardId];
    }

    function getAvailableSupply(uint256 _cardId) public view returns (uint256 supply) {
        require(isCardValid(_cardId), "Card does not exist");

        // If we've minted more than available supply, dont panic
        if (_cardSupply[_cardId] > _cardMap[_cardId].totalSupply) {
            return 0;
        }

        return _cardMap[_cardId].totalSupply - _cardSupply[_cardId];
    }

    function getMysterPackPrices(uint256 _seasonId)
        external
        view
        returns (uint256 pack1, uint256 pack5, uint256 pack10)
    {
        require(_seasonExists(_seasonId), "Season does not exist");

        Season memory season = _seasonMap[_seasonId];

        uint256 pack1Price = _getFMANFromUSD(season.mysteryPack1Price);
        uint256 pack5Price = _getFMANFromUSD(season.mysteryPack5Price);
        uint256 pack10Price = _getFMANFromUSD(season.mysteryPack10Price);

        return (pack1Price, pack5Price, pack10Price);
    }

    function getAvailableSeasonSupply(uint256 _id) external view returns (uint256 supply) {
        require(_seasonExists(_id), "Season does not exist");

        uint256[] memory seasonCardIds = _seasonMap[_id].cardIds;

        uint256 available = 0;

        for (uint256 i = 0; i < seasonCardIds.length; i++) {
            available += getAvailableSupply(seasonCardIds[i]);
        }

        return available;
    }

    function getCard(uint256 _id)
        external
        view
        returns (
            uint256 id,
            uint256 level,
            uint256 usdPrice,
            uint256 totalSupply,
            uint256 maxOwnable,
            uint256 availableAmount,
            uint256 ownedAmount
        )
    {
        require(isCardValid(_id), "Card does not exist");

        Card memory fetchedCard = _cardMap[_id];

        uint256 available = getAvailableSupply(fetchedCard.id);
        uint256 owned = 0;

        if (_msgSender() != address(0)) {
            balanceOf(_msgSender(), fetchedCard.id);
        }

        return (
            fetchedCard.id,
            fetchedCard.level,
            fetchedCard.price,
            fetchedCard.totalSupply,
            fetchedCard.maxOwnable,
            available,
            owned
        );
    }

    function getSeasonIds() external view returns (uint256[] memory allSeasonIds) {
        return _seasonIds;
    }

    function getCardIds() external view returns (uint256[] memory allCardIds) {
        return _cardIds;
    }

    function getSeasonCards(uint256 _id) external view returns (uint256[] memory seasonCardIds) {
        require(_seasonExists(_id), "Season does not exist");

        return _seasonMap[_id].cardIds;
    }

    function mintMysteryPack(address _to, uint256 _seasonId, uint256 _quantity)
        external
        returns (uint256[] memory minted)
    {
        require(_mintingActive, "Minting is not active");
        require(_seasonExists(_seasonId), "Season does not exist");
        require(_quantity == 1 || _quantity == 5 || _quantity == 10, "Quantity must be 1,5, or 10");

        Season memory season = _seasonMap[_seasonId];

        // Verify there are actually enough cards left to mint
        uint256 seasonCardSupply = 0;
        for (uint256 i = 0; i < season.cardIds.length; i++) {
            uint256 cardId = season.cardIds[i];

            seasonCardSupply = seasonCardSupply + getAvailableSupply(cardId);
        }

        require(seasonCardSupply >= _quantity, "Not enough cards left to mint");

        // Figure out total token amount
        uint256 usdAmount = season.mysteryPack10Price;

        if (_quantity == 5) {
            usdAmount = season.mysteryPack5Price;
        } else if (_quantity == 1) {
            usdAmount = season.mysteryPack1Price;
        }

        // Get the price of the pack
        uint256 tokenAmount = _getFMANFromUSD(usdAmount);

        // Verify balance and transfer tokens
        require(IERC20(_tokenAddress).balanceOf(_msgSender()) >= tokenAmount, "Insufficient balance to mint");

        require(IERC20(_tokenAddress).transferFrom(_msgSender(), address(this), tokenAmount), "Failed to transfer FMAN");
        emit Purchase(_msgSender(), tokenAmount, "FMAN");

        // Start the mint
        uint256[] memory randomSeeds = __generateRandomMulti(_generateRandom(), _quantity);
        uint256[] memory mintedCardIds = new uint256[](_quantity);

        for (uint256 i = 0; i < _quantity; i++) {
            uint256 seed = randomSeeds[i];
            uint256 cardId = _getMysteryPackCard(_to, _seasonId, seed);
            _mint(_to, cardId, 1, "0x");
            _cardSupply[cardId] = _cardSupply[cardId].add(1);
            mintedCardIds[i] = cardId;
        }

        return mintedCardIds;
    }

    function mintDrop(address _to, uint256 _cardId, uint256 _quantity) external payable returns (uint256 minted) {
        require(_mintingActive, "Minting is not active");
        require(isCardValid(_cardId), "Card does not exist");
        require(_mintDroppableMap[_cardId], "Card is not mint droppable");

        Card memory fetchedCard = _cardMap[_cardId];

        uint256 supply = getAvailableSupply(_cardId);
        uint256 ownedBalance = balanceOf(_to, _cardId);

        require(supply > 0, "Card has no supply left");
        require(ownedBalance < fetchedCard.maxOwnable, "Owned max supply of card");

        uint256 tokenAmount = _getETHFromUSD(fetchedCard.price * _quantity);

        // Verify balance and transfer tokens
        require(msg.value >= tokenAmount, "Insufficient balance to mint");

        emit Purchase(_msgSender(), tokenAmount, "ETH");

        _mint(_to, _cardId, _quantity, "0x");
        _cardSupply[_cardId] = _cardSupply[_cardId].add(1);

        return _cardId;
    }

    function transfer(address _to, uint256 _id, uint256 _quantity) external {
        safeTransferFrom(_msgSender(), _to, _id, _quantity, "0x");
    }

    // /////////////////////////////////////////////
    // INTERNAL
    // /////////////////////////////////////////////

    function _getFMANFromUSD(uint256 _usd) internal view returns (uint256 amount) {
        address[] memory path = new address[](3);
        path[0] = _usdcAddress;
        path[1] = _wethAddress;
        path[2] = _tokenAddress;

        uint256[] memory amounts = IUniswapV2Router02(_routerAddress).getAmountsOut(_usd * (10 ** 6), path);

        return amounts[2];
    }

    function _getETHFromUSD(uint256 _usd) public view returns (uint256 amount) {
        address[] memory path = new address[](2);
        path[0] = _usdcAddress;
        path[1] = _wethAddress;

        uint256[] memory amounts = IUniswapV2Router02(_routerAddress).getAmountsOut(_usd * (10 ** 6), path);

        return amounts[1];
    }

    function _seasonExists(uint256 _id) internal view returns (bool) {
        Season memory season = _seasonMap[_id];
        if (season.id > 0) {
            return true;
        }

        return false;
    }

    function _getSeasonLevelProbability(uint256 _id, uint256 _level) internal view returns (uint256 probability) {
        require(_seasonExists(_id), "Season does not exist");
        Season memory season = _seasonMap[_id];

        if (_level == 1) {
            return season.level1Probability;
        } else if (_level == 2) {
            return season.level2Probability;
        } else if (_level == 3) {
            return season.level3Probability;
        } else if (_level == 4) {
            return season.level4Probability;
        } else if (_level == 5) {
            return season.level5Probability;
        }
    }

    function _getMysteryPackMintableCardIds(address _owner, uint256 _seasonId)
        internal
        view
        returns (uint256[] memory ids)
    {
        require(_seasonExists(_seasonId), "Season does not exist");
        Season memory season = _seasonMap[_seasonId];

        uint256[] memory seasonCardIds = season.cardIds;
        uint256[] memory mintableCardIds = new uint256[](seasonCardIds.length);

        for (uint256 i = 0; i < seasonCardIds.length; i++) {
            Card memory fetchedCard = _cardMap[seasonCardIds[i]];

            uint256 supply = getAvailableSupply(fetchedCard.id);
            uint256 ownedBalance = balanceOf(_owner, fetchedCard.id);

            if (supply > 0 && ownedBalance < fetchedCard.maxOwnable) {
                mintableCardIds[i] = fetchedCard.id;
            } else {
                mintableCardIds[i] = 0;
            }
        }

        return mintableCardIds;
    }

    function _getMysteryPackCard(address _owner, uint256 _seasonId, uint256 _targetNumberSeed)
        internal
        view
        returns (uint256 id)
    {
        require(_seasonExists(_seasonId), "Season does not exist");

        Season memory season = _seasonMap[_seasonId];
        uint256 level = _getMysteryPackLevel(_owner, _seasonId, _targetNumberSeed);

        for (uint256 i = 0; i < season.cardIds.length; i++) {
            Card memory fetchedCard = _cardMap[season.cardIds[i]];

            if (fetchedCard.level == level) {
                return fetchedCard.id;
            }
        }

        return _getMysteryPackCard(_owner, _seasonId, _targetNumberSeed);
    }

    function _getMysteryPackLevel(address _owner, uint256 _seasonId, uint256 _targetNumberSeed)
        internal
        view
        returns (uint256 level)
    {
        uint256[] memory mintableCardIds = _getMysteryPackMintableCardIds(_owner, _seasonId);

        uint256 totalWeight = 0;
        uint256[] memory levels = new uint256[](_cardIds.length);

        for (uint256 i = 0; i < mintableCardIds.length; i++) {
            if (mintableCardIds[i] > 0) {
                uint256 probability = _getSeasonLevelProbability(_seasonId, mintableCardIds[i]);
                totalWeight = totalWeight + probability;
                levels[i] = probability;
            }
        }

        // Final number were working with here
        uint256 targetNumber = _targetNumberSeed.mod(totalWeight).add(1);

        for (uint256 i = 0; i < levels.length; i++) {
            if (targetNumber <= levels[i]) {
                // Since we 0 index, just add 1 to get a real level
                return i + 1;
            }
            // Subtract the weight and continue
            targetNumber = targetNumber - levels[i];
        }

        // Call again if we drop through
        return _getMysteryPackLevel(_owner, _seasonId, _targetNumberSeed);
    }

    // /////////////////////////////////////////////
    // PRIVATE
    // /////////////////////////////////////////////

    function _generateRandom() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp)));
    }

    function __generateRandomMulti(uint256 _seed, uint256 _times) private pure returns (uint256[] memory generated) {
        generated = new uint256[](_times);
        for (uint256 i = 0; i < _times; i++) {
            generated[i] = uint256(keccak256(abi.encode(_seed, i)));
        }
        return generated;
    }
}
