// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Blacklistable.sol";
import "./EthlessTransfer.sol";
import "./Burnable.sol";
import "./Mintable.sol";
import "./ERC20Reservable.sol";


contract Gluwacoin is
    Blacklistable,
    EthlessTransfer,
    Burnable,
    Mintable,
    ERC20Reservable
{
    function initialize(
        address admin,
        uint256 supplyCap_,
        uint8 mintingAuthorizationThreshold_
    ) external virtual initializer {
        __Controllable_init_unchained(admin);
        __ERC20_init_unchained(supplyCap_);
        __Mintable_init_unchained(mintingAuthorizationThreshold_);
    }

    function version() public pure virtual returns (string memory) {
        return "0.1";
    }

    function name() public pure virtual override returns (string memory) {
        return "wCTC";
    }

    /**
     * @dev The the version parameter for the EIP712 domain based on token name. We do not need to init EIP712 anymore
     *
     */
    function _EIP712Version() internal pure override returns (string memory) {
        return version();
    }

    /**
     * @dev The the name parameter for the EIP712 domain based on token name. We do not need to init EIP712 anymore
     *
     */
    function _EIP712Name() internal pure override returns (string memory) {
        return name();
    }

    function chainId() external view returns (uint256) {
        return block.chainid;
    }

    /**
     * @dev Returns the amount of tokens owned by `account` deducted by the reserved amount.
     */
    function balanceOf(
        address account
    )
        public
        view
        virtual
        override(ERC20Upgradeable, ERC20Reservable)
        returns (uint256)
    {
        return ERC20Reservable.balanceOf(account);
    }

    function _update(address from, address to, uint256 value) internal override {
        require(!isBlacklisted(from) && !isBlacklisted(to), "Gluwacoin: From or To is blacklisted");
        require(balanceOf(from) >= value || from == address(0), "Gluwacoin: Insufficient balance");
        super._update(from, to, value);
    }

    uint256[50] private __gap;
}
