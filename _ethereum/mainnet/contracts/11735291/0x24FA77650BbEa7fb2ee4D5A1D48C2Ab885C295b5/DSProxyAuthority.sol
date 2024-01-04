//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.6;

import "./Ownable.sol";

interface IDSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) external view returns (bool);
}

contract DSProxyAuthority is IDSAuthority, Ownable{

    mapping(address => bool)  public srcCanCall;
    
    function setSrcCanCall(address src, bool can) public onlyOwner {
        srcCanCall[src] = can;
    }

    function canCall(
        address src, address dst, bytes4 sig
    ) external view override returns (bool){
        return srcCanCall[src];
    }

}
