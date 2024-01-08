// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0 <0.7.0;

import "./AufNFT.sol";

interface ERC20Interface {
    function totalSupply() external returns (uint);
    function balanceOf(address tokenOwner) external returns (uint balance);
    function allowance(address tokenOwner, address spender) external returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function transferGuess(address recipient, uint256 _amount) external returns (bool success);
    function transferGuessUnstake(address recipient, uint256 _amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract AufFarmingIBY {
    string public name = "Farm AMONG NFT using IBY";
    address public owner;
   
    AufNFT public aufNFT;

    address[] public stakers;
    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    ERC20Interface public ibyAddress = ERC20Interface(0x6A68DE599E8E0b1856E322CE5Bd11c5C3C79712B);

    constructor(AufNFT _aufNFT) public {
       
        aufNFT = _aufNFT;
        owner = msg.sender;
    }

    function stakeTokens(uint _amount) public {
       
        require(_amount == 10000000000000000000000, "amount must be 10,000 AMONG");

        // Trasnfer Auf tokens to this contract for staking
        ERC20Interface(ibyAddress).transferFrom(msg.sender, address(this), _amount);

        // Update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        // Add user to stakers array *only* if they haven't staked already
        if(!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        // Update staking status
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }

    // Unstaking Tokens (Withdraw)
    function unstakeTokens() public {
        // Fetch staking balance
        uint balance = stakingBalance[msg.sender];

        // Require amount greater than 0
        require(balance > 0, "staking balance cannot be 0");

        // Transfer Auf tokens to this contract for staking
        ERC20Interface(ibyAddress).transfer(msg.sender, balance);

        // Reset staking balance
        stakingBalance[msg.sender] = 0;

        // Update staking status
        isStaking[msg.sender] = false;
    }

    // Issuing Tokens
    function issueNFT() public {
        // Only owner can call this function
        require(msg.sender == owner, "caller must be the owner");

        // Issue tokens to all stakers
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            uint NFTtokens = 0;
            if(balance > 0) {
                NFTtokens = balance / 10000000000000000000000;
                for (uint j=0; j<NFTtokens; j++) {
                aufNFT.mint(recipient);
                }
   
            }
        }
    }

}
