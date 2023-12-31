// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./StakerBase.sol";
import "./ILidoCrvStakerBase.sol";


contract LidoCrvStakerBase is StakerBase {
    address public constant ST_ETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant CRV = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;

    uint256[50] private _gap;

    function initialize() public initializer {
       __Ownable_init();
    }
    
}