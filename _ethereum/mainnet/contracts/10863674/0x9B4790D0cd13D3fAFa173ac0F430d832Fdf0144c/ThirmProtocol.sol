// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

contract ThirmProtocol {

    address payable owner;
    uint256 MAX_LENGTH = 999;
    mapping(address => mapping(string => string)) addressStore;
    mapping(string => uint256) tTokenStore;

    constructor()  {
        owner = msg.sender;
    }

    function getTToken(string memory  _token) public view returns ( uint256 ) {
        return tTokenStore[_token];
    }
    
    function setTToken(string memory _tkn,uint256  _value) public isadmin()  {
        tTokenStore[_tkn] = _value;
    }

    function setAddress(string memory _key, string memory _value) public {
        require(bytes(_value).length <= MAX_LENGTH);
        addressStore[msg.sender][_key] = _value;
    }
    
    function getAddress(address  _acct, string memory _key)
        public
        view
        returns (string memory)
    {
        return addressStore[_acct][_key];
    }

    function delme() public isadmin(){
    selfdestruct(owner);
    }
    
    modifier isadmin() {
        require( msg.sender == owner, "Not authorized.");
        _;
    }

}