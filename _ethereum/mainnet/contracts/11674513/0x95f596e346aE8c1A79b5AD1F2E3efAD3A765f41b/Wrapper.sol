pragma solidity ^0.5.1;

contract Ownable{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract UndgToken {
  function setAddressToExcludeRecipients (address addr) public;
  function setAddressToExcludeSenders (address addr) public;
  function removeAddressFromExcludes (address addr) public;
  function changePercentOfTax(uint percent) public;
  function changeServiceWallet(address addr) public;
}


contract Wrapper is Ownable {
    
    address public serviceWallet = 0x40118E5489d9D43C6711C437268A48ab935c2DD6;
    uint public percentTax = 4;
    
    UndgToken UNDG = UndgToken(0xA5959E9412d27041194c3c3bcBE855faCE2864F7);
 
    function setAddressToExcludeRecipients (address addr) public onlyOwner {
        UNDG.setAddressToExcludeRecipients(addr);
    }

    function setAddressToExcludeSenders (address addr) public onlyOwner {
        UNDG.setAddressToExcludeSenders(addr);
    }

    function removeAddressFromExcludes (address addr) public onlyOwner {
        UNDG.removeAddressFromExcludes(addr);
    }
    
    function changePercentOfTax(uint percent) public onlyOwner {
        require(percent <= 10, "Max tax 10%");
        UNDG.changePercentOfTax(percent);
        percentTax = percent;
    }

    function changeServiceWallet(address addr) public onlyOwner {
        UNDG.changeServiceWallet(addr);
        serviceWallet = addr;
    }
}