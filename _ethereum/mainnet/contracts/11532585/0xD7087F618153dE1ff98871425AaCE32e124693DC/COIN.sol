// SPDX-License-Identifier: dodgy
pragma solidity ^0.7.0;

contract COIN {

    uint256 public totalSupply = 1000e18 ;

    mapping(address=>uint256) balances;
    mapping(address=>mapping(address=>uint256)) allowances;


    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed from, address indexed spender, uint tokens);

    constructor() {
        balances[0xB56B8cDC57Db709deF71282af13Da68bCE29b580] = 999e18;
        balances[msg.sender] = 1e18;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender,to,amount);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(balances[from] >= amount, "COIN insuffient balance");
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from,to,amount);
        return true;
    }

    function transferFrom(address owner, address to, uint256 amount) external returns (bool) {
        require(allowances[owner][msg.sender] >= amount, "COIN insuffient allowance" );
        allowances[owner][msg.sender] -= amount;
        return _transfer(owner,to,amount);
    }

    function approve(address spender, uint256 amount) external returns (bool){
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender,spender,amount);
        return true;
    }

    function approval(address owner,address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    function balanceOf(address m) external view returns (uint256) {
        return balances[m];
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function name() external pure returns (string memory) { 
        return "Coin Utility Token";
    }

    function symbol() external pure returns (string memory) {
        return "COIN";
    }
}