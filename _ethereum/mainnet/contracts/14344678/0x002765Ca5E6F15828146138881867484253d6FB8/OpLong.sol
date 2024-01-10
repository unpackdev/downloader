// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OpCommon.sol";
import "./IProtocolAaveV2.sol";
import "./IProtocolERC20.sol";
import "./IOperationCenter.sol";
import "./IAccountCenter.sol";
import "./IEventCenterLeveragePosition.sol";

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeMath.sol";

interface ProtocolCenterInterface {
    function getProtocol(string memory protocolName)
        external
        view
        returns (address protocol);
}

interface ConnectorAaveV2Interface {
    function deposit(
        address token,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable;
}

interface ConnectorCenterInterface {
    function getConnector(string calldata connectorNames)
        external
        view
        returns (bool, address);
}

interface EventCenterInterface {
    function emitAddMarginEvent(
        address collateralToken,
        uint256 amountCollateralToken
    ) external;
}

struct Token {
    address token;
    string symbol;
}

interface TokenCenterInterface {
    function listLongToken() external view returns (Token[] memory tokenList);

    function isLongable(address token) external view returns (bool longable);
}

interface IERC3156FlashLender {
    function maxFlashLoan(address token) external view returns (uint256);

    function flashFee(address token, uint256 amount)
        external
        view
        returns (uint256);

    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata _spells
    ) external returns (bool);
}

contract OpLong is OpCommon {
    using SafeERC20 for IERC20;

    address internal constant ethAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable lender;
    address public immutable opCenterAddress;
    uint256 public flashBalance;
    address public flashInitiator;
    address public flashToken;
    uint256 public flashAmount;
    uint256 public flashFee;

    AaveLendingPoolProviderInterface internal constant aaveProvider =
        AaveLendingPoolProviderInterface(
            0x88757f2f99175387aB4C6a4b3067c77A695b0349
        );

    constructor(address _opCenterAddress, address _lender) {
        lender = _lender;
        opCenterAddress = _opCenterAddress;
    }

    function openLong(
        address leverageToken,
        address targetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) public payable onlyAuth {

        bool _isLongable = TokenCenterInterface(
            OperationCenterInterface(opCenterAddress).tokenCenterAddress()
        ).isLongable(targetToken);
        require(
            _isLongable,
            "CHFY: target token not support to do longleverage"
        );

        require(
            rateMode == 1 || rateMode == 2,
            "CHFRY: rateMode should be 1 or 2"
        );

        (bool success, ) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("ERC20").delegatecall(
                abi.encodeWithSignature(
                    "push(address,uint256)",
                    leverageToken,
                    amountLeverageToken
                )
            );

        require(success == true, "CHFRY: push coin fail");

        uint8 operation;
        bytes memory arguments;
        bytes memory data;

        operation = 1;

        arguments = abi.encode(
            leverageToken,
            targetToken,
            amountLeverageToken,
            amountFlashLoan,
            unitAmt,
            rateMode
        );

        data = abi.encode(operation, arguments);
        _flash(leverageToken, amountFlashLoan, data);
    }

    function closeLong(
        address leverageToken,
        address targetToken,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) public payable onlyAuth{
        require(
            rateMode == 1 || rateMode == 2,
            "CHFRY: rateMode should be 1 or 2"
        );

        bool isLastPosition = true;

        bool success;
        bytes memory _data;
        Token[] memory tokenList = TokenCenterInterface(
            OperationCenterInterface(opCenterAddress).tokenCenterAddress()
        ).listLongToken();

        for (uint256 i = 0; i < tokenList.length; i++) {
            if (
                tokenList[i].token != targetToken &&
                tokenList[i].token != address(0)
            ) {
                (success, _data) = ProtocolCenterInterface(
                    OperationCenterInterface(opCenterAddress)
                        .protocolCenterAddress()
                ).getProtocol("AAVEV2").delegatecall(
                        abi.encodeWithSignature(
                            "getCollateralBalance(address)",
                            tokenList[i].token
                        )
                    );

                require(
                    success == true,
                    "CHFRY: call AAVEV2 protocol getCollateralBalance fail 2"
                );
                if (abi.decode(_data, (uint256)) != 0) {
                    isLastPosition = false;
                    break;
                }
            }
        }

        (success, _data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "getPaybackBalance(address,uint256)",
                    leverageToken,
                    2
                )
            );

        require(
            success == true,
            "CHFRY: call AAVEV2 protocol getPaybackBalance fail"
        );

        uint256 amountLeverageTokenBorrow = abi.decode(_data, (uint256));

        if (
            isLastPosition == true ||
            (amountFlashLoan > amountLeverageTokenBorrow)
        ) {
            amountFlashLoan = amountLeverageTokenBorrow;
        }

        uint8 operation;
        bytes memory arguments;
        bytes memory data;

        operation = 2;

        arguments = abi.encode(
            leverageToken,
            targetToken,
            amountTargetToken,
            amountFlashLoan,
            isLastPosition,
            unitAmt,
            rateMode
        );

        data = abi.encode(operation, arguments);
        _flash(leverageToken, amountFlashLoan, data);
    }

    function cleanLong(
        address leverageToken,
        address targetToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) public payable onlyAuth {

        (bool success, bytes memory _data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "getCollateralBalance(address)",
                    targetToken
                )
            );

        require(
            success == true,
            "CHFRY: call AAVEV2 protocol getCollateralBalance fail 1"
        );

        uint256 amountTargetToken = abi.decode(_data, (uint256));

        closeLong(
            leverageToken,
            targetToken,
            amountTargetToken,
            amountFlashLoan,
            unitAmt,
            rateMode
        );
    }

    function repay(address paybackToken) external payable onlyAuth {
        bool success;
        bytes memory data;
        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "getPaybackBalance(address,uint256)",
                    paybackToken,
                    2
                )
            );

        require(
            success == true,
            "CHFRY: call AAVEV2 protocol getPaybackBalance fail"
        );

        uint256 amountPaybackToken = abi.decode(data, (uint256));

        if (amountPaybackToken > 0) {
            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("ERC20").delegatecall(
                    abi.encodeWithSignature(
                        "push(address,uint256)",
                        paybackToken,
                        amountPaybackToken
                    )
                );

            require(success == true, "CHFRY: push token fail");

            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("AAVEV2").delegatecall(
                    abi.encodeWithSignature(
                        "paybackToken(address,uint256,uint256)",
                        paybackToken,
                        amountPaybackToken,
                        2
                    )
                );
            require(success == true, "CHFRY: call AAVEV2 paybackToken fail");
            EventCenterLeveragePositionInterface(
                OperationCenterInterface(opCenterAddress).eventCenterAddress()
            ).emitRepayEvent(paybackToken, amountPaybackToken);
        }
    }

    function withdraw(address collateralToken) external payable onlyAuth{
        bool success;
        bytes memory data;

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "getCollateralBalance(address)",
                    collateralToken
                )
            );

        require(
            success == true,
            "CHFRY: call AAVEV2 protocol getCollateralBalance of leverageToken fail "
        );

        if (abi.decode(data, (uint256)) > 0) {
            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("AAVEV2").delegatecall(
                    abi.encodeWithSignature(
                        "withdrawToken(address,uint256)",
                        collateralToken,
                        type(uint256).max
                    )
                );
            require(success == true, "CHFRY: call AAVEV2 withdrawToken fail 2");

            uint256 amountWithDraw = abi.decode(data, (uint256));

            address EOA = AccountCenterInterface(accountCenter).getEOA(
                address(this)
            );

            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("ERC20").delegatecall(
                    abi.encodeWithSignature(
                        "pull(address,uint256,address)",
                        collateralToken,
                        amountWithDraw,
                        EOA
                    )
                );

            require(success == true, "CHFRY: pull back coin fail");
            EventCenterLeveragePositionInterface(
                OperationCenterInterface(opCenterAddress).eventCenterAddress()
            ).emitWithDrawEvent(collateralToken, amountWithDraw);
        }
    }

    function addMargin(address collateralToken, uint256 amountCollateralToken)
        external
        payable
        onlyAuth
    {

        (bool success, bytes memory data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("ERC20").delegatecall(
                abi.encodeWithSignature(
                    "push(address,uint256)",
                    collateralToken,
                    amountCollateralToken
                )
            );

        require(success == true, "CHFRY: push token fail");

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "depositToken(address,uint256)",
                    collateralToken,
                    amountCollateralToken
                )
            );

        require(
            success == true,
            "CHFRY: call AAVEV2 protocol depositToken fail"
        );

        EventCenterInterface(
            OperationCenterInterface(opCenterAddress).eventCenterAddress()
        ).emitAddMarginEvent(collateralToken, amountCollateralToken);
    }

    function _flash(
        address token,
        uint256 amount,
        bytes memory data
    ) internal {

        uint256 allowance = IERC20(token).allowance(
            address(this),
            address(lender)
        );
        
        uint256 fee = IERC3156FlashLender(lender).flashFee(token, amount);

        (bool notOverflow, uint256 repayment) = SafeMath.tryAdd(amount, fee);
        require(notOverflow == true, "CHFRY: overflow");

        (notOverflow, allowance) = SafeMath.tryAdd(allowance, repayment);
        require(notOverflow == true, "CHFRY: overflow");

        IERC20(token).approve(address(lender), allowance);

        IERC3156FlashLender(lender).flashLoan(
            address(this),
            token,
            amount,
            data
        );
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external payable returns (bytes32) {
        require(msg.sender == address(lender), "onFlashLoan: Untrusted lender");

        require(
            initiator == address(this),
            "onFlashLoan: Untrusted loan initiator"
        );

        uint8 operation;
        bytes memory arguments;

        flashInitiator = initiator;
        flashToken = token;
        flashAmount = amount;
        flashFee = fee;

        (operation, arguments) = abi.decode(data, (uint8, bytes));

        if (operation == uint8(1)) {
            handleOpenLong(arguments);
        } else if (operation == uint8(2)) {
            handleCloseLong(arguments);
        }

        EventCenterLeveragePositionInterface(
            OperationCenterInterface(opCenterAddress).eventCenterAddress()
        ).emitUseFlashLoanForLeverageEvent(token, amount);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function handleOpenLong(bytes memory arguments) internal {
        bool notOverflow;
        uint256 _temp;
        uint256 pay;

        bool success;
        bytes memory data;

        (
            address leverageToken,
            address targetToken,
            uint256 amountLeverageToken,
            uint256 amountFlashLoan,
            uint256 unitAmt,
            uint256 rateMode
        ) = abi.decode(
                arguments,
                (address, address, uint256, uint256, uint256, uint256)
            );

        (notOverflow, pay) = SafeMath.tryAdd(
            amountLeverageToken,
            amountFlashLoan
        );

        require(notOverflow == true, "CHFRY: overflow 1");

        uint256 flashLoanFee = IERC3156FlashLender(lender).flashFee(
            leverageToken,
            amountFlashLoan
        );

        (notOverflow, _temp) = SafeMath.trySub(pay, flashLoanFee);

        require(notOverflow == true, "CHFRY: overflow 2");

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("UniswapV2").delegatecall(
                abi.encodeWithSignature(
                    "sellToken(address,address,uint256,uint256)",
                    targetToken,
                    leverageToken,
                    _temp,
                    unitAmt
                )
            );

        require(success == true, "CHFRY: call UniswapV2 sellToken fail");

        uint256 buyAmount = abi.decode(data, (uint256));

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "depositToken(address,uint256)",
                    targetToken,
                    buyAmount
                )
            );

        require(success == true, "CHFRY: call AAVEV2 depositToken fail");

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "borrowToken(address,uint256,uint256)",
                    leverageToken,
                    amountFlashLoan,
                    rateMode
                )
            );
        require(success == true, "CHFRY: call AAVEV2 borrowToken fail");

        EventCenterLeveragePositionInterface(
            OperationCenterInterface(opCenterAddress).eventCenterAddress()
        ).emitOpenLongLeverageEvent(
                leverageToken,
                targetToken,
                pay,
                buyAmount,
                amountLeverageToken,
                amountFlashLoan,
                unitAmt,
                rateMode
            );
    }

    function handleCloseLong(bytes memory arguments) internal {
        uint256 _temp;
        uint256 gain;
        bool notOverflow;
        bool success;
        bytes memory data;
        (
            address leverageToken,
            address targetToken,
            uint256 amountTargetToken,
            uint256 amountFlashLoan,
            bool isLastPosition,
            uint256 unitAmt,
            uint256 rateMode
        ) = abi.decode(
                arguments,
                (address, address, uint256, uint256, bool, uint256, uint256)
            );

        uint256 flashLoanFee = IERC3156FlashLender(lender).flashFee(
            leverageToken,
            amountFlashLoan
        );

        if (amountFlashLoan > 0) {
            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("AAVEV2").delegatecall(
                    abi.encodeWithSignature(
                        "paybackToken(address,uint256,uint256)",
                        leverageToken,
                        amountFlashLoan,
                        rateMode
                    )
                );
            require(success == true, "CHFRY: call AAVEV2 paybackToken fail");
        }

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "withdrawToken(address,uint256)",
                    targetToken,
                    amountTargetToken
                )
            );

        require(success == true, "CHFRY: call AAVEV2 withdrawToken fail 1");

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("UniswapV2").delegatecall(
                abi.encodeWithSignature(
                    "sellToken(address,address,uint256,uint256)",
                    leverageToken,
                    targetToken,
                    amountTargetToken,
                    unitAmt
                )
            );

        require(success == true, "CHFRY: call UniswapV2 protocol fail");

        gain = abi.decode(data, (uint256));

        (notOverflow, gain) = SafeMath.trySub(gain, flashLoanFee);

        require(notOverflow == true, "CHFRY: gain not cover flashLoanFee");

        if (isLastPosition == true) {
            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("AAVEV2").delegatecall(
                    abi.encodeWithSignature(
                        "getCollateralBalance(address)",
                        leverageToken
                    )
                );

            require(
                success == true,
                "CHFRY: call AAVEV2 protocol getCollateralBalance of leverageToken fail "
            );

            if (abi.decode(data, (uint256)) > 0) {
                (success, data) = ProtocolCenterInterface(
                    OperationCenterInterface(opCenterAddress)
                        .protocolCenterAddress()
                ).getProtocol("AAVEV2").delegatecall(
                        abi.encodeWithSignature(
                            "withdrawToken(address,uint256)",
                            leverageToken,
                            type(uint256).max
                        )
                    );
                require(
                    success == true,
                    "CHFRY: call AAVEV2 withdrawToken fail 2"
                );

                uint256 amountWithDraw = abi.decode(data, (uint256));

                EventCenterLeveragePositionInterface(
                    OperationCenterInterface(opCenterAddress)
                        .eventCenterAddress()
                ).emitRemoveMarginEvent(leverageToken, amountWithDraw);

                (notOverflow, _temp) = SafeMath.tryAdd(gain, amountWithDraw);
                require(notOverflow == true, "CHFRY: overflow");

                (notOverflow, _temp) = SafeMath.trySub(_temp, amountFlashLoan);

                require(notOverflow == true, "CHFRY: gain not cover flashloan");
            } else {
                (notOverflow, _temp) = SafeMath.trySub(gain, amountFlashLoan);
                require(notOverflow == true, "CHFRY: gain not cover flashloan");
            }
        } else {
            (notOverflow, _temp) = SafeMath.trySub(gain, amountFlashLoan);
            require(notOverflow == true, "CHFRY: gain not cover flashloan");
        }

        if (_temp > uint256(0)) {
            address EOA = AccountCenterInterface(accountCenter).getEOA(
                address(this)
            );

            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("ERC20").delegatecall(
                    abi.encodeWithSignature(
                        "pull(address,uint256,address)",
                        leverageToken,
                        _temp,
                        EOA
                    )
                );

            require(success == true, "CHFRY: pull back coin fail");
        }

        EventCenterLeveragePositionInterface(
            OperationCenterInterface(opCenterAddress).eventCenterAddress()
        ).emitCloseLongLeverageEvent(
                leverageToken,
                targetToken,
                gain,
                amountTargetToken,
                amountFlashLoan,
                amountFlashLoan,
                unitAmt,
                rateMode
            );
    }

    function getUserAccountData()
        internal
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());
        (
            totalCollateralETH,
            totalDebtETH,
            availableBorrowsETH,
            currentLiquidationThreshold,
            ltv,
            healthFactor
        ) = aave.getUserAccountData(address(this));
    }
}

interface AaveLendingPoolProviderInterface {
    function getLendingPool() external view returns (address);

    function getPriceOracle() external view returns (address);
}

interface AaveInterface {
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function setUserUseReserveAsCollateral(
        address _asset,
        bool _useAsCollateral
    ) external;

    function swapBorrowRateMode(address _asset, uint256 _rateMode) external;
}
