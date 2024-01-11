// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Context.sol";
import "./IERC165.sol";
import "./ERC165.sol";
import "./AccessControl.sol";
import "./EnumerableSet.sol";
import "./AccessControlEnumerable.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./ERC20Pausable.sol";

contract ApolloFiToken is
Context,
AccessControlEnumerable,
ERC20Burnable,
ERC20Pausable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 private immutable globalSupply;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _globalSupply
    ) ERC20(name, symbol) {
        require(_globalSupply > 0, "globalSupply is 0");

        globalSupply = _globalSupply;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function cap() public view virtual returns (uint256) {
        return globalSupply;
    }

    function mint(address to, uint256 amount) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "must have minter role to mint"
        );
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "cap exceeded");
        super._mint(account, amount);
    }

    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "must have pauser role to unpause"
        );
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
