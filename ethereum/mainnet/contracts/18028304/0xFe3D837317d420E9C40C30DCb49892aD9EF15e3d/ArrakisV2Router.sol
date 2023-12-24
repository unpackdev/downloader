// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IGauge.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./IArrakisV2.sol";
import "./SArrakisV2Router.sol";
import "./SPermit2.sol";
import "./ArrakisV2RouterStorage.sol";
import "./SArrakisV2Router.sol";
import "./EnumerableSet.sol";

/// @title ArrakisV2 Public Vault Router
/// @notice Smart contract for adding and removing liquidity from Public ArrakisV2 vaults
/// @author Arrakis Finance
/// @dev DO NOT ADD STATE VARIABLES - APPEND THEM TO ArrakisV2RouterStorage
contract ArrakisV2Router is ArrakisV2RouterStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address payable;
    using SafeERC20 for IERC20;

    constructor(
        address weth_,
        address resolver_,
        address permit2_
    ) ArrakisV2RouterStorage(weth_, resolver_, permit2_) {} // solhint-disable-line no-empty-blocks

    /// @notice addLiquidity adds liquidity to ArrakisV2 vault of interest (mints LP tokens)
    /// @param params_ AddLiquidityData struct containing data for adding liquidity
    /// @return amount0 amount of token0 transferred from msg.sender to mint `mintAmount`
    /// @return amount1 amount of token1 transferred from msg.sender to mint `mintAmount`
    /// @return sharesReceived amount of ArrakisV2 tokens transferred to `receiver`
    // solhint-disable-next-line code-complexity, function-max-lines
    function addLiquidity(AddLiquidityData memory params_)
        external
        payable
        whenNotPaused
        nonReentrant
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 sharesReceived
        )
    {
        require(
            params_.amount0Max > 0 || params_.amount1Max > 0,
            "Empty max amounts"
        );
        if (params_.gauge != address(0)) {
            require(
                params_.vault == IGauge(params_.gauge).staking_token(),
                "Incorrect gauge!"
            );
        }

        (amount0, amount1, sharesReceived) = resolver.getMintAmounts(
            IArrakisV2(params_.vault),
            params_.amount0Max,
            params_.amount1Max
        );

        require(sharesReceived > 0, "nothing to mint");
        require(
            amount0 >= params_.amount0Min &&
                amount1 >= params_.amount1Min &&
                sharesReceived >= params_.amountSharesMin,
            "below min amounts"
        );

        IERC20 token0 = IArrakisV2(params_.vault).token0();
        IERC20 token1 = IArrakisV2(params_.vault).token1();

        bool isToken0Weth;
        if (msg.value > 0) {
            isToken0Weth = _wrapETH(amount0, amount1, false, token0, token1);
        }

        if (amount0 > 0 && (msg.value == 0 || !isToken0Weth)) {
            token0.safeTransferFrom(msg.sender, address(this), amount0);
        }
        if (amount1 > 0 && (msg.value == 0 || isToken0Weth)) {
            token1.safeTransferFrom(msg.sender, address(this), amount1);
        }

        _addLiquidity(
            params_.vault,
            amount0,
            amount1,
            sharesReceived,
            params_.gauge,
            params_.receiver,
            token0,
            token1
        );

        if (msg.value > 0) {
            if (isToken0Weth && msg.value > amount0) {
                payable(msg.sender).sendValue(msg.value - amount0);
            } else if (!isToken0Weth && msg.value > amount1) {
                payable(msg.sender).sendValue(msg.value - amount1);
            }
        }
    }

    /// @notice swapAndAddLiquidity transfer tokens to and calls ArrakisV2Router
    /// @param params_ SwapAndAddData struct containing data for swap
    /// @return amount0 amount of token0 transferred from msg.sender to mint `mintAmount`
    /// @return amount1 amount of token1 transferred from msg.sender to mint `mintAmount`
    /// @return sharesReceived amount of ArrakisV2 tokens transferred to `receiver`
    /// @return amount0Diff token0 balance difference post swap
    /// @return amount1Diff token1 balance difference post swap
    // solhint-disable-next-line code-complexity, function-max-lines
    function swapAndAddLiquidity(SwapAndAddData memory params_)
        external
        payable
        whenNotPaused
        nonReentrant
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 sharesReceived,
            uint256 amount0Diff,
            uint256 amount1Diff
        )
    {
        require(
            params_.addData.amount0Max > 0 || params_.addData.amount1Max > 0,
            "Empty max amounts"
        );
        if (params_.addData.gauge != address(0)) {
            require(
                params_.addData.vault ==
                    IGauge(params_.addData.gauge).staking_token(),
                "Incorrect gauge!"
            );
        }

        IERC20 token0 = IArrakisV2(params_.addData.vault).token0();
        IERC20 token1 = IArrakisV2(params_.addData.vault).token1();

        bool isToken0Weth;
        if (msg.value > 0) {
            isToken0Weth = _wrapETH(
                params_.addData.amount0Max,
                params_.addData.amount1Max,
                true,
                token0,
                token1
            );
        }

        if (
            params_.addData.amount0Max > 0 && (msg.value == 0 || !isToken0Weth)
        ) {
            token0.safeTransferFrom(
                msg.sender,
                address(this),
                params_.addData.amount0Max
            );
        }
        if (
            params_.addData.amount1Max > 0 && (msg.value == 0 || isToken0Weth)
        ) {
            token1.safeTransferFrom(
                msg.sender,
                address(this),
                params_.addData.amount1Max
            );
        }

        (
            amount0,
            amount1,
            sharesReceived,
            amount0Diff,
            amount1Diff
        ) = _swapAndAddLiquidity(params_, token0, token1);
    }

    /// @notice removeLiquidity removes liquidity from vault and burns LP tokens
    /// @param params_ RemoveLiquidityData struct containing data for withdrawals
    /// @return amount0 actual amount of token0 transferred to receiver for burning `burnAmount`
    /// @return amount1 actual amount of token1 transferred to receiver for burning `burnAmount`
    // solhint-disable-next-line code-complexity, function-max-lines
    function removeLiquidity(RemoveLiquidityData memory params_)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        require(params_.burnAmount > 0, "nothing to burn");
        if (params_.gauge != address(0)) {
            require(
                params_.vault == IGauge(params_.gauge).staking_token(),
                "Incorrect gauge!"
            );
            IGauge(params_.gauge).claim_rewards(msg.sender);
            IERC20(params_.gauge).safeTransferFrom(
                msg.sender,
                address(this),
                params_.burnAmount
            );

            IGauge(params_.gauge).withdraw(params_.burnAmount);
        } else {
            IERC20(params_.vault).safeTransferFrom(
                msg.sender,
                address(this),
                params_.burnAmount
            );
        }

        (amount0, amount1) = _removeLiquidity(params_);
    }

    /// @notice addLiquidityPermit2 adds liquidity to ArrakisV2 vault of interest (mints LP tokens)
    /// @param params_ AddLiquidityPermit2Data struct containing data for adding liquidity
    /// @return amount0 amount of token0 transferred from msg.sender to mint `mintAmount`
    /// @return amount1 amount of token1 transferred from msg.sender to mint `mintAmount`
    /// @return sharesReceived amount of ArrakisV2 tokens transferred to `receiver`
    // solhint-disable-next-line code-complexity, function-max-lines
    function addLiquidityPermit2(AddLiquidityPermit2Data memory params_)
        external
        payable
        whenNotPaused
        nonReentrant
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 sharesReceived
        )
    {
        require(
            params_.addData.amount0Max > 0 || params_.addData.amount1Max > 0,
            "Empty max amounts"
        );
        if (params_.addData.gauge != address(0)) {
            require(
                params_.addData.vault ==
                    IGauge(params_.addData.gauge).staking_token(),
                "Incorrect gauge!"
            );
        }

        (amount0, amount1, sharesReceived) = resolver.getMintAmounts(
            IArrakisV2(params_.addData.vault),
            params_.addData.amount0Max,
            params_.addData.amount1Max
        );

        require(sharesReceived > 0, "nothing to mint");
        require(
            amount0 >= params_.addData.amount0Min &&
                amount1 >= params_.addData.amount1Min &&
                sharesReceived >= params_.addData.amountSharesMin,
            "below min amounts"
        );

        IERC20 token0 = IArrakisV2(params_.addData.vault).token0();
        IERC20 token1 = IArrakisV2(params_.addData.vault).token1();
        _permit2Add(params_, amount0, amount1, token0, token1);

        _addLiquidity(
            params_.addData.vault,
            amount0,
            amount1,
            sharesReceived,
            params_.addData.gauge,
            params_.addData.receiver,
            token0,
            token1
        );

        if (msg.value > 0) {
            bool isToken0Weth = _isToken0Weth(address(token0), address(token1));
            if (isToken0Weth && msg.value > amount0) {
                payable(msg.sender).sendValue(msg.value - amount0);
            } else if (!isToken0Weth && msg.value > amount1) {
                payable(msg.sender).sendValue(msg.value - amount1);
            }
        }
    }

    /// @notice swapAndAddLiquidityPermit2 transfer tokens to and calls ArrakisV2Router
    /// @param params_ SwapAndAddPermit2Data struct containing data for swap
    /// @return amount0 amount of token0 transferred from msg.sender to mint `mintAmount`
    /// @return amount1 amount of token1 transferred from msg.sender to mint `mintAmount`
    /// @return sharesReceived amount of ArrakisV2 tokens transferred to `receiver`
    /// @return amount0Diff token0 balance difference post swap
    /// @return amount1Diff token1 balance difference post swap
    // solhint-disable-next-line code-complexity, function-max-lines
    function swapAndAddLiquidityPermit2(SwapAndAddPermit2Data memory params_)
        external
        payable
        whenNotPaused
        nonReentrant
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 sharesReceived,
            uint256 amount0Diff,
            uint256 amount1Diff
        )
    {
        require(
            params_.swapAndAddData.addData.amount0Max > 0 ||
                params_.swapAndAddData.addData.amount1Max > 0,
            "Empty max amounts"
        );
        if (params_.swapAndAddData.addData.gauge != address(0)) {
            require(
                params_.swapAndAddData.addData.vault ==
                    IGauge(params_.swapAndAddData.addData.gauge)
                        .staking_token(),
                "Incorrect gauge!"
            );
        }

        IERC20 token0 = IArrakisV2(params_.swapAndAddData.addData.vault)
            .token0();
        IERC20 token1 = IArrakisV2(params_.swapAndAddData.addData.vault)
            .token1();

        _permit2SwapAndAdd(params_, token0, token1);

        (
            amount0,
            amount1,
            sharesReceived,
            amount0Diff,
            amount1Diff
        ) = _swapAndAddLiquidity(params_.swapAndAddData, token0, token1);
    }

    /// @notice removeLiquidityPermit2 removes liquidity from vault and burns LP tokens
    /// @param params_ RemoveLiquidityPermit2Data struct containing data for withdrawals
    /// @return amount0 actual amount of token0 transferred to receiver for burning `burnAmount`
    /// @return amount1 actual amount of token1 transferred to receiver for burning `burnAmount`
    // solhint-disable-next-line code-complexity, function-max-lines
    function removeLiquidityPermit2(RemoveLiquidityPermit2Data memory params_)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        require(params_.removeData.burnAmount > 0, "nothing to burn");
        SignatureTransferDetails
            memory transferDetails = SignatureTransferDetails({
                to: address(this),
                requestedAmount: params_.removeData.burnAmount
            });
        if (params_.removeData.gauge != address(0)) {
            require(
                params_.removeData.vault ==
                    IGauge(params_.removeData.gauge).staking_token(),
                "Incorrect gauge!"
            );
            IGauge(params_.removeData.gauge).claim_rewards(msg.sender);
            permit2.permitTransferFrom(
                params_.permit,
                transferDetails,
                msg.sender,
                params_.signature
            );

            IGauge(params_.removeData.gauge).withdraw(
                params_.removeData.burnAmount
            );
        } else {
            permit2.permitTransferFrom(
                params_.permit,
                transferDetails,
                msg.sender,
                params_.signature
            );
        }

        (amount0, amount1) = _removeLiquidity(params_.removeData);
    }

    // solhint-disable-next-line function-max-lines
    function _addLiquidity(
        address vault_,
        uint256 amount0In_,
        uint256 amount1In_,
        uint256 mintAmount_,
        address gauge_,
        address receiver_,
        IERC20 token0_,
        IERC20 token1_
    ) internal {
        token0_.safeIncreaseAllowance(vault_, amount0In_);
        token1_.safeIncreaseAllowance(vault_, amount1In_);

        {
            MintRules memory mintRules = mintRestrictedVaults[vault_];
            if (mintRules.supplyCap > 0) {
                require(
                    IArrakisV2(vault_).totalSupply() + mintAmount_ <=
                        mintRules.supplyCap,
                    "above supply cap"
                );
            }
            if (mintRules.hasWhitelist) {
                require(
                    _mintWhitelist[vault_].contains(msg.sender),
                    "not whitelisted"
                );
            }
        }

        uint256 balance0 = token0_.balanceOf(address(this));
        uint256 balance1 = token1_.balanceOf(address(this));
        if (gauge_ == address(0)) {
            IArrakisV2(vault_).mint(mintAmount_, receiver_);
        } else {
            IArrakisV2(vault_).mint(mintAmount_, address(this));

            IERC20(vault_).safeIncreaseAllowance(gauge_, mintAmount_);
            IGauge(gauge_).deposit(mintAmount_, receiver_);
        }

        require(
            balance0 - amount0In_ == token0_.balanceOf(address(this)),
            "deposit0"
        );
        require(
            balance1 - amount1In_ == token1_.balanceOf(address(this)),
            "deposit1"
        );
    }

    // solhint-disable-next-line function-max-lines, code-complexity
    function _swapAndAddLiquidity(
        SwapAndAddData memory params_,
        IERC20 token0_,
        IERC20 token1_
    )
        internal
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 sharesReceived,
            uint256 amount0Diff,
            uint256 amount1Diff
        )
    {
        if (params_.swapData.zeroForOne) {
            token0_.safeTransfer(
                address(swapper),
                params_.swapData.amountInSwap
            );
        } else {
            token1_.safeTransfer(
                address(swapper),
                params_.swapData.amountInSwap
            );
        }

        (amount0Diff, amount1Diff) = swapper.swap(params_);

        emit Swapped(
            params_.swapData.zeroForOne,
            amount0Diff,
            amount1Diff,
            params_.swapData.amountOutSwap
        );

        uint256 amount0Use = (params_.swapData.zeroForOne)
            ? params_.addData.amount0Max - amount0Diff
            : params_.addData.amount0Max + amount0Diff;
        uint256 amount1Use = (params_.swapData.zeroForOne)
            ? params_.addData.amount1Max + amount1Diff
            : params_.addData.amount1Max - amount1Diff;

        (amount0, amount1, sharesReceived) = resolver.getMintAmounts(
            IArrakisV2(params_.addData.vault),
            amount0Use,
            amount1Use
        );

        require(sharesReceived > 0, "nothing to mint");
        require(
            amount0 >= params_.addData.amount0Min &&
                amount1 >= params_.addData.amount1Min &&
                sharesReceived >= params_.addData.amountSharesMin,
            "below min amounts"
        );

        _addLiquidity(
            params_.addData.vault,
            amount0,
            amount1,
            sharesReceived,
            params_.addData.gauge,
            params_.addData.receiver,
            token0_,
            token1_
        );

        bool isToken0Weth;
        if (msg.value > 0) {
            isToken0Weth = _isToken0Weth(address(token0_), address(token1_));
            if (isToken0Weth && amount0Use > amount0) {
                _unwrapRefundETH(msg.sender, amount0Use - amount0);
            } else if (!isToken0Weth && amount1Use > amount1) {
                _unwrapRefundETH(msg.sender, amount1Use - amount1);
            }
        }

        if (amount0Use > amount0 && (msg.value == 0 || !isToken0Weth)) {
            token0_.safeTransfer(msg.sender, amount0Use - amount0);
        }
        if (amount1Use > amount1 && (msg.value == 0 || isToken0Weth)) {
            token1_.safeTransfer(msg.sender, amount1Use - amount1);
        }
    }

    function _removeLiquidity(RemoveLiquidityData memory removeData_)
        internal
        returns (uint256 amount0, uint256 amount1)
    {
        if (removeData_.receiveETH) {
            (amount0, amount1) = IArrakisV2(removeData_.vault).burn(
                removeData_.burnAmount,
                address(this)
            );
        } else {
            (amount0, amount1) = IArrakisV2(removeData_.vault).burn(
                removeData_.burnAmount,
                removeData_.receiver
            );
        }

        require(
            amount0 >= removeData_.amount0Min &&
                amount1 >= removeData_.amount1Min,
            "received below minimum"
        );

        if (removeData_.receiveETH) {
            _receiveETH(
                IArrakisV2(removeData_.vault),
                amount0,
                amount1,
                removeData_.receiver
            );
        }
    }

    // solhint-disable-next-line function-max-lines
    function _permit2Add(
        AddLiquidityPermit2Data memory params_,
        uint256 amount0_,
        uint256 amount1_,
        IERC20 token0_,
        IERC20 token1_
    ) internal {
        if (msg.value > 0) {
            require(params_.permit.permitted.length == 1, "length mismatch");
            bool isToken0Weth = _wrapETH(
                amount0_,
                amount1_,
                false,
                token0_,
                token1_
            );
            uint256 amount = isToken0Weth ? amount1_ : amount0_;
            if (amount > 0) {
                SignatureTransferDetails
                    memory transferDetails = SignatureTransferDetails({
                        to: address(this),
                        requestedAmount: amount
                    });
                PermitTransferFrom memory permit = PermitTransferFrom({
                    permitted: params_.permit.permitted[0],
                    nonce: params_.permit.nonce,
                    deadline: params_.permit.deadline
                });
                permit2.permitTransferFrom(
                    permit,
                    transferDetails,
                    msg.sender,
                    params_.signature
                );
            }
        } else {
            require(params_.permit.permitted.length == 2, "length mismatch");
            SignatureTransferDetails[]
                memory transfers = new SignatureTransferDetails[](2);
            transfers[0] = SignatureTransferDetails({
                to: address(this),
                requestedAmount: amount0_
            });
            transfers[1] = SignatureTransferDetails({
                to: address(this),
                requestedAmount: amount1_
            });
            permit2.permitTransferFrom(
                params_.permit,
                transfers,
                msg.sender,
                params_.signature
            );
        }
    }

    // solhint-disable-next-line function-max-lines
    function _permit2SwapAndAdd(
        SwapAndAddPermit2Data memory params_,
        IERC20 token0_,
        IERC20 token1_
    ) internal {
        if (msg.value > 0) {
            require(params_.permit.permitted.length == 1, "length mismatch");
            bool isToken0Weth = _wrapETH(
                params_.swapAndAddData.addData.amount0Max,
                params_.swapAndAddData.addData.amount1Max,
                true,
                token0_,
                token1_
            );
            uint256 amount = isToken0Weth
                ? params_.swapAndAddData.addData.amount1Max
                : params_.swapAndAddData.addData.amount0Max;
            if (amount > 0) {
                SignatureTransferDetails
                    memory transferDetails = SignatureTransferDetails({
                        to: address(this),
                        requestedAmount: amount
                    });
                PermitTransferFrom memory permit = PermitTransferFrom({
                    permitted: params_.permit.permitted[0],
                    nonce: params_.permit.nonce,
                    deadline: params_.permit.deadline
                });
                permit2.permitTransferFrom(
                    permit,
                    transferDetails,
                    msg.sender,
                    params_.signature
                );
            }
        } else {
            require(params_.permit.permitted.length == 2, "length mismatch");
            SignatureTransferDetails[]
                memory transfers = new SignatureTransferDetails[](2);
            transfers[0] = SignatureTransferDetails({
                to: address(this),
                requestedAmount: params_.swapAndAddData.addData.amount0Max
            });
            transfers[1] = SignatureTransferDetails({
                to: address(this),
                requestedAmount: params_.swapAndAddData.addData.amount1Max
            });
            permit2.permitTransferFrom(
                params_.permit,
                transfers,
                msg.sender,
                params_.signature
            );
        }
    }

    function _wrapETH(
        uint256 amount0In_,
        uint256 amount1In_,
        bool matchAmount_,
        IERC20 token0_,
        IERC20 token1_
    ) internal returns (bool isToken0Weth) {
        isToken0Weth = _isToken0Weth(address(token0_), address(token1_));
        uint256 wethAmount = isToken0Weth ? amount0In_ : amount1In_;
        if (matchAmount_) {
            require(wethAmount == msg.value, "Invalid amount of ETH forwarded");
        } else {
            require(wethAmount <= msg.value, "Not enough ETH forwarded");
        }

        weth.deposit{value: wethAmount}();
    }

    function _unwrapRefundETH(address refund_, uint256 refundAmount_) internal {
        weth.withdraw(refundAmount_);
        payable(refund_).sendValue(refundAmount_);
    }

    // solhint-disable-next-line code-complexity
    function _receiveETH(
        IArrakisV2 vault_,
        uint256 amount0_,
        uint256 amount1_,
        address payable receiver_
    ) internal {
        IERC20 token0 = vault_.token0();
        IERC20 token1 = vault_.token1();
        bool wethToken0 = _isToken0Weth(address(token0), address(token1));
        if (wethToken0) {
            if (amount0_ > 0) {
                weth.withdraw(amount0_);
                receiver_.sendValue(amount0_);
            }
            if (amount1_ > 0) {
                token1.safeTransfer(receiver_, amount1_);
            }
        } else {
            if (amount1_ > 0) {
                weth.withdraw(amount1_);
                receiver_.sendValue(amount1_);
            }
            if (amount0_ > 0) {
                token0.safeTransfer(receiver_, amount0_);
            }
        }
    }

    function _isToken0Weth(address token0_, address token1_)
        internal
        view
        returns (bool wethToken0)
    {
        if (token0_ == address(weth)) {
            wethToken0 = true;
        } else if (token1_ != address(weth)) {
            revert("one vault token must be WETH");
        }
    }
}
