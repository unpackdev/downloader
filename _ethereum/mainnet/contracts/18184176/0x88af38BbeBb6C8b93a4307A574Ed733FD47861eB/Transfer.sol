import "./BaseModule.sol";
import "./IERC20.sol";

interface ISmartWalletDiamondFactory {
    function getUserFromWallet(address wallet) external view returns(address owner);
}

pragma solidity 0.8.19;

// SPDX-License-Identifier: MIT

contract Transfer is BaseModule {
    constructor() BaseModule("Transfer") {}

    error Unauthorized();
    error EthTransferFail();

    /// @notice override function for transferIn
    function oTransferIn(
        bytes memory originalData,
        TokenAmt[] memory tokenAmts
    ) public pure returns (bytes memory) {
        (
            address from,
            /* address token */,
            /* uint amount */
        ) = abi.decode(originalData, (address, address, uint));
        return abi.encode(from, tokenAmts[0].token, tokenAmts[0].amt);
    }

    /// @notice Transfers token into smart wallet
    /// @custom:version 1
    /// @custom:in 0
    /// @custom:out TokenIn
    /// @custom:equal true
    /// @custom:override oTransferIn
    /// @custom:event address from,address tokenIn0,uint256 amountIn0
    /// @custom:mirror transferOut
    /// @custom:getter getBalance
    function transferIn(
        address from,
        address token,
        uint amount
    ) public payable returns (TokenAmt[] memory) {
        IERC20(token).transferFrom(from, address(this), amount);
        TokenAmt[] memory tokenAmts = new TokenAmt[](1);
        tokenAmts[0] = TokenAmt({token: token, amt: amount});
        emit Event(this.transferIn.selector, 0, abi.encode(from, token, amount));
        return tokenAmts;
    }

    /// @notice withdraw funds from smart wallet
    /// @dev the funds can only be returned to smart wallet owner
    /// @dev uses entire balance if amount input is 0
    /// @custom:version 1
    /// @custom:in 1
    /// @custom:out none
    /// @custom:equal true
    /// @custom:override oTransferOut
    /// @custom:event address tokenOut0,uint256 amountOut0
    /// @custom:mirror transferIn
    /// @custom:getter getBalance    
    function transferOut(address token, uint amount) public payable {
        address owner = ISmartWalletDiamondFactory(BaseModule.diamond)
            .getUserFromWallet(address(this));
        if (owner == address(0)) revert Unauthorized();
        if (token == address(0)) {
            amount = amount == type(uint256).max ? address(this).balance : amount;
            (bool success, ) = owner.call{value: amount}("");
            if (!success) revert EthTransferFail();
        } else {
            amount = amount == type(uint256).max
                ? IERC20(token).balanceOf(address(this))
                : amount;
            IERC20(token).transfer(owner, amount);
        }
        emit Event(this.transferOut.selector, 0, abi.encode(token, amount));
    }

    /// @notice override function for transferOut
    function oTransferOut(
        bytes memory,
        TokenAmt[] memory tokenAmts
    ) public pure returns (bytes memory) {
        /// @dev only 1 input expected
        /// @dev we can return directly as transferOut only requires token & amount
        return abi.encode(tokenAmts[0].token, tokenAmts[0].amt);
    }


    /// @notice revokes the allowance of a given spender
    /// @ custom:version 1
    /// @custom:in 0
    /// @custom:out none
    /// @custom:equal false
    /// @custom:override none
    /// @custom:event none
    /// @custom:mirror none
    /// @custom:getter none
    function revoke(address token, address spender) public payable {
        IERC20(token).approve(spender, 0);
    }

    /// @notice gets the balance of a target
    /// @custom:version 1
    /// @custom:in 1
    /// @custom:out none
    /// @custom:equal false
    /// @custom:override none
    /// @custom:event none
    /// @custom:mirror none
    /// @custom:getter none
    function getBalance(address target, address token) public view returns(TokenAmt[] memory){
        TokenAmt[] memory tokenAmt = new TokenAmt[](1);
        tokenAmt[0]=TokenAmt({
            token:token,
            amt:IERC20(token).balanceOf(target)
        });
        return tokenAmt;
    }
}
