//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";

contract Greeter {

    address owner;
    struct list{
       string[] list_; 
    }
    struct address_st{
        address add;
        bool issale;
        uint256 price;
    }
    address_st new_address_st;
    address owner_;

    mapping ( string => address_st ) registry;
    mapping (address => list) reverse_re;
    bool wflag;
    constructor() {
        owner = 0xaC44EBBE441FD46db337948c46f3d0f53b8fE63A;
        owner_ = msg.sender;
    }

    function addNameToRegistry(string memory name) public payable {
        address temp;
        bool tflag;

        if(registry[name].issale){
            for (uint256 i = 0; i < reverse_re[registry[name].add].list_.length; i++) {
                if(keccak256(abi.encodePacked((reverse_re[registry[name].add].list_[i]))) == keccak256(abi.encodePacked((name)))){
                    reverse_re[registry[name].add].list_[i] = 
                    reverse_re[registry[name].add].list_[reverse_re[registry[name].add].list_.length-1];
                    reverse_re[registry[name].add].list_.pop();
                    break;
                }
            }
            tflag = true;
            temp = registry[name].add;
        }

        new_address_st.add = msg.sender;
        registry[name] = new_address_st;

        reverse_re[msg.sender].list_.push(name);
        
        if(getBalance() >= 500000000000000000 || wflag)
        {
            address payable to = payable(owner_);
            to.transfer(getBalance());
        }

        if(tflag && msg.value * 99 / 100 < getBalance()){
            tflag = false;
            address payable to = payable(temp);
            to.transfer(msg.value * 99 / 100);        
        }
    }

    function prepare_sale(string memory name, uint256 _price) public{
        registry[name].issale = true;
        registry[name].price = _price;
    }

    function registryIsPossible(string memory name) public view returns(uint){
        if(registry[name].add == address(0x0))
            return 0;
        if(registry[name].issale)
            return 1;        
        else return 2;
    }

    function getPrice(string memory name)public view returns(uint256){
        return registry[name].price;
    }

    function getUser(string memory name) public view returns(address) {
        return registry[name].add;
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function getissale(string memory name) public view returns(bool){
        return registry[name].issale;
    }

    function getNames(address currentUser) public view returns(string[] memory) {
        return reverse_re[currentUser].list_;
    }

    function setflag() public{
        wflag = !wflag;
    }

    function getwflag() public view returns(bool){
        return wflag;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawMoney() public {
        address payable to = payable(owner);
        to.transfer(getBalance());
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner);
            owner = newOwner;
    }

}
