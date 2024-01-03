// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IArtHtml {
    function getStart() external view returns(string memory);
    function getEnd() external view returns(string memory);
}
