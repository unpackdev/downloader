// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

/**
 * @title   Primitive Connector
 * @author  Primitive
 * @notice  Low-level abstract contract for Primitive Connectors to inherit from.
 * @dev     @primitivefi/v1-connectors@v2.0.0
 */

// Open Zeppelin
import "./Context.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
// Primitive
import "./CoreLib.sol";
import "./IPrimitiveConnector.sol";

abstract contract PrimitiveConnector is IPrimitiveConnector, Context {
    using SafeERC20 for IERC20; // Reverts when `transfer` or `transferFrom` erc20 calls don't return proper data

    IWETH internal _weth; // Canonical WETH9
    IPrimitiveRouter internal _primitiveRouter; // The PrimitiveRouter contract which executes calls.
    mapping(address => mapping(address => bool)) internal _approved; // Stores approvals for future checks.

    // ===== Constructor =====

    constructor(address weth_, address primitiveRouter_) public {
        _weth = IWETH(weth_);
        _primitiveRouter = IPrimitiveRouter(primitiveRouter_);
        checkApproval(weth_, primitiveRouter_); // Approves this contract's weth to be spent by router.
    }

    /**
     * @notice  Reverts if the `option` is not registered in the PrimitiveRouter contract.
     * @dev     Any `option` which is deployed from the Primitive Registry can be registered with the Router.
     * @param   option The Primitive Option to check if registered.
     */
    modifier onlyRegistered(IOption option) {
        require(
            _primitiveRouter.getRegisteredOption(address(option)),
            "PrimitiveSwaps: EVIL_OPTION"
        );
        _;
    }

    // ===== External =====

    /**
     * @notice  Approves the `spender` to pull `token` from this contract.
     * @dev     This contract does not hold funds, infinite approvals cannot be exploited for profit.
     * @param   token The token to approve spending for.
     * @param   spender The address to allow to spend `token`.
     */
    function checkApproval(address token, address spender)
        public
        override
        returns (bool)
    {
        if (!_approved[token][spender]) {
            IERC20(token).safeApprove(spender, uint256(-1));
            _approved[token][spender] = true;
        }
        return true;
    }

    // ===== Internal =====

    /**
     * @notice  Deposits `msg.value` into the Weth contract for Weth tokens.
     * @return  Whether or not ether was deposited into Weth.
     */
    function _depositETH() internal returns (bool) {
        if (msg.value > 0) {
            _weth.deposit.value(msg.value)();
            return true;
        }
        return false;
    }

    /**
     * @notice  Uses this contract's balance of Weth to withdraw Ether and send it to `getCaller()`.
     */
    function _withdrawETH() internal returns (bool) {
        uint256 quantity = IERC20(address(_weth)).balanceOf(address(this));
        if (quantity > 0) {
            // Withdraw ethers with weth.
            _weth.withdraw(quantity);
            // Send ether.
            (bool success, ) = getCaller().call.value(quantity)("");
            // Revert is call is unsuccessful.
            require(success, "Connector: ERR_SENDING_ETHER");
            return success;
        }
        return true;
    }

    /**
     * @notice  Calls the Router to pull `token` from the getCaller() and send them to this contract.
     * @dev     This eliminates the need for users to approve the Router and each connector.
     * @param   token The token to pull from `getCaller()` into this contract.
     * @param   quantity The amount of `token` to pull into this contract.
     * @return  Whether or not the `token` was transferred into this contract.
     */
    function _transferFromCaller(address token, uint256 quantity)
        internal
        returns (bool)
    {
        if (quantity > 0) {
            _primitiveRouter.transferFromCaller(token, quantity);
            return true;
        }
        return false;
    }

    /**
     * @notice  Pushes this contract's balance of `token` to `getCaller()`.
     * @dev     getCaller() is the original `msg.sender` of the Router's `execute` fn.
     * @param   token The token to transfer to `getCaller()`.
     * @return  Whether or not the `token` was transferred to `getCaller()`.
     */
    function _transferToCaller(address token) internal returns (bool) {
        uint256 quantity = IERC20(token).balanceOf(address(this));
        if (quantity > 0) {
            IERC20(token).safeTransfer(getCaller(), quantity);
            return true;
        }
        return false;
    }

    /**
     * @notice  Calls the Router to pull `token` from the getCaller() and send them to this contract.
     * @dev     This eliminates the need for users to approve the Router and each connector.
     * @param   token The token to pull from `getCaller()`.
     * @param   quantity The amount of `token` to pull.
     * @param   receiver The `to` address to send `quantity` of `token` to.
     * @return  Whether or not `token` was transferred to `receiver`.
     */
    function _transferFromCallerToReceiver(
        address token,
        uint256 quantity,
        address receiver
    ) internal returns (bool) {
        if (quantity > 0) {
            _primitiveRouter.transferFromCallerToReceiver(token, quantity, receiver);
            return true;
        }
        return false;
    }

    /**
     * @notice  Uses this contract's balance of underlyingTokens to mint optionTokens to this contract.
     * @param   optionToken The Primitive Option to mint.
     * @return  (uint, uint) (longOptions, shortOptions)
     */
    function _mintOptions(IOption optionToken) internal returns (uint256, uint256) {
        address underlying = optionToken.getUnderlyingTokenAddress();
        _transferBalanceToReceiver(underlying, address(optionToken)); // Sends to option contract
        return optionToken.mintOptions(address(this));
    }

    /**
     * @notice  Uses this contract's balance of underlyingTokens to mint optionTokens to `receiver`.
     * @param   optionToken The Primitive Option to mint.
     * @param   receiver The address that will received the minted long and short optionTokens.
     * @return  (uint, uint) Returns the (long, short) option tokens minted
     */
    function _mintOptionsToReceiver(IOption optionToken, address receiver)
        internal
        returns (uint256, uint256)
    {
        address underlying = optionToken.getUnderlyingTokenAddress();
        _transferBalanceToReceiver(underlying, address(optionToken)); // Sends to option contract
        return optionToken.mintOptions(receiver);
    }

    /**
     * @notice  Pulls underlying tokens from `getCaller()` to option contract, then invokes mintOptions().
     * @param   optionToken The option token to mint.
     * @param   quantity The amount of option tokens to mint.
     * @return  (uint, uint) Returns the (long, short) option tokens minted
     */
    function _mintOptionsFromCaller(IOption optionToken, uint256 quantity)
        internal
        returns (uint256, uint256)
    {
        require(quantity > 0, "ERR_ZERO");
        _transferFromCallerToReceiver(
            optionToken.getUnderlyingTokenAddress(),
            quantity,
            address(optionToken)
        );
        return optionToken.mintOptions(address(this));
    }

    /**
     * @notice  Multi-step operation to close options.
     *          1. Transfer balanceOf `redeem` option token to the option contract.
     *          2. If NOT expired, pull `option` tokens from `getCaller()` and send to option contract.
     *          3. Invoke `closeOptions()` to burn the options and release underlyings to this contract.
     * @return  The amount of underlyingTokens released to this contract.
     */
    function _closeOptions(IOption optionToken) internal returns (uint256) {
        address redeem = optionToken.redeemToken();
        uint256 short = IERC20(redeem).balanceOf(address(this));
        uint256 long = IERC20(address(optionToken)).balanceOf(getCaller());
        uint256 proportional = CoreLib.getProportionalShortOptions(optionToken, long);
        // IF user has more longs than proportional shorts, close the `short` amount.
        if (proportional > short) {
            proportional = short;
        }

        // If option is expired, transfer the amt of proportional thats larger.
        if (optionToken.getExpiryTime() >= now) {
            // Transfers the max proportional amount of short options to option contract.
            IERC20(redeem).safeTransfer(address(optionToken), proportional);
            // Pulls the max amount of long options and sends to option contract.
            _transferFromCallerToReceiver(
                address(optionToken),
                CoreLib.getProportionalLongOptions(optionToken, proportional),
                address(optionToken)
            );
        } else {
            // If not expired, transfer all redeem in balance.
            IERC20(redeem).safeTransfer(address(optionToken), short);
        }
        uint outputUnderlyings;
        if(proportional > 0) {
            (, ,  outputUnderlyings) = optionToken.closeOptions(address(this));
        }
        return outputUnderlyings;
    }

    /**
     * @notice  Multi-step operation to exercise options.
     *          1. Transfer balanceOf `strike` token to option contract.
     *          2. Transfer `amount` of options to exercise to option contract.
     *          3. Invoke `exerciseOptions()` and specify `getCaller()` as the receiver.
     * @dev     If the balanceOf `strike` and `amount` of options are not in correct proportions, call will fail.
     * @param   optionToken The option to exercise.
     * @param   amount The quantity of options to exercise.
     */
    function _exerciseOptions(IOption optionToken, uint256 amount)
        internal
        returns (uint256, uint256)
    {
        address strike = optionToken.getStrikeTokenAddress();
        _transferBalanceToReceiver(strike, address(optionToken));
        IERC20(address(optionToken)).safeTransfer(address(optionToken), amount);
        return optionToken.exerciseOptions(getCaller(), amount, new bytes(0));
    }

    /**
     * @notice  Transfers this contract's balance of Redeem tokens and invokes the redemption function.
     * @param   optionToken The optionToken to redeem, not the redeem token itself.
     */
    function _redeemOptions(IOption optionToken) internal returns (uint256) {
        address redeem = optionToken.redeemToken();
        _transferBalanceToReceiver(redeem, address(optionToken));
        return optionToken.redeemStrikeTokens(getCaller());
    }

    /**
     * @notice  Utility function to transfer this contract's balance of `token` to `receiver`.
     * @param   token The token to transfer.
     * @param   receiver The address that receives the token.
     * @return  Returns the quantity of `token` transferred.
     */
    function _transferBalanceToReceiver(address token, address receiver)
        internal
        returns (uint256)
    {
        uint256 quantity = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(receiver, quantity);
        return quantity;
    }

    // ===== Fallback =====

    receive() external payable {
        assert(_msgSender() == address(_weth)); // only accept ETH via fallback from the WETH contract
    }

    // ===== View =====

    /**
     * @notice  Returns the Weth contract address.
     */
    function getWeth() public view override returns (IWETH) {
        return _weth;
    }

    /**
     * @notice  Returns the state variable `_CALLER` in the Primitive Router.
     */
    function getCaller() public view override returns (address) {
        return _primitiveRouter.getCaller();
    }

    /**
     * @notice  Returns the Primitive Router contract address.
     */
    function getPrimitiveRouter() public view override returns (IPrimitiveRouter) {
        return _primitiveRouter;
    }

    /**
     * @notice  Returns whether or not `spender` is approved to spend `token`, from this contract.
     */
    function isApproved(address token, address spender)
        public
        view
        override
        returns (bool)
    {
        return _approved[token][spender];
    }
}
