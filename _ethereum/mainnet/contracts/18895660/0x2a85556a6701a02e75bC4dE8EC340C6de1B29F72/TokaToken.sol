// SPDX-License-Identifier: MIT

pragma solidity =0.8.21;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./Ownable.sol";

contract TokaToken is ERC20Capped, Ownable {
    mapping(address => bool) public isMinter;
    mapping(address => bool) public isBurner;

    constructor() ERC20("Toka Token", "TOKA") ERC20Capped(1_000_000_000 * (10 ** 18)) Ownable(msg.sender) {}

    function addMinter(address _minter) external onlyOwner {
        isMinter[_minter] = true;
    }

    function removeMinter(address _minter) external onlyOwner {
        isMinter[_minter] = false;
    }

    function addBurner(address _burner) external onlyOwner {
        isBurner[_burner] = true;
    }

    function removeBurner(address _burner) external onlyOwner {
        isBurner[_burner] = false;
    }

    function mint(address _to, uint256 _amount) external {
        require(isMinter[msg.sender], "Only minter can mint");
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        require(isBurner[msg.sender], "Only burner can burn");
        _burn(_from, _amount);
    }
}
