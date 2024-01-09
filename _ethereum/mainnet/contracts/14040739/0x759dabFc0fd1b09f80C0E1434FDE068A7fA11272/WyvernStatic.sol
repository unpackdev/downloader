/*

  << Wyvern Static >>

*/

pragma solidity 0.7.5;

import "./StaticERC20.sol";
import "./StaticERC721.sol";
import "./StaticERC1155.sol";
import "./StaticUtil.sol";

/**
 * @title WyvernStatic
 * @author Wyvern Protocol Developers
 */
contract WyvernStatic is StaticERC20, StaticERC721, StaticERC1155, StaticUtil {

    string public constant name = "Wyvern Static";

    constructor (address atomicizerAddress)
        public
    {
        atomicizer = atomicizerAddress;
    }

    function test () 
        public
        pure
    {
    }

}
