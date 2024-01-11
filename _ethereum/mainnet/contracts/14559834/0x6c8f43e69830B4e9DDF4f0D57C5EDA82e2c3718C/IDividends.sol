//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IDividends {
    function withdrawableBy(address investor) external view returns (uint256);
    function withdrawnBy(address investor) external view returns (uint256);
    function totalDistributed() external view returns (uint256);
    function undistributedBalance() external view returns (uint256);

    function distribute() external;
    function withdrawDividends() external;
    function withdraw() external;
}
