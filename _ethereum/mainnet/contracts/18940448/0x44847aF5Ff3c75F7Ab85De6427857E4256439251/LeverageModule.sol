// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSA.sol";
import "./UUPSUpgradeable.sol";
import "./ModuleBase.sol";
import "./IOwnable.sol";
import "./SafeERC20.sol";
import "./IERC20Metadata.sol";

import "./Invoke.sol";
import "./ILeverageFacet.sol";
import "./ILendFacet.sol";
import "./ILeverageModule.sol";
import "./IPriceOracle.sol";

contract LeverageModule is
    ModuleBase,
    ILeverageModule,
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    using Invoke for IVault;
    using SafeERC20 for IERC20;
    modifier onlyOwner() {
        require(
            msg.sender == IOwnable(diamond).owner(),
            "TradeModule:only owner"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _diamond) public initializer {
        __UUPSUpgradeable_init();
        diamond = _diamond;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function verifyPutOrder(
        ILeverageFacet.LeveragePutOrder memory _order,
        ILeverageFacet.LeveragePutLenderData calldata _lenderData,
        ILeverageFacet.FeeData memory _feeData,
        bytes calldata _borrowerSignature,
        bytes calldata _lenderSignature
    ) internal view {
        IVaultFacet vaultFacet = IVaultFacet(diamond);
        require(
            !vaultFacet.getVaultLock(_order.borrower),
            "LeverageModule:borrower is locked"
        );
        require(
            !vaultFacet.getVaultLock(_order.lender),
            "LeverageModule:lender is locked"
        );
        require(
            vaultFacet.getVaultType(_order.borrower) == 9,
            "LeverageModule:borrower vaultType 9"
        );
        require(
            vaultFacet.getVaultType(_order.lender) == 8,
            "LeverageModule:lender vaultType 8"
        );
        require(
            _order.recipient != address(0) &&
                _order.recipient != _order.borrower,
            "LeverageModule:recipient error"
        );
        require(
            _order.lender != _order.borrower,
            "LeverageModule:lender error"
        );
        require(
            _order.expirationDate > block.timestamp,
            "LeverageModule:invalid expirationDate"
        );
        require(
            _order.startDate < block.timestamp,
            "LeverageModule:invalid startDate"
        );
        IPlatformFacet platformFacet = IPlatformFacet(diamond);

        address eth = platformFacet.getEth();
        //verify collateralAsset
        if (_order.collateralAsset == eth) {
            require(
                _order.borrower.balance >= _order.collateralAmount,
                "LeverageModule:borrower collateralAsset not enough"
            );
            require(
                _order.lender.balance >= _order.lockedCollateralAmount,
                "LeverageModule:lender collateralAsset lockedCollateralAmount not enough"
            );
        } else {
            require(
                IERC20(_order.collateralAsset).balanceOf(_order.borrower) >=
                    _order.collateralAmount,
                "LeverageModule:borrower collateralAsset not enough"
            );
            require(
                IERC20(_order.collateralAsset).balanceOf(_order.lender) >=
                    _order.lockedCollateralAmount,
                "LeverageModule:lender collateralAsset lockedCollateralAmount not enough"
            );
        }
        require(
            _lenderData.maxCollateraAmount >= _order.collateralAmount,
            "LeverageModule:collateralAmount exceeds the maximum collateral amount"
        );
        require(
            _lenderData.minCollateraAmount <= _order.collateralAmount,
            "LeverageModule:collateralAmount below the minimum collateral amount"
        );
        //verify borrowAsset
        if (_order.borrowAsset == eth) {
            require(
                _order.lender.balance >= _order.borrowAmount,
                "LeverageModule:lender borrowAsset not enough"
            );
        } else {
            require(
                IERC20(_order.borrowAsset).balanceOf(_order.lender) >=
                    _order.borrowAmount,
                "LeverageModule:lender borrowAsset not enough"
            );
        }
        ILeverageFacet leverageFacet = ILeverageFacet(diamond);
        require(
            leverageFacet.getLeverageOrderByOrderId(_order.orderId).orderId ==
                0,
            "LeverageModule:orderId repeated"
        );
        require(
            !leverageFacet.getBorrowSignature(_borrowerSignature),
            "LeverageModule:_borrowerSignature repeated"
        );

        require(
            _order.borrowAsset == _lenderData.borrowAsset &&
                _order.collateralAsset == _lenderData.collateralAsset &&
                _order.expirationDate == _lenderData.expirationDate &&
                _order.startDate == _lenderData.startDate &&
                _order.pledgeCount == _lenderData.pledgeCount &&
                _order.ltv == _lenderData.ltv &&
                _order.interest == _lenderData.interest &&
                _order.platformFeeRate == _lenderData.platformFeeRate &&
                _order.tradeFeeRate == _lenderData.tradeFeeRate,
            "LeverageModule:data not same"
        );

        vaildBorrowerSign(_order.borrower, _order, _borrowerSignature);
        vaildLenderSign(_order.lender, _lenderData, _lenderSignature);

        validSlippage(
            _order.lockedCollateralAmount,
            _feeData.lockedCollateralAmount,
            _order.slippage,
            _lenderData.slippage
        );
        validSlippage(
            _order.borrowAmount,
            _feeData.borrowAmount,
            _order.slippage,
            _lenderData.slippage
        );
        validSlippage(
            _order.debtAmount,
            _feeData.debtAmount,
            _order.slippage,
            _lenderData.slippage
        );
    }

    function getFee(
        uint input,
        uint ltv,
        uint interestRate,
        uint tradeRate,
        uint price,
        uint decimalA,
        uint decimalB
    ) public pure returns (uint, uint, uint) {
        uint usdcAmount = (input * price * 10 ** decimalB) /
            1 ether /
            10 ** decimalA;
        uint debtAmount = (usdcAmount * ltv) / 1 ether;
        uint interest = (debtAmount * interestRate) / 1 ether;
        uint tradeFee = (debtAmount * (1 ether - interestRate) * tradeRate) /
            1 ether /
            1 ether;
        return (debtAmount, interest, tradeFee);
    }

    function calculateFees(
        ILeverageFacet.LeveragePutOrder memory _order,
        uint price,
        uint priceRevert,
        IPlatformFacet platformFacet,
        address eth
    ) public view returns (ILeverageFacet.FeeData memory data) {
        uint decimalCollateralAsset = IERC20Metadata(
            _order.collateralAsset == eth
                ? platformFacet.getWeth()
                : _order.collateralAsset
        ).decimals();
        uint decimalBorrowAsset = IERC20Metadata(
            _order.borrowAsset == eth
                ? platformFacet.getWeth()
                : _order.borrowAsset
        ).decimals();
        data.collateralAmount = _order.collateralAmount;
        for (uint i = 0; i < _order.pledgeCount; i++) {
            (uint debtAmount, uint interest, uint tradeFee) = getFee(
                data.collateralAmount,
                _order.ltv,
                _order.interest,
                _order.tradeFeeRate,
                price,
                decimalCollateralAsset,
                decimalBorrowAsset
            );
            data.collateralAmount =
                ((debtAmount - interest - tradeFee) *
                    priceRevert *
                    10 ** decimalCollateralAsset) /
                1 ether /
                10 ** decimalBorrowAsset;
            data.interestAmount += interest;
            data.tradeFeeAmount += i < _order.pledgeCount - 1 ? tradeFee : 0;
            data.borrowAmount = debtAmount - interest;
            data.debtAmount += debtAmount;
            data.lockedCollateralAmount += i < _order.pledgeCount - 1
                ? data.collateralAmount
                : 0;
        }
        data.collateralAmount = _order.collateralAmount;
        return data;
    }

    function calculate(
        ILeverageFacet leverageFacet,
        ILeverageFacet.LeveragePutOrder memory _order,
        IPlatformFacet platformFacet,
        address eth
    ) public view returns (ILeverageFacet.FeeData memory) {
        uint256 price = IPriceOracle(leverageFacet.getPriceOracle()).getPrice(
            _order.collateralAsset == eth
                ? platformFacet.getWeth()
                : _order.collateralAsset,
            _order.borrowAsset == eth
                ? platformFacet.getWeth()
                : _order.borrowAsset
        );
        uint256 priceRevert = IPriceOracle(leverageFacet.getPriceOracle())
            .getPrice(
                _order.borrowAsset == eth
                    ? platformFacet.getWeth()
                    : _order.borrowAsset,
                _order.collateralAsset == eth
                    ? platformFacet.getWeth()
                    : _order.collateralAsset
            );

        return calculateFees(_order, price, priceRevert, platformFacet, eth);
    }

    function submitLeveragePutOrder(
        ILeverageFacet.LeveragePutOrder memory _leveragePutOrder,
        ILeverageFacet.LeveragePutLenderData calldata _lenderData,
        bytes calldata _borrowerSignature,
        bytes calldata _lenderSignature
    ) external nonReentrant onlyWhiteList {
        //verify data
        ILeverageFacet leverageFacet = ILeverageFacet(diamond);
        IPlatformFacet platformFacet = IPlatformFacet(diamond);
        address eth = platformFacet.getEth();
        ILeverageFacet.FeeData memory feeData = calculate(
            leverageFacet,
            _leveragePutOrder,
            platformFacet,
            eth
        );
        verifyPutOrder(
            _leveragePutOrder,
            _lenderData,
            feeData,
            _borrowerSignature,
            _lenderSignature
        );
        //storage data
        IVaultFacet vaultFacet = IVaultFacet(diamond);

        vaultFacet.setVaultLock(_leveragePutOrder.borrower, true);

        _leveragePutOrder.index = leverageFacet.getLeverageLenderPutOrderLength(
            _leveragePutOrder.lender
        );
        leverageFacet.setLeverageBorrowerPutOrder(
            _leveragePutOrder.borrower,
            _leveragePutOrder
        );
        leverageFacet.setLeverageLenderPutOrder(
            _leveragePutOrder.lender,
            _leveragePutOrder.borrower
        );

        if (_leveragePutOrder.borrowAsset == eth) {
            IVault(_leveragePutOrder.lender).invokeTransferEth(
                _leveragePutOrder.recipient,
                feeData.borrowAmount
            );
        } else {
            IVault(_leveragePutOrder.lender).invokeTransfer(
                _leveragePutOrder.borrowAsset,
                _leveragePutOrder.recipient,
                feeData.borrowAmount
            );
        }
        if (_leveragePutOrder.collateralAsset == eth) {
            IVault(_leveragePutOrder.lender).invokeTransferEth(
                _leveragePutOrder.borrower,
                feeData.lockedCollateralAmount
            );
        } else {
            IVault(_leveragePutOrder.lender).invokeTransfer(
                _leveragePutOrder.collateralAsset,
                _leveragePutOrder.borrower,
                feeData.lockedCollateralAmount
            );
        }
        leverageLendFee(_leveragePutOrder, feeData);
        leverageFacet.setLeverageFeeData(_leveragePutOrder.orderId, feeData);
        leverageFacet.setBorrowSignature(_borrowerSignature);
        leverageFacet.setLeverageOrderByOrderId(
            _leveragePutOrder.orderId,
            _leveragePutOrder
        );
        updatePosition(
            _leveragePutOrder.borrower,
            _leveragePutOrder.collateralAsset,
            0
        );
        updatePosition(
            _leveragePutOrder.borrower,
            _leveragePutOrder.borrowAsset,
            0
        );
        updatePosition(
            _leveragePutOrder.lender,
            _leveragePutOrder.collateralAsset,
            0
        );
        updatePosition(
            _leveragePutOrder.lender,
            _leveragePutOrder.borrowAsset,
            0
        );
        //set CurrentVaultModule
        setFuncBlackAndWhiteList(
            _leveragePutOrder.lender,
            _leveragePutOrder.borrower,
            true
        );
        emit SubmitLeveragePutOrder(msg.sender, _leveragePutOrder, feeData);
    }

    function vaildBorrowerSign(
        address _signer,
        ILeverageFacet.LeveragePutOrder memory _data,
        bytes memory _signature
    ) public view {
        bytes32 infoTypeHash = keccak256(
            "LeveragePutOrder(uint256 orderId,uint256 startDate,uint256 expirationDate,address lender,address borrower,address recipient,address collateralAsset,uint256 collateralAmount,address borrowAsset,uint256 borrowAmount,uint256 lockedCollateralAmount,uint256 debtAmount,uint256 pledgeCount,uint256 slippage,uint256 ltv,uint256 platformFeeAmount,uint256 tradeFeeAmount,uint256 loanFeeAmount,uint256 platformFeeRate,uint256 tradeFeeRate,uint256 interest,uint256 index)"
        );
        bytes32 _hashInfo = keccak256(abi.encode(infoTypeHash, _data));
        verifySignature(_signer, _hashInfo, _signature);
    }

    function vaildLenderSign(
        address _signer,
        ILeverageFacet.LeveragePutLenderData calldata _data,
        bytes memory _signature
    ) public view {
        bytes32 infoTypeHash = keccak256(
            "LeveragePutLenderData(address lender,address collateralAsset,address borrowAsset,uint256 minCollateraAmount,uint256 maxCollateraAmount,uint256 ltv,uint256 interest,uint256 slippage,uint256 pledgeCount,uint256 startDate,uint256 expirationDate,uint256 platformFeeRate,uint256 tradeFeeRate)"
        );
        bytes32 _hashInfo = keccak256(abi.encode(infoTypeHash, _data));
        verifySignature(_signer, _hashInfo, _signature);
    }

    function verifySignature(
        address _signer,
        bytes32 _hash,
        bytes memory _signature
    ) public view {
        bytes32 domainHash = ILendFacet(diamond).getDomainHash();
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainHash, _hash)
        );
        address signer = IVault(_signer).owner();
        address recoverAddress = ECDSA.recover(digest, _signature);
        require(recoverAddress == signer, "LeverageModule:signature error");
    }

    function validSlippage(
        uint amountA,
        uint amountB,
        uint borrrowSlippage,
        uint lenderSlippage
    ) public pure returns (bool) {
        uint slippage = borrrowSlippage < lenderSlippage
            ? borrrowSlippage
            : lenderSlippage;
        require(
            amountA <= (amountB * (1 ether + slippage)) / 1 ether,
            "LeverageModule: amountA < amountB"
        );
        require(
            amountA >= (amountB * (1 ether - slippage)) / 1 ether,
            "LeverageModule: amountA > amountB"
        );
        return true;
    }

    /*
    liquidate
    -debtor  borrow
    _type=true:liqudate collateralAsset
    _type=false:liqudate borrowAsset
    -loaner lender 
    liqudate collateralAsset
    */
    function liquidateLeveragePutOrder(
        address _borrower,
        uint256 _type
    ) external payable nonReentrant {
        uint256 liquidateAmount;
        uint256 tradeFee;
        ILeverageFacet leverageFacet = ILeverageFacet(diamond);
        IVaultFacet vaultFacet = IVaultFacet(diamond);
        ILeverageFacet.LeveragePutOrder
            memory _leveragePutOrder = ILeverageFacet(diamond)
                .getLeverageBorrowerPutOrder(_borrower);
        require(
            _leveragePutOrder.borrower != address(0),
            "LeverageModule:putOrder not exist"
        );
        leverageFacet.deleteLeverageBorrowerPutOrder(
            _leveragePutOrder.borrower
        );
        vaultFacet.setVaultLock(_leveragePutOrder.borrower, false);

        address eth = IPlatformFacet(diamond).getEth();
        address owner = IVault(_leveragePutOrder.borrower).owner();
        ILeverageFacet.FeeData memory feeData = ILeverageFacet(diamond)
            .getLeverageFeeData(_leveragePutOrder.orderId);
        if (
            owner == msg.sender ||
            (IPlatformFacet(diamond).getIsVault(msg.sender) &&
                IOwnable(msg.sender).owner() == owner)
        ) {
            // give up collateral
            if (_type == 1) {
                if (_leveragePutOrder.collateralAsset == eth) {
                    IVault(_leveragePutOrder.borrower).invokeTransferEth(
                        _leveragePutOrder.lender,
                        _leveragePutOrder.collateralAmount +
                            feeData.lockedCollateralAmount
                    );
                    liquidateAmount =
                        _leveragePutOrder.collateralAmount +
                        feeData.lockedCollateralAmount;
                } else {
                    //transfer token
                    // IVault(_leveragePutOrder.debtor).invokeTransfer(_leveragePutOrder.collateralAsset,_leveragePutOrder.loaner,_leveragePutOrder.collateralAmount);
                    uint256 balance = IERC20(_leveragePutOrder.collateralAsset)
                        .balanceOf(_leveragePutOrder.borrower);
                    require(
                        balance >=
                            _leveragePutOrder.collateralAmount +
                                feeData.lockedCollateralAmount,
                        "LeverageModule:balance error"
                    );
                    liquidateAmount = balance;
                    IVault(_leveragePutOrder.borrower).invokeTransfer(
                        _leveragePutOrder.collateralAsset,
                        _leveragePutOrder.lender,
                        liquidateAmount
                    );
                }
                updatePosition(
                    _leveragePutOrder.lender,
                    _leveragePutOrder.collateralAsset,
                    0
                );
                // pay all debtAmount
            } else if (_type == 2) {
                liquidateAmount = feeData.debtAmount;
                if (_leveragePutOrder.borrowAsset == eth) {
                    require(
                        msg.value >= liquidateAmount,
                        "LeverageModule: msg.vaule not enough"
                    );
                    _leveragePutOrder.lender.call{value: liquidateAmount};
                } else {
                    IERC20(_leveragePutOrder.borrowAsset).safeTransferFrom(
                        _leveragePutOrder.recipient,
                        _leveragePutOrder.lender,
                        liquidateAmount
                    );
                }
                updatePosition(
                    _leveragePutOrder.lender,
                    _leveragePutOrder.borrowAsset,
                    0
                );
            } else if (_type == 3) {
                // Revolving repay
                uint liquidatePrice;
                (
                    liquidateAmount,
                    tradeFee,
                    liquidatePrice
                ) = getliquidateAmount(
                    feeData,
                    _leveragePutOrder,
                    leverageFacet,
                    eth
                );
                handleRepayTransfer(
                    _leveragePutOrder,
                    liquidateAmount,
                    tradeFee,
                    eth
                );
                updatePosition(
                    _leveragePutOrder.lender,
                    _leveragePutOrder.collateralAsset,
                    0
                );
            }
        } else {
            require(
                _leveragePutOrder.expirationDate < block.timestamp,
                "LeverageModule:not expirationDate"
            );
            if (_leveragePutOrder.collateralAsset == eth) {
                liquidateAmount =
                    _leveragePutOrder.collateralAmount +
                    feeData.lockedCollateralAmount;
                IVault(_leveragePutOrder.borrower).invokeTransferEth(
                    _leveragePutOrder.lender,
                    liquidateAmount
                );
            } else {
                //transfer token
                // IVault(_leveragePutOrder.debtor).invokeTransfer(_leveragePutOrder.collateralAsset,_leveragePutOrder.loaner,_leveragePutOrder.collateralAmount);
                uint256 balance = IERC20(_leveragePutOrder.collateralAsset)
                    .balanceOf(_leveragePutOrder.borrower);
                require(
                    balance >=
                        _leveragePutOrder.collateralAmount +
                            feeData.lockedCollateralAmount,
                    "LeverageModule:balance error"
                );
                liquidateAmount = balance;
                IVault(_leveragePutOrder.borrower).invokeTransfer(
                    _leveragePutOrder.collateralAsset,
                    _leveragePutOrder.lender,
                    liquidateAmount
                );
            }
            updatePosition(
                _leveragePutOrder.lender,
                _leveragePutOrder.collateralAsset,
                0
            );
        }

        leverageFacet.deleteLeverageLenderPutOrder(
            _leveragePutOrder.lender,
            _leveragePutOrder.index
        );
        setFuncBlackAndWhiteList(
            _leveragePutOrder.lender,
            _leveragePutOrder.borrower,
            false
        );
        leverageFacet.deleteLeverageFeeData(_leveragePutOrder.orderId);

        emit LiquidateLeveragePutOrder(
            msg.sender,
            _leveragePutOrder,
            _borrower,
            _type,
            liquidateAmount,
            tradeFee
        );
    }

    function handleRepayTransfer(
        ILeverageFacet.LeveragePutOrder memory _leveragePutOrder,
        uint liquidateAmount,
        uint tradeFee,
        address eth
    ) internal {
        address _lendFeePlatformRecipient = ILeverageFacet(diamond)
            .getleverageLendPlatformFeeRecipient();
        if (_leveragePutOrder.collateralAsset == eth) {
            if (tradeFee != 0 && _lendFeePlatformRecipient != address(0)) {
                IVault(_leveragePutOrder.borrower).invokeTransferEth(
                    _lendFeePlatformRecipient,
                    tradeFee
                );
            }
            IVault(_leveragePutOrder.borrower).invokeTransferEth(
                _leveragePutOrder.lender,
                liquidateAmount
            );
        } else {
            if (tradeFee != 0 && _lendFeePlatformRecipient != address(0)) {
                IVault(_leveragePutOrder.borrower).invokeTransfer(
                    _leveragePutOrder.collateralAsset,
                    _lendFeePlatformRecipient,
                    tradeFee
                );
            }
            IVault(_leveragePutOrder.borrower).invokeTransfer(
                _leveragePutOrder.collateralAsset,
                _leveragePutOrder.lender,
                liquidateAmount
            );
        }
    }

    function leverageLendFee(
        ILeverageFacet.LeveragePutOrder memory _leveragePutOrder,
        ILeverageFacet.FeeData memory feeData
    ) internal {
        address _lendFeePlatformRecipient = ILeverageFacet(diamond)
            .getleverageLendPlatformFeeRecipient();
        require(
            _lendFeePlatformRecipient != address(0),
            "LeverageModule:_lendFeePlatformRecipient is zero "
        );
        if (_leveragePutOrder.borrowAsset == IPlatformFacet(diamond).getEth()) {
            if (
                feeData.interestAmount != 0 &&
                _leveragePutOrder.platformFeeRate != 0
            ) {
                IVault(_leveragePutOrder.lender).invokeTransferEth(
                    _lendFeePlatformRecipient,
                    (feeData.interestAmount *
                        _leveragePutOrder.platformFeeRate) / 1 ether
                );
            }

            if (feeData.tradeFeeAmount != 0) {
                IVault(_leveragePutOrder.lender).invokeTransferEth(
                    _lendFeePlatformRecipient,
                    feeData.tradeFeeAmount
                );
            }
        } else {
            if (
                feeData.interestAmount != 0 &&
                _leveragePutOrder.platformFeeRate != 0
            ) {
                IVault(_leveragePutOrder.lender).invokeTransfer(
                    _leveragePutOrder.borrowAsset,
                    _lendFeePlatformRecipient,
                    (feeData.interestAmount *
                        _leveragePutOrder.platformFeeRate) / 1 ether
                );
            }

            if (feeData.tradeFeeAmount != 0) {
                IVault(_leveragePutOrder.lender).invokeTransfer(
                    _leveragePutOrder.borrowAsset,
                    _lendFeePlatformRecipient,
                    feeData.tradeFeeAmount
                );
            }
        }
    }

    function setFuncBlackAndWhiteList(
        address _blacker,
        address _whiter,
        bool _type
    ) internal {
        IVaultFacet vaultFacet = IVaultFacet(diamond);
        vaultFacet.setFuncBlackList(
            _blacker,
            bytes4(keccak256("setVaultType(address,uint256)")),
            _type
        );
        vaultFacet.setFuncWhiteList(
            _whiter,
            bytes4(
                keccak256(
                    "liquidateLeveragePutOrder(address,uint256,uint256,uint256)"
                )
            ),
            _type
        );
    }

    function setWhiteList(address _user, bool _type) external onlyOwner {
        ILeverageFacet(diamond).setWhiteList(_user, _type);
    }

    function setApprove(address _asset, uint256 _amount) external {
        IVault(msg.sender).invokeApprove(_asset, address(this), _amount);
    }

    modifier onlyWhiteList() {
        require(
            ILeverageFacet(diamond).getWhiteList(msg.sender),
            "LeverageModule:msg.sender onlyWhiteList"
        );
        _;
    }

    function getliquidateAmount(
        ILeverageFacet.FeeData memory _data,
        ILeverageFacet.LeveragePutOrder memory _order,
        ILeverageFacet leverageFacet,
        address eth
    )
        public
        view
        returns (uint liquidateAmount, uint tradeFee, uint liquidatePrice)
    {
        IPlatformFacet platformFacet = IPlatformFacet(diamond);
        uint _collateralAssetDecimal = IERC20Metadata(
            _order.collateralAsset == eth
                ? platformFacet.getWeth()
                : _order.collateralAsset
        ).decimals();
        uint _borrowAssetDecimal = IERC20Metadata(
            _order.borrowAsset == eth
                ? platformFacet.getWeth()
                : _order.borrowAsset
        ).decimals();
        liquidatePrice = toDecimals(
            (_data.debtAmount * (1 ether + _order.tradeFeeRate)) /
                (_order.collateralAmount + _data.lockedCollateralAmount),
            _collateralAssetDecimal,
            _borrowAssetDecimal
        );
        uint nowPrice = IPriceOracle(leverageFacet.getPriceOracle()).getPrice(
            _order.collateralAsset == eth
                ? platformFacet.getWeth()
                : _order.collateralAsset,
            _order.borrowAsset == eth
                ? platformFacet.getWeth()
                : _order.borrowAsset
        );
        uint nowRevertPrice = IPriceOracle(leverageFacet.getPriceOracle())
            .getPrice(
                _order.borrowAsset == eth
                    ? platformFacet.getWeth()
                    : _order.borrowAsset,
                _order.collateralAsset == eth
                    ? platformFacet.getWeth()
                    : _order.collateralAsset
            );
        require(
            liquidatePrice <= nowPrice,
            "LeverageModule: no enough collateralAsset to repay"
        );
        // 11 ether-  17920*0.0004*10**18
        uint repayAmount = toDecimals(
            _data.debtAmount * nowRevertPrice,
            _collateralAssetDecimal,
            _borrowAssetDecimal + 18
        );
        uint fee = (repayAmount * _order.tradeFeeRate) / 1 ether;
        return (repayAmount - fee, fee, liquidatePrice);
    }

    function toDecimals(
        uint _input,
        uint _decimalsA,
        uint _decimalsB
    ) public pure returns (uint) {
        return
            _decimalsA >= _decimalsB
                ? _input * 10 ** (_decimalsA - _decimalsB)
                : _input / 10 ** (_decimalsB - _decimalsA);
    }
}
