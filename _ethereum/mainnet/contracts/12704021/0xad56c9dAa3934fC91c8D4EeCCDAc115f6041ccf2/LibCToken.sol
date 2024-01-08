// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "./SafeERC20.sol";
import "./Compound.sol";

/**
 * @title Library to simplify CToken interaction
 * @author KeeperDAO
 * @dev this library abstracts cERC20 and cEther interactions.
 */
library LibCToken {
    using SafeERC20 for IERC20;

    // Network: MAINNET
    Comptroller constant COMPTROLLER = Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    CEther constant CETHER = CEther(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);

    /**
     * @notice checks if the given cToken is listed as a valid market on 
     * comptroller.
     * 
     * @param _cToken cToken address
     */
    function isListed(CToken _cToken) internal view returns (bool listed) {
        (listed, , ) = COMPTROLLER.markets(address(_cToken));
    }

    /**
     * @notice returns the given cToken's underlying token address.
     * 
     * @param _cToken cToken address
     */
    function underlying(CToken _cToken) internal view returns (address) {
        if (address(_cToken) == address(CETHER)) {
            return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        } else {
            return CErc20(address(_cToken)).underlying();
        }
    }

    /**
     * @notice redeems given amount of underlying tokens.
     * 
     * @param _cToken cToken address
     * @param _amount underlying token amount
     */
    function redeemUnderlying(CToken _cToken, uint _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            require(CETHER.redeemUnderlying(_amount) == 0, "failed to redeem ether");
        } else {
            require(CErc20(address(_cToken)).redeemUnderlying(_amount) == 0, "failed to redeem ERC20");
        }
    }

    /**
     * @notice borrows given amount of underlying tokens.
     * 
     * @param _cToken cToken address
     * @param _amount underlying token amount
     */
    function borrow(CToken _cToken, uint _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            require(CETHER.borrow(_amount) == 0, "failed to borrow ether");
        } else {
            require(CErc20(address(_cToken)).borrow(_amount) == 0, "failed to borrow ERC20");
        }
    }

    /**
     * @notice deposits given amount of underlying tokens.
     * 
     * @param _cToken cToken address
     * @param _amount underlying token amount
     */
    function mint(CToken _cToken, uint _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            CETHER.mint{ value: _amount }();
        } else {

            require(CErc20(address(_cToken)).mint(_amount) == 0, "failed to mint cERC20");
        }
    }

    /**
     * @notice repay given amount of underlying tokens.
     * 
     * @param _cToken cToken address
     * @param _amount underlying token amount
     */
    function repayBorrow(CToken _cToken, uint _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            CETHER.repayBorrow{ value: _amount }();
        } else {
            require(CErc20(address(_cToken)).repayBorrow(_amount) == 0, "failed to mint cERC20");
        }
    }

    /**
     * @notice repay given amount of underlying tokens on behalf of the borrower.
     * 
     * @param _cToken cToken address
     * @param _borrower borrower address
     * @param _amount underlying token amount
     */
    function repayBorrowBehalf(CToken _cToken, address _borrower, uint _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            CETHER.repayBorrowBehalf{ value: _amount }(_borrower);
        } else {
            require(CErc20(address(_cToken)).repayBorrowBehalf(_borrower, _amount) == 0, "failed to mint cERC20");
        }
    }

    /**
     * @notice transfer given amount of underlying tokens to the given address.
     * 
     * @param _cToken cToken address
     * @param _to reciever address
     * @param _amount underlying token amount
     */
    function transferUnderlying(CToken _cToken, address payable _to, uint256 _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            (bool success,) = _to.call{ value: _amount }("");
            require(success, "Transfer Failed");
        } else {
            IERC20(CErc20(address(_cToken)).underlying()).safeTransfer(_to, _amount);
        }
    }

    /**
     * @notice approve given amount of underlying tokens to the given address.
     * 
     * @param _cToken cToken address
     * @param _spender spender address
     * @param _amount underlying token amount
     */
    function approveUnderlying(CToken _cToken, address _spender, uint256 _amount) internal {
        if (address(_cToken) != address(CETHER)) {
            IERC20 token = IERC20(CErc20(address(_cToken)).underlying());
            token.safeIncreaseAllowance(_spender, _amount);
        } 
    }

    /**
     * @notice pull approve given amount of underlying tokens to the given address.
     * 
     * @param _cToken cToken address
     * @param _from address from which the funds need to be pulled
     * @param _to address to which the funds are approved to
     * @param _amount underlying token amount
     */
    function pullAndApproveUnderlying(CToken _cToken, address _from, address _to, uint256 _amount) internal {
        if (address(_cToken) == address(CETHER)) {
            require(msg.value == _amount, "failed to mint CETHER");
        } else {
            IERC20 token = IERC20(CErc20(address(_cToken)).underlying());
            token.safeTransferFrom(_from, address(this), _amount);
            token.safeIncreaseAllowance(_to, _amount);
        }
    }
}
