// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./StakerBase.sol";
import "./ILidoStakerBase.sol";


contract LidoStakerBase is StakerBase {
    address public constant ST_ETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    uint256[50] private _gap;

    function initialize() public initializer {
       __Ownable_init();
    }
    
}