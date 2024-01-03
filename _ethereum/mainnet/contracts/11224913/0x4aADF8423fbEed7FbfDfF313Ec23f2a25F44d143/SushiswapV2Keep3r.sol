// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IKeep3rV1Mini.sol";
import "./ISushiswapV2Factory.sol";
import "./ISushiswapV2Maker.sol";
import "./ISushiswapV2Pair.sol";

contract SushiswapV2Keep3r {

    modifier upkeep() {
        require(KP3R.isKeeper(msg.sender), "SushiswapV2Keep3r::isKeeper: keeper is not registered");
        _;
        KP3R.worked(msg.sender);
    }

    IKeep3rV1Mini public KP3R;
    ISushiswapV2Factory public constant SV2F = ISushiswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    ISushiswapV2Maker public constant SV2M = ISushiswapV2Maker(0x6684977bBED67e101BB80Fc07fCcfba655c0a64F);

    constructor(address keepertoken) public {
        KP3R = IKeep3rV1Mini(keepertoken);
    }

    function count() public view returns (uint) {
        uint _count = 0;
        for (uint i = 0; i < SV2F.allPairsLength(); i++) {
            if (haveBalance(SV2F.allPairs(i))) {
                _count++;
            }
        }
        return _count;
    }

    function workable() public view returns (bool) {
        return count() > 0;
    }

    function workableAll(uint _count) external view returns (address[] memory) {
        return (workable(_count, 0, SV2F.allPairsLength()));
    }

    function workable(uint _count, uint start, uint end) public view returns (address[] memory) {
        address[] memory _workable = new address[](_count);
        uint index = 0;
        for (uint i = start; i < end; i++) {
            if (haveBalance(SV2F.allPairs(i))) {
                _workable[index] = SV2F.allPairs(i);
                index++;
            }
        }
        return _workable;
    }

    function haveBalance(address pair) public view returns (bool) {
        return ISushiswapV2Pair(pair).balanceOf(address(SV2M)) > 0;
    }

    function batch(ISushiswapV2Pair[] calldata pair) external {
        bool _worked = true;
        for (uint i = 0; i < pair.length; i++) {
            if (haveBalance(address(pair[i]))) {
                (bool success, bytes memory message) = address(SV2M).delegatecall(abi.encodeWithSignature("convert(address,address)", pair[i].token0(), pair[i].token1()));
                require(success, string(abi.encodePacked("SushiswapV2Keep3r::convert: failed [", message, "]")));
            } else {
                _worked = false;
            }
        }
        require(_worked, "SushiswapV2Keep3r::batch: job(s) failed");
    }

    function work() external upkeep{
        require(workable(),"No pairs to convert");
        // iterate and add convert all pairs with balance
        for (uint i = 0; i < SV2F.allPairsLength(); i++) {
            if (haveBalance(SV2F.allPairs(i))) {
                //Do work
                (bool success, bytes memory message) = address(SV2M).delegatecall(abi.encodeWithSignature("convert(address,address)", ISushiswapV2Pair(SV2F.allPairs(i)).token0(), ISushiswapV2Pair(SV2F.allPairs(i)).token1()));
                require(success,  string(abi.encodePacked("SushiswapV2Keep3r::convert: failed [", message, "]")));
            }
        }
    }
}
