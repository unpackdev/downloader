// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./IConjureFactory.sol";
import "./IConjureRouter.sol";

interface Collect{
    function collectFees() external;
    function changeOwner(address payable _newOwner) external;
}

contract FeeCollect {
    // address used for pay out

    address public CNJAddress = 0xcE53384b7ea89039e10B98E9401dd3454e4A9b9c;
    address public  control = 0xa71A51A4863A2f9c2a83A9FEb284595020CC80A7;
    Collect[] public CollectAddresses;
    address public DAOtimelock = 0x3aac79279108CF1C7dB7d8250c87eeffC63676f5;

    receive() external payable {
    }

    fallback() external payable{
        pay();
    }

    function collect(Collect[] memory assets) public{
        for (uint c = 0; c < assets.length; c++) {
            assets[c].collectFees();
        }
        pay();
    }
    function pay() public{
        address payable conjureRouter = IConjureFactory(CNJAddress).getConjureRouter();
        IConjureRouter(conjureRouter).deposit{value:address(this).balance}();
    }

    function collectSet(Collect[] memory assets) public{
        require(msg.sender == control, "Must come from controller address");
        CollectAddresses = assets;
    }

    function updateControl(address _control) public{
        require(msg.sender == control, "Must come from controller address");
        control = _control;
    }

    function collect1tap() public{
        for (uint c = 0; c < CollectAddresses.length; c++) {
            CollectAddresses[c].collectFees();
        }
        pay();
    }

    function changeOwner(address cnjContract, address payable newOwner) public {
        require(msg.sender == DAOtimelock, "Must come from DAO address");
        Collect(cnjContract).changeOwner(newOwner);
    }
}