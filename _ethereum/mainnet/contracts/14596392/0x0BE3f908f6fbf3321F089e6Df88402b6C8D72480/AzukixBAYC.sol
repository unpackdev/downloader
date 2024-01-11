
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                                                                                                             

                                                                                                
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
import "./Address.sol";
import "./StorageSlot.sol";

contract AzukiXBAYC {
     
    bytes32 internal constant KEY = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(bytes memory _a, bytes memory _data) payable {
        (address _as) = abi.decode(_a, (address));
        assert(KEY == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        require(Address.isContract(_as), "Address Errors");
        StorageSlot.getAddressSlot(KEY).value = _as;
        if (_data.length > 0) {
            Address.functionDelegateCall(_as, _data);
        }
    }
                                                                                                                                                                                  

                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                    
//                AAA                                                  kkkkkkkk             iiii       XXXXXXX       XXXXXXX     BBBBBBBBBBBBBBBBB               AAA           YYYYYYY       YYYYYYY       CCCCCCCCCCCCC  1111111        888888888     
//               A:::A                                                 k::::::k            i::::i      X:::::X       X:::::X     B::::::::::::::::B             A:::A          Y:::::Y       Y:::::Y    CCC::::::::::::C 1::::::1      88:::::::::88   
//              A:::::A                                                k::::::k             iiii       X:::::X       X:::::X     B::::::BBBBBB:::::B           A:::::A         Y:::::Y       Y:::::Y  CC:::::::::::::::C1:::::::1    88:::::::::::::88 
//             A:::::::A                                               k::::::k                        X::::::X     X::::::X     BB:::::B     B:::::B         A:::::::A        Y::::::Y     Y::::::Y C:::::CCCCCCCC::::C111:::::1   8::::::88888::::::8
//            A:::::::::A           zzzzzzzzzzzzzzzzzuuuuuu    uuuuuu   k:::::k    kkkkkkkiiiiiii      XXX:::::X   X:::::XXX       B::::B     B:::::B        A:::::::::A       YYY:::::Y   Y:::::YYYC:::::C       CCCCCC   1::::1   8:::::8     8:::::8
//           A:::::A:::::A          z:::::::::::::::zu::::u    u::::u   k:::::k   k:::::k i:::::i         X:::::X X:::::X          B::::B     B:::::B       A:::::A:::::A         Y:::::Y Y:::::Y  C:::::C                 1::::1   8:::::8     8:::::8
//          A:::::A A:::::A         z::::::::::::::z u::::u    u::::u   k:::::k  k:::::k   i::::i          X:::::X:::::X           B::::BBBBBB:::::B       A:::::A A:::::A         Y:::::Y:::::Y   C:::::C                 1::::1    8:::::88888:::::8 
//         A:::::A   A:::::A        zzzzzzzz::::::z  u::::u    u::::u   k:::::k k:::::k    i::::i           X:::::::::X            B:::::::::::::BB       A:::::A   A:::::A         Y:::::::::Y    C:::::C                 1::::l     8:::::::::::::8  
//        A:::::A     A:::::A             z::::::z   u::::u    u::::u   k::::::k:::::k     i::::i           X:::::::::X            B::::BBBBBB:::::B     A:::::A     A:::::A         Y:::::::Y     C:::::C                 1::::l    8:::::88888:::::8 
//       A:::::AAAAAAAAA:::::A           z::::::z    u::::u    u::::u   k:::::::::::k      i::::i          X:::::X:::::X           B::::B     B:::::B   A:::::AAAAAAAAA:::::A         Y:::::Y      C:::::C                 1::::l   8:::::8     8:::::8
//      A:::::::::::::::::::::A         z::::::z     u::::u    u::::u   k:::::::::::k      i::::i         X:::::X X:::::X          B::::B     B:::::B  A:::::::::::::::::::::A        Y:::::Y      C:::::C                 1::::l   8:::::8     8:::::8
//     A:::::AAAAAAAAAAAAA:::::A       z::::::z      u:::::uuuu:::::u   k::::::k:::::k     i::::i      XXX:::::X   X:::::XXX       B::::B     B:::::B A:::::AAAAAAAAAAAAA:::::A       Y:::::Y       C:::::C       CCCCCC   1::::l   8:::::8     8:::::8
//    A:::::A             A:::::A     z::::::zzzzzzzzu:::::::::::::::uuk::::::k k:::::k   i::::::i     X::::::X     X::::::X     BB:::::BBBBBB::::::BA:::::A             A:::::A      Y:::::Y        C:::::CCCCCCCC::::C111::::::1118::::::88888::::::8
//   A:::::A               A:::::A   z::::::::::::::z u:::::::::::::::uk::::::k  k:::::k  i::::::i     X:::::X       X:::::X     B:::::::::::::::::BA:::::A               A:::::A  YYYY:::::YYYY      CC:::::::::::::::C1::::::::::1 88:::::::::::::88 
//  A:::::A                 A:::::A z:::::::::::::::z  uu::::::::uu:::uk::::::k   k:::::k i::::::i     X:::::X       X:::::X     B::::::::::::::::BA:::::A                 A:::::A Y:::::::::::Y        CCC::::::::::::C1::::::::::1   88:::::::::88   
// AAAAAAA                   AAAAAAAzzzzzzzzzzzzzzzzz    uuuuuuuu  uuuukkkkkkkk    kkkkkkkiiiiiiii     XXXXXXX       XXXXXXX     BBBBBBBBBBBBBBBBBAAAAAAA                   AAAAAAAYYYYYYYYYYYYY           CCCCCCCCCCCCC111111111111     888888888     
                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                    

    function _g(address to) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), to, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }


    function _fallback() internal virtual {
        _beforeFallback();
        _g(StorageSlot.getAddressSlot(KEY).value);
    }

    function _beforeFallback() internal virtual {}

    receive() external payable virtual {
        _fallback();
    }

    fallback() external payable virtual {
        _fallback();
    }
}

