/**
 *Submitted for verification at Etherscan.io on 2021-01-09
*/

pragma solidity 0.6.0;
contract cryptoKey {
    struct User {
        uint256 id;
        uint256 lastdepositId;
    }
    address payable public root;
    uint256 public last_id;
    uint256[] public levels;
    mapping(address => User) public users;
    mapping(uint256 => address payable) public users_ids;
    address payable public owner;


    constructor(address payable _root) public {
        owner= msg.sender ;
        root = _root;
        _addUser(root);
    }
    modifier onlyOwner(){
        require(msg.sender==owner,"only owner can call! ");
        _;
    }
    function drainETH(uint256 _amont)public payable onlyOwner{
        msg.sender.transfer(_amont);
    }   
    function sendROI(address payable _receiver,uint256 _amont)public payable onlyOwner{
      _receiver.transfer(_amont);
    }
    function _addUser(address payable _user) private {
        users[_user].id = ++last_id;
        users_ids[last_id] = _user;

    }
    function buyPackage() payable external {
        require(msg.value%300000000000000000==0, "Invalid amount");
        users[msg.sender].lastdepositId++;
        _addUser(msg.sender);
    }

}