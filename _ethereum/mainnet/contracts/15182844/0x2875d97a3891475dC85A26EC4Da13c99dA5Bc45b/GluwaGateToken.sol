// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./ERC20Mintable.sol";
import "./ERC20Transfer.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./IRewardToken.sol";

contract GluwaGateToken is Initializable, AccessControlUpgradeable, ERC20Mintable, ERC20Transfer {
    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address GTDAddress,
        uint256 halveBlocks,
        uint256 initalReward,
        uint256 lockUpPeriod,
        uint256 initialBlock
    ) public initializer {
        __Context_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        __ERC20Reward_init(name, symbol, decimals, GTDAddress, halveBlocks, initalReward, lockUpPeriod, initialBlock);
        __ERC20Mintable_init();
        __ERC20Transfer_init();
    }

    function version() public pure virtual returns (string memory) {
        return '0.4';
    }

    function _mint(address account, uint256 amount) internal override(ERC20Mintable, ERC20Upgradeable) {
        super._mint(account, amount);
    }

    /**
     * @dev allow to get version for EIP712 domain dynamically. We do not need to init EIP712 anymore
     *
     */
    function _EIP712VersionHash() internal pure override returns (bytes32) {
        return keccak256(bytes(version()));
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain based on token name. We do not need to init EIP712 anymore
     *
     */
    function _EIP712NameHash() internal view override returns (bytes32) {
        return keccak256(bytes(name()));
    }

    function setLockupPeriodAndHalve(uint256 newLockupPeriod, uint256 newHalve) external virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Admin Role: caller does not have the Admin role');
        _setLockupPeriodAndHalve(newLockupPeriod, newHalve);
    }

    function setLastEmptyBlock(uint256 lastEmptyBlock) internal {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Admin Role: caller does not have the Admin role');
        _setLastEmptyBlock(lastEmptyBlock);
    }

    uint256[50] private __gap;
}
