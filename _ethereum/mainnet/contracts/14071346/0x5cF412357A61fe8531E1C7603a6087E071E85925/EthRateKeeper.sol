// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PausableCrowdsale.sol";

// KeeperCompatible.sol imports the functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "./KeeperCompatible.sol";
import "./AggregatorV3Interface.sol";
import "./Ownable.sol";

contract EthRateKeeper is KeeperCompatibleInterface, Ownable {

    address payable crowdsale;

    AggregatorV3Interface internal priceFeed;

    /*
    This multiplication is done every time,
    so we better save the result 
    */
    //uint256 ONE_ETH = 1_000_000_000_000_000_000;
    //uint256 ONE_DOLLAR = 100_000_000;
    uint256 ONE_ETH_TIMES_ONE_DOLLAR= 100_000_000_000_000_000_000_000_000;


    /**
    * Use an interval in seconds and a timestamp to slow execution of Upkeep
    */
    uint private _interval;
    uint public lastTimeStamp;

     /**
     * Network: Mumbai
     * Aggregator: MATIC/USD
     * Address: 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
     */

     /**
     * Network: Polygon
     * Aggregator: MATIC/USD
     * Address: 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
     */

     /**
     * Network: Ethereum
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */


    constructor(uint _updateInterval, address payable _crowdsale) {
      crowdsale = _crowdsale; //Crowdsale to perform upkeep
      priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

      _interval = _updateInterval;
      lastTimeStamp = block.timestamp;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData ) {
        
        //First we need to check if enough time has passed since the last time
        if((block.timestamp - lastTimeStamp) > _interval ) {

        //1-. Get current Eth rate in crowdsale
        PausableCrowdsale c = PausableCrowdsale(crowdsale); 
        uint256 ethRate = c.rate();

        //2-. Get current matic price
        int maticPrice = getLatestPrice();

        //3-. Do conversion
        uint256 result = convert(maticPrice);

        //4-. Compare conversion against current eth rate
        return(ethRate != result, abi.encode(result));
    }
    
        return(false, bytes(""));
    }

    function performUpkeep(bytes calldata performData ) external override {
        //Perform some revalidation to ensure conditions are met
        require((block.timestamp - lastTimeStamp) > _interval, "Not enough time elapsed since last upkeep");
        
        //update timestamp
        lastTimeStamp = block.timestamp;
        uint256 newRate = abi.decode(performData, (uint256));

        //2-. Get current matic price
        int maticPrice = getLatestPrice();

        //3-. Do conversion
        uint256 result = convert(maticPrice);

        //Perform some revalidation to ensure conditions are met
        require(newRate == result, "Perform data from checkUpkeep not matching");

        //Load the smart contract
        PausableCrowdsale c = PausableCrowdsale(crowdsale); 
        
        //Update new rate
        c.setNewEthRate(newRate);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() internal view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     * Returns the number of decimals present in the response value
     */
    function decimals() internal view returns (uint8 _decimals) {
        _decimals = priceFeed.decimals();
        return _decimals;
    }


    /**
     * @dev Perform end step of cross multiplication
     * @param _maticPrice Current fiat value of matic
     */
    function convert(int _maticPrice) internal view returns (uint256 result){

        result = ONE_ETH_TIMES_ONE_DOLLAR / uint256(_maticPrice);
    }

    /**
     * @dev Sets a new interval at which the upkeep must be checked
     * @param _newInterval New interval, can't be 0
     */
    function updateInterval(uint _newInterval) public onlyOwner {
        require(_newInterval != 0, "updateInterval: New interval can't 0");
        _interval = _newInterval;
    }
    
     /**
     * @dev Return the current interval at which upkeep must be checked
     */
    function interval()view public returns(uint) {
        return _interval;
    }


}