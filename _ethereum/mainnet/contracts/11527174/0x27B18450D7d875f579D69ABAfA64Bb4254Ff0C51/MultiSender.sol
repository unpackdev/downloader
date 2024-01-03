// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract MultiSender {
    
    address payable public owner;
    uint256 public userfee;
    uint32 public arrayLimit;
    
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
    
    
    function collectFee() public onlyOwner
    {
        owner.transfer(address(this).balance);
    }
    
    function config(uint256 _newFee, uint32 _newLimit) public onlyOwner {
        
        userfee = _newFee;
        arrayLimit = _newLimit;
    }
    
    constructor()
    {
        arrayLimit = 10000;
        userfee = 0.001 ether;
        owner = msg.sender;
    }
    
    fallback () external payable {}
    
    function multisend(address payable[] calldata  _contributors, uint256[] calldata _balances) public payable {
        uint256 total = msg.value;
        require(total >= userfee);
        require(_contributors.length <= arrayLimit);
        total = sub(total, userfee);
        uint32 i = 0;
        for (i; i < _contributors.length; i++) {
            total = sub(total, _balances[i]);
           _contributors[i].transfer(_balances[i]);
        }
    }
    
      function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
      }

}