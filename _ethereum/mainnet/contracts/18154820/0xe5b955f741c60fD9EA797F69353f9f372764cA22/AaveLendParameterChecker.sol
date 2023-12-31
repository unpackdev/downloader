// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./IParameterChecker.sol";

interface IAavePoolV3 {
    function getReserveAddressById(uint16 id) external view returns (address);
}

contract AaveLendParameterChecker is IParameterChecker {
    
    function getAddressListForChecking(
        address to,
        bytes4 selector,
        bytes calldata data
    ) external override view returns (address[] memory) {

        if (selector == 0xd5eed868 // borrow(args:bytes32)
         || selector == 0x563dd613 // repay(args:bytes32)
         || selector == 0xdc7c0bff // repayWithATokens(args:bytes32)
         || selector == 0x4d013f03 // setUserUseReserveAsCollateral(args:bytes32)
         || selector == 0xf7a73840 // supply(args:bytes32)
         || selector == 0x1fe3c6f3 // swapBorrowRateMode(args:bytes32)
         || selector == 0x8e19899e // withdraw(args:bytes32)
         ) {
            uint16 assetId = getAssetId(data, 0);
            address[] memory rv = new address[](1);
            rv[0] = getAddressByAssetId(to, assetId);
            return rv;
        }
        else if (selector == 0xfd21ecff // liquidationCall(args1:bytes32,args2:bytes32)
        ) {
            (address user, uint16 id1, uint16 id2) = getLiquidationCallParams(data, 0);
            address[] memory rv = new address[](3);
            rv[0] = user;
            rv[1] = getAddressByAssetId(to, id1);
            rv[2] = getAddressByAssetId(to, id2);
            return rv;
        }
        else if (selector == 0x9cd19996 // mintToTreasury(assets:address[])
        ) {            
            address[] calldata assets = getAddressArray(data, 0);
            address[] memory rv = new address[](assets.length);
            for (uint256 i = 0; i < assets.length; i++)
            {
                rv[i] = assets[i];
            }
            return rv;
        }
        else if (selector == 0x427da177 // rebalanceStableBorrowRate(args:bytes32)
        ) {
            (address user, uint16 assetId) = getAddressAndAssetId(data, 0);
            address[] memory rv = new address[](2);
            rv[0] = user;
            rv[1] = getAddressByAssetId(to, assetId);
            return rv;
        }
        return new address[](0);
    }    

    function getAddressByAssetId(address to, uint16 assetId) internal view returns (address) {
        address rv = IAavePoolV3(to).getReserveAddressById(assetId);
        return rv;
    }    

    function getAddressArray(bytes calldata data, uint256 pos) internal pure returns (address[] calldata rv) {        
        assembly {        
            let lengthPtr := add(add(data.offset, calldataload(add(add(data.offset, shl(5, pos)), 4))), 4)
            rv.length := calldataload(lengthPtr)
            rv.offset := add(lengthPtr, 0x20)
        }
    }
    
    function getAssetId(bytes calldata data, uint256 pos) internal pure returns (uint16 id) {        
        assembly {        
            let args := calldataload(add(add(data.offset, shl(5, pos)), 4))
            id := and(args, 0xFFFF)      
        }
    }
    
    function getAddressAndAssetId(bytes calldata data, uint256 pos) internal pure returns (address user, uint16 id) {
        assembly {        
            let args := calldataload(add(add(data.offset, shl(5, pos)), 4))                    
            id := and(args, 0xFFFF)
            user := and(shr(16, args), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    function getLiquidationCallParams(bytes calldata data, uint256 pos) internal pure returns (address user, uint16 id1, uint16 id2) {
        assembly {        
            let args := calldataload(add(add(data.offset, shl(5, pos)), 4))
            id1 := and(args, 0xFFFF)
            id2 := and(shr(16, args), 0xFFFF)
            user := and(shr(32, args), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }
}
