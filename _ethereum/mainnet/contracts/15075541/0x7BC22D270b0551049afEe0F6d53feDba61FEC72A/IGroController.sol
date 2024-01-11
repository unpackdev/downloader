//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

interface IGroController {

    function DAI() external view returns (address);
    function USDC() external view returns (address);
    function USDT() external view returns (address);

    function stablecoins() external view returns (address[3] memory);
    function buoy() external view returns (address);
    function depositHandler() external view returns (address);
    function withdrawHandler() external view returns (address);
    function gvt() external view returns (address);
    function pwrd() external view returns (address);
}