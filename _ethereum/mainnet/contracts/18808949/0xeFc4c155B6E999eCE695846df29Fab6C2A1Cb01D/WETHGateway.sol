// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IWETH.sol";
import "./IPool.sol";
import "./IYToken.sol";
import "./IWETHGateway.sol";

/// @author YLDR <admin@apyflow.com>
contract WETHGateway is IWETHGateway {
    using SafeERC20 for IERC20;

    IWETH internal immutable WETH;
    IPool internal immutable POOL;

    /**
     * @dev Sets the WETH address and the PoolAddressesProvider address. Infinite approves pool.
     * @param weth Address of the Wrapped Ether contract
     *
     */
    constructor(address weth, IPool pool) {
        WETH = IWETH(weth);
        POOL = pool;
        IWETH(weth).approve(address(pool), type(uint256).max);
    }

    /**
     * @dev deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying asset (aTokens)
     * is minted.
     * @param onBehalfOf address of the user who will receive the aTokens representing the deposit
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
     *
     */
    function depositETH(address onBehalfOf, uint16 referralCode) external payable override {
        WETH.deposit{value: msg.value}();
        POOL.supply(address(WETH), msg.value, onBehalfOf, referralCode);
    }

    /**
     * @dev withdraws the WETH _reserves of msg.sender.
     * @param amount amount of yWETH to withdraw and receive native ETH
     * @param to address of the user who will receive native ETH
     */
    function withdrawETH(uint256 amount, address to) external override {
        IYToken yWETH = IYToken(POOL.getReserveData(address(WETH)).yTokenAddress);
        uint256 userBalance = yWETH.balanceOf(msg.sender);
        uint256 amountToWithdraw = amount;

        // if amount is equal to uint(-1), the user wants to redeem everything
        if (amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }
        yWETH.transferFrom(msg.sender, address(this), amountToWithdraw);
        POOL.withdraw(address(WETH), amountToWithdraw, address(this));
        WETH.withdraw(amountToWithdraw);
        _safeTransferETH(to, amountToWithdraw);
    }

    /**
     * @dev repays a borrow on the WETH reserve, for the specified amount (or for the whole amount, if uint256(-1) is specified).
     * @param amount the amount to repay, or uint256(-1) if the user wants to repay everything
     * @param onBehalfOf the address for which msg.sender is repaying
     */
    function repayETH(uint256 amount, address onBehalfOf) external payable override {
        uint256 userDebt = IERC20(POOL.getReserveData(address(WETH)).variableDebtTokenAddress).balanceOf(onBehalfOf);
        uint256 paybackAmount = userDebt;
        if (amount < paybackAmount) {
            paybackAmount = amount;
        }
        require(msg.value >= paybackAmount, "msg.value is less than repayment amount");
        WETH.deposit{value: paybackAmount}();
        POOL.repay(address(WETH), msg.value, onBehalfOf);

        // refund remaining dust eth
        if (msg.value > paybackAmount) _safeTransferETH(msg.sender, msg.value - paybackAmount);
    }

    /**
     * @dev borrow WETH, unwraps to ETH and send both the ETH and DebtTokens to msg.sender, via `approveDelegation` and onBehalf argument in `Pool.borrow`.
     * @param amount the amount of ETH to borrow
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards
     */
    function borrowETH(uint256 amount, uint16 referralCode) external override {
        POOL.borrow(address(WETH), amount, referralCode, msg.sender);
        WETH.withdraw(amount);
        _safeTransferETH(msg.sender, amount);
    }

    /**
     * @dev withdraws the WETH _reserves of msg.sender.
     * @param amount amount of yWETH to withdraw and receive native ETH
     * @param to address of the user who will receive native ETH
     * @param deadline validity deadline of permit and so depositWithPermit signature
     * @param permitV V parameter of ERC712 permit sig
     * @param permitR R parameter of ERC712 permit sig
     * @param permitS S parameter of ERC712 permit sig
     */
    function withdrawETHWithPermit(
        uint256 amount,
        address to,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external override {
        IYToken yWETH = IYToken(POOL.getReserveData(address(WETH)).yTokenAddress);
        uint256 userBalance = yWETH.balanceOf(msg.sender);
        uint256 amountToWithdraw = amount;

        // if amount is equal to type(uint256).max, the user wants to redeem everything
        if (amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }
        // permit `amount` rather than `amountToWithdraw` to make it easier for front-ends and integrators
        yWETH.permit(msg.sender, address(this), amount, deadline, permitV, permitR, permitS);
        yWETH.transferFrom(msg.sender, address(this), amountToWithdraw);
        POOL.withdraw(address(WETH), amountToWithdraw, address(this));
        WETH.withdraw(amountToWithdraw);
        _safeTransferETH(to, amountToWithdraw);
    }

    /**
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value: value}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    /**
     * @dev Get WETH address used by WrappedTokenGatewayV3
     */
    function getWETHAddress() external view returns (address) {
        return address(WETH);
    }

    /**
     * @dev Only WETH contract is allowed to transfer ETH here. Prevent other addresses to send Ether to this contract.
     */
    receive() external payable {
        require(msg.sender == address(WETH), "Receive not allowed");
    }

    /**
     * @dev Revert fallback calls
     */
    fallback() external payable {
        revert("Fallback not allowed");
    }
}
