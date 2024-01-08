// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC20BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AddressUpgradeable.sol";

/**
 * @title ZCXHT
 * @author Unizen
 * @notice Holder Token for ZCX that can be swapped for the real
 * utility token on the vesting contract. It is not transferable, beside
 * being minted / burned / staking /swap on vesting contract.
 **/
contract ZCXHT is ERC20BurnableUpgradeable, OwnableUpgradeable {
    mapping(address => bool) internal _whitelisted;

    function initialize() public initializer {
        __Ownable_init();
        __ERC20_init("ZCX Holder Token", "ZCXHT");
        _whitelisted[_msgSender()] = true;
        _whitelisted[address(0)] = true;
        _mint(_msgSender(), 3108 * 10**18);
    }

    /* internal functions */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override {
        if (AddressUpgradeable.isContract(from)) {
            require(_whitelisted[from] == true, "CAN_NOT_TRANSFER");
        }
        if (AddressUpgradeable.isContract(to)) {
            require(_whitelisted[to] == true, "CAN_NOT_TRANSFER");
        }
    }

    /* control functions */
    function addToWhitelist(address addr) external onlyOwner {
        // enable address for transfers
        _whitelisted[addr] = true;
    }

    function removeFromWhitelist(address addr) external onlyOwner {
        // disable address for transfers
        _whitelisted[addr] = false;
    }
}
