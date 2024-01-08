// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0 <0.7.0;



import "./AufToken.sol";
import "./AufNFT.sol";

contract AufFarming {
    string public name = "Farm AMONG NFT";
    address public owner;
    AufToken public aufToken;
    AufNFT public aufNFT;

    address[] public stakers;
    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    constructor(AufToken _aufToken, AufNFT _aufNFT) public {
        aufToken = _aufToken;
        aufNFT = _aufNFT;
        owner = msg.sender;
    }

    function stakeTokens(uint _amount) public {
       
        require(_amount == 10000000000000000000000, "amount must be 10,000 AMONG");

        // Trasnfer Auf tokens to this contract for staking
        aufToken.transferFrom(msg.sender, address(this), _amount);

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
        aufToken.transfer(msg.sender, balance);

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
