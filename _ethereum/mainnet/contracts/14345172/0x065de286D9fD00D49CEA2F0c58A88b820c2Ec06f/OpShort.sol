// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OpCommon.sol";
import "./IProtocolAaveV2.sol";
import "./IProtocolERC20.sol";
import "./IOperationCenter.sol";
import "./IEventCenterLeveragePosition.sol";
import "./IAccountCenter.sol";
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
    function listShortToken() external view returns (Token[] memory tokenList);
    function isShortable(address token) external view returns (bool longable);
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

contract OpShort is OpCommon {
    using SafeERC20 for IERC20;

    address internal constant ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable lender;
    address public immutable opCenterAddress;

    uint256 public flashBalance;
    address public flashInitiator;
    address public flashToken;
    uint256 public flashAmount;
    uint256 public flashFee;

    constructor(address _opCenterAddress, address _lender) {
        lender = _lender;
        opCenterAddress = _opCenterAddress;
    }

    function openShort(
        address leverageToken,
        address targetToken,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) public payable onlyAuth {

        bool _isShortable = TokenCenterInterface(
            OperationCenterInterface(opCenterAddress).tokenCenterAddress()
        )
        .isShortable(targetToken);
        require(_isShortable,"CHFY: target token not support to do short leverage");

        require(
            rateMode == 1 || rateMode == 2,
            "CHFRY: rateMode should be 1 or 2"
        );

        uint8 operation;
        bytes memory arguments;
        bytes memory data;

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

        operation = 3;

        arguments = abi.encode(
            leverageToken,
            targetToken,
            amountTargetToken,
            amountLeverageToken,
            amountFlashLoan,
            unitAmt,
            rateMode
        );

        data = abi.encode(operation, arguments);
        _flash(leverageToken, amountFlashLoan, data);
    }

    function closeShort(
        address leverageToken,
        address targetToken,
        uint256 amountTargetToken,
        uint256 amountWithdraw,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) public payable onlyAuth {

        require(
            rateMode == 1 || rateMode == 2,
            "CHFRY: rateMode should be 1 or 2"
        );

        uint8 operation;
        bytes memory arguments;
        bytes memory data;

        operation = 4;

        arguments = abi.encode(
            leverageToken,
            targetToken,
            amountTargetToken,
            amountWithdraw,
            amountFlashLoan,
            unitAmt,
            rateMode
        );

        data = abi.encode(operation, arguments);
        _flash(leverageToken, amountFlashLoan, data);
    }

    function cleanShort(
        address leverageToken,
        address targetToken,
        uint256 amountWithdraw,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) public payable onlyAuth {

        (bool success, bytes memory _data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "getPaybackBalance(address,uint256)",
                    targetToken,
                    rateMode
                )
            );

        require(
            success == true,
            "CHFRY: call AAVEV2 protocol getPaybackBalance fail"
        );

        uint256 amountTargetToken = abi.decode(_data, (uint256));

        closeShort(
            leverageToken,
            targetToken,
            amountTargetToken,
            amountWithdraw,
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
            "CHFRY: call AAVEV2 protocol getCollateralBalance fail"
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

        if (operation == uint8(3)) {
            handleOpenShort(arguments);
        } else if (operation == uint8(4)) {
            handleCloseShort(arguments);
        }

        EventCenterLeveragePositionInterface(
            OperationCenterInterface(opCenterAddress).eventCenterAddress()
        ).emitUseFlashLoanForLeverageEvent(token, amount);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function handleOpenShort(bytes memory arguments) internal {
        bool notOverflow;
        uint256 _temp;
        uint256 pay;
        bool success;
        bytes memory data;
        uint256 amountDeposite;
        (
            address leverageToken,
            address targetToken,
            uint256 amountTargetToken,
            uint256 amountLeverageToken,
            uint256 amountFlashLoan,
            uint256 unitAmt,
            uint256 rateMode
        ) = abi.decode(
                arguments,
                (address, address, uint256, uint256, uint256, uint256, uint256)
            );

        (notOverflow, _temp) = SafeMath.tryAdd(
            amountLeverageToken,
            amountFlashLoan
        );
        require(notOverflow == true, "CHFRY: overflow 1");

        uint256 flashLoanFee = IERC3156FlashLender(lender).flashFee(
            leverageToken,
            amountFlashLoan
        );

        (notOverflow, _temp) = SafeMath.trySub(_temp, flashLoanFee);

        require(notOverflow == true, "CHFRY: overflow 2");
        amountDeposite = _temp;
        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "depositToken(address,uint256)",
                    leverageToken,
                    _temp
                )
            );
        require(
            success == true,
            "CHFRY: call AAVEV2 protocol depositToken fail"
        );

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "borrowToken(address,uint256,uint256)",
                    targetToken,
                    amountTargetToken,
                    rateMode
                )
            );

        require(
            success == true,
            "CHFRY: call AAVEV2 protocol handleOpenShort borrowToken fail"
        );

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

        require(
            success == true,
            "CHFRY: call UniswapV2 protocol fail sellToken"
        );

        pay = abi.decode(data, (uint256));

        (notOverflow, _temp) = SafeMath.trySub(pay, amountFlashLoan);

        require(notOverflow == true, "CHFRY: swap reault not cover FlashLoan");

        if (_temp > uint256(0)) {
            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("ERC20").delegatecall(
                    abi.encodeWithSignature(
                        "pull(address,uint256,address)",
                        leverageToken,
                        _temp,
                        AccountCenterInterface(accountCenter).getEOA(
                            address(this)
                        )
                    )
                );
            require(success == true, "CHFRY: pull back coin fail");
        }

        (notOverflow, pay) = SafeMath.tryAdd(pay, flashLoanFee);

        require(notOverflow == true, "CHFRY: overflow 4");

        EventCenterLeveragePositionInterface(
            OperationCenterInterface(opCenterAddress).eventCenterAddress()
        ).emitOpenShortLeverageEvent(
                leverageToken,
                targetToken,
                pay,
                amountTargetToken,
                amountDeposite,
                amountFlashLoan,
                unitAmt,
                rateMode
            );
    }

    function handleCloseShort(bytes memory arguments) internal {
        bool notOverflow;
        uint256 _temp;
        uint256 gain;
        bool success;
        bytes memory data;
        (
            address leverageToken,
            address targetToken,
            uint256 amountTargetToken,
            uint256 amountWithdraw,
            uint256 amountFlashLoan,
            uint256 unitAmt,
            uint256 rateMode
        ) = abi.decode(
                arguments,
                (address, address, uint256, uint256, uint256, uint256, uint256)
            );

        uint256 flashLoanFee = IERC3156FlashLender(lender).flashFee(
            leverageToken,
            amountFlashLoan
        );

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("UniswapV2").delegatecall(
                abi.encodeWithSignature(
                    "buyToken(address,address,uint256,uint256)",
                    targetToken,
                    leverageToken,
                    amountTargetToken,
                    unitAmt
                )
            );

        require(
            success == true,
            "CHFRY: call UniswapV2 handleCloseShort buyToken fail"
        );

        uint256 sellAmount = abi.decode(data, (uint256));

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "paybackToken(address,uint256,uint256)",
                    targetToken,
                    amountTargetToken,
                    rateMode
                )
            );

        require(success == true, "CHFRY: call AAVEV2 paybackToken fail");

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "withdrawToken(address,uint256)",
                    leverageToken,
                    amountWithdraw
                )
            );

        require(success == true, "CHFRY: call AAVEV2 withdrawToken() fail");

        (notOverflow, _temp) = SafeMath.trySub(amountWithdraw, flashLoanFee);

        require(notOverflow == true, "CHFRY: overflow 1");

        gain = _temp;

        (notOverflow, _temp) = SafeMath.trySub(_temp, sellAmount);

        require(notOverflow == true, "CHFRY: overflow 2");

        if (_temp > uint256(0)) {
            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("ERC20").delegatecall(
                    abi.encodeWithSignature(
                        "pull(address,uint256,address)",
                        leverageToken,
                        _temp,
                        AccountCenterInterface(accountCenter).getEOA(
                            address(this)
                        )
                    )
                );

            require(success == true, "CHFRY: pull back coin fail");
        }

        EventCenterLeveragePositionInterface(
            OperationCenterInterface(opCenterAddress).eventCenterAddress()
        ).emitCloseShortLeverageEvent(
                leverageToken,
                targetToken,
                gain,
                amountTargetToken,
                amountFlashLoan,
                amountWithdraw,
                unitAmt,
                rateMode
            );
    }
}
