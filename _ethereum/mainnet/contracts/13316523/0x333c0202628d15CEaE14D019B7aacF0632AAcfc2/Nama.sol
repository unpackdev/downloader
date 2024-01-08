// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20SnapshotUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract Nama is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20SnapshotUpgradeable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    mapping(address => bool) public minters;
    uint256 public deploymentTimestamp;

    event AddMinter(address indexed _addr);

    function initialize() virtual initializer public {
        __ERC20_init("Nama Finance", "NAMA");
        __ERC20Burnable_init();
        __ERC20Snapshot_init();
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _mint(_msgSender(), 3700000 * 10 ** decimals());
        deploymentTimestamp = block.timestamp;
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() public whenPaused onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public {
        require(_msgSender() == owner() || minters[_msgSender()] == true, "Ownable: caller is not the owner or minter");
        _mint(to, amount);
    }

    function addMinter(address _addr) external onlyOwner {
        require(address(_addr) != address(0), "addMinter: zero address");
        minters[_addr] = true;
        emit AddMinter(_addr);
    }

    function removeMinter(address _addr) external onlyOwner {
        require(address(_addr) != address(0), "removeMinter: zero address");
        minters[_addr] = false;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    whenNotPaused
    override(ERC20Upgradeable, ERC20SnapshotUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}
}
