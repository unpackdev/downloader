// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IWanchainMPC.sol";

contract MockMPC is IWanchainMPC {
    uint256 public bip44chainId;
    constructor(uint256 _bip44chainId) {
        bip44chainId = _bip44chainId;
    }

    function getStoremanGroupConfig(bytes32 /*id*/) external view override returns (bytes32, uint8, uint, uint, uint, uint, uint, bytes memory, bytes memory, uint, uint) {
        return (0x1234567890123456789012345678901234567890123456789012345678901234, 5, 1000, 1, 2, 1, 2, abi.encodePacked("group public key 1"), abi.encodePacked("group public key 2"), block.timestamp - 100, block.timestamp + 36000000);
    }

    function verify(
        uint /*curveId*/, 
        bytes32 /*signature*/, 
        bytes32 /*groupKeyX*/, 
        bytes32 /*groupKeyY*/, 
        bytes32 /*randomPointX*/, 
        bytes32 /*randomPointY*/, 
        bytes32 /*message*/
    ) external override pure returns (bool) {
        return true;
    }

    function getPartners() external view returns(address tokenManager, address smgAdminProxy, address smgFeeProxy, address quota, address sigVerifier) {
        return (address(0), address(this), address(0), address(0), address(this));
    }
    
    function currentChainID() external view returns (uint256) {
        return bip44chainId;
    }
}

