// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "./IERC20Upgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./SafeMathUpgradeable.sol";


contract PayRueERC721 is ERC721Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint;

    IERC20Upgradeable public propelToken;

    CountersUpgradeable.Counter private _tokenIds;

    mapping (uint => TokenMeta) private _tokenMeta;

    string public baseURI;

    struct TokenMeta {
        uint id;
        uint price;
        string name;
        string uri;
        bool sale;
        bool priceInPropel; // deprecated
        address currency;  // 0 -> native blockchain currency
        address minter; // person who gets royalties
        uint royalty; // 100 -> 1.0%
    }

    address public commissionReceiverAddress; // platfrom fee receiver
    mapping (address => bool) public activeCurrencies; // 0 -> native blockchain currency
    mapping (address => uint) public sellCurrencyFees; // 100 -> 1.0%
    mapping (address => uint) public buyCurrencyFees; // 100 -> 1.0%
    address public propelMigrationAddress;

    /**
     *  Constructor
     */

    function initialize(
        address _propelTokenAddress,
        address _commissionReceiverAddress) public initializer {

        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        ERC721Upgradeable.__ERC721_init("PAYRUESTORE", "PAYRUESTORE");
        propelToken = IERC20Upgradeable(_propelTokenAddress);
        commissionReceiverAddress = _commissionReceiverAddress;
    }

    /**
     * Modifier
     */

    modifier onlyTokenOwner(uint _tokenId) {
        require(ownerOf(_tokenId) == _msgSender(), "PayRueERC721: Not an owner");
        _;
    }

    modifier activeCurrency(address _tokenAddress) {
        require(activeCurrencies[_tokenAddress], "PayRueERC721: Currency is not active");
        _;
    }

    modifier canBuy(uint _tokenId) {
        require(_msgSender() != address(0) && _msgSender() != ownerOf(_tokenId), "PayRueERC721: Cannot buy");
        require(_tokenMeta[_tokenId].sale, "PayRueERC721: Not on sale");
        _;
    }

    /**
     * Only owner
     */

    function setBaseURI(string memory _newBaseURI) public virtual onlyOwner {
        baseURI = _newBaseURI;
    }

    function setComissionReceiverAddress(address _commissionReceiverAddress) public onlyOwner {
        commissionReceiverAddress = _commissionReceiverAddress;
    }

    function setCurrency(address _currency, bool _active, uint _sellFee, uint _buyFee) public onlyOwner {
        require(_sellFee <= 10000, "PayRueERC721: Incorrect sell fee");
        require(_buyFee <= 10000, "PayRueERC721: Incorrect buy fee");
        activeCurrencies[_currency] = _active;
        sellCurrencyFees[_currency] = _sellFee;
        buyCurrencyFees[_currency] = _buyFee;
    }

    /**
     * Only token owner
     */

    function resellToken(uint _tokenId, uint _price) public payable nonReentrant onlyTokenOwner(_tokenId) activeCurrency(address(0))  {
        require(_price > 0, "PayRueERC721: Incorrect price");

        uint fee = getSellFee(address(0), _price);
        require(msg.value == fee, "PayRueERC721: Invalid commission value");

        AddressUpgradeable.sendValue(payable(commissionReceiverAddress), msg.value);

        setTokenSale(_tokenId, address(0), _price, true);
    }

    function resellTokenByToken(uint _tokenId, address _currency, uint _price) public nonReentrant onlyTokenOwner(_tokenId) activeCurrency(_currency) {
        require(_price > 0, "PayRueERC721: Incorrect price");

        uint fee = getSellFee(_currency, _price);
        require(
            IERC20Upgradeable(_currency).transferFrom(_msgSender(),  payable(commissionReceiverAddress), fee),
            "PayRueERC721: Token transfer failed"
        );
        
        setTokenSale(_tokenId, _currency, _price, true);
    }

    function setSaleOff(uint _tokenId) public onlyTokenOwner(_tokenId) {
        _tokenMeta[_tokenId].sale = false;
    }

    /**
     * Anybody
     */

    function purchaseToken(
        uint _tokenId
    ) public payable nonReentrant activeCurrency(address(0)) canBuy(_tokenId) {

        require(!_tokenMeta[_tokenId].priceInPropel, "PayRueERC721: Migration required");

        (address currency, uint fee) = getBuyFee(_tokenId);
        require(currency == address(0), "PayRueERC721: Wrong currency");
        uint price = _tokenMeta[_tokenId].price;

        require(msg.value == price.add(fee), "PayRueERC721: Inorrect funds amount sent");
        address tokenSeller = ownerOf(_tokenId);

        (address minter, uint royalty) = getRoyalty(_tokenId);
        uint payout = price.sub(royalty);

        AddressUpgradeable.sendValue(payable(tokenSeller), payout);
        if (royalty > 0) {
            AddressUpgradeable.sendValue(payable(minter), royalty);
        }
        if (fee > 0) {
            AddressUpgradeable.sendValue(payable(commissionReceiverAddress), fee);
        }
        _transfer(tokenSeller, _msgSender(), _tokenId);
    }

    function purchaseTokenByToken(
        uint _tokenId,
        address _currency
    ) public nonReentrant activeCurrency(_currency) canBuy(_tokenId) {

        require(!_tokenMeta[_tokenId].priceInPropel, "PayRueERC721: Migration required");

        (address currency, uint fee) = getBuyFee(_tokenId);
        require(currency == _currency, "PayRueERC721: Wrong currency");
        uint price = _tokenMeta[_tokenId].price;

        address tokenSeller = ownerOf(_tokenId);

        (address minter, uint royalty) = getRoyalty(_tokenId);
        uint payout = price.sub(royalty);

        require(
            IERC20Upgradeable(_currency).transferFrom(_msgSender(), payable(tokenSeller),
            payout ),
            "PayRueERC721: Cannot Transfer Token"
        );

        if (royalty > 0) {
            require(
                IERC20Upgradeable(_currency).transferFrom(_msgSender(), payable(minter),
                royalty ),
                "PayRueERC721: Cannot Transfer Token"
            );
        }

        if (fee > 0) {
            require(
                IERC20Upgradeable(_currency).transferFrom(_msgSender(), payable(commissionReceiverAddress),
                fee ),
                "PayRueERC721: Cannot Transfer Token"
            );
        }

        _transfer(tokenSeller, _msgSender(), _tokenId);
    }

    function mintCollectable(
        address _owner,
        string memory _tokenURI,
        string memory _name,
        uint _price,
        uint _roaylty
    ) public payable nonReentrant activeCurrency(address(0)) returns (uint) {
        require(_price > 0, "PayRueERC721: Incorrect price");
        require(_roaylty <= 3000, "PayRueERC721: Incorrect royalty");

        uint fee = getSellFee(address(0), _price);
        require(msg.value == fee, "PayRueERC721: Incorrect fee sent");

        AddressUpgradeable.sendValue(payable(commissionReceiverAddress), msg.value);
        _tokenIds.increment();

        uint newItemId = _tokenIds.current();
        _mint(_owner, newItemId);

        TokenMeta memory meta = TokenMeta(
            newItemId,
            _price, 
            _name, 
            _tokenURI, 
            true, 
            false, 
            address(0),
            _owner,
            _roaylty
        );
        _setTokenMeta(newItemId, meta);

        return newItemId;
    }

    function mintCollectableByToken(
        address _owner,
        string memory _tokenURI,
        string memory _name,
        address _currency,
        uint _price,
        uint _roaylty
    ) public nonReentrant activeCurrency(_currency) returns (uint) {
        require(_price > 0, "PayRueERC721: Incorrect price");
        require(_roaylty <= 3000, "PayRueERC721: Incorrect royalty");

        uint fee = getSellFee(_currency, _price);
        require(
            IERC20Upgradeable(_currency).transferFrom(_msgSender(), payable(commissionReceiverAddress), fee ),
            "PayRueERC721: Cannot transfer token"
        );
        _tokenIds.increment();

        uint newItemId = _tokenIds.current();
        _mint(_owner, newItemId);

        TokenMeta memory meta = TokenMeta(
            newItemId, 
            _price, 
            _name,
            _tokenURI,
            true,
            false,
            _currency,
            _owner,
            _roaylty
        );

        _setTokenMeta(newItemId, meta);

        return newItemId;
    }

    /**
     * Migration
     */

    function migratePropelSale(
        uint _tokenId
    ) public activeCurrency(address(propelToken)) {
        require(_tokenMeta[_tokenId].priceInPropel, "PayRueERC721: Migration not needed");
        require(_tokenMeta[_tokenId].sale, "PayRueERC721: Migration not needed");

        _tokenMeta[_tokenId].currency = address(propelToken);
    }

    /**
     * View
     */

    function getAllOnSale() public view virtual returns( TokenMeta[] memory ) {
        TokenMeta[] memory tokensOnSale = new TokenMeta[](_tokenIds.current());
        uint counter = 0;

        for(uint i = 1; i < _tokenIds.current() + 1; i++) {
            if(_tokenMeta[i].sale == true) {
                tokensOnSale[counter] = _tokenMeta[i];
                counter++;
            }
        }
        return tokensOnSale;
    }

    function tokenPrice(uint tokenId) public view virtual returns (uint) {
        require(_exists(tokenId), "PayRueERC721: Price query for nonexistent token");
        return _tokenMeta[tokenId].price;
    }

    function tokenMeta(uint _tokenId) public view returns (TokenMeta memory) {
        require(_exists(_tokenId), "PayRueERC721: Price query for nonexistent token");
        return _tokenMeta[_tokenId];
    }

    function getSellFee(address _currency, uint _price) public view activeCurrency(_currency) returns (uint) {
        return _price.mul(sellCurrencyFees[_currency]).div(10000);
    }

    function getBuyFee(uint _tokenId) public view returns (address, uint) {
        require(_exists(_tokenId), "PayRueERC721: Token not exists");
        TokenMeta memory token = _tokenMeta[_tokenId];
        address currency = token.currency;
        uint price = token.price;
        return (currency, price.mul(buyCurrencyFees[currency]).div(10000));
    }

    function getRoyalty(uint _tokenId) public view returns (address, uint) {
        uint price = _tokenMeta[_tokenId].price;
        uint royalty = _tokenMeta[_tokenId].royalty;
        address minter = _tokenMeta[_tokenId].minter;
        return (minter, price.mul(royalty).div(10000));
    }

    /**
     * Private
     */

    function _setTokenMeta(uint _tokenId, TokenMeta memory _meta) private {
        _tokenMeta[_tokenId] = _meta;
    }

    function setTokenSale(uint _tokenId, address _currency, uint _price, bool _sale) private {
        _tokenMeta[_tokenId].sale = _sale;
        _tokenMeta[_tokenId].currency = _currency;
        _tokenMeta[_tokenId].price = _price;
    }

    /**
     * Virtual
     */

    function _baseURI() internal view override virtual returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint tokenId
    ) internal virtual override {
        _tokenMeta[tokenId].sale = false;
    }
}
