// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./IAddressManager.sol";
import "./ICegaVault.sol";
import "./Errors.sol";

contract CegaVault is ICegaVault, ERC20 {
    address public immutable cegaEntry;
    uint8 public constant VAULT_DECIMALS = 18;

    modifier onlyCegaEntry() {
        require(cegaEntry == msg.sender, Errors.NOT_CEGA_ENTRY);
        _;
    }

    constructor(
        IAddressManager _addressManager,
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC20(_tokenName, _tokenSymbol) {
        cegaEntry = _addressManager.getCegaEntry();
    }

    function decimals() public view virtual override returns (uint8) {
        return VAULT_DECIMALS;
    }

    function mint(address account, uint256 amount) external onlyCegaEntry {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyCegaEntry {
        _burn(account, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 value
    ) internal override {
        if (msg.sender == cegaEntry) {
            return;
        }
        super._spendAllowance(owner, spender, value);
    }
}
