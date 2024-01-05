pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./AdminAuth.sol";
import "./FlashLoanReceiverBase.sol";
import "./DSProxyInterface.sol";
import "./DFSExchangeCore.sol";
import "./ShifterRegistry.sol";
import "./LoanShifterTaker.sol";

/// @title LoanShifterReceiver Recevies the Aave flash loan and calls actions through users DSProxy
contract LoanShifterReceiver is DFSExchangeCore, FlashLoanReceiverBase, AdminAuth {
    address public constant DISCOUNT_ADDR = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER =
        ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint public constant SERVICE_FEE = 400; // 0.25% Fee

    ShifterRegistry public constant shifterRegistry =
        ShifterRegistry(0x597C52281b31B9d949a9D8fEbA08F7A2530a965e);

    struct ParamData {
        bytes proxyData1;
        bytes proxyData2;
        address proxy;
        address debtAddr;
        uint8 protocol1;
        uint8 protocol2;
        uint8 swapType;
    }

    constructor() public FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER) {}

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external override {
        // Format the call data for DSProxy
        (ParamData memory paramData, ExchangeData memory exchangeData) =
            packFunctionCall(_amount, _fee, _params);

        address protocolAddr1 = shifterRegistry.getAddr(getNameByProtocol(paramData.protocol1));
        address protocolAddr2 = shifterRegistry.getAddr(getNameByProtocol(paramData.protocol2));

        // Send Flash loan amount to DSProxy
        sendTokenToProxy(payable(paramData.proxy), _reserve, _amount);

        // Execute the Close/Change debt operation
        DSProxyInterface(paramData.proxy).execute(protocolAddr1, paramData.proxyData1);

        exchangeData.dfsFeeDivider = SERVICE_FEE;
        exchangeData.user = DSProxyInterface(paramData.proxy).owner();

        if (paramData.swapType == 1) {
            uint256 amount = exchangeData.srcAmount;

            if (exchangeData.srcAddr != exchangeData.destAddr) {
                // COLL_SWAP
                (, amount) = _sell(exchangeData);
            }

            sendTokenAndEthToProxy(payable(paramData.proxy), exchangeData.destAddr, amount);
        } else if (paramData.swapType == 2) {
            // DEBT_SWAP

            if (exchangeData.srcAddr != exchangeData.destAddr) {
                exchangeData.destAmount = (_amount + _fee);
                _buy(exchangeData);

                // Send extra to DSProxy
                sendTokenToProxy(
                    payable(paramData.proxy),
                    exchangeData.srcAddr,
                    ERC20(exchangeData.srcAddr).balanceOf(address(this))
                );
            }
        } else {
            // NO_SWAP just send tokens to proxy
            sendTokenAndEthToProxy(
                payable(paramData.proxy),
                exchangeData.srcAddr,
                getBalance(exchangeData.srcAddr)
            );
        }

        // Execute the Open operation
        DSProxyInterface(paramData.proxy).execute(protocolAddr2, paramData.proxyData2);

        // Repay FL
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    function packFunctionCall(
        uint256 _amount,
        uint256 _fee,
        bytes memory _params
    )
        internal
        pure
        returns (ParamData memory paramData, ExchangeData memory exchangeData)
    {

        LoanShifterTaker.LoanShiftData memory shiftData;
        address proxy;

        (shiftData, exchangeData, proxy) = abi.decode(
            _params,
            (LoanShifterTaker.LoanShiftData, ExchangeData, address)
        );

        bytes memory proxyData1;
        bytes memory proxyData2;
        uint256 openDebtAmount = (_amount + _fee);

        if (shiftData.fromProtocol == LoanShifterTaker.Protocols.MCD) {
            // MAKER FROM
            proxyData1 = abi.encodeWithSignature(
                "close(uint256,address,uint256,uint256)",
                shiftData.id1,
                shiftData.addrLoan1,
                _amount,
                shiftData.collAmount
            );
        } else if (shiftData.fromProtocol == LoanShifterTaker.Protocols.COMPOUND) {
            // COMPOUND FROM
            if (shiftData.swapType == LoanShifterTaker.SwapType.DEBT_SWAP) {
                // DEBT_SWAP
                proxyData1 = abi.encodeWithSignature(
                    "changeDebt(address,address,uint256,uint256)",
                    shiftData.debtAddr1,
                    shiftData.debtAddr2,
                    _amount,
                    exchangeData.srcAmount
                );
            } else {
                proxyData1 = abi.encodeWithSignature(
                    "close(address,address,uint256,uint256)",
                    shiftData.addrLoan1,
                    shiftData.debtAddr1,
                    shiftData.collAmount,
                    shiftData.debtAmount
                );
            }
        }

        if (shiftData.toProtocol == LoanShifterTaker.Protocols.MCD) {
            // MAKER TO
            proxyData2 = abi.encodeWithSignature(
                "open(uint256,address,uint256)",
                shiftData.id2,
                shiftData.addrLoan2,
                openDebtAmount
            );
        } else if (shiftData.toProtocol == LoanShifterTaker.Protocols.COMPOUND) {
            // COMPOUND TO
            if (shiftData.swapType == LoanShifterTaker.SwapType.DEBT_SWAP) {
                // DEBT_SWAP
                proxyData2 = abi.encodeWithSignature("repayAll(address)", shiftData.debtAddr2);
            } else {
                proxyData2 = abi.encodeWithSignature(
                    "open(address,address,uint256)",
                    shiftData.addrLoan2,
                    shiftData.debtAddr2,
                    openDebtAmount
                );
            }
        }

        paramData = ParamData({
            proxyData1: proxyData1,
            proxyData2: proxyData2,
            proxy: proxy,
            debtAddr: shiftData.debtAddr1,
            protocol1: uint8(shiftData.fromProtocol),
            protocol2: uint8(shiftData.toProtocol),
            swapType: uint8(shiftData.swapType)
        });
    }

    function sendTokenAndEthToProxy(
        address payable _proxy,
        address _reserve,
        uint256 _amount
    ) internal {
        if (_reserve != ETH_ADDRESS) {
            ERC20(_reserve).safeTransfer(_proxy, _amount);
        }

        _proxy.transfer(address(this).balance);
    }

    function sendTokenToProxy(
        address payable _proxy,
        address _reserve,
        uint256 _amount
    ) internal {
        if (_reserve != ETH_ADDRESS) {
            ERC20(_reserve).safeTransfer(_proxy, _amount);
        } else {
            _proxy.transfer(address(this).balance);
        }
    }

    function getNameByProtocol(uint8 _proto) internal pure returns (string memory) {
        if (_proto == 0) {
            return "MCD_SHIFTER";
        } else if (_proto == 1) {
            return "COMP_SHIFTER";
        }
    }

    receive() external payable override(FlashLoanReceiverBase, DFSExchangeCore) {}
}
