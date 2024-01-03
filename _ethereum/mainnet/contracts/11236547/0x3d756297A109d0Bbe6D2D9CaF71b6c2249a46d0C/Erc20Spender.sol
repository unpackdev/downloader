pragma solidity 0.5.10;

contract ERC20Token {
    function transferFrom(address from, address to, uint value) public;
}

contract Manageable {
    mapping(address => bool) public admins;
    constructor() public {
        admins[msg.sender] = true;
    }

    modifier onlyAdmins() {
        require(admins[msg.sender]);
        _;
    }

    function modifyAdmins(address[] memory newAdmins, address[] memory removedAdmins) public onlyAdmins {
        for(uint256 index; index < newAdmins.length; index++) {
            admins[newAdmins[index]] = true;
        }
        for(uint256 index; index < removedAdmins.length; index++) {
            admins[removedAdmins[index]] = false;
        }
    }
}

contract Erc20Spender is Manageable {

    function transferFrom(address tokenAddress, address from, address to, uint256 value) public {
        ERC20Token(tokenAddress).transferFrom(from, to, value);
    }
    
    function tokenFallback(address, uint256) public pure { revert(); }

    function() external payable { revert(); }
}