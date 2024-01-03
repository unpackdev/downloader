// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.6.0;

interface TreasuryInterface {
    function createBooty() external returns(address);
    function registerPlayerBooty(address payable dest, address bootyContract) external;

    function payments(address dest) external view returns (uint256);
    function withdrawPayments(address payable payee) external;

    function balanceOfL7l(address dest) external view returns (uint256);
    function rewardL7l(address dest, uint256 amount) external;
    function withdrawL7l(address dest) external;
}