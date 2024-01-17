// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ApeTokenInterface.sol";
import "./ComptrollerInterface.sol";

contract ApeTokenHelper is Ownable {
    using SafeERC20 for IERC20;

    ComptrollerInterface public immutable comptroller;

    /**
     * @notice Emitted when tokens are seized
     */
    event TokenSeized(address token, uint256 amount);

    constructor(ComptrollerInterface _comptroller) {
        comptroller = _comptroller;
    }

    /**
     * @notice The sender mints and borrows.
     * @param apeTokenMint The market that user wants to mint
     * @param mintAmount The mint amount
     * @param apeTokenBorrow The market that user wants to borrow
     * @param borrowAmount The borrow amount
     */
    function mintBorrow(
        ApeTokenInterface apeTokenMint,
        uint256 mintAmount,
        ApeTokenInterface apeTokenBorrow,
        uint256 borrowAmount
    ) external {
        require(
            comptroller.isMarketListed(address(apeTokenMint)) &&
                comptroller.isMarketListed(address(apeTokenBorrow)),
            "market not list"
        );
        _mint(apeTokenMint, mintAmount);

        require(
            apeTokenBorrow.borrow(payable(msg.sender), borrowAmount) == 0,
            "borrow failed"
        );
    }

    /**
     * @notice The sender mints.
     * @param apeTokenMint The market that user wants to mint
     * @param mintAmount The mint amount
     */
    function mint(ApeTokenInterface apeTokenMint, uint256 mintAmount) external {
        require(
            comptroller.isMarketListed(address(apeTokenMint)),
            "market not list"
        );
        _mint(apeTokenMint, mintAmount);
    }

    function _mint(ApeTokenInterface apeTokenMint, uint256 mintAmount)
        internal
    {
        address underlying = apeTokenMint.underlying();

        // Get funds from user.
        IERC20(underlying).safeTransferFrom(
            msg.sender,
            address(this),
            mintAmount
        );

        // Mint and borrow.
        IERC20(underlying).approve(address(apeTokenMint), mintAmount);
        require(apeTokenMint.mint(msg.sender, mintAmount) == 0, "mint failed");
    }

    /**
     * @notice The sender repays and redeems.
     * @param apeTokenRepay The market that user wants to repay
     * @param repayAmount The repay amount
     * @param apeTokenRedeem The market that user wants to redeem
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @param redeemAmount The amount of underlying to receive from redeeming cTokens
     */
    function repayRedeem(
        ApeTokenInterface apeTokenRepay,
        uint256 repayAmount,
        ApeTokenInterface apeTokenRedeem,
        uint256 redeemTokens,
        uint256 redeemAmount
    ) external {
        require(
            comptroller.isMarketListed(address(apeTokenRepay)) &&
                comptroller.isMarketListed(address(apeTokenRedeem)),
            "market not list"
        );
        _repay(apeTokenRepay, repayAmount);

        require(
            apeTokenRedeem.redeem(
                payable(msg.sender),
                redeemTokens,
                redeemAmount
            ) == 0,
            "redeem failed"
        );
    }

    /**
     * @notice The sender repays.
     * @param apeTokenRepay The market that user wants to repay
     * @param repayAmount The repay amount
     */
    function repay(ApeTokenInterface apeTokenRepay, uint256 repayAmount)
        external
    {
        require(
            comptroller.isMarketListed(address(apeTokenRepay)),
            "market not list"
        );
        _repay(apeTokenRepay, repayAmount);
    }

    function _repay(ApeTokenInterface apeTokenRepay, uint256 repayAmount)
        internal
    {
        address underlying = apeTokenRepay.underlying();

        if (repayAmount == type(uint256).max) {
            repayAmount = apeTokenRepay.borrowBalanceCurrent(msg.sender);
        }

        // Get funds from user.
        IERC20(underlying).safeTransferFrom(
            msg.sender,
            address(this),
            repayAmount
        );

        // Repay and redeem.
        IERC20(underlying).approve(address(apeTokenRepay), repayAmount);
        require(
            apeTokenRepay.repayBorrow(msg.sender, repayAmount) == 0,
            "repay failed"
        );
    }

    /*** Admin functions ***/

    /**
     * @notice Seize tokens in this contract.
     * @param token The token
     * @param amount The amount
     */
    function seize(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
        emit TokenSeized(token, amount);
    }
}
