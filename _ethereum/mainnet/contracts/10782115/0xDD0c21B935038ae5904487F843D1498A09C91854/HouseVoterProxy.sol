/**
 *Submitted for verification at Etherscan.io on 2020-08-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface MasterChef {
    function balanceOf(address) external view returns (uint);
}

contract HouseVoterProxy {
    using SafeMath for uint;
    
    IERC20 public constant votes = IERC20(0x19810559dF63f19cfE88923313250550eDADB743);
    MasterChef public constant chef = MasterChef(0xc18109C4fEe0b915CEE8C56d65CC1b44c866aA35);
    uint public constant pool = uint(12);
    
    function decimals() external pure returns (uint8) {
        return uint8(0);
    }
    
    function name() external pure returns (string memory) {
        return "Toast.finance";
    }
    
    function symbol() external pure returns (string memory) {
        return "HOUSE";
    }
    
    function totalSupply() external view returns (uint) {
        return votes.totalSupply();
    }
    
    function balanceOf(address _voter) external view returns (uint) {
        uint _votes = chef.balanceOf(_voter).add(votes.balanceOf(_voter));
        return _votes;
    }
    
    constructor() public {}
}