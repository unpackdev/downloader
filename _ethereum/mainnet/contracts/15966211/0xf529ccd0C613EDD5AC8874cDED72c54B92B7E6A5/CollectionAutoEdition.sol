// SPDX-License-Identifier: MIT
// Latest stable version of solidity
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "./FarmV2.sol";
import "./MoneyHandler.sol";
import "./IERC20.sol";
import "./EnumerableSet.sol";
import "./ERC1155.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./IFactory.sol";
import "./IPriceFeed.sol";
import "./MerkleProof.sol";

interface IMintableInterface {
    function mint(address to, uint256 _id) external;
}

interface IMintableBatchInterface {
    function mintBatch(
        address to,
        uint256[] memory _ids,
        uint256[] memory _amount
    ) external;
}

contract CollectionAutoEdition is ERC1155, AccessControl {
    event Sold(
        address indexed operator,
        address indexed to,
        uint256 indexed id,
        uint256 amount
    );
    event SoldBatch(
        address indexed operator,
        address indexed to,
        uint256[] ids,
        uint256 amount
    );
    event PaymentShared(address account, uint256 amount);
    event PaymentTreasure(address account, uint256 amount);
    event SoldWithStones(address buyer, uint256 amount);
    event NewStartTime(uint256 startTime);
    event NewEndTime(uint256 endTime);
    event NewUsdAmount(uint256 amount);
    event SetAddresses(
        address token,
        address stone,
        address treasury,
        address moneyHandler
    );

    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.UintSet soldCards;

    bytes32 public constant MINTER_ROLE = bytes32(keccak256("MINTER_ROLE"));

    IERC20 public token;
    FarmV2 public stone;
    MoneyHandler public moneyHand;

    /**@notice amount is a USD value only for Matic */
    uint256 public amount;
    uint256 public percent;
    uint256 public available;
    uint256 public sold;
    uint256 public total;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public startTimeWhitelist;
    uint256 public endTimeWhitelist;
    uint8 public cType;

    address public facAddress;
    address public ernTreasure;
    bytes32 public root;

    constructor(CollectionData memory collecData) ERC1155(collecData.uri) {
        amount = collecData.amount;
        available = collecData.total;
        total = collecData.total;
        startTime = collecData.startTime;
        endTime = collecData.endTime;
        percent = collecData.percent;
        facAddress = collecData.factoryAddress;

        _setupRole(DEFAULT_ADMIN_ROLE, collecData.admin);
        _setupRole(DEFAULT_ADMIN_ROLE, facAddress);

        addExternalAddresses(
            collecData.token,
            collecData.stone,
            collecData.treasury,
            collecData.moneyHandler
        );
    }

    modifier onlyFactory() {
        require(
            msg.sender == facAddress,
            "This function can only be called by factory contract"
        );
        _;
    }

    function setRoot(bytes32 _root) public onlyRole(DEFAULT_ADMIN_ROLE) {
        root = _root;
    }

    function addExternalAddresses(
        address _token,
        address _stone, // 0x0000000000000000000
        address _treasury,
        address _moneyHandler
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        token = IERC20(_token);
        stone = FarmV2(_stone);
        moneyHand = MoneyHandler(_moneyHandler);
        ernTreasure = _treasury;

        emit SetAddresses(_token, _stone, _treasury, _moneyHandler);
    }

    function recoverToken(address _token)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }

    /// @notice Buy NFT batch
    /// @param _buyer Buyer's address
    /// @param _ids Token IDs to purchase
    function buyBatch(address _buyer, uint256[] memory _ids)
        external
        onlyFactory
    {
        uint256 _quantity = _ids.length;
        uint256[] memory _amts = new uint256[](_quantity);
        require(available > _quantity, "Collection is sold Out");
        for (uint256 i = 0; i < _quantity; i++) {
            require(!(soldCards.contains(_ids[i])), "Token ID already sold");
            _amts[i] = 1;
        }
        require(
            startTime <= block.timestamp && endTime > block.timestamp,
            "Sales are not available at this time"
        );
        address(stone) == address(0)
            ? _withTokenAmt(_buyer, _quantity)
            : _withStonesAmt(_buyer, _quantity);

        _mintBatch(_buyer, _ids, _amts, "");

        available -= _quantity;
        sold += _quantity;
        for (uint256 i = 0; i < _quantity; i++) {
            soldCards.add(_ids[i]);
        }
        emit SoldBatch(address(this), _buyer, _ids, amount);
    }

    /// @notice Buy NFT batch for whitelisted wallets
    /// @param _buyer Buyer's address
    /// @param _ids Token IDs to purchase
    /// @param _proof Merkle tree proof
    function buyWithWhitelistBatch(
        address _buyer,
        uint256[] memory _ids,
        bytes32[] calldata _proof
    ) external onlyFactory {
        uint256 _quantity = _ids.length;
        uint256[] memory _amts = new uint256[](_quantity);
        require(available >= _quantity, "Collection is sold Out");
        require(isWhitelisted(_buyer, _proof), "Wallet is not in whitelist");
        for (uint256 i = 0; i < _quantity; i++) {
            require(!(soldCards.contains(_ids[i])), "Token ID already sold");
            _amts[i] = 1;
        }
        require(
            startTimeWhitelist <= block.timestamp &&
                endTimeWhitelist > block.timestamp,
            "Sales are not available at this time"
        );
        address(stone) == address(0)
            ? _withTokenAmt(_buyer, _quantity)
            : _withStonesAmt(_buyer, _quantity);

        _mintBatch(_buyer, _ids, _amts, "");

        available -= _quantity;
        sold += _quantity;
        for (uint256 i = 0; i < _quantity; i++) {
            soldCards.add(_ids[i]);
        }
        emit SoldBatch(address(this), _buyer, _ids, amount);
    }

    function mint(address to, uint256 _id) external onlyFactory {
        require(!(soldCards.contains(_id)), "This card already sold");
        require(available > 0, "Sold Out");

        _mint(to, _id, 1, "");

        available -= 1;
        sold += 1;
        soldCards.add(_id);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amount_
    ) external onlyFactory {
        require(available > ids.length, "Sold Out");

        for (uint256 i = 0; i < ids.length; i++) {
            require(!(soldCards.contains(ids[i])), "This card already sold");
        }

        _mintBatch(to, ids, amount_, "");

        available -= ids.length;
        sold += ids.length;

        for (uint256 i = 0; i < ids.length; i++) {
            soldCards.add(ids[i]);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Collects stones for buyBatch
    /// @param _buyer Buyer's address
    /// @param _quantity Quantity of NFTs purchased with stones
    function _withStonesAmt(address _buyer, uint256 _quantity) private {
        uint256 stones = stone.rewardedStones(_buyer);
        uint256 _amount = amount * _quantity;
        require(stones >= _amount, "Insufficient stones");
        require(stone.payment(_buyer, _amount), "Payment was unsuccessful");
        emit SoldWithStones(_buyer, _amount);
    }

    function calcPerc(uint256 _amount, uint256 _percent)
        private
        pure
        returns (uint256)
    {
        uint256 sellmul = SafeMath.mul(_amount, _percent);
        uint256 sellAmount = SafeMath.div(sellmul, 10**18);
        return sellAmount;
    }

    function setStarTime(uint256 _starTime)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        startTime = _starTime;

        emit NewStartTime(startTime);
    }

    function setEndTime(uint256 _endTime)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        endTime = _endTime;

        emit NewEndTime(endTime);
    }

    function setWhitelistStarTime(uint256 _starTime)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        startTimeWhitelist = _starTime;
    }

    function setWhitelistEndTime(uint256 _endTime)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        endTimeWhitelist = _endTime;
    }

    function setAmount(uint256 _newAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        amount = _newAmount;

        emit NewUsdAmount(amount);
    }

    /// @notice Collects tokens for buyBatch
    ///   Since it's first sale it does not send anything to moneyhandler
    /// @param _buyer Buyer's address
    /// @param _quantity Quantity of NFTs purchased
    function _withTokenAmt(address _buyer, uint256 _quantity) private {
        // Calculate amount to collect
        uint256 _total = getCardPrice() * _quantity;
        require(token.balanceOf(_buyer) >= _total, "Insufficient funds");
        token.transferFrom(_buyer, ernTreasure, _total);
        emit PaymentTreasure(address(this), _total);
    }

    function getTokenPrice() public view returns (uint256) {
        address priceOracle = IFactory(facAddress).getPriceOracle();
        address tokenFeed = IPriceFeed(priceOracle).getFeed(address(token));
        int256 priceUSD = IPriceFeed(priceOracle).getThePrice(tokenFeed);
        uint256 uPriceUSD = uint256(priceUSD);

        return uPriceUSD;
    }

    function getCardPrice() public view returns (uint256) {
        uint256 tokenPrice = getTokenPrice();
        uint256 result = (amount * (1e44)) / (tokenPrice * (1e18));

        return result;
    }

    function setTotal(uint256 _total) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_total <= total, "Total must decrease");
        require(_total >= sold, "Too many sold");
        total = _total;
        available = total - sold;
    }

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    function isWhitelisted(address _user, bytes32[] calldata proof)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verify(proof, root, keccak256(abi.encodePacked(_user)));
    }
}
