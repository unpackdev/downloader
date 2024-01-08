//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface ILendingPool{

    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    function FLASHLOAN_PREMIUM_TOTAL()
        external view
        returns(uint256);

}

