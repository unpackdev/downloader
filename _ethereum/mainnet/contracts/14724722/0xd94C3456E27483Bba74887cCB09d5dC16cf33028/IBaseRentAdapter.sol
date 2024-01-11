// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./LibLandworks.sol";

interface IBaseRentAdapter {
    function withdrawNFTFromRent(uint256 loanId) external;
}
