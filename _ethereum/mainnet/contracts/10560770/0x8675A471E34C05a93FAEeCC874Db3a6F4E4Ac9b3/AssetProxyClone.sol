pragma solidity 0.6.12;

contract AssetProxyClone {
    fallback () external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let res := delegatecall(gas(), 0x64aC67f8715CAC475D3029EE7C05b756FB0B27b5, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch res case 0 { revert(0, returndatasize()) } default { return(0, returndatasize()) }
        }
    }
}