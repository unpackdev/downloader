// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "./ERC1967Proxy.sol";

contract CompetitionProxy is ERC1967Proxy{

    constructor(address _logic, bytes memory _data) ERC1967Proxy(_logic, _data){}

    function getImplementation() external view returns(address){
        return _getImplementation();
    }
}