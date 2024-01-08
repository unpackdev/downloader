// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./SafeMath.sol";

import "./SimplePositionBaseConnector.sol";
import "./ISimplePositionLeveragedLendingConnector.sol";
import "./IExchangerAdapterProvider.sol";
import "./DyDxFlashModule.sol";
import "./ExchangerDispatcher.sol";
import "./FundsManager.sol";

contract SimplePositionLeveragedLendingConnector is
    SimplePositionBaseConnector,
    ExchangerDispatcher,
    FundsManager,
    DyDxFlashModule,
    ISimplePositionLeveragedLendingConnector
{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    constructor(
        address soloAddress,
        uint256 _principal,
        uint256 _profit,
        address _holder
    ) public DyDxFlashModule(soloAddress) FundsManager(_principal, _profit, _holder) {}

    function getExchanger(bytes1 flag) private view returns (address) {
        return IExchangerAdapterProvider(aStore().foldingRegistry).getExchangerAdapter(flag);
    }

    struct FoldingData {
        uint256 principalAmount;
        uint256 supplyAmount;
        uint256 borrowAmount;
        bool increasePosition;
        bytes exchangeDataBeforePosition;
        bytes exchangeDataAfterPosition;
    }

    function increaseSimplePositionWithFlashLoan(
        address flashLoanToken,
        uint256 flashLoanAmount,
        address platform,
        address supplyToken,
        uint256 principalAmount,
        uint256 supplyAmount,
        address borrowToken,
        uint256 borrowAmount,
        bytes memory exchangeDataBeforePosition,
        bytes memory exchangeDataAfterPosition
    ) external override onlyAccountOwnerOrRegistry {
        address lender = getLender(platform);
        if (isSimplePosition()) {
            requireSimplePositionDetails(platform, supplyToken, borrowToken);
        } else {
            simplePositionStore().platform = platform;
            simplePositionStore().supplyToken = supplyToken;
            simplePositionStore().borrowToken = borrowToken;

            address[] memory markets = new address[](2);
            markets[0] = supplyToken;
            markets[1] = borrowToken;
            enterMarkets(lender, platform, markets);
        }
        if (flashLoanAmount == 0) {
            _increaseWithFlashLoan(
                supplyToken,
                0,
                0,
                FoldingData({
                    principalAmount: principalAmount,
                    supplyAmount: supplyAmount,
                    borrowAmount: borrowAmount,
                    increasePosition: true,
                    exchangeDataBeforePosition: exchangeDataBeforePosition,
                    exchangeDataAfterPosition: exchangeDataAfterPosition
                })
            );
        } else {
            getFlashLoan(
                flashLoanToken,
                flashLoanAmount,
                abi.encode(
                    FoldingData({
                        principalAmount: principalAmount,
                        supplyAmount: supplyAmount,
                        borrowAmount: borrowAmount,
                        increasePosition: true,
                        exchangeDataBeforePosition: exchangeDataBeforePosition,
                        exchangeDataAfterPosition: exchangeDataAfterPosition
                    })
                )
            );
        }
    }

    function decreaseSimplePositionWithFlashLoan(
        address flashLoanToken,
        uint256 flashLoanAmount,
        address platform,
        address redeemToken,
        uint256 redeemPrincipal,
        uint256 redeemAmount,
        address repayToken,
        uint256 repayAmount,
        bytes memory exchangeDataBeforePosition,
        bytes memory exchangeDataAfterPosition
    ) external override onlyAccountOwner {
        requireSimplePositionDetails(platform, redeemToken, repayToken);
        if (flashLoanAmount == 0) {
            _decreaseWithFlashLoan(
                redeemToken,
                0,
                0,
                FoldingData({
                    principalAmount: redeemPrincipal,
                    supplyAmount: redeemAmount,
                    borrowAmount: repayAmount,
                    increasePosition: false,
                    exchangeDataBeforePosition: exchangeDataBeforePosition,
                    exchangeDataAfterPosition: exchangeDataAfterPosition
                })
            );
        } else {
            getFlashLoan(
                flashLoanToken,
                flashLoanAmount,
                abi.encode(
                    FoldingData({
                        principalAmount: redeemPrincipal,
                        supplyAmount: redeemAmount,
                        borrowAmount: repayAmount,
                        increasePosition: false,
                        exchangeDataBeforePosition: exchangeDataBeforePosition,
                        exchangeDataAfterPosition: exchangeDataAfterPosition
                    })
                )
            );
        }
    }

    /// @dev Called by the flash loaner in the flash loan callback
    function useFlashLoan(
        address flashloanToken,
        uint256 flashloanAmount,
        uint256 repayFlashAmount,
        bytes memory passedData
    ) internal override {
        FoldingData memory fd = abi.decode(passedData, (FoldingData));

        if (fd.increasePosition) {
            _increaseWithFlashLoan(flashloanToken, flashloanAmount, repayFlashAmount, fd);
        } else {
            _decreaseWithFlashLoan(flashloanToken, flashloanAmount, repayFlashAmount, fd);
        }
    }

    function _increaseWithFlashLoan(
        address flashloanToken,
        uint256 flashloanAmount,
        uint256 repayFlashAmount,
        FoldingData memory fd
    ) internal {
        SimplePositionStore memory sp = simplePositionStore();
        address lender = getLender(sp.platform);
        if (fd.principalAmount > 0) {
            addPrincipal(fd.principalAmount);
        }
        uint256 availableSupplyAmount;
        if (sp.supplyToken == flashloanToken) {
            availableSupplyAmount = flashloanAmount.add(fd.principalAmount);
            require(availableSupplyAmount >= fd.supplyAmount, 'SPLLC1');
        } else {
            availableSupplyAmount = swapFromExact(
                getExchanger(fd.exchangeDataBeforePosition[0]),
                flashloanToken,
                sp.supplyToken,
                flashloanAmount,
                fd.supplyAmount.sub(fd.principalAmount)
            ).add(fd.principalAmount);
        }

        supply(lender, sp.platform, sp.supplyToken, availableSupplyAmount);

        if (repayFlashAmount == 0) {
            return;
        }

        if (sp.borrowToken == flashloanToken) {
            require(fd.borrowAmount >= repayFlashAmount, 'SPLLC2');
            borrow(lender, sp.platform, sp.borrowToken, repayFlashAmount);
        } else {
            address exchangerAdapter = getExchanger(fd.exchangeDataAfterPosition[0]);
            uint256 borrowAmountNeeded = getAmountIn(
                exchangerAdapter,
                sp.borrowToken,
                flashloanToken,
                repayFlashAmount
            );
            require(fd.borrowAmount >= borrowAmountNeeded, 'SPLLC2');
            borrow(lender, sp.platform, sp.borrowToken, borrowAmountNeeded);
            swapToExact(exchangerAdapter, sp.borrowToken, flashloanToken, borrowAmountNeeded, repayFlashAmount);
        }
    }

    function _decreaseWithFlashLoan(
        address flashloanToken,
        uint256 flashloanAmount,
        uint256 repayFlashAmount,
        FoldingData memory fd
    ) internal {
        SimplePositionStore memory sp = simplePositionStore();
        address lender = getLender(sp.platform);

        uint256 debt = getBorrowBalance(lender, sp.platform, sp.borrowToken);
        uint256 deposit = getSupplyBalance(lender, sp.platform, sp.supplyToken);
        uint256 positionValue = deposit.sub(
            debt.mul(getReferencePrice(lender, sp.platform, sp.borrowToken)).div(
                getReferencePrice(lender, sp.platform, sp.supplyToken)
            )
        );
        if (debt > fd.borrowAmount) {
            debt = fd.borrowAmount;
        }
        if (debt > 0) {
            if (sp.borrowToken == flashloanToken) {
                require(flashloanAmount >= debt, 'SPLLC3');
                repayFlashAmount = repayFlashAmount.sub(flashloanAmount - debt);
            } else {
                uint256 flashloanAmountNeeded = swapToExact(
                    getExchanger(fd.exchangeDataBeforePosition[0]),
                    flashloanToken,
                    sp.borrowToken,
                    flashloanAmount,
                    debt
                );
                repayFlashAmount = repayFlashAmount.sub(flashloanAmount - flashloanAmountNeeded);
            }
            repayBorrow(lender, sp.platform, sp.borrowToken, debt);
        }

        if (fd.supplyAmount > deposit) {
            fd.supplyAmount = deposit;
        }

        redeemSupply(lender, sp.platform, sp.supplyToken, fd.supplyAmount);

        uint256 redeemPrincipalAmount;
        if (sp.supplyToken == flashloanToken) {
            redeemPrincipalAmount = fd.supplyAmount.sub(repayFlashAmount);
        } else {
            redeemPrincipalAmount = fd.supplyAmount.sub(
                swapToExact(
                    getExchanger(fd.exchangeDataAfterPosition[0]),
                    sp.supplyToken,
                    flashloanToken,
                    fd.supplyAmount,
                    repayFlashAmount
                )
            );
        }
        require(redeemPrincipalAmount >= fd.principalAmount, 'SPLLC5');
        if (redeemPrincipalAmount > 0) {
            withdraw(redeemPrincipalAmount, positionValue);
        }
    }
}
