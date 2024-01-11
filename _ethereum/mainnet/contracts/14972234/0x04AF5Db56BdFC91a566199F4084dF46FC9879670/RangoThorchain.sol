// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./BaseContract.sol";
import "./IThorchainRouter.sol";
import "./IRangoThorchain.sol";

contract RangoThorchain is IRangoThorchain, BaseContract {
    event ThorchainTxInitiated(address vault, address token, uint amount, string memo, uint expiration);

    receive() external payable {
//        assert(msg.sender == nativeWrappedAddress);
    }

    //    address rangoThorchainAddress;
    //
    //    function updateRangoThorchainAddress(address _address) external onlyOwner {
    //        rangoThorchainAddress = _address;
    //    }

    //    function swapIn(
    function swapInToThorchain(
        address token,
        uint amount,
        address tcRouter,
        address tcVault,
        string calldata thorchainMemo,
        uint expiration
    ) external payable whenNotPaused nonReentrant {
        BaseContractStorage storage baseStorage = getBaseContractStorage();
        require(baseStorage.whitelistContracts[tcRouter], "given thorchain router not whitelisted");
        require(amount > 0, "Requested amount should be positive");
        if (token == NULL_ADDRESS) {
            require(msg.value >= amount, "zero input while fromToken is native");
        } else {
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
            approve(token, tcRouter, amount);
        }

        IThorchainRouter(tcRouter).depositWithExpiry{value : msg.value}(
            payable(tcVault), // address payable vault,
            token, // address asset,
            amount, // uint amount,
            thorchainMemo, // string calldata memo,
            expiration  // uint expiration) external payable;
        );
        emit ThorchainTxInitiated(tcVault, token, amount, thorchainMemo, expiration);
    }

    //    function swapOut(address token, address to, uint256 amountOutMin) external payable whenNotPaused nonReentrant // TODO: limit to be called only by thorchain router?
    //    {
    //        address[] memory path = new address[](2);
    //        path[0] = nativeWrappedAddress;
    //        path[1] = token;
    //        swapRouter.swapExactETHForTokens{value : msg.value}( // todo: implement multiple contracts each for uniswap v2, v3, sushi etc? or just use existing thorchain routers?
    //            amountOutMin,
    //            path,
    //            to,
    //            type(uint).max // deadline
    //        );
    //    }
}