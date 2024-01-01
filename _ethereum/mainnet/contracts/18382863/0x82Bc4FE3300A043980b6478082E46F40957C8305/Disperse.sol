pragma solidity ^0.8.18;

//SPDX-License-Identifier: MIT Licensed

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(address from, address to, uint256 value) external;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Disperse {
    IERC20 public TOKEN;

    address public owner;  

    modifier onlyOwner() {
        require(msg.sender == owner, " Not an owner");
        _;
    }

    constructor(address _owner, address _TOKEN) {
        owner = _owner;
        TOKEN = IERC20(_TOKEN);
    }
 
 
       function disperseToken(
        address[] calldata addresses,
        uint256[] calldata amounts
    ) public {
        require(
            addresses.length == amounts.length,
            "Array sizes must be equal"
        );
        uint256 i = 0;
        while (i < addresses.length) {
            uint256 _amount = amounts[i]*(1e18);
            TOKEN.transferFrom(msg.sender, addresses[i], _amount);
            i += 1;
        }
    }
    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    } 

    // to draw out tokens
    function transferStuckTokens(
        IERC20 token,
        uint256 _value
    ) external onlyOwner {
        token.transfer(msg.sender, _value);
    }
}