// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// imported contracts
import "./DepositWithdrawToken.sol";
import "./SafeERC20.sol";

// interfaces
import "./IERC20Metadata.sol";

import "./errors.sol";

contract WrappedTokenScaled is DepositWithdrawToken {
    using SafeERC20 for IERC20Metadata;
    /*///////////////////////////////////////////////////////////////
                        Constants & Immutables
    //////////////////////////////////////////////////////////////*/

    int256 public immutable scale;

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _allowlist, address _underlying)
        DepositWithdrawToken(_name, _symbol, _decimals, _allowlist, _underlying)
        initializer
    {
        scale = int8(_decimals) - int8(underlying.decimals());
        if (scale == 0) revert BadAmount();
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/
    function initialize(string memory _name, string memory _symbol, address _owner) external initializer {
        __DepositWithdrawToken_init(_name, _symbol, _owner);
    }

    /**
     * @notice Deposits underlying to mint wrapped version to a recipient
     * @dev any amount past token.decimals - underlying.decimals is truncated
     * @param _from is the address to draw from
     * @param _recipient is the address of the recipient
     * @param _amount is the amount of underlying to deposit (underlying decimals)
     */
    function _depositFor(address _from, address _recipient, uint256 _amount) internal virtual override returns (uint256 amount) {
        if (_from != address(this)) _checkPermissions(_from);
        _checkPermissions(_recipient);

        uint256 mint;
        if (scale < 0) {
            mint = _amount / (10 ** uint256(-scale));
            amount = mint * (10 ** uint256(-scale)); // not taking more than scale can support
        } else {
            mint = _amount * (10 ** uint256(scale));
            amount = _amount;
        }

        if (mint == 0) revert BadAmount();

        _mint(_recipient, mint);

        emit Deposit(_recipient, amount);

        if (_from != address(this)) underlying.safeTransferFrom(_from, address(this), amount);
    }

    /**
     * @notice Withdraws a underlying by burning the wrapper and sends to a recipient
     * @param _recipient is the address of the recipient
     * @param _amount is the amount of wrapper to burn
     */
    function _withdrawTo(address _recipient, uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s)
        internal
        virtual
        override
        returns (uint256 amount)
    {
        _checkPermissions(msg.sender);
        if (_recipient != msg.sender) _checkPermissions(_recipient);

        _assertWithdrawSignature(_recipient, _amount, _v, _r, _s);

        if (scale < 0) amount = _amount * (10 ** uint256(-scale));
        else amount = _amount / (10 ** uint256(scale));

        if (amount == 0) revert BadAmount();

        _burn(msg.sender, _amount);

        emit Withdrawal(_recipient, amount);

        underlying.safeTransfer(_recipient, amount);
    }
}
