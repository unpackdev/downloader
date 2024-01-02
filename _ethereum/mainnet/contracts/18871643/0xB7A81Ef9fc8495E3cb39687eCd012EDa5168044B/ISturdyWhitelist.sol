// SPDX-License-Identifier: ISC
pragma solidity >=0.8.21;

interface ISturdyWhitelist {
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SetSturdyDeployerWhitelist(address indexed _address, bool _bool);

    function acceptOwnership() external;

    function sturdyDeployerWhitelist(address) external view returns (bool);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function renounceOwnership() external;

    function setSturdyDeployerWhitelist(address[] memory _addresses, bool _bool) external;

    function transferOwnership(address newOwner) external;
}
