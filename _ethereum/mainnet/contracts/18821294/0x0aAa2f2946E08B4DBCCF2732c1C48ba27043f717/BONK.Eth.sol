// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract BONK_EthToken is ERC20, ERC20Burnable {
    address public deployerWallet = 0xb930F50CD69396eB4600869597894a8991A0f964;
    address private _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    constructor() ERC20("BONK.Eth Token", "BONK.Eth") {
        _mint(deployerWallet, 10_000_000_000 ether); // Set initial supply to 10 billion
        _owner = deployerWallet;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function _burnToNull(address account, uint256 amount) internal {
        _burn(account, amount);
        _transfer(account, address(0), amount);
    }

    function renounceContract() external onlyOwner {
        _owner = address(0);
    }
}
