// SPDX-License-Identifier: MIT

/// @author Tient Technologies (Twitter:https://twitter.com/tient_tech | Github:https://github.com/Tient-Technologies | | LinkedIn:https://www.linkedin.com/company/tient-technologies/)
/// @dev NiceArti (https://github.com/NiceArti)
/// To maintain developer you can also donate to this address - 0xDc3d3fA1aEbd13fF247E5F5D84A08A495b3215FB
/// @title The interface for implementing the CflatsTerritory smart contract 
/// with a full description of each function and their implementation 
/// is presented to your attention.

pragma solidity ^0.8.18;

interface ICflatsTerritory 
{
    /// @dev Emitted when user buys territory
    /// `from` is the address that transfers terrotory to recepient
    /// `to` is the address of account that bought territory
    /// `gen` is the gen number of territory that relates to Cflats NFT
    event TerritoryTransfer(address indexed from, address indexed to, uint256 gen);


    /// @dev Shows address of utility token
    function utilityToken() external view returns(address);


    /// @dev Shows the amount of territories that users owns
    function balanceOf(address owner, uint256 gen) external view returns (uint256);


    /// @dev Shows if `owner` has territory for staking NFT gen
    /// @param owner is an account address of user
    /// @param gen is a number of gen that is allowed to stake token
    /// @return true if `owner` has territory for special `gen`
    function hasTerritoryForGen(
        address owner,
        uint256 gen
    ) external view returns (bool);


    /// @dev Shows the price for buying territory for special `gen`
    /// @param gen is a number of gen that is allowed to stake token
    /// @return true if `owner` has territory for special `gen`
    function getPriceForGen(uint256 gen) external view returns (uint256);


    /// @dev Allows user to buy territory using $CFLAT tokens  
    /// @param gen is a number of NFT gen
    /// @param amount of $CFLAT for buing territory
    /// 
    /// @custom:requires amount to be greather than or equal to price of territory
    ///
    /// @return true if `owner` has territory for special `gen`
    function buy(uint256 gen, uint256 amount) external returns (bool);
    
    
    /// @dev Allows user to transfer territory to anyone  
    /// @param recipient the address who will receive territory
    /// @param gen is a number of NFT gen
    /// 
    /// @custom:requires `owner` balance to be at least two
    ///
    /// @return true if `owner` has territory for special `gen`
    function transfer(
        address recipient,
        uint256 gen
    ) external returns (bool);
}
