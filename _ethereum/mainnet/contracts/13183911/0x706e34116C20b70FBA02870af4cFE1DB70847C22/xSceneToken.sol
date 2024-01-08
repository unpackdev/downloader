// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./ERC20.sol";

contract xSceneToken is Context, Ownable, ERC20 {
    using SafeMath for uint256;

    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);

    mapping(address => bool) private minters;

    modifier onlyMinter() {
        require(minters[_msgSender()], 'xSceneToken: caller is not the minter');
        _;
    }

    constructor() ERC20('XScene Token', 'SCENE') {}

    function addMinter(address minter) external onlyOwner {
        if (!minters[minter]) {
            minters[minter] = true;
            emit MinterAdded(minter);
        }
    }

    function removeMinter(address minter) external onlyOwner {
        if (minters[minter]) {
            minters[minter] = false;
            emit MinterRemoved(minter);
        }
    }

    function mint(address account, uint256 amount) public virtual onlyMinter {
        _mint(account, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(
            amount,
            'xSceneToken: burn amount exceeds allowance'
        );

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}
