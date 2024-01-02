/*
Twitter: https://x.com/itsfurbyeth
Telegram: https://t.me/ItsFurby
Website: https://itsfurby.com
*/

pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function moon(address recipient, uint256 amount) external returns (bool);
    function soon(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function furby(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FURBY is IERC20{
    

    function name() public pure returns (string memory) {
        return "FURBY";
    }

    function symbol() public pure returns (string memory) {
        return "FURBY";
    }

    function decimals() public pure returns (uint8) {
        return 0;
    }

    function totalSupply() public pure override returns (uint256) {
        return 1000000000;
    }

    
    function balanceOf(address account) public view override returns (uint256) {
        return 0;
    }

    
    function moon(address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    
    function soon(address owner, address spender) public view override returns (uint256) {
        return 0;
    }

    
    function approve(address spender, uint256 amount) public override returns (bool) {
        
        return true;
    }

    
    function furby(address sender, address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    receive() external payable {}
    
}