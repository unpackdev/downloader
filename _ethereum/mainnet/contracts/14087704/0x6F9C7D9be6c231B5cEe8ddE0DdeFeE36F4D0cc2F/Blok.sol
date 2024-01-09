// SPDX-License-Identifier: None
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./ERC20Burnable.sol";

import "./AddrArrayLib.sol";

contract BPAD is ERC20Burnable, Ownable {
    using AddrArrayLib for AddrArrayLib.Addresses;

    /**
     * @dev Emitted when owner change fee account and fee amount.
     */
    event UpdateTaxInfo(address indexed owner, uint256 indexed feePercent);

    uint256 public constant PRECISION = 100;
    uint256 public constant INITIAL_SUPPLY = 7_500_000_000 * 10**18;

    address public _feeAccount;
    uint256 public _feePercent;

    // List of no fee addresses when transfer token
    AddrArrayLib.Addresses noFeeAddrs;

    constructor(
        address feeAccount,
        uint256 feePercent,
        address owner,
        address mintToAddr
    ) ERC20("BPAD", "BPAD") {
        require(feeAccount != address(0), "BPAD: fee account from the zero address");
        require(feePercent <= PRECISION, "BPAD: incorrect fee percent");
        require(owner != address(0), "BPAD: incorrect owner address");
        require(mintToAddr != address(0), "BPAD: incorrect mintToAddr address");
        if (_msgSender() != owner) {
            transferOwnership(owner);
        }
        _feeAccount = feeAccount;
        _feePercent = feePercent;
        _mint(mintToAddr, INITIAL_SUPPLY);
    }

    /**
     * @dev Update the fee collector and the percent of fee from transfer operation
     */
    function updateTaxInfo(address feeAccount, uint256 feePercent) external onlyOwner {
        require(feeAccount != address(0), "BPAD: fee account from the zero address");
        require(feePercent <= PRECISION, "BPAD: incorrect fee percent");
        _feeAccount = feeAccount;
        _feePercent = feePercent;
        emit UpdateTaxInfo(feeAccount, feePercent);
    }

    /**
     * @dev Push non-fee address
     */
    function addNoFeeAddress(address addr) external onlyOwner {
        noFeeAddrs.pushAddress(addr);
    }

    /**
     * @dev Pop non-fee address
     */
    function removeNoFeeAddress(address addr) external onlyOwner {
        require(noFeeAddrs.removeAddress(addr), "Address: address does not exist");
    }

    /**
     * @dev Check if address is existed in non-fee address list
     */
    function isExisted(address addr) public view returns (bool) {
        return noFeeAddrs.exists(addr);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "BPAD: transfer from the zero address");
        require(recipient != address(0), "BPAD: transfer to the zero address");

        if (isExisted(sender) || _feePercent == 0) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 _fee = (amount * _feePercent) / PRECISION;
            uint256 _recepientAmount = amount - _fee;

            super._transfer(sender, recipient, _recepientAmount);
            super._transfer(sender, _feeAccount, _fee);
        }
    }
}
