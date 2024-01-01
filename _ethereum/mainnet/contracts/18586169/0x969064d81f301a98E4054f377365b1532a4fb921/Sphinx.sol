// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Sphinx is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 1000000000 * 10**18; // 1 billion tokens

    mapping(address => bool) public isHolder;
    address[] public holders; // An array to store the list of token holders

    constructor() ERC20("SPHINX", "SPHINX") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
        isHolder[msg.sender] = true;
        holders.push(msg.sender);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        super.transfer(recipient, amount);
        updateHolderStatus(msg.sender);
        updateHolderStatus(recipient);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        super.transferFrom(sender, recipient, amount);
        updateHolderStatus(sender);
        updateHolderStatus(recipient);
        return true;
    }

    // Function to retrieve the list of token holders
    function getTokenHolders() external view returns (address[] memory) {
        return holders;
    }

    // Internal function to update holder status
    function updateHolderStatus(address holder) internal {
        if (balanceOf(holder) == 0 && isHolder[holder]) {
            isHolder[holder] = false;
            for (uint256 i = 0; i < holders.length; i++) {
                if (holders[i] == holder) {
                    holders[i] = holders[holders.length - 1];
                    holders.pop();
                    break;
                }
            }
        } else if (balanceOf(holder) > 0 && !isHolder[holder]) {
            isHolder[holder] = true;
            holders.push(holder);
        }
    }
}
