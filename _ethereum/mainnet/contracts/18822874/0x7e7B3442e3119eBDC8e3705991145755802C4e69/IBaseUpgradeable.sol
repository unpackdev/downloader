// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

interface IBaseUpgradeable {
    error BaseUpgradeable__NotAuthorized();

    struct Operation {
        address to; // The address of the contract to be called
        uint96 value;
        bytes data; // The data to be passed to the contract
    }

    function roleManager() external view returns (address);
}
