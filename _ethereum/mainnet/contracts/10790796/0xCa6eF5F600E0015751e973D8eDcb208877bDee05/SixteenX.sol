pragma solidity ^0.5.17;

/**   
     /** 16X PER DAY **
      
      Join our Telegram - https://t.me/sixteenXperday
      
It is a hyper inflationary token that gives the control of liquidity to its hodlers. 
There will be an initial supply of 1000 16X tokens listed on uniswap. 
The screenshot of all the holding wallets is taken right after 60 minutes of uniswap launch, 
we unlock the same quantity of tokens everyone is holding in their wallets and it will be distributed to all the hodlers.
Everyone will have their coins doubled in 60 minutes. 
The next window of 60 minutes starts right after the distribution is done and so on. 
The holders will have the opportunity of making 16X everyday. 
The tokens will keep unlocking till the total supply of 10 million is unlocked and distributed to the holders. 
Once the total supply is unlocked, it will be a completely decentralised system.
The asset will have its own value and the project will be driven by the community.

Important
Every time new tokens are unlocked, 20% goes to a managing wallet and funds are used to manage the gas fee and team rewards. 
As its going to be a hyper inflationary token, we will lock the liquidity only after we take our initial investment out from the liquidity pool i.e. 2 ETH + gas fee. 
The holders are required to keep the tokens in their wallet from the time of screenshot to the receiving of unlocked tokens. Anyone selling right after the screenshot and before token distribution will get disqualified. 

The motive behind the token is to provide a financial instrument for investors to earn from it according to their percentage of holding and ability to time the trades. The best movers will truly make more than 16X in a day. 


Proof of Hodling..
Let The Game Begin.

         */
  
  contract SixteenX {
    // Track how many tokens are owned by each address.
    mapping (address => uint256) public balanceOf;

    // Modify this section
    string public name = "16X PER DAY";
    string public symbol = "16X";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        // Initially assign all tokens to the contract's creator.
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  // deduct from sender's balance
        balanceOf[to] += value;          // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}