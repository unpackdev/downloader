// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./ERC20Burnable.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";


contract OneInchMerch is ERC20Burnable, Ownable {
    using SafeERC20 for IERC20;

    constructor(string memory _name, string memory _symbol, address _owner, uint256 _supply) ERC20(_name, _symbol) {
        _mint(_owner, _supply);
        transferOwnership(_owner);
    }

    function rescueFunds(IERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(msg.sender, amount);
    }

    function _burn(address account, uint256 amount) internal override {
        require(amount % 1e18 == 0, "Partial burn is not allowed");
        super._burn(account, amount);
    }
}
