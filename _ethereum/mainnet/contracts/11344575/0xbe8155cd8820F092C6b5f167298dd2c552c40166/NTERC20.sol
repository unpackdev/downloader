// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @dev Non-transferrable, ownable ERC-20
 */
contract NTERC20 is ERC20, Ownable {
    bool private _transferrable;

    /**
     * @dev Sets the default values and owner
     */
    constructor(string memory name_, string memory symbol_) public ERC20(name_, symbol_) {}

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function setTransferrable(bool transferrable) external onlyOwner {
        _transferrable = transferrable;
    }

    function isTransferrable() external view returns (bool) {
        return _transferrable;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
        require(from == address(0) || from == owner() || _transferrable == true, "NTERC20/cannot-transfer");
    }
}
