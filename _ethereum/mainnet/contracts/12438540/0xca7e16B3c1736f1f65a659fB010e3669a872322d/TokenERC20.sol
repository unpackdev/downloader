// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./TokenAdmin.sol";

/**
 * @title dForce's lending Token ERC20 Contract
 * @author dForce
 */
abstract contract TokenERC20 is TokenAdmin {
    /**
     * @dev Transfers `_amount` tokens from `_spender` to `_recipient`.
     * @param _spender The address of the source account.
     * @param _recipient The address of the destination account.
     * @param _amount The number of tokens to transfer.
     */
    function _transferTokens(
        address _spender,
        address _recipient,
        uint256 _amount
    ) internal returns (bool) {
        require(
            _spender != _recipient,
            "_transferTokens: Do not self-transfer!"
        );

        controller.beforeTransfer(
            address(this),
            msg.sender,
            _recipient,
            _amount
        );

        _transfer(_spender, _recipient, _amount);

        controller.afterTransfer(address(this), _spender, _recipient, _amount);

        return true;
    }

    //----------------------------------
    //********* ERC20 Actions **********
    //----------------------------------

    /**
     * @notice Cause iToken is an ERC20 token, so users can `transfer` them,
     *         but this action is only allowed when after transferring tokens, the caller
     *         does not have a shortfall.
     * @dev Moves `_amount` tokens from caller to `_recipient`.
     * @param _recipient The address of the destination account.
     * @param _amount The number of tokens to transfer.
     */
    function transfer(address _recipient, uint256 _amount)
        public
        virtual
        override
        nonReentrant
        returns (bool)
    {
        return _transferTokens(msg.sender, _recipient, _amount);
    }

    /**
     * @notice Cause iToken is an ERC20 token, so users can `transferFrom` them,
     *         but this action is only allowed when after transferring tokens, the `_spender`
     *         does not have a shortfall.
     * @dev Moves `_amount` tokens from `_spender` to `_recipient`.
     * @param _spender The address of the source account.
     * @param _recipient The address of the destination account.
     * @param _amount The number of tokens to transfer.
     */
    function transferFrom(
        address _spender,
        address _recipient,
        uint256 _amount
    ) public virtual override nonReentrant returns (bool) {
        _approve(
            _spender,
            msg.sender,
            allowance[_spender][msg.sender].sub(_amount)
        );
        return _transferTokens(_spender, _recipient, _amount);
    }
}
