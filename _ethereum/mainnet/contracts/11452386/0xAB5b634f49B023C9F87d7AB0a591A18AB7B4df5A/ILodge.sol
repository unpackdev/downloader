// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ILodge {
    event TokenCreated(address user, uint256 id, uint256 supply);

    function items(uint256 _token) external view returns(uint256);
    function boost(uint256 _id) external view returns (uint256);

    function setURI(string memory _newuri) external;
    function mint(address _account, uint256 _id, uint256 _amount, uint256 _boost) external;
}
