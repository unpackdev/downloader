pragma solidity >=0.6.0 <0.7.0;

interface IAllowList {
    function isAllowedAccount(address account) external view returns (bool);
}

interface IAllowListChange {
    function allowAccount(address account) external;

    function disallowAccount(address account) external;
}
