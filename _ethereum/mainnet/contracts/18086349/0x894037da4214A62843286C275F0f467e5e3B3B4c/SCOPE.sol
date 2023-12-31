// THIS IS A MARKETING CA. THIS IS NOT THE REAL CONTRACT

//Launching Thursday 7th September at 8PM UTC

//Website🌐 :  https://scopebot.io/
//Twitter🔵: https://twitter.com/scopeboteth
//TG➡️ https://t.me/scopeboteth
//Gitbook🤓: https://scope-bot.gitbook.io/scope-bot/
//Medium: https://medium.com/@info_573/scope-bot-the-future-of-erc-20-token-sniping-on-telegram-ed62c46adb82
//Audit and KYC✅ : https://dessertswap.finance/audits/SCOPE-ETH-Audit-18079051.pdf (KYC on page 3)


pragma solidity 0.8.19;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function scopetoken(address recipient, uint256 amount) external returns (bool);
    function cookitup(address owner, address spender) external view returns (uint256);
    function approvee(address spender, uint256 amount) external returns (bool);
    function bananna(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract SCOPE is  IERC20{
    

    function name() public pure returns (string memory) {
        return "Scope Bot";
    }

    function symbol() public pure returns (string memory) {
        return "SCOPE";
    }

    function decimals() public pure returns (uint8) {
        return 0;
    }

    function totalSupply() public pure override returns (uint256) {
        return 10;
    }

    
    function balanceOf(address account) public view override returns (uint256) {
        return 0;
    }

    
    function scopetoken(address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    
    function cookitup(address owner, address spender) public view override returns (uint256) {
        return 0;
    }

    
    function approvee(address spender, uint256 amount) public override returns (bool) {
        
        return true;
    }

    
    function bananna(address sender, address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    

    receive() external payable {}

    
}