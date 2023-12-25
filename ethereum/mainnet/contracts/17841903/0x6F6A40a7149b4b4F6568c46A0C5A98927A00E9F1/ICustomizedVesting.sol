// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICustomizedVesting {
    function addAllocation(address recipient, uint amount) external;
    function removeAllocation(address recipient, uint amount) external;
    function claim() external;
    function available(address address_) external view returns (uint);
    function released(address address_) external view returns (uint);
    function outstanding(address address_) external view returns (uint);
    function setTokenAddress(address _tokenAddress) external;
}
