//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.7;

import "./IERC165.sol";

interface ISplitForwarder is IERC165 {
    function merkleRoot() external view returns (bytes32);
    function splitPool() external view returns (address);
    function initialize(bytes32 _merkleRoot, address _splitPool) external;
}