// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./AggregateV3Interface.sol";
import "./IERC20Extended.sol";
import "./IKeplerERC20.sol";
import "./ITreasury.sol";
import "./IUniswapV2Pair.sol";


contract SPV is Ownable {
    
    using SafeERC20 for IERC20Extended;
    using SafeMath for uint;

    event TokenAdded( address indexed token, PRICETYPE indexed priceType, uint indexed price );
    event TokenPriceUpdate( address indexed token, uint indexed price );
    event TokenPriceTypeUpdate( address indexed token, PRICETYPE indexed priceType );
    event TokenRemoved( address indexed token );
    event ValueAudited( uint indexed total );
    event TreasuryWithdrawn( address indexed token, uint indexed amount );
    event TreasuryReturned( address indexed token, uint indexed amount );

    uint public constant keeperDecimals = 9;

    enum PRICETYPE { STABLE, CHAINLINK, UNISWAP, MANUAL }

    struct TokenPrice {
        address token;
        PRICETYPE priceType;
        uint price;     // At keeper decimals
    }

    TokenPrice[] public tokens;

    struct ChainlinkPriceFeed {
        address feed;
        uint decimals;
    }
    mapping( address => ChainlinkPriceFeed ) public chainlinkPriceFeeds;

    mapping( address => address ) public uniswapPools;   // The other token must be a stablecoin

    address public immutable treasury;
    address public SPVWallet;
    uint public totalValue;
    uint public totalProfit;

    uint public spvRecordedValue;
    uint public recordTime;
    uint public profitInterval;
    bool public allowUpdate;    // False when SPV is transferring funds


    constructor (address _treasury, address _USDC, address _USDT, address _DAI, address _SPVWallet, uint _profitInterval) {
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _SPVWallet != address(0) );
        SPVWallet = _SPVWallet;

        tokens.push(TokenPrice({
            token: _USDC,
            priceType: PRICETYPE.STABLE,
            price: 10 ** keeperDecimals
        }));
        tokens.push(TokenPrice({
            token: _USDT,
            priceType: PRICETYPE.STABLE,
            price: 10 ** keeperDecimals
        }));
        tokens.push(TokenPrice({
            token: _DAI,
            priceType: PRICETYPE.STABLE,
            price: 10 ** keeperDecimals
        }));

        recordTime = block.timestamp;
        require( _profitInterval > 0, "Interval cannot be 0" );
        profitInterval = _profitInterval;
        spvRecordedValue = 0;
        allowUpdate = true;
        updateTotalValue();
    }


    function enableUpdates() external onlyOwner() {
        allowUpdate = true;
    }


    function disableUpdates() external onlyOwner() {
        allowUpdate = false;
    }


    function setInterval( uint _profitInterval ) external onlyOwner() {
        require( _profitInterval > 0, "Interval cannot be 0" );
        profitInterval = _profitInterval;
    }


    function chainlinkTokenPrice(address _token) public view returns (uint) {
        ( , int price, , , ) = AggregatorV3Interface( chainlinkPriceFeeds[_token].feed ).latestRoundData();
        return uint(price).mul( 10 ** keeperDecimals ).div( 10 ** chainlinkPriceFeeds[_token].decimals );
    }


    function uniswapTokenPrice(address _token) public view returns (uint) {
        address _pair = uniswapPools[_token];
        ( uint reserve0, uint reserve1, ) = IUniswapV2Pair( _pair ).getReserves();
        uint reserve;
        address reserveToken;
        uint tokenAmount;
        if ( IUniswapV2Pair( _pair ).token0() == _token ) {
            reserveToken = IUniswapV2Pair( _pair ).token1();
            reserve = reserve1;
            tokenAmount = reserve0;
        } else {
            reserveToken = IUniswapV2Pair( _pair ).token0();
            reserve = reserve0;
            tokenAmount = reserve1;
        }
        return reserve.mul(10 ** keeperDecimals).mul( 10 ** IERC20Extended(_token).decimals() ).div( tokenAmount ).div( 10 ** IERC20Extended(reserveToken).decimals() );
    }



    function setNewTokenPrice(address _token, PRICETYPE _priceType, address _feedOrPool, uint _decimals, uint _price) internal returns (uint tokenPrice) {
        if (_priceType == PRICETYPE.STABLE) {
            tokenPrice = 10 ** keeperDecimals;
        } else if (_priceType == PRICETYPE.CHAINLINK) {
            chainlinkPriceFeeds[_token] = ChainlinkPriceFeed({
                feed: _feedOrPool,
                decimals: _decimals
            });
            tokenPrice = chainlinkTokenPrice(_token);
        } else if (_priceType == PRICETYPE.UNISWAP) {
            uniswapPools[_token] = _feedOrPool;
            tokenPrice = uniswapTokenPrice(_token);
        } else if (_priceType == PRICETYPE.MANUAL) {
            tokenPrice = _price;
        } else {
            tokenPrice = 0;
        }
    }


    function addToken(address _token, PRICETYPE _priceType, address _feedOrPool, uint _decimals, uint _price) external onlyOwner() {
        uint tokenPrice = setNewTokenPrice(_token, _priceType, _feedOrPool, _decimals, _price);
        require(tokenPrice > 0, "Token price cannot be 0");

        tokens.push(TokenPrice({
            token: _token,
            priceType: _priceType,
            price: tokenPrice
        }));

        updateTotalValue();
        emit TokenAdded(_token, _priceType, tokenPrice);
    }


    function updateTokenPrice( uint _index, address _token, uint _price ) external onlyOwner() {
        require( _token == tokens[ _index ].token, "Wrong token" );
        require( tokens[ _index ].priceType == PRICETYPE.MANUAL, "Only manual tokens can be updated" );
        tokens[ _index ].price = _price;

        updateTotalValue();
        emit TokenPriceUpdate(_token, _price);
    }


    function updateTokenPriceType( uint _index, address _token, PRICETYPE _priceType, address _feedOrPool, uint _decimals, uint _price ) external onlyOwner() {
        require( _token == tokens[ _index ].token, "Wrong token" );
        tokens[ _index ].priceType = _priceType;

        uint tokenPrice = setNewTokenPrice(_token, _priceType, _feedOrPool, _decimals, _price);
        require(tokenPrice > 0, "Token price cannot be 0");
        tokens[ _index ].price = tokenPrice;

        updateTotalValue();
        emit TokenPriceTypeUpdate(_token, _priceType);
        emit TokenPriceUpdate(_token, tokenPrice);
    }


    function removeToken( uint _index, address _token ) external onlyOwner() {
        require( _token == tokens[ _index ].token, "Wrong token" );
        tokens[ _index ] = tokens[tokens.length-1];
        tokens.pop();
        updateTotalValue();
        emit TokenRemoved(_token);
    }


    function getTokenBalance( uint _index ) internal view returns (uint) {
        address _token = tokens[ _index ].token;
        return IERC20Extended(_token).balanceOf( SPVWallet ).mul(tokens[ _index ].price).div( 10 ** IERC20Extended( _token ).decimals() );
    }


    function auditTotalValue() external {
        if ( allowUpdate ) {
            uint newValue;
            for ( uint i = 0; i < tokens.length; i++ ) {
                PRICETYPE priceType = tokens[i].priceType;
                if (priceType == PRICETYPE.CHAINLINK) {
                    tokens[i].price = chainlinkTokenPrice(tokens[i].token);
                } else if (priceType == PRICETYPE.UNISWAP) {
                    tokens[i].price = uniswapTokenPrice(tokens[i].token);
                }
                newValue = newValue.add( getTokenBalance(i) );
            }
            totalValue = newValue;
            emit ValueAudited(totalValue);
        }
    }


    function calculateProfits() external {
        require( recordTime.add( profitInterval ) <= block.timestamp, "Not yet" );
        require( msg.sender == SPVWallet || msg.sender == ITreasury( treasury ).DAO(), "Not allowed" );
        recordTime = block.timestamp;
        updateTotalValue();
        uint currentValue;
        uint treasuryDebt = ITreasury( treasury ).spvDebt();
        if ( treasuryDebt > totalValue ) {
            currentValue = 0;
        } else {
            currentValue = totalValue.sub(treasuryDebt);
        }
        if ( currentValue > spvRecordedValue ) {
            uint profit = currentValue.sub( spvRecordedValue );
            spvRecordedValue = currentValue;
            totalProfit = totalProfit.add(profit);
        }
    }


    function treasuryWithdraw( uint _index, address _token, uint _amount ) external {
        require( msg.sender == SPVWallet, "Only SPV Wallet allowed" );
        require( _token == tokens[ _index ].token, "Wrong token" );
        ITreasury( treasury ).SPVWithdraw( _token, _amount );
        updateTotalValue();
        emit TreasuryWithdrawn( _token, _amount );
    }


    function returnToTreasury( uint _index, address _token, uint _amount ) external {
        require( _token == tokens[ _index ].token, "Wrong token" );
        require( msg.sender == SPVWallet, "Only SPV Wallet can return." );
        IERC20Extended( _token ).safeTransferFrom( msg.sender, address(this), _amount );
        IERC20Extended( _token ).approve( treasury, _amount );
        ITreasury( treasury ).SPVDeposit( _token, _amount );
        updateTotalValue();
        emit TreasuryReturned( _token, _amount );
    }


    function migrateTokens( address newSPV ) external onlyOwner() {
        for ( uint i = 0; i < tokens.length; i++ ) {
            address _token = tokens[ i ].token;
            IERC20Extended(_token).transfer(newSPV, IERC20Extended(_token).balanceOf( address(this) ) );
        }
        safeTransferETH(newSPV, address(this).balance );
    }


    function updateTotalValue() internal {
        if ( allowUpdate ) {
            uint newValue;
            for ( uint i = 0; i < tokens.length; i++ ) {
                newValue = newValue.add( getTokenBalance(i) );
            }
            totalValue = newValue;
        }
    }


    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }

}