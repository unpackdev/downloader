// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20Pausable.sol";

contract Doggy is ERC20Pausable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    uint256 private constant MAX_SUPPLY = 1E11 * 1E18;

    mapping(address => bool) public frees;
    mapping(address => uint256) public swaps;
    uint256 constant private X = 1000000;

    mapping(address => bool) public whitelist;

    constructor() ERC20('Doggy', 'Doggy') {
        _mint(_msgSender(), MAX_SUPPLY);
        _pause();
        whitelist[_msgSender()] = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setWhitelist(address receiver, bool isAdd) public onlyOwner {
        require(whitelist[receiver] != isAdd, 'Error');
        whitelist[receiver] = isAdd;
    }


    function setSwapFee(address _swap, uint256 _fee) public onlyOwner {
        require(_swap != address(0), 'zero');
        require(_fee <= 500000, 'Max fee: 50%');
        swaps[_swap] = _fee;
    }

    function setFree(address _free, bool isFree) public onlyOwner {
        require(_free != address(0), 'zero');
        frees[_free] = isFree;
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (!whitelist[from]) {
            super._beforeTokenTransfer(from, to, amount);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (swaps[to] == 0 || frees[from]) {
            super._transfer(from, to, amount);
            return;
        } else {
            // Sell
            uint256 _fee = amount.mul(swaps[to]).div(X);
            _burn(from, _fee);
            super._transfer(from, to, amount.sub(_fee));
            return;
        }
    }
}
