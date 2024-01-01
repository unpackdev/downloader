pragma solidity ^0.8.18;

import "./IERC721.sol";

interface IEcliptic is IERC721 {
    function transferPoint(uint32 _point, address _newOwner, bool _reset) external;
    function setTransferProxy(uint32 _point, address _transferProxy) external;
}

interface IAzimuth {
    function getOwner(uint32 _point) external view returns (address);
    function getOwnedPoints(address) external view returns (uint32[] memory);
    function owner() external view returns (address);
    function canTransfer(uint32 _point, address who) external view returns(bool);
}

interface ISoulboundAccessories {
    function miladyAuthority() external view returns(address);
}