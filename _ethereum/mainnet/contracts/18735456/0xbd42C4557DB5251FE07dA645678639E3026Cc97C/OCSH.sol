// SPDX-License-Identifier: MIT

/*
  /$$$$$$                  /$$ /$$                     /$$          
 /$$__  $$                | $$|__/                    | $$          
| $$  \ $$  /$$$$$$   /$$$$$$$ /$$ /$$$$$$$   /$$$$$$ | $$  /$$$$$$$
| $$  | $$ /$$__  $$ /$$__  $$| $$| $$__  $$ |____  $$| $$ /$$_____/
| $$  | $$| $$  \__/| $$  | $$| $$| $$  \ $$  /$$$$$$$| $$|  $$$$$$ 
| $$  | $$| $$      | $$  | $$| $$| $$  | $$ /$$__  $$| $$ \____  $$
|  $$$$$$/| $$      |  $$$$$$$| $$| $$  | $$|  $$$$$$$| $$ /$$$$$$$/
 \______/ |__/       \_______/|__/|__/  |__/ \_______/|__/|_______/ 
                                                                    
                                                                    
                                                                    
              /$$$$$$                      /$$                      
             /$$__  $$                    | $$                      
            | $$  \__/  /$$$$$$   /$$$$$$$| $$$$$$$                 
            | $$       |____  $$ /$$_____/| $$__  $$                
            | $$        /$$$$$$$|  $$$$$$ | $$  \ $$                
            | $$    $$ /$$__  $$ \____  $$| $$  | $$                
            |  $$$$$$/|  $$$$$$$ /$$$$$$$/| $$  | $$                
             \______/  \_______/|_______/ |__/  |__/                

Website: https://www.ordinalscash.net/
Telegram: https://t.me/OrdinalsCashPort
X: https://twitter.com/OrdinalsCash
*/
pragma solidity ^0.8.23;

contract OCSH {
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    string public constant name = "ORDCSH";
    string public constant symbol = "OCSH";
    uint8 public constant decimals = 18;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(uint256 initialSupply) {
        _mint(msg.sender, initialSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}