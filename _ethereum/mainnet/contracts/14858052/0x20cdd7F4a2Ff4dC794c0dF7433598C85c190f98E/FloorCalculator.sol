// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity 0.7.4;

import "./IFloorCalculator.sol";
import "./IPi.sol";
import "./SafeMath.sol";
import "./UniswapV2Library.sol";
import "./IUniswapV2Factory.sol";
import "./TokensRecoverable.sol";
import "./EnumerableSet.sol";

contract FloorCalculator is TokensRecoverable
{

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IPi immutable Pi;
    IUniswapV2Factory[] uniswapV2Factories;
    EnumerableSet.AddressSet ignoredAddresses;

    constructor(IPi _Pi)
    {
        Pi = _Pi;
        uniswapV2Factories.push(IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)); // uniswap factory added
        
    }

    function addUniswapV2Factory(IUniswapV2Factory _uniswapV2Factory) public ownerOnly  {
        uniswapV2Factories.push(_uniswapV2Factory);
    }

    function resetV2Factories() public ownerOnly {
         delete uniswapV2Factories;
     }
    
    function getUniV2Factories() public view returns(IUniswapV2Factory[] memory) {
        return uniswapV2Factories;
    }

    
    function allowedUniswapFactories() public view returns (uint256) { return uniswapV2Factories.length; }

    // add addresses that you have just locked Pi permanently and wont ask for Wizard or pETH from pool
    function setIgnore(address ignoredAddress, bool add) public ownerOnly
    {
        if (add) 
        { 
            ignoredAddresses.add(ignoredAddress); 
        } 
        else 
        { 
            ignoredAddresses.remove(ignoredAddress); 
        }
    }

    function isIgnoredAddress(address ignoredAddress) public view returns (bool)
    {
        return ignoredAddresses.contains(ignoredAddress);
    }

    function ignoredAddressCount() public view returns (uint256)
    {
        return ignoredAddresses.length();
    }

    function ignoredAddressAt(uint256 index) public view returns (address)
    {
        return ignoredAddresses.at(index);
    }

    function ignoredAddressesTotalBalance() public view returns (uint256)
    {
        uint256 total = 0;
        for (uint i = 0; i < ignoredAddresses.length(); i++) {
            total = total.add(Pi.balanceOf(ignoredAddresses.at(i)));
        }

        return total;
    }



    // wrapped BNB = ? 
    // backing token is pETH 
   
    function calculateSubFloorPETH(IERC20 wrappedToken, IERC20 backingToken) public view returns (uint256)
    {
        uint256 backingInPool = 0;
        uint256 sellAllProceeds = 0;
        address[] memory path = new address[](2);
        path[0] = address(Pi);
        path[1] = address(backingToken);
        uint256 subFloor=0;
    
        for(uint i=0;i<uniswapV2Factories.length;i++){

            address pair = UniswapV2Library.pairFor(address(uniswapV2Factories[i]), address(Pi), address(backingToken));
            
            uint256 freePi = Pi.totalSupply().sub(Pi.balanceOf(pair)).sub(ignoredAddressesTotalBalance());

            if (freePi > 0) {
                uint256[] memory amountsOut = UniswapV2Library.getAmountsOut(address(uniswapV2Factories[i]), freePi, path);
                sellAllProceeds = sellAllProceeds.add(amountsOut[1]);
            }
        
            backingInPool = backingInPool.add(backingToken.balanceOf(pair));           
                    
        }

        if (backingInPool <= sellAllProceeds) { return 0; }
        uint256 excessInPool = backingInPool.sub(sellAllProceeds);

        uint256 requiredBacking = backingToken.totalSupply().sub(excessInPool);
        uint256 currentBacking = wrappedToken.balanceOf(address(backingToken));
        if (requiredBacking >= currentBacking) { return 0; }
        
        subFloor = currentBacking.sub(requiredBacking); 
        return subFloor;           
        
    }
}