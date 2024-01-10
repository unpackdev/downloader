// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Sperm is ERC20, Ownable {
    address public minter;

    constructor() ERC20("Sperm", "SPERM") {
        _mint(msg.sender, 500000 * 10**decimals());
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Only minter");
        _;
    }

    function burn(uint256 _amount) external onlyOwner {
        _burn(msg.sender, _amount);
    }

    function mint(address _user, uint256 _amount) external onlyMinter {
        _mint(_user, _amount);
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }
}
