// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC721.sol";

interface IBAYC is IERC721 {
    function balanceOf(address owner) override external view returns (uint balance);
}