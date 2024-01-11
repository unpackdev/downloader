pragma solidity =0.6.6;

interface IOwnable {
    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}
