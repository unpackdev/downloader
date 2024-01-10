//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract Egg is ERC20, Ownable, Pausable {

    bool public _enabled = false; 
    address public stakingContract;

    address public marketingAddress;
    address public communityAddress;
    address public liquidityAddress;
    uint256 public tokenAmount = 0;

    uint public marketingPercent = 2;
    uint public communityPercent = 1;
    uint public liquidityPercent = 2;


    mapping(address => uint256) public holder;
    

    constructor() ERC20("Egg", "EGG") {
        // _mint(msg.sender, 10076 * (10 ** 18));
        marketingAddress = 0x37504C40cFDF39ea0fD5BD5AE3ecff5C1bf85A4A;
        communityAddress = 0x9cF12D47aa3760504d81fCB67921eD03cf47d620;
        liquidityAddress = 0xa983b2C63A4F59d98b9989f28260d7ee75fF528f;
    }

    function disable() public onlyOwner {
        _pause();
    }
    function enable() public onlyOwner {
        _unpause();
    }

    function setMarketingAddress(address _marketingAddress) public onlyOwner {
        marketingAddress = _marketingAddress;
    }

    function setCommunityAddress(address _communityAddress) public onlyOwner {
        communityAddress = _communityAddress;
    }

    function setliquidityAddress(address _liquidityAddress) public onlyOwner {
        liquidityAddress = _liquidityAddress;
    }


    function setMarketingPercent(uint _marketingPercent) public onlyOwner {
        marketingPercent = _marketingPercent;
    }

    function setCommunityPercent(uint _communityPercent) public onlyOwner {
        communityPercent = _communityPercent;
    }

    function setliquidityPercent(uint _liquidityPercent) public onlyOwner {
        liquidityPercent = _liquidityPercent;
    }


    function setStakingContract(address _stakingContract) public onlyOwner {
       stakingContract = _stakingContract;
    }
    
    function burn(address account, uint256 amount) public virtual onlyOwner returns (bool){
        _burn(account,amount);
        return true;
    }

    function mint(address sender, uint256 amount) external {
        require(msg.sender == owner() || msg.sender == stakingContract, "Bad request");
        _mint(sender, amount * (10 ** 18));
        tokenAmount += amount;
        holder[sender] += amount;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, liquidityAddress,      (amount * liquidityPercent) / 100);
        _transfer(msg.sender, marketingAddress,     (amount * marketingPercent) / 100);
        _transfer(msg.sender, communityAddress,     (amount * communityPercent) / 100);
        _transfer(msg.sender, recipient, (amount * (100 - liquidityPercent - marketingPercent - communityPercent)) / 100 );

        holder[liquidityAddress]   += (amount * liquidityPercent) / 100;
        holder[marketingAddress] +=  (amount * marketingPercent) / 100;
        holder[communityAddress] +=  (amount * communityPercent) / 100;
        holder[recipient]       +=   (amount * (100 - liquidityPercent - marketingPercent - communityPercent)) / 100;
        
        holder[msg.sender] -=  amount;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override  returns (bool){
        _transfer(sender, liquidityAddress,      (amount * liquidityPercent) / 100);
        _transfer(sender, marketingAddress,     (amount * marketingPercent) / 100);
        _transfer(sender, communityAddress,     (amount * communityPercent) / 100);
        _transfer(sender, recipient,            (amount * (100 - liquidityPercent - marketingPercent - communityPercent)) / 100 );
        
        holder[liquidityAddress]   +=(amount * liquidityPercent) / 100;
        holder[marketingAddress] += (amount * marketingPercent) / 100;
        holder[communityAddress] += (amount * communityPercent) / 100;
        holder[recipient]       +=  (amount * (100 - liquidityPercent - marketingPercent - communityPercent)) / 100 ;
        
        holder[sender] -=  amount;
        return true;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}