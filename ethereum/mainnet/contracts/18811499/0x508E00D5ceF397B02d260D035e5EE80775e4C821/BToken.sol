// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20Pausable.sol";

contract BToken is ERC20Pausable, Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 100 * 1E8 * 1E18;
    uint256 public currentSupply = 0;

    mapping(address => bool) public whitelist;

    constructor() ERC20('Bitcoin Cats', '1CAT') {
        whitelist[address(0)] = true;
        _pause();
    }

    function mint(address account, uint256 amount) public onlyOwner {
        require(amount.add(currentSupply) <= MAX_SUPPLY, 'Error: amount');
        currentSupply += amount;
        _mint(account, amount);
    }

    function setWhitelist(address receiver, bool isAdd) public onlyOwner {
        require(whitelist[receiver] != isAdd, 'Error');
        whitelist[receiver] = isAdd;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
        currentSupply -= amount;
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
        currentSupply -= amount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (!whitelist[from]) super._beforeTokenTransfer(from, to, amount);
    }
}
