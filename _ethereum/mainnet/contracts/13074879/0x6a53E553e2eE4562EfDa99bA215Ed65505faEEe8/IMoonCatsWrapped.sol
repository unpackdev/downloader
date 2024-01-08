// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IMoonCatsWrapped {
    function wrap(bytes5 catId) external;
    function _catIDToTokenID(bytes5 catId) external view returns(uint256);
}