pragma solidity ^0.4.0;


//市场信息
contract marketinfo {
   
    address[] public requests;
    function add_market( address data) public {
        requests.push(data);
    }
    
}