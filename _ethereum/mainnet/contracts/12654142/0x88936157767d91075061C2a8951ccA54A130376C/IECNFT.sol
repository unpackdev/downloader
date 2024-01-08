//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0 <0.8.0;

interface IECNFT {

    function sale_is_over() external view returns (bool);
    function transferFrom(address, address, uint256) external;
    function safeTransferFrom(address, address, uint256) external;
    function safeTransferFrom(address, address, uint256, bytes memory) external;

}