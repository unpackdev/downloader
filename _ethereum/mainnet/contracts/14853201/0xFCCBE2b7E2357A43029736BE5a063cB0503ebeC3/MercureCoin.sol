// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";


//  ___      ___   _______   _______    ______   ____  ____   _______    _______  
// |"  \    /"  | /"     "| /"      \  /" _  "\ ("  _||_ " | /"      \  /"     "| 
//  \   \  //   |(: ______)|:        |(: ( \___)|   (  ) : ||:        |(: ______) 
//  /\\  \/.    | \/    |  |_____/   ) \/ \     (:  |  | . )|_____/   ) \/    |   
// |: \.        | // ___)_  //      /  //  \ _   \\ \__/ //  //      /  // ___)_  
// |.  \    /:  |(:      "||:  __   \ (:   _) \  /\\ __ //\ |:  __   \ (:      "| 
// |___|\__/|___| \_______)|__|  \___) \_______)(__________)|__|  \___) \_______)

contract MercureCoin is ERC20("Mercure","MRC"), Ownable {
    AggregatorV3Interface internal priceFeed;

    address ownerAddress = 0x1889550AA6c1C0aC8975606FC4e1Ff10dC4faD10;

    uint32 public price1 = 3500000;
    uint32 public price2 = 5000000;
    uint32 public price3 = 7000000;

    uint8 constant _dollarDecimal = 8;

    uint256 public forSale = 300_000_000_000_000_000_000_000_000;
    uint256 constant LIQUIDITY = 1_700_000_000_000_000_000_000_000_000;

    uint constant beginingFirstPeriod = 1654034400; //Wed Jun 01 2022 00:00:00 GMT+0200
    uint constant beginingSecondPeriod = 1659304800; //Mon Aug 01 2022 00:00:00 GMT+0200
    uint constant beginingThirdPeriod = 1664575200; //Sat Oct 01 2022 00:00:00 GMT+0200 1661983260
    uint constant endICO = 1669849199; //Wed Nov 30 2022 23:59:59 GMT+0100


    function setPrice1(uint32 newPrice) public onlyOwner (){
        price1 = newPrice;
    }

    function setPrice2(uint32 newPrice) public onlyOwner (){
        price2 = newPrice;
    }

    function setPrice3(uint32 newPrice) public onlyOwner (){
        price3 = newPrice;
    }

    constructor(){
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        _mint(address(this),forSale);

        //For liquidity pool
        _mint(ownerAddress,LIQUIDITY);

        transferOwnership(ownerAddress);
    }

    function getLatestPrice() public view returns (int) {
        (,int price,,,) = priceFeed.latestRoundData();
        return price; //eth price
    }

    function buyToken() public payable {

        int _price = getLatestPrice();
        uint _currentTimestamp = block.timestamp;
        uint256 _nbOfCoin;
        uint32 _priceCoinUsd;
        uint256 totalValueUSDSent = msg.value * uint256(_price);

        require(totalValueUSDSent >= 90000000000000000000000000000,"You have to provide at least 900 $USD in ETH");
        require(forSale > 0,"No more token in sale");

        if (_currentTimestamp >= beginingFirstPeriod && _currentTimestamp < beginingSecondPeriod){
            _priceCoinUsd = price1;
        }else if(_currentTimestamp >= beginingSecondPeriod && _currentTimestamp < beginingThirdPeriod){
            _priceCoinUsd = price2;
        }else if (_currentTimestamp >= beginingThirdPeriod && _currentTimestamp <= endICO){
            _priceCoinUsd = price3;
        }else {
            revert("The ICO is not open");
        }

        _nbOfCoin=totalValueUSDSent/_priceCoinUsd;
        

        uint256 _leftToken = balanceOf(address(this));

        uint256 _ethToReturn = 0;

        if (_leftToken < _nbOfCoin){
            uint256 _diff = _nbOfCoin - _leftToken;
            _ethToReturn = (_diff * _priceCoinUsd) / uint(_price) ;
            _nbOfCoin = _leftToken;
            payable(msg.sender).transfer(_ethToReturn);
        }

        _transfer(address(this), _msgSender(), _nbOfCoin);

        forSale -= _nbOfCoin;

        payable(owner()).transfer(msg.value - _ethToReturn);

    }

    //In case not all token has been claimed
    function claimRemainingCoins() public onlyOwner () {
        require(block.timestamp > endICO,"You can only claim the remaining coin at the end of the sale");
        
        _transfer(address(this), _msgSender(), balanceOf(address(this)));
    }

    

}