// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IUUNNRegistry.sol";
import "./IOCProtectionStorage.sol";
import "./IPool.sol";
import "./CopMappingInterface.sol";
import "./Ownable.sol";

contract CopMapping is Ownable, CopMappingInterface{
   
    address private _copRegistryAddress;

    constructor(address copRegistryAddress) public{
        _copRegistryAddress = copRegistryAddress;
    }

    function _setCopRegistry(address copRegistryAddress) public onlyOwner {
        _copRegistryAddress = copRegistryAddress;
    }

    function copRegistry() public view returns (IUUNNRegistry){
        return IUUNNRegistry(_copRegistryAddress);
    }

    function getTokenAddress() override public view returns (address){
        return _copRegistryAddress;
    }

    function getProtectionData(uint256 underlyingTokenId) override public view returns (address, uint256, uint256, uint256, uint, uint){
        return IOCProtections(copRegistry().protectionContract(underlyingTokenId)).getProtectionData(underlyingTokenId);
    }

    function getUnderlyingAsset(uint256 underlyingTokenId) override public view returns (address){
        (address pool, , , , , ) = getProtectionData(underlyingTokenId);
        return IAssetPool(pool).getAssetToken();
    }

    function getUnderlyingAmount(uint256 underlyingTokenId) override public view returns (uint256){
        ( , uint256 amount, , , , ) = getProtectionData(underlyingTokenId);
        return amount;
    }

    function getUnderlyingStrikePrice(uint256 underlyingTokenId) override public view returns (uint){
        ( , , uint256 strike, , , ) = getProtectionData(underlyingTokenId);
        return strike * 1e10; 
    }

    function getUnderlyingDeadline(uint256 underlyingTokenId) override public view returns (uint){
        ( , , , , , uint deadline) = getProtectionData(underlyingTokenId);
        return deadline;
    }

}