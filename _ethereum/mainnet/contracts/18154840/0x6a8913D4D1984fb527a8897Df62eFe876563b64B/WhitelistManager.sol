// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./OwnerManager.sol";

/**
 * @title WhitelistManager
 * @notice A contract managing whitelist addresses, selectors and parameters
 */
abstract contract WhitelistManager is OwnerManager {

    event AddedWhitelistAddress(address indexed _address, bytes4[] selectorList, uint256[][] parametersList);
    event UpdatedWhitelistAddress(address indexed _address, bytes4[] selectorList, uint256[][] parametersList);
    event RemovedWhitelistAddress(address indexed _address);
    
    // a linked list is used for a better efficience over an array
    mapping(address => address) internal whitelistAddresses;
    uint256 internal whitelistAddressCount;
    // pack 20 bytes address and 4 bytes selector together as key
    mapping(bytes32 => uint256[]) internal whitelistAddressSelectorParametersMap;
    
    /**
     * @notice Set the initial whitelists. To be called by KnightSafe setup only. 
     * @dev The function is similar to updateWhitelistAddress. But since "owner" is not ready at setup, we need to copy the code here.
     * @param initAddresses List of initial whitelist addresses
     * @param initSelectorLists List of initial whitelist selectors
     * @param initParametersLists List of initial whitelist parameters
     */
    function setupWhitelist(address[] memory initAddresses, bytes4[][] memory initSelectorLists, uint256[][][] memory initParametersLists) internal {
        require(initAddresses.length == initSelectorLists.length && initAddresses.length == initParametersLists.length, "Input arrays do not have the same length");  

        whitelistAddresses[address(this)] = ADDRESS_PTR;
        whitelistAddresses[owner] = address(this);
        whitelistAddresses[ADDRESS_PTR] = owner;
        whitelistAddressCount = 2;
         
        for (uint256 i = 0; i < initAddresses.length; i++) {            
            require(initAddresses[i] != address(0) && initAddresses[i] != ADDRESS_PTR, "Input address is invalid");
            require(initSelectorLists[i].length == initParametersLists[i].length, "Input arrays do not have the same length");

            if (!isWhitelistAddress(initAddresses[i])) {
                whitelistAddresses[initAddresses[i]] = whitelistAddresses[ADDRESS_PTR];
                whitelistAddresses[ADDRESS_PTR] = initAddresses[i];
                whitelistAddressCount++;
                emit AddedWhitelistAddress(initAddresses[i], initSelectorLists[i], initParametersLists[i]);
            } else {
                emit UpdatedWhitelistAddress(initAddresses[i], initSelectorLists[i], initParametersLists[i]);
            }
            for (uint256 j = 0; j < initSelectorLists[i].length; j++) {
                bytes4 selector = initSelectorLists[i][j];
                bytes32 addressSelector = bytes32(abi.encodePacked(initAddresses[i], selector));
                whitelistAddressSelectorParametersMap[addressSelector] = initParametersLists[i][j];
            }
        }
    }
    
    /**
     * @notice If address does not exist in the whitelist, a new whitelist is added, otherwise settings will be overwritten.
     *         One whitelist address can have multiple whitelist selectors and one selector can have multiple whitelist parameters.
     * @param _address Address to be added to the whiteliste or address to be updated settings
     * @param selectorList 4-bytes selector list to be whitelisted
     * @param parametersList parameter position list to be whitelisted
     */
    function updateWhitelistAddress(
        address _address,
        bytes4[] memory selectorList,
        uint256[][] memory parametersList
    ) public onlyOwner {
        require(_address != address(0) && _address != ADDRESS_PTR, "Input address is invalid");
        require(selectorList.length == parametersList.length, "Input arrays do not have the same length");

        if (!isWhitelistAddress(_address)) {
            whitelistAddresses[_address] = whitelistAddresses[ADDRESS_PTR];
            whitelistAddresses[ADDRESS_PTR] = _address;
            whitelistAddressCount++;
            emit AddedWhitelistAddress(_address, selectorList, parametersList);
        } else {
            emit UpdatedWhitelistAddress(_address, selectorList, parametersList);
        }
        for (uint256 i = 0; i < selectorList.length; i++) {
            bytes4 selector = selectorList[i];
            bytes32 addressSelector = bytes32(abi.encodePacked(_address, selector));
            whitelistAddressSelectorParametersMap[addressSelector] = parametersList[i];
        }
    }

    /**
     * @notice Removing whitelist address do not reset corresponding whitelisted selectors and parameters.
     *         Please call updateWhitelistAddress to clear settings before calling this function if user intends to do so.
     * @param _address Address to be removed from the whitelist
     */
    function removeWhitelistAddress(address _address) public onlyOwner {
        require(_address != address(0) && _address != ADDRESS_PTR, "Input address is invalid");
        require(whitelistAddresses[_address] != address(0), "Input address is not in the whitelist");

        address previousAddress = ADDRESS_PTR;
        address currentAddress = whitelistAddresses[previousAddress];
        while (currentAddress != ADDRESS_PTR) {
            if (currentAddress == _address) {
                whitelistAddresses[previousAddress] = whitelistAddresses[_address];
                whitelistAddresses[_address] = address(0);
                whitelistAddressCount--;
                emit RemovedWhitelistAddress(_address);
                break;
            }
            previousAddress = currentAddress;
            currentAddress = whitelistAddresses[previousAddress];
        }
    }

    /**
     * @notice Allowing multiple remove whitelist and update whitelist in one call.
     * @dev Remove first, update next. Checkings and event emissions to be done in "removeWhitelistAddress" and "updateWhitelistAddress".
     * @param toRemoveAddresses List of addresses to be removed from the whitelist.
     * @param toUpdateAddresses List of addresses to be added to the whiteliste or address to be updated settings.
     * @param toUpdateSelectorLists Corresponding selector lists to be whitelisted.
     * @param toUpdateParametersLists Corresponding parameter position lists to be whitelisted.
     */
    function batchUpdateWhitelistAddresses(address[] memory toRemoveAddresses, address[] memory toUpdateAddresses, bytes4[][] memory toUpdateSelectorLists, uint256[][][] memory toUpdateParametersLists) public onlyOwner {
        require(toUpdateAddresses.length == toUpdateSelectorLists.length && toUpdateAddresses.length == toUpdateParametersLists.length, "Input arrays do not have the same length");   
        for (uint256 i = 0; i < toRemoveAddresses.length; i++) {
            removeWhitelistAddress(toRemoveAddresses[i]);
        }
        for (uint256 i = 0; i < toUpdateAddresses.length; i++) {
            updateWhitelistAddress(toUpdateAddresses[i], toUpdateSelectorLists[i], toUpdateParametersLists[i]);
        }
    }

    /**
     * @notice Check if "_address" is in the whitelist.
     * @param _address Address to be checked.
     * @return Boolean if _address is in the whitelist.
     */
    function isWhitelistAddress(address _address) public view returns (bool) {
        return _address != ADDRESS_PTR && whitelistAddresses[_address] != address(0);
    }

    /**
     * @notice Get the list of whitelist addresses.
     * @return Array of the whitelist addresses.
     */
    function getWhitelistAddresses() public view returns (address[] memory) {
        address[] memory array = new address[](whitelistAddressCount);

        uint256 index = 0;
        address currentAddress = whitelistAddresses[ADDRESS_PTR];
        while (currentAddress != ADDRESS_PTR) {
            array[index] = currentAddress;
            currentAddress = whitelistAddresses[currentAddress];
            index++;
        }
        return array;
    }

    /**
     * @notice Get the parameter position list of "_address" and its corresponding "selector".
     * @param _address Address to be checked.
     * @param selector 4-bytes selector to be checked.
     * @return Array of parameter positions.
     */
    function getWhitelistFunctionParameters(address _address, bytes4 selector) public view returns (uint256[] memory) {
        bytes32 addressSelector = bytes32(abi.encodePacked(_address, selector));
        return whitelistAddressSelectorParametersMap[addressSelector];
    }

    /**
     * @notice Get the parameter position lists of "_address" and a list of its corresponding selectors.
     * @param _address Address to be checked.
     * @param selectorList List of 4-bytes selectors to be checked.
     * @return 2D-Array of parameter positions.
     */
    function getWhitelistFunctionParametersMultiple(address _address, bytes4[] memory selectorList) public view returns (uint256[][] memory) {
        uint256[][] memory results = new uint256[][](selectorList.length);
        for (uint256 i = 0; i < selectorList.length; i++) {
            results[i] = getWhitelistFunctionParameters(_address,selectorList[i]);
        }
        return results;
    }
}