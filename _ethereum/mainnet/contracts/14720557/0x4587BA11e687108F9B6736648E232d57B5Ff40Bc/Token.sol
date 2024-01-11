// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";

interface IToken is IERC20{
    function purchase(uint amount) external payable returns (uint, uint);
    function mint(uint amount) external; 
    function convertAmount(uint amount) external view returns(uint);
    function transfer(address recipient, uint256 amount) external override returns (bool);
    function withdraw(uint amount, address payable pocket) external;
    function redeem(address receiver, uint amount, uint transaction) external payable;
    function getUtilityAccount() external view returns (address);
}   


contract Token is ERC20, Ownable{
    address public minter;
    address public utility_account;
    
    uint public tokenPriceInWei;
   
    event Redeem(address indexed receiver, uint indexed amount, uint indexed transaction);

    constructor(address _utility_account) ERC20("PZLR","$PZLR") {
        minter = msg.sender;
        utility_account = _utility_account;

        tokenPriceInWei = 79642600119000;
    }

    function setUtilityAccount(address _utility_account) public onlyOwner
    {
       utility_account = _utility_account;
    }
    
    function getUtilityAccount() public view returns (address)
    {
        return utility_account;
    }

    function mint(uint amount) virtual external onlyOwner{
        _mint(minter,amount * 10 ** 18);
    }

    function redeem(address receiver, uint amount, uint transaction) virtual external payable{
        require(balanceOf(minter) >= amount,"Insufficient PZLR Available");

        transferFrom(minter,receiver, amount);

        emit Redeem(receiver, amount, transaction);
    }
    
    function purchase(uint qty) virtual public payable returns (uint tokens, uint amount)
    {
        uint _amount =  tokenPriceInWei * qty;
        uint _tokens = (qty * 10 ** 18); 
       
        require(msg.value > 0, "Send ETH to purchase tokens");
        require(msg.sender.balance > _amount,"Insufficient funds (ETH) available");
        require(msg.value >= _amount,"Insufficient funds (ETH) sent");
        require(balanceOf(minter) >= _tokens,"Amount of PZLR requested is unavailable: ");
        
        _transfer(minter,msg.sender,_tokens);
        
        return (_tokens, _amount);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        if (msg.sender == utility_account)
        {
            _approve(minter, spender, amount);
            return true;
        }
        else
            return ERC20.approve(spender, amount);
    }

    function withdraw(uint _amount, address payable _pocket) virtual external onlyOwner
    {
        require(_amount <=address(this).balance,"Not enough pocket money available");
      
        _pocket.transfer(_amount);
    }
}

