// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20SnapshotUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./Initializable.sol";

contract LEX is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20SnapshotUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC20PermitUpgradeable
{
    uint256 public MAX_SUPPLY;
    uint256 public MAX_SALE_SUPPLY;

    uint256 public PRIVATE_SALE_SUPPLY;
    uint256 public ICO_SALE_SUPPLY;
    uint256 public IEO_SALE_SUPPLY;
    uint256 public IDO_SALE_SUPPLY;

    function initialize() public initializer {
        __ERC20_init("LEX", "LEX");
        __ERC20Burnable_init();
        __ERC20Snapshot_init();
        __Ownable_init();
        __Pausable_init();
        __ERC20Permit_init("LEX");

        MAX_SUPPLY = 31736917 * 10**decimals();
        MAX_SALE_SUPPLY = 9521075 * 10**decimals();

        PRIVATE_SALE_SUPPLY = 1713350 * 10**decimals();
        ICO_SALE_SUPPLY = 66812375 * 10**decimals();
        IEO_SALE_SUPPLY = 263875 * 10**decimals();
        IDO_SALE_SUPPLY = 8626125 * 10**decimals();

        // require(
        //     MAX_SALE_SUPPLY ==
        //         (PRIVATE_SALE_SUPPLY +
        //             ICO_SALE_SUPPLY +
        //             IEO_SALE_SUPPLY +
        //             IDO_SALE_SUPPLY)
        // );

        // _mint(msg.sender, 31736917 * 10**decimals());
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY);
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override(ERC20Upgradeable, ERC20SnapshotUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
