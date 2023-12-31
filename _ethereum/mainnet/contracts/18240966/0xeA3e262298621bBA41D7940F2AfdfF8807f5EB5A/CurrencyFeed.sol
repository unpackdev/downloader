
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

import "./IPriceFeed.sol";
import "./ICurrencyFeed.sol";

contract CurrencyFeed
    is Ownable, ICurrencyFeed
{
    using SafeMath for uint256;

    IPriceFeed private _priceFeed;

    bool private _validRoundCheck;

    constructor() {
        // _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // IERC20 eth;
        // address MAINNET_STETH_USD = 0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8;
        // address MAINNET_WBTC_BTC  = 0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23;
        // address MAINNET_BNB_USD   = 0x14e613AC84a31f709eadbdF89C6CC390fDc9540A;  // 24hr
        // address MAINNET_MATIC_USD = 0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676;  // 1hr
        // address MAINNET_LINK_USD  = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c;  // 1hr


        // MAIN NET USD FEEDS
        addCurrency('ETH'  , 18, 5400  , ERC20(address(0x0))                              , 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, true);     //  1 Hr 
        // addCurrency('DAI'  , 18, 5400  , ERC20(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9), 0x6B175474E89094C44Da98b954EedeAC495271d0F, true);      // 1 hr
        // addCurrency('USDP' , 18, 5400  , ERC20(0x8E870D67F660D95d5be530380D0eC0bd388289E1), 0x09023c0DA49Aaf8fc3fA3ADF34C6A7016D38D5e3, true);      // 1 hr
        addCurrency('USDT' ,  6, 129600, ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7), 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D, true);    // 24 hrs
        // addCurrency('USDC' ,  6, 129600, ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48), 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6, true);    // 24 hrs
        // addCurrency('TUSD' , 18, 129600, ERC20(0x0000000000085d4780B73119b644AE5ecd22b376), 0xec746eCF986E2927Abd291a2A1716c940100f8Ba, true);    // 24 hrs
        // addCurrency('BUSD' , 18, 129600, ERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53), 0x833D8Eb16D306ed1FbB5D7A2E019e106B960965A, true);    // 24 hrs
        // addCurrency('USDD' , 18, 129600, ERC20(0x0C10bF8FcB7Bf5412187A595ab97a3609160b5c6), 0x0ed39A19D2a68b722408d84e4d970827f61E6c0A, true);    // 24 hrs
    }

    bytes32[] internal _currencyIds;
    mapping (bytes32  => Currency)   internal _currency;

    function getPrice(string memory symbol) 
    public view
    returns (Price memory)
    {
        require(address(_priceFeed) != address(0), "Price feed not set");
        Currency memory currency = getCurrency(symbol);
        IPriceFeed.PriceRound memory priceRound = _priceFeed.getRound(currency.priceContract);
        uint256 unitPrice = uint256(priceRound.answer).mul(1e2).div(10**priceRound.decimals);
        return Price(unitPrice, priceRound, currency);
    }

    function setRoundCheck(bool status) 
    public 
    onlyOwner
    {
        _validRoundCheck = status;
    }

    function getRoundCheck() 
    public view 
    returns(bool) 
    {
        return _validRoundCheck;
    }

    function getPrice(string memory symbol, uint80 roundId) 
    public view
    returns (Price memory)
    {
        require(address(_priceFeed) != address(0), "Price feed not set");
        Currency memory currency = getCurrency(symbol);
        IPriceFeed.PriceRound memory priceRound = _priceFeed.getRound(currency.priceContract, roundId);
        if(_validRoundCheck)
        {        
            require(priceRound.startedAt > (block.timestamp - currency.roundThreshold), "RoundId: Invalid");
        }
        uint256 unitPrice = uint256(priceRound.answer).mul(1e2).div(10**priceRound.decimals);
        return Price(unitPrice, priceRound, currency);
    }

    function setPriceFeed(address priceFeed) 
    external 
    onlyOwner 
    {
        _priceFeed = IPriceFeed(priceFeed);
    }

    function addCurrency(string memory symbol, uint8 decimals, uint256 roundThreshold, IERC20 tokenContract, address priceFeedContract, bool enabled) 
    public virtual
    onlyOwner        
    {
        bytes32 _id = _getCurrencyId(symbol);
        require(!_exists(_id), 'Currency: exists');

        _currency[_id] = Currency(symbol, decimals, tokenContract, priceFeedContract, roundThreshold, enabled);
        _currencyIds.push(_id);
    }

    // function updateCurrency(string memory symbol, uint8 decimals, uint256 roundThreshold, IERC20 tokenContract, address priceFeedContract) 
    // public virtual
    // onlyOwner
    // {
    //     bytes32 _id = _getCurrencyId(symbol);
    //     require(_exists(_id), 'Currency: does\'t exist');
    //     for(uint256 i=0; i<_currencyIds.length; i++)
    //     {
    //         if(_id == _currencyIds[i])
    //         {
    //             _currency[_id] = Currency(symbol, decimals, ERC20(address(tokenContract)), priceFeedContract, roundThreshold, true);
    //         }
    //     }
    // }

    function dropCurrency(string memory symbol) 
    public  virtual 
    onlyOwner
    {
        bytes32 _id = _getCurrencyId(symbol);
        require(_exists(_id), 'Currency: does\'t exist');
        for(uint256 i=0; i<_currencyIds.length; i++)
        {
            if(_id == _currencyIds[i])
            {
                _currencyIds[i] = _currencyIds[_currencyIds.length -1];
                _currencyIds.pop();
                delete _currency[_id];
            }
        }
    }

    function getCurrency(string memory symbol) 
    public view 
    returns  (Currency memory) 
    {
        require(exists(symbol), "Currency: doesn't exist");
        Currency memory cur = _currency[_getCurrencyId(symbol)];
        require(cur.enabled,    "Currency: doesn't support");
        return cur;
    }

    function getCurrencies() 
    public view 
    returns (Currency[] memory) 
    {
        Currency[]  memory  _currencies = new Currency[](_currencyIds.length);
        for(uint i=0; i<_currencyIds.length; i++)
        {
            _currencies[i] = _currency[_currencyIds[i]];
        }
        return _currencies;
    }

    function exists(string memory symbol) 
    public view 
    returns(bool) 
    {
        return _exists(_getCurrencyId(symbol));
    }

    function _getCurrencyId(string memory symbol) 
    internal pure 
    returns(bytes32)
    {
        return keccak256(abi.encode(symbol));
    }

    function _exists(bytes32 currencyId) 
    private view 
    returns (bool) 
    {
        for(uint256 i=0; i<_currencyIds.length; i++){
            if( currencyId == _currencyIds[i])
                return true;
        }
        return false;
    }

    function isEnabled(string memory symbol) 
    public view 
    returns(bool) 
    {
        Currency memory _cur = getCurrency(symbol);
        return _cur.enabled;
    }
}