pragma solidity 0.6.6;

interface ICurveMinter {
    function mint(address gauge_addr) external;
}