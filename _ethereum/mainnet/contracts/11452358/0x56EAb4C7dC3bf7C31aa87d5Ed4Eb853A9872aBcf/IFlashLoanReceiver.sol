// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IFlashLoanReceiver {
    function executeOperation(
        address _token, 
        uint256 _amount, 
        uint256 _fee, 
        bytes memory _params
    ) external;

    // function executeOperation(
    //     address[] calldata _reserves,
    //     uint256[] calldata _amounts,
    //     uint256[] calldata _fees,
    //     bytes calldata params
    // ) external returns (bool);
}