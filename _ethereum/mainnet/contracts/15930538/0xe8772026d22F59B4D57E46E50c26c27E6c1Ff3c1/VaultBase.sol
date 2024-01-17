// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import "./ITokenDecimals.sol";
import "./Pausable.sol";
import "./ERC20.sol";
import "./CallerGuard.sol";
import "./SafeTransfer.sol";


abstract contract VaultBase is Pausable, ERC20, CallerGuard, SafeTransfer {

    error ZeroAmountError();
    error TotalSupplyLimitError();

    address public immutable asset;
    uint256 public totalSupplyLimit;

    event SetTotalSupplyLimit(uint256 limit);

    event Deposit(address indexed caller, uint256 assetAmount);
    event Withdraw(address indexed caller, uint256 assetAmount);

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol,
        bool _depositAllowed
    )
        ERC20(
            _name,
            _symbol,
            ITokenDecimals(_asset).decimals()
        )
    {
        asset = _asset;

        _setTotalSupplyLimit(
            _depositAllowed ?
                type(uint256).max :
                0
        );
    }

    // Decimals = vault token decimals = asset decimals
    function setTotalSupplyLimit(uint256 _limit) external onlyManager {
        _setTotalSupplyLimit(_limit);
    }

    function deposit(uint256 assetAmount) public virtual whenNotPaused checkCaller {
        if (assetAmount == 0) {
            revert ZeroAmountError();
        }

        if (totalSupply + assetAmount > totalSupplyLimit) {
            revert TotalSupplyLimitError();
        }

        // Need to transfer before minting or ERC777s could reenter
        safeTransferFrom(asset, msg.sender, address(this), assetAmount);

        _mint(msg.sender, assetAmount);

        emit Deposit(msg.sender, assetAmount);
    }

    function withdraw(uint256 assetAmount) public virtual whenNotPaused checkCaller {
        _burn(msg.sender, assetAmount);

        emit Withdraw(msg.sender, assetAmount);

        safeTransfer(asset, msg.sender, assetAmount);
    }

    function _setTotalSupplyLimit(uint256 _limit) private {
        totalSupplyLimit = _limit;

        emit SetTotalSupplyLimit(_limit);
    }
}
