// contracts/DBridgeToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AccessControl.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract DBridgeToken is ERC20Burnable, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    event Bridge(address indexed src, uint256 amount, uint256 chainId);

    constructor() ERC20("DBridge Token", "DBRIDGE") {}

    function mint(
        address _account, 
        uint256 _amount
    ) public onlyRole(MINTER_ROLE) returns (bool) {
        _mint(_account, _amount);
        return true;
    }

    function bridge(uint256 amount, uint256 chainId) public {
        _burn(_msgSender(), amount);
        emit Bridge(_msgSender(), amount, chainId);
    }
}