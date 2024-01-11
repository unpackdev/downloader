
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                                               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
import "./Address.sol";
import "./StorageSlot.sol";

contract ReGuLaTeD{
    // ReGuLaTeD
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
                                                                                  
                                                                                                                                                                                                                

    fallback() external payable virtual {
        _fallback();
    }
}


                                                                                                                                                                                                    
                                                                                                                                                                                                    
// RRRRRRRRRRRRRRRRR                               GGGGGGGGGGGGG                  LLLLLLLLLLL                            TTTTTTTTTTTTTTTTTTTTTTT              DDDDDDDDDDDDD         222222222222222    
// R::::::::::::::::R                           GGG::::::::::::G                  L:::::::::L                            T:::::::::::::::::::::T              D::::::::::::DDD     2:::::::::::::::22  
// R::::::RRRRRR:::::R                        GG:::::::::::::::G                  L:::::::::L                            T:::::::::::::::::::::T              D:::::::::::::::DD   2::::::222222:::::2 
// RR:::::R     R:::::R                      G:::::GGGGGGGG::::G                  LL:::::::LL                            T:::::TT:::::::TT:::::T              DDD:::::DDDDD:::::D  2222222     2:::::2 
//   R::::R     R:::::R    eeeeeeeeeeee     G:::::G       GGGGGGuuuuuu    uuuuuu    L:::::L                 aaaaaaaaaaaaaTTTTTT  T:::::T  TTTTTTeeeeeeeeeeee    D:::::D    D:::::D             2:::::2 
//   R::::R     R:::::R  ee::::::::::::ee  G:::::G              u::::u    u::::u    L:::::L                 a::::::::::::a       T:::::T      ee::::::::::::ee  D:::::D     D:::::D            2:::::2 
//   R::::RRRRRR:::::R  e::::::eeeee:::::eeG:::::G              u::::u    u::::u    L:::::L                 aaaaaaaaa:::::a      T:::::T     e::::::eeeee:::::eeD:::::D     D:::::D         2222::::2  
//   R:::::::::::::RR  e::::::e     e:::::eG:::::G    GGGGGGGGGGu::::u    u::::u    L:::::L                          a::::a      T:::::T    e::::::e     e:::::eD:::::D     D:::::D    22222::::::22   
//   R::::RRRRRR:::::R e:::::::eeeee::::::eG:::::G    G::::::::Gu::::u    u::::u    L:::::L                   aaaaaaa:::::a      T:::::T    e:::::::eeeee::::::eD:::::D     D:::::D  22::::::::222     
//   R::::R     R:::::Re:::::::::::::::::e G:::::G    GGGGG::::Gu::::u    u::::u    L:::::L                 aa::::::::::::a      T:::::T    e:::::::::::::::::e D:::::D     D:::::D 2:::::22222        
//   R::::R     R:::::Re::::::eeeeeeeeeee  G:::::G        G::::Gu::::u    u::::u    L:::::L                a::::aaaa::::::a      T:::::T    e::::::eeeeeeeeeee  D:::::D     D:::::D2:::::2             
//   R::::R     R:::::Re:::::::e            G:::::G       G::::Gu:::::uuuu:::::u    L:::::L         LLLLLLa::::a    a:::::a      T:::::T    e:::::::e           D:::::D    D:::::D 2:::::2             
// RR:::::R     R:::::Re::::::::e            G:::::GGGGGGGG::::Gu:::::::::::::::uuLL:::::::LLLLLLLLL:::::La::::a    a:::::a    TT:::::::TT  e::::::::e        DDD:::::DDDDD:::::D  2:::::2       222222
// R::::::R     R:::::R e::::::::eeeeeeee     GG:::::::::::::::G u:::::::::::::::uL::::::::::::::::::::::La:::::aaaa::::::a    T:::::::::T   e::::::::eeeeeeeeD:::::::::::::::DD   2::::::2222222:::::2
// R::::::R     R:::::R  ee:::::::::::::e       GGG::::::GGG:::G  uu::::::::uu:::uL::::::::::::::::::::::L a::::::::::aa:::a   T:::::::::T    ee:::::::::::::eD::::::::::::DDD     2::::::::::::::::::2
// RRRRRRRR     RRRRRRR    eeeeeeeeeeeeee          GGGGGG   GGGG    uuuuuuuu  uuuuLLLLLLLLLLLLLLLLLLLLLLLL  aaaaaaaaaa  aaaa   TTTTTTTTTTT      eeeeeeeeeeeeeeDDDDDDDDDDDDD        22222222222222222222
                                                                                                                                                                                                    
                                                                                                                                                                                                    
                                                                                                                                                                                                    
                                                                                                                                                                                                    
                                                                                                                                                                                                    
                                                                                                                                                                                                    
                                                                                                                                                                                                    
