//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./InterestInterface.sol";
import "./IMultiplierCalculator.sol";
import "./SafeMath.sol";
import "./Admin.sol";

/** @title Interest Module V2 for Paladin PalPools  */
/// @author Paladin
contract InterestCalculatorV2 is InterestInterface, Admin {
    using SafeMath for uint;


    bool private initiated = false;

    mapping(address => bool) public useMultiplier;

    uint public blocksPerYear = 2336000;

    uint public multiplierPerBlock;
    uint public baseRatePerBlock;
    uint public jumpMultiplierPerBlock;

    mapping(address => IMultiplierCalculator) public multiplierForPool;
    

    constructor(){
        admin = msg.sender;
    }


    function initiate(
        uint multiplierPerYear,
        uint baseRatePerYear,
        uint jumpMultiplierPerYear,
        address[] memory palPools,
        address[] memory multiplierCalculators
    ) external adminOnly {
        require(!initiated, "Already initiated");
        require(palPools.length == multiplierCalculators.length);

        multiplierPerBlock = multiplierPerYear.div(blocksPerYear);
        baseRatePerBlock = baseRatePerYear.div(blocksPerYear);
        jumpMultiplierPerBlock = jumpMultiplierPerYear.div(blocksPerYear);

        for(uint i = 0; i < palPools.length; i++){
            multiplierForPool[palPools[i]] = IMultiplierCalculator(multiplierCalculators[i]);
        }

        initiated = true;
    }


    /**
    * @notice Calculates the Utilization Rate of a PalPool
    * @dev Calculates the Utilization Rate of a PalPool depending of Cash, Borrows & Reserves
    * @param cash Cash amount of the calling PalPool
    * @param borrows Total Borrowed amount of the calling PalPool
    * @param reserves Total Reserves amount of the calling PalPool
    * @return uint : Utilisation Rate of the Pool (scale 1e18)
    */
    function utilizationRate(uint cash, uint borrows, uint reserves) public pure returns(uint){
        //If no funds are borrowed, the Pool is not used
        if(borrows == 0){
            return 0;
        }
        // Utilization Rate = Borrows / (Cash + Borrows - Reserves)
        return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
    }

    /**
    * @notice Calculates the Supply Rate for the calling PalPool
    * @dev Calculates the Supply Rate depending on the Pool Borrow Rate & Reserve Factor
    * @param palPool Address of the PalPool calling the function
    * @param cash Cash amount of the calling PalPool
    * @param borrows Total Borrowed amount of the calling PalPool
    * @param reserves Total Reserves amount of the calling PalPool
    * @param reserveFactor Reserve Factor of the calling PalPool
    * @return uint : Supply Rate for the Pool (scale 1e18)
    */
    function getSupplyRate(address palPool, uint cash, uint borrows, uint reserves, uint reserveFactor) external view override returns(uint){
        //Fetch the Pool Utilisation Rate & Borrow Rate
        uint _utilRate = utilizationRate(cash, borrows, reserves);
        uint _bRate = _borrowRate(palPool, cash, borrows, reserves);

        //Supply Rate = Utilization Rate * (Borrow Rate * (1 - Reserve Factor))
        uint _tempRate = _bRate.mul(uint(1e18).sub(reserveFactor)).div(1e18);
        return _utilRate.mul(_tempRate).div(1e18);
    }
    
    /**
    * @notice Get the Borrow Rate for a PalPool depending on the given parameters
    * @dev Calls the internal fucntion _borrowRate
    * @param palPool Address of the PalPool calling the function
    * @param cash Cash amount of the calling PalPool
    * @param borrows Total Borrowed amount of the calling PalPool
    * @param reserves Total Reserves amount of the calling PalPool
    * @return uint : Borrow Rate for the Pool (scale 1e18)
    */
    function getBorrowRate(address palPool, uint cash, uint borrows, uint reserves) external view override returns(uint){
        //Internal call
        return _borrowRate(palPool, cash, borrows, reserves);
    }

    /**
    * @dev Calculates the Borrow Rate for the PalPool, depending on the utilisation rate & the kink value.
    * @param palPool Address of the PalPool calling the function
    * @param cash Cash amount of the calling PalPool
    * @param borrows Total Borrowed amount of the calling PalPool
    * @param reserves Total Reserves amount of the calling PalPool
    * @return uint : Borrow Rate for the Pool (scale 1e18)
    */
    function _borrowRate(address palPool, uint cash, uint borrows, uint reserves) internal view returns(uint){
        //Fetch the utilisation rate
        uint _utilRate = utilizationRate(cash, borrows, reserves);

        if(useMultiplier[palPool]){
            // multiplier model calculation
            uint _govMultiplier = multiplierForPool[palPool].getCurrentMultiplier();

            return (_utilRate.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock)).mul(_govMultiplier).div(1e18);
        
        
        } else if(_utilRate > 0.8e18){
            // jumpRate model calculation 
            uint _tempRate = uint256(0.8e18).mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);

            return (_utilRate.sub(0.8e18).mul(jumpMultiplierPerBlock).div(1e18)).add(_tempRate);
        }

        //Base rate calculation
        return _utilRate.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
    }


    //Admin functions


    function activateMultiplier(address palPool) external adminOnly {
        require(!useMultiplier[palPool], "Already activated");
        useMultiplier[palPool] = true;
    }

    function stopMultiplier(address palPool) external adminOnly {
        require(useMultiplier[palPool], "Not activated");
        useMultiplier[palPool] = false;
    }


    function updateBaseValues(uint newMultiplierPerYear, uint newBaseRatePerYear, uint jumpMultiplierPerYear) external adminOnly {
        multiplierPerBlock = newMultiplierPerYear.div(blocksPerYear);
        baseRatePerBlock = newBaseRatePerYear.div(blocksPerYear);
        jumpMultiplierPerBlock = jumpMultiplierPerYear.div(blocksPerYear);
    }


    function updateBlocksPerYear(uint newBlockPerYear) external adminOnly {
        blocksPerYear = newBlockPerYear;
    }

    function updatePoolMultiplierCalculator(address palPool, address newMultiplierCalculator) external adminOnly {
        //either update already existing item, or add a new one
        multiplierForPool[palPool] = IMultiplierCalculator(newMultiplierCalculator);
    }
}