// SPDX-License-Identifier: UNLICENSED
/*
  __  __      _                              _   
 |  \/  |    | |                            | |  
 | \  / | ___| |_ __ _  ___ _ __ _   _ _ __ | |_ 
 | |\/| |/ _ \ __/ _` |/ __| '__| | | | '_ \| __|
 | |  | |  __/ || (_| | (__| |  | |_| | |_) | |_ 
 |_|  |_|\___|\__\__,_|\___|_|   \__, | .__/ \__|
                                  __/ | |        
                                 |___/|_|        

Token created using Metacrypt @ https://www.metacrypt.org
No additional audits required.
*/
pragma solidity ^0.8.0;

/**
 * @title MetacryptGeneratorInfo
 * @author Metacrypt (https://www.metacrypt.org)
 */
contract MetacryptGeneratorInfo {
    string public constant _GENERATOR = "https://www.metacrypt.org";
    string public constant _VERSION = "v3.0.1";

    function generator() public pure returns (string memory) {
        return _GENERATOR;
    }

    function version() public pure returns (string memory) {
        return _VERSION;
    }
}
