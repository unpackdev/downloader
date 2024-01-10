// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./Strings.sol";


/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract eta {
    string public _baseURI="https://ipfs.io/ipfs/QmajnnxRpUb94dSad8QtZiYJB1fKN4HnPMsKwA3FQ5j79A/";
    string public _suffixURI="";

    
    function setBaseURI(string memory uri) public  {
        _baseURI = uri;
    }
    function setSuffixURI(string memory suffix) public  {
        _suffixURI = suffix;
    }
    function tokenURI(uint256 id) public view  returns (string memory) {
            return string(abi.encodePacked(_baseURI, Strings.toString(id),_suffixURI));
        }
    /**
     * @dev Store value in variable
     * @param num value to store
     */

}