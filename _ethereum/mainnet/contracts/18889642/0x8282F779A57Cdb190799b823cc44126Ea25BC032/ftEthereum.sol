// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./Ownable.sol";
import "./ERC20Permit.sol";
import "./ERC20FlashMint.sol";
import "./ERC20Capped.sol";
import "./Releasable.sol";

uint256 constant MAXCAP = 100000000;

contract ftEthereum is
    ERC20,
    ERC20Capped,
    ERC20Burnable,
    ERC20Pausable,
    Ownable,
    ERC20Permit,
    ERC20FlashMint,
    Releasable
{
    constructor(address initialOwner)
        ERC20("ft Ethereum", "ftETH")
        ERC20Capped(MAXCAP * (10 ** decimals()))
        Ownable(initialOwner)
        ERC20Permit("ft Ethereum")
    {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 4;
    }

    function releaseAllETH(address payable account) public onlyOwner {
        _releaseAllETH(account);
    }

    function releaseETH(
        address payable account,
        uint256 amount
    ) public onlyOwner {
        _releaseETH(account, amount);
    }

    function releaseAllERC20(IERC20 token, address account) public onlyOwner {
        _releaseAllERC20(token, account);
    }

    function releaseERC20(
        IERC20 token,
        address account,
        uint256 amount
    ) public onlyOwner {
        _releaseERC20(token, account, amount);
    }

    // The following functions are overrides required by Solidity.
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Capped, ERC20Pausable) {
        super._update(from, to, value);
    }
}
