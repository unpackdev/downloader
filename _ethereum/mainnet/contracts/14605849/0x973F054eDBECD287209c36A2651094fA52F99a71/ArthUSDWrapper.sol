//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ARTHGmuRebaseERC20.sol";

contract ArthUSDWrapper is ARTHGmuRebaseERC20 {
    IERC20 public arth;

    event Deposit(address indexed who, uint256 amount);
    event Withdraw(address indexed who, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        address _arth,
        address _gmuOracle,
        address governance,
        uint256 chainId
    ) ARTHGmuRebaseERC20(_name, _symbol, _gmuOracle, governance, chainId) {
        arth = IERC20(_arth);
        _transferOwnership(governance); // transfer ownership to governance
    }

    /**
     * @dev Allow a user to deposit underlying tokens and mint the corresponding number of wrapped tokens.
     */
    function depositFor(address account, uint256 amount) public virtual returns (bool) {
        SafeERC20.safeTransferFrom(arth, _msgSender(), address(this), amount);
        _mint(account, amount);
        emit Deposit(account, amount);
        return true;
    }

    function deposit(uint256 amount) public virtual returns (bool) {
        return depositFor(_msgSender(), amount);
    }


    /**
     * @dev Allow a user to burn a number of wrapped tokens and withdraw the corresponding number of underlying tokens.
     */
    function withdrawTo(address account, uint256 amount) public virtual returns (bool) {
        _burn(_msgSender(), amount);
        SafeERC20.safeTransfer(arth, account, amount);
        emit Withdraw(account, amount);
        return true;
    }

    function withdraw(uint256 amount) public virtual returns (bool) {
        return withdrawTo(_msgSender(), amount);
    }
}
