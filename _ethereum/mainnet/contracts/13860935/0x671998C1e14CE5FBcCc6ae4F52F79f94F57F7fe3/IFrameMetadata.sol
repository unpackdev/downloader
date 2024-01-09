// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./IERC165.sol";

interface IFrameMetadata is IERC165 {

    /* Returns framed uri
     *
    */
    function framedURI(uint256 tokenId) external view returns (string memory);

}