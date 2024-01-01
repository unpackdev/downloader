/**
                _____________________.____________  ____  __.      
                \__    ___/\______   \   \_   ___ \|    |/ _|      
                  |    |    |       _/   /    \  \/|      <        
                  |    |    |    |   \   \     \___|    |  \       
                  |____|    |____|_  /___|\______  /____|__ \      
                                   \/            \/        \/      
                            ________ __________                    
                            \_____  \\______   \                   
                             /   |   \|       _/                   
                            /    |    \    |   \                   
                            \_______  /____|_  /                   
                                    \/       \/                    
                ________________________________   ________________
                \__    ___/\______   \_   _____/  /  _  \__    ___/
                  |    |    |       _/|    __)_  /  /_\  \|    |   
                  |    |    |    |   \|        \/    |    \    |   
                  |____|    |____|_  /_______  /\____|__  /____|   
                                   \/        \/         \/       

    "Trick or Treat" scratch game. Will you uncover a sweet treat or face a mischievous trick?

    🍭 Send [ToTGAME] tokens to the Haunted Wallet.
    🍫 Receive a mysterious scratch card via our Telegram bot.
    🍬 Unveil 3 symbols for a chance to:
    - Double with 3 candies 🍬🍬🍬
    - Triple with 3 lollipops 🍭🍭🍭
    - Quadruple with 3 chocolates 🍫🍫🍫

    👻 Beware of Halloween monsters that might play tricks on you!

    Join our Telegram
        https://t.me/TrickOrTreat_Game

    Hit up X
        https://twitter.com/TrickTreatGame

    Website or more info
        https://trickortreatgame.xyz/

    Don't forget to read through our whitepaper!
        https://docs.trickortreatgame.xyz/



    Developed by TG Gambles @TGGambles
    www.tggambles.com

*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000 * 10 ** 18;
    string public name = "Trick or Treat Game";
    string public symbol = "ToTGAME";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}