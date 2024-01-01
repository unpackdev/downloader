pragma solidity ^0.8.9;

import "./Ownable.sol";

/*
        
 ________      _______       _______       ________      ________      
|\   ____\    |\  ___ \     |\  ___ \     |\   ____\    |\   ____\     
\ \  \___|    \ \   __/|    \ \   __/|    \ \  \___|    \ \  \___|_    
 \ \  \  ___   \ \  \_|/__   \ \  \_|/__   \ \  \  ___   \ \_____  \   
  \ \  \|\  \   \ \  \_|\ \   \ \  \_|\ \   \ \  \|\  \   \|____|\  \  
   \ \_______\   \ \_______\   \ \_______\   \ \_______\    ____\_\  \ 
    \|_______|    \|_______|    \|_______|    \|_______|   |\_________\
                                                           \|_________|
                                                                       
                                    
*/

/// @title FeeStructure @ Geegs
/// @author rektt (https://twitter.com/aceplxx)

contract FeeStructure is Ownable {
    bool public dynamicFee;
    uint256 public platformFee;
    uint256 public disputeFee;

    constructor(uint256 pFee, uint256 dFee) {
        platformFee = pFee;
        disputeFee = dFee;
    }

    /// @notice set platform fee
    /// @param feePercent the fee in percent
    function setPlatformFee(uint256 feePercent) external onlyOwner {
        platformFee = feePercent;
    }

    /// @notice set dispute resolver fee incentive
    /// @param feePercent the fee in percent
    function setDisputeFee(uint256 feePercent) external onlyOwner {
        disputeFee = feePercent;
    }

    function toggleDynamicFee() external onlyOwner {
        dynamicFee = !dynamicFee;
    }

    function calculateFee(
        uint256 wage,
        uint256 feePercent
    ) external view returns (uint256, uint256) {
        uint256 feeBasis = dynamicFee ? feePercent : platformFee;
        uint256 fees = feeBasis > 0 ? (wage * feeBasis) / 100 : 0;
        return (fees, feeBasis);
    }

    function calculateDisputeFee(uint256 wage) external view returns (uint256) {
        uint256 fees = disputeFee > 0 ? (wage * disputeFee) / 100 : 0;
        return fees;
    }
}
