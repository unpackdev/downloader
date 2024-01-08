// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20Upgradeable.sol";

contract publicSale is Ownable{
    
    address payable private _owner;
    ERC20Upgradeable public KOO;
    
    uint256 public EtherRaised = 0;
    uint256 public KOOperWei = 6000000;
    uint256 public KOOperETH = 6000000 * 10 ** 18;
    uint256 public TotalKOOforSale = KOOperETH * 100;

    event purchase(address sender, uint256 ETHdeposit, uint256 KOOrecieved);
    event deposit(address sender, uint256 KOOrecieved);

    constructor(address _t){
        _owner = payable(msg.sender);
        KOO = ERC20Upgradeable(_t);
        KOO.approve(address(this), 2**256-1);
    }

    function depositKOOforSale() public payable {
        emit deposit(msg.sender, KOO.balanceOf(address(this)));
    }

    function collectFunds() public payable onlyOwner {   
        _owner.transfer(address(this).balance);
    }

    function refundKOO(uint256 _amt) public payable onlyOwner {   
        KOO.transfer(_owner, _amt);
    }

    function getKOObalance() public view returns(uint256){
        return KOO.balanceOf(address(this));
    }

    function Invest() payable public{
        require((msg.value >= 0.05 ether && msg.value <= 1.5 ether), 'Only accepting ETH investment in the range 0.05ether - 1.5ether');
        
        uint256 _amt = msg.value * KOOperWei;
        require(KOO.balanceOf(address(this)) > _amt, "No more KOO tokens left for sale!");
        
        KOO.transfer(msg.sender, _amt);
        emit purchase(msg.sender, msg.value, _amt);
        EtherRaised += msg.value;
    }
    
    function endSale() public onlyOwner{
        selfdestruct(_owner);
    }
}