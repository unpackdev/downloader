
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                                                         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
import "./Address.sol";
import "./StorageSlot.sol";

contract AzukiXBAYC {
    // Azuki X BAYC 
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

                                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                             
//                AAA                                                  kkkkkkkk             iiii       XXXXXXX       XXXXXXX     BBBBBBBBBBBBBBBBB               AAA           YYYYYYY       YYYYYYY       CCCCCCCCCCCCC 222222222222222     222222222222222    
//               A:::A                                                 k::::::k            i::::i      X:::::X       X:::::X     B::::::::::::::::B             A:::A          Y:::::Y       Y:::::Y    CCC::::::::::::C2:::::::::::::::22  2:::::::::::::::22  
//              A:::::A                                                k::::::k             iiii       X:::::X       X:::::X     B::::::BBBBBB:::::B           A:::::A         Y:::::Y       Y:::::Y  CC:::::::::::::::C2::::::222222:::::2 2::::::222222:::::2 
//             A:::::::A                                               k::::::k                        X::::::X     X::::::X     BB:::::B     B:::::B         A:::::::A        Y::::::Y     Y::::::Y C:::::CCCCCCCC::::C2222222     2:::::2 2222222     2:::::2 
//            A:::::::::A           zzzzzzzzzzzzzzzzzuuuuuu    uuuuuu   k:::::k    kkkkkkkiiiiiii      XXX:::::X   X:::::XXX       B::::B     B:::::B        A:::::::::A       YYY:::::Y   Y:::::YYYC:::::C       CCCCCC            2:::::2             2:::::2 
//           A:::::A:::::A          z:::::::::::::::zu::::u    u::::u   k:::::k   k:::::k i:::::i         X:::::X X:::::X          B::::B     B:::::B       A:::::A:::::A         Y:::::Y Y:::::Y  C:::::C                          2:::::2             2:::::2 
//          A:::::A A:::::A         z::::::::::::::z u::::u    u::::u   k:::::k  k:::::k   i::::i          X:::::X:::::X           B::::BBBBBB:::::B       A:::::A A:::::A         Y:::::Y:::::Y   C:::::C                       2222::::2           2222::::2  
//         A:::::A   A:::::A        zzzzzzzz::::::z  u::::u    u::::u   k:::::k k:::::k    i::::i           X:::::::::X            B:::::::::::::BB       A:::::A   A:::::A         Y:::::::::Y    C:::::C                  22222::::::22       22222::::::22   
//        A:::::A     A:::::A             z::::::z   u::::u    u::::u   k::::::k:::::k     i::::i           X:::::::::X            B::::BBBBBB:::::B     A:::::A     A:::::A         Y:::::::Y     C:::::C                22::::::::222       22::::::::222     
//       A:::::AAAAAAAAA:::::A           z::::::z    u::::u    u::::u   k:::::::::::k      i::::i          X:::::X:::::X           B::::B     B:::::B   A:::::AAAAAAAAA:::::A         Y:::::Y      C:::::C               2:::::22222         2:::::22222        
//      A:::::::::::::::::::::A         z::::::z     u::::u    u::::u   k:::::::::::k      i::::i         X:::::X X:::::X          B::::B     B:::::B  A:::::::::::::::::::::A        Y:::::Y      C:::::C              2:::::2             2:::::2             
//     A:::::AAAAAAAAAAAAA:::::A       z::::::z      u:::::uuuu:::::u   k::::::k:::::k     i::::i      XXX:::::X   X:::::XXX       B::::B     B:::::B A:::::AAAAAAAAAAAAA:::::A       Y:::::Y       C:::::C       CCCCCC2:::::2             2:::::2             
//    A:::::A             A:::::A     z::::::zzzzzzzzu:::::::::::::::uuk::::::k k:::::k   i::::::i     X::::::X     X::::::X     BB:::::BBBBBB::::::BA:::::A             A:::::A      Y:::::Y        C:::::CCCCCCCC::::C2:::::2       2222222:::::2       222222
//   A:::::A               A:::::A   z::::::::::::::z u:::::::::::::::uk::::::k  k:::::k  i::::::i     X:::::X       X:::::X     B:::::::::::::::::BA:::::A               A:::::A  YYYY:::::YYYY      CC:::::::::::::::C2::::::2222222:::::22::::::2222222:::::2
//  A:::::A                 A:::::A z:::::::::::::::z  uu::::::::uu:::uk::::::k   k:::::k i::::::i     X:::::X       X:::::X     B::::::::::::::::BA:::::A                 A:::::A Y:::::::::::Y        CCC::::::::::::C2::::::::::::::::::22::::::::::::::::::2
// AAAAAAA                   AAAAAAAzzzzzzzzzzzzzzzzz    uuuuuuuu  uuuukkkkkkkk    kkkkkkkiiiiiiii     XXXXXXX       XXXXXXX     BBBBBBBBBBBBBBBBBAAAAAAA                   AAAAAAAYYYYYYYYYYYYY           CCCCCCCCCCCCC2222222222222222222222222222222222222222
                                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                             

    fallback() external payable virtual {
        _fallback();
    }
}

