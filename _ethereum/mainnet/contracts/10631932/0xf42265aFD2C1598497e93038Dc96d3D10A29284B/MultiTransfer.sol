pragma solidity ^0.6.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract MultiTransfer {
    address owner;
    
    IERC20 usdt;
    
    constructor (address _usdt) public {
        owner = msg.sender;
        usdt = IERC20(_usdt);
    }
    
    function multiTransferUSDT(
        address[] memory to,
        uint256[] memory amounts
    )
    public
    {
        require(to.length == amounts.length);
        for(uint256 i = 0; i < to.length; i++) {
            usdt.transfer(to[i], amounts[i]);
        }
    }
    
    function returnUSDT() external {
        require(msg.sender == owner);
        usdt.transfer(msg.sender, usdt.balanceOf(address(this)));
    }
    
    function changeUSDT(address _usdt) external {
        require(msg.sender == owner);
        usdt = IERC20(_usdt);
    }
}