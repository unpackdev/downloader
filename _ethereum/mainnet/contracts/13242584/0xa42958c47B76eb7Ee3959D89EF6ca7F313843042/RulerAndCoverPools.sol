//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CIPStaking.sol";
import "./CHCCollect.sol";
import "./CHSLite.sol";
import "./CHSSwap.sol";

contract CoverCollarPool is CIPSwap, CHSSwap {
    function address_bond() public pure override returns (address) {
        return 0x4688a8b1F292FDaB17E9a90c8Bc379dC1DBd8713;
    }

    function address_want() public pure override returns (address) {
        return 0x11facD2B150caDD5322AeB62219cBF9A3cF8Da79;
    }

    function address_coll() public pure override returns (address) {
        return 0xC5fb11512E724941b8Ed28966459Ac8e9332507E;
    }

    function address_call() public pure override returns (address) {
        return 0xc8f6E9E7E3b106Bcc5f8c1Cf8Ab3dBC1D0a256c4;
    }

    function address_collar() public pure override returns (address) {
        return 0x11facD2B150caDD5322AeB62219cBF9A3cF8Da79;
    }

    function expiry_time() public pure override returns (uint256) {
        return 1696118400;
    }
}
//coll cover->collar 0xC5fb11512E724941b8Ed28966459Ac8e9332507E 
//call cover->collar 0xc8f6E9E7E3b106Bcc5f8c1Cf8Ab3dBC1D0a256c4 
//collar for cover 0x11facD2B150caDD5322AeB62219cBF9A3cF8Da79

contract RulerCollarPool is CIPSwap, CHSSwap {
    function address_bond() public pure override returns (address) {
        return 0x2aECCB42482cc64E087b6D2e5Da39f5A7A7001f8;
    }

    function address_want() public pure override returns (address) {
        return 0x46D9464fA3ebF33A1f9B22CE93024fb8A8122404;
    }

    function address_coll() public pure override returns (address) {
        return 0x6F85f9e369e8777cAeCaBc3fcd7f3997838AbF0f;
    }

    function address_call() public pure override returns (address) {
        return 0x4ab83FDe6ADaB8a2d049eEF050e603040afa8D13;
    }

    function address_collar() public pure override returns (address) {
        return 0x46D9464fA3ebF33A1f9B22CE93024fb8A8122404;
    }

    function expiry_time() public pure override returns (uint256) {
        return 1696118400;
    }
}

//coll ruler->collar 0x6F85f9e369e8777cAeCaBc3fcd7f3997838AbF0f 
//call ruler->collar 0x4ab83FDe6ADaB8a2d049eEF050e603040afa8D13 
//collar for ruler 0x46D9464fA3ebF33A1f9B22CE93024fb8A8122404
