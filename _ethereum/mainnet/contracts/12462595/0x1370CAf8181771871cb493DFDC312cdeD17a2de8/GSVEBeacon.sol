// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract GSVEBeacon is Ownable{
    
    mapping(address => address) private _deployedAddress;
    mapping(address => address) private _addressGasToken;
    mapping(address => uint256) private _supportedGasTokens;
    
    constructor (address _wchi, address _wgst2, address _wgst1) public {
        //chi, gst2 and gst1
        _supportedGasTokens[0x0000000000004946c0e9F43F4Dee607b0eF1fA1c] = 30053;
        _supportedGasTokens[0x0000000000b3F879cb30FE243b4Dfee438691c04] = 30870;
        _supportedGasTokens[0x88d60255F917e3eb94eaE199d827DAd837fac4cB] = 20046;

        //wchi, wgst2 and wgst1
        _supportedGasTokens[_wchi] = 30053;
        _supportedGasTokens[_wgst2] = 30870;
        _supportedGasTokens[_wgst1] = 20046;
    }
    
    /**
    * @dev return the location of a users deployed wrapper
    */
    function getDeployedAddress(address creator) public view returns(address){
        return _deployedAddress[creator];
    }

    /**
    * @dev return the gas token used by a safe
    */
    function getAddressGastoken(address safe) public view returns(address){
        return _addressGasToken[safe];
    }

    /**
    * @dev return the savings a gas token gives
    */
    function getAddressGasTokenSaving(address gastoken) public view returns(uint256){
        return _supportedGasTokens[gastoken];
    }
    
    /**
    * @dev return the address and savings for a given safe proxy
    */
    function getGasTokenAndSaving(address safe) public view returns(address, uint256){
        return (getAddressGastoken(safe), getAddressGasTokenSaving(safe));
    }

    /**
    * @dev allows the creator of a safe to change the gas token used by the safe
    */
    function setAddressGasToken(address safe, address gasToken) public{
        require(_deployedAddress[msg.sender] == safe, "GSVE: Sender is not the safe creator");
        if (gasToken != address(0)){
            require(_supportedGasTokens[gasToken] > 0, "GSVE: Invalid Gas Token");
        }
        _addressGasToken[safe] = gasToken;
        emit UpdatedGasToken(safe, gasToken);
    }

    /**
    * @dev sets the initial gas token of a given safe proxy
    */
    function initSafe(address owner, address safe) public onlyOwner{
        require(_deployedAddress[owner] == address(0), "GSVE: address already init'd");
        _deployedAddress[owner] = safe;
        _addressGasToken[safe] = address(0);
        emit UpdatedGasToken(safe, address(0));
    }

    event UpdatedGasToken(address safe, address gasToken);

}