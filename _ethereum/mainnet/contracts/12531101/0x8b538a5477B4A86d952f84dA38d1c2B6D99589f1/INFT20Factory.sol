//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface INFT20Factory {

    function nftToToken(address pair) external returns (address);

}

