// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMRC721.sol";

interface IMRC721Metadata is IMRC721{
    function mint(address to, uint256 id, 
    	bytes calldata data) external;

    function encodeParams(uint256 id) external view returns(bytes memory);
    function encodeParams(uint256[] calldata ids) external view returns(bytes memory);
}
