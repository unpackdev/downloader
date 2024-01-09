// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


import "./Ownable.sol";
import "./ERC20.sol";

contract FlyzWrappedLOOKS is Ownable, ERC20 {
    mapping(address => bool) public minters; 

    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);

    constructor() ERC20("FLYZ WRAPPED LOOKS", "FWLOOKS", 18) {}

    modifier onlyMinter() {
        require(minters[msg.sender], "FlyzWrappedLOOKS: not minter");
        _;
    }

    function mintTo(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        require(amount <= balanceOf(msg.sender), "FlyzWrappedLOOKS: over amount");
        _burn(msg.sender, amount);
    }

    function addMinter(address minter) external onlyOwner {
        require(minter != address(0), "FlyzWrappedLOOKS: invalid address(0)");
        require(!minters[minter], "FlyzWrappedLOOKS: already minter");
        minters[minter] = true;
        emit MinterAdded(minter);
    }

    function removeMinter(address minter) external onlyOwner {
        require(minters[minter], "FlyzWrappedLOOKS: not minter");
        minters[minter] = false;
        emit MinterRemoved(minter);
    }

}