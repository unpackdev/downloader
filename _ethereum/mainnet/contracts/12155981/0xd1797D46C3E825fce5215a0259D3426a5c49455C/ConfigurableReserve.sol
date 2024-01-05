// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Ownable.sol";

import "./IConfigurableReserve.sol";
import "./IPrizePool.sol";

/// @title Implementation of IConfigurable reserve
/// @notice Provides an Ownable configurable reserve for prize pools. This includes an opt-out default rate for prize pools. 
/// For flexibility this includes a specified withdraw Strategist address which can be set by the owner.
/// The prize pool Reserve can withdrawn by the owner or the reserve strategist. 
contract ConfigurableReserve is IConfigurableReserve, Ownable {
    
    /// @notice Storage of Reserve Rate Mantissa associated with a Prize Pool
    mapping(address => ReserveRate) public prizePoolMantissas;

    /// @notice Storage of the address of a withdrawal strategist 
    address public withdrawStrategist;

    /// @notice Storage of the default rate mantissa
    uint224 public defaultReserveRateMantissa;

    constructor() Ownable(){

    }

    /// @notice Returns the reserve rate for a particular source
    /// @param source The source for which the reserve rate should be return.  These are normally prize pools.
    /// @return The reserve rate as a fixed point 18 number, like Ether.  A rate of 0.05 = 50000000000000000
    function reserveRateMantissa(address source) external override view returns (uint256){
        if(!prizePoolMantissas[source].useCustom){
            return uint256(defaultReserveRateMantissa);
        }
        // else return the custom rate
        return prizePoolMantissas[source].rateMantissa;
    }

    /// @notice Allows the owner of the contract to set the reserve rates for a given set of sources.
    /// @dev Length must match sources param.
    /// @param sources The sources for which to set the reserve rates.
    /// @param _reserveRates The respective ReserveRates for the sources.  
    function setReserveRateMantissa(address[] calldata sources,  uint224[] calldata _reserveRates, bool[] calldata useCustom) external override onlyOwner{
        for(uint256 i = 0; i <  sources.length; i++){
            prizePoolMantissas[sources[i]].rateMantissa = _reserveRates[i];
            prizePoolMantissas[sources[i]].useCustom = useCustom[i];
            emit ReserveRateMantissaSet(sources[i], _reserveRates[i], useCustom[i]);
        }
    }

    /// @notice Allows the owner of the contract to set the withdrawal strategy address
    /// @param _strategist The new withdrawal strategist address
    function setWithdrawStrategist(address _strategist) external override onlyOwner{
        withdrawStrategist = _strategist;
        emit ReserveWithdrawStrategistChanged(_strategist);
    }

    /// @notice Calls withdrawReserve on the Prize Pool
    /// @param prizePool The Prize Pool to withdraw reserve
    /// @param to The reserve transfer destination address
    /// @return The amount of reserve withdrawn from the prize pool
    function withdrawReserve(address prizePool, address to) external override onlyOwnerOrWithdrawStrategist returns (uint256){
        return PrizePoolInterface(prizePool).withdrawReserve(to);
    }

    /// @notice Sets the default ReserveRate mantissa
    /// @param _reserveRateMantissa The new default reserve rate mantissa
    function setDefaultReserveRateMantissa(uint224 _reserveRateMantissa) external override onlyOwner{
        defaultReserveRateMantissa = _reserveRateMantissa;
        emit DefaultReserveRateMantissaSet(_reserveRateMantissa);
    }

    /// @notice Only allows the owner or current strategist to call a function
    modifier onlyOwnerOrWithdrawStrategist(){
        require(msg.sender == owner() || msg.sender == withdrawStrategist, "!onlyOwnerOrWithdrawStrategist");
        _;
    }
}