//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./CustomPS.sol";
import "./CloneFactory.sol";

contract MasterPS is CloneFactory {
    address public masterContract;
    CustomPS[] public pses;
    event PSCreated(address ps);

    constructor(address _masterContract){
        masterContract = _masterContract;
     }

    function createPS(address[] memory addresses, uint256[] memory shares) public {
        CustomPS ps = CustomPS(
            createClone(masterContract)
        );        
        ps.init(addresses, shares);                
        pses.push(ps);
        emit PSCreated(address(ps));
    }
}
