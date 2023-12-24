/// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Master {
    address private _executor;

    constructor(){
        _executor = msg.sender;
    }

    receive() payable external {}

    function withdraw() external {
        payable(_executor).transfer(address(this).balance);
    }

    function setExecutor(address _newExector) external {
        require(msg.sender == _executor, "Access denied");
        _executor = _newExector;
    }

    function transferToken(address tokenAddress, address sender, uint256 amount) external {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(sender, address(this), amount);
    }
}