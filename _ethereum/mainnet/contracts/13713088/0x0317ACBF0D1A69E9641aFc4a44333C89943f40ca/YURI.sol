
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yuri Beats
/// @author: manifold.xyz

import "./Proxy.sol";
import "./Address.sol";
import "./StorageSlot.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                              bbbbbbbb                                                                                           //
//                                                                   iiii       b::::::b                                                        tttt                               //
//                                                                  i::::i      b::::::b                                                     ttt:::t                               //
//                                                                   iiii       b::::::b                                                     t:::::t                               //
//                                                                               b:::::b                                                     t:::::t                               //
//    yyyyyyy           yyyyyyyuuuuuu    uuuuuu rrrrr   rrrrrrrrr  iiiiiii       b:::::bbbbbbbbb        eeeeeeeeeeee    aaaaaaaaaaaaa  ttttttt:::::ttttttt        ssssssssss       //
//     y:::::y         y:::::y u::::u    u::::u r::::rrr:::::::::r i:::::i       b::::::::::::::bb    ee::::::::::::ee  a::::::::::::a t:::::::::::::::::t      ss::::::::::s      //
//      y:::::y       y:::::y  u::::u    u::::u r:::::::::::::::::r i::::i       b::::::::::::::::b  e::::::eeeee:::::eeaaaaaaaaa:::::at:::::::::::::::::t    ss:::::::::::::s     //
//       y:::::y     y:::::y   u::::u    u::::u rr::::::rrrrr::::::ri::::i       b:::::bbbbb:::::::be::::::e     e:::::e         a::::atttttt:::::::tttttt    s::::::ssss:::::s    //
//        y:::::y   y:::::y    u::::u    u::::u  r:::::r     r:::::ri::::i       b:::::b    b::::::be:::::::eeeee::::::e  aaaaaaa:::::a      t:::::t           s:::::s  ssssss     //
//         y:::::y y:::::y     u::::u    u::::u  r:::::r     rrrrrrri::::i       b:::::b     b:::::be:::::::::::::::::e aa::::::::::::a      t:::::t             s::::::s          //
//          y:::::y:::::y      u::::u    u::::u  r:::::r            i::::i       b:::::b     b:::::be::::::eeeeeeeeeee a::::aaaa::::::a      t:::::t                s::::::s       //
//           y:::::::::y       u:::::uuuu:::::u  r:::::r            i::::i       b:::::b     b:::::be:::::::e         a::::a    a:::::a      t:::::t    ttttttssssss   s:::::s     //
//            y:::::::y        u:::::::::::::::uur:::::r           i::::::i      b:::::bbbbbb::::::be::::::::e        a::::a    a:::::a      t::::::tttt:::::ts:::::ssss::::::s    //
//             y:::::y          u:::::::::::::::ur:::::r           i::::::i      b::::::::::::::::b  e::::::::eeeeeeeea:::::aaaa::::::a      tt::::::::::::::ts::::::::::::::s     //
//            y:::::y            uu::::::::uu:::ur:::::r           i::::::i      b:::::::::::::::b    ee:::::::::::::e a::::::::::aa:::a       tt:::::::::::tt s:::::::::::ss      //
//           y:::::y               uuuuuuuu  uuuurrrrrrr           iiiiiiii      bbbbbbbbbbbbbbbb       eeeeeeeeeeeeee  aaaaaaaaaa  aaaa         ttttttttttt    sssssssssss        //
//          y:::::y                                                                                                                                                                //
//         y:::::y                                                                                                                                                                 //
//        y:::::y                                                                                                                                                                  //
//       y:::::y                                                                                                                                                                   //
//      yyyyyyy                                                                                                                                                                    //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract YURI is Proxy {
    
    constructor(address creatorImplementation) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = creatorImplementation;
        Address.functionDelegateCall(
            creatorImplementation,
            abi.encodeWithSignature("initialize(string,string)", "Yuri Beats", "YURI")
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}
