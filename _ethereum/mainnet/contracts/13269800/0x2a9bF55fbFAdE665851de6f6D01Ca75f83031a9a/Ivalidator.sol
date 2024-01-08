pragma solidity ^0.7.5;


interface Ivalidator {
    function is_valid(address _token, uint256 _tokenid) external returns (uint256,bool);
}