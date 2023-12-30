pragma solidity ^0.6.0;

import "./Static.sol";

abstract contract ISubscriptions is Static {

    function canCall(Method _method, uint _cdpId) external virtual view returns(bool, uint);
    function getOwner(uint _cdpId) external virtual view returns(address);
    function ratioGoodAfter(Method _method, uint _cdpId) external virtual view returns(bool, uint);
    function getRatio(uint _cdpId) public view virtual returns (uint);
    function getSubscribedInfo(uint _cdpId) public virtual view returns(bool, uint128, uint128, uint128, uint128, address, uint coll, uint debt);
    function unsubscribeIfMoved(uint _cdpId) public virtual;
}
