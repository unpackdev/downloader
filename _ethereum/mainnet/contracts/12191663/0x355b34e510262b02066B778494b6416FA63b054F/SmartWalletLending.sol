pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./ILendingPoolCore.sol";
import "./IComptroller.sol";
import "./ISmartWalletLending.sol";
import "./Utils.sol";
import "./Withdrawable.sol";
import "./SafeERC20.sol";


contract SmartWalletLending is ISmartWalletLending, Utils, Withdrawable {
    using SafeERC20 for IERC20Ext;
    using SafeMath for uint256;

    struct AaveLendingPoolData {
        IAaveLendingPoolV2 lendingPoolV2;
        IProtocolDataProvider provider;
        mapping(IERC20Ext => address) aTokensV2;
        IWeth weth;
        IAaveLendingPoolV1 lendingPoolV1;
        mapping(IERC20Ext => address) aTokensV1;
        address lendingPoolCoreV1;
        uint16 referalCode;
    }

    AaveLendingPoolData public aaveLendingPool;

    struct CompoundData {
        address comptroller;
        mapping(IERC20Ext => address) cTokens;
    }

    CompoundData public compoundData;

    address public swapImplementation;

    event UpdatedSwapImplementation(address indexed _oldSwapImpl, address indexed _newSwapImpl);
    event UpdatedAaveLendingPool(
        IAaveLendingPoolV2 poolV2,
        IProtocolDataProvider provider,
        IAaveLendingPoolV1 poolV1,
        address lendingPoolCoreV1,
        uint16 referalCode,
        IWeth weth,
        IERC20Ext[] tokens,
        address[] aTokensV1,
        address[] aTokensV2
    );
    event UpdatedCompoudData(
        address comptroller,
        address cEth,
        address[] cTokens,
        IERC20Ext[] underlyingTokens
    );

    modifier onlySwapImpl() {
        require(msg.sender == swapImplementation, "only swap impl");
        _;
    }

    constructor(address _admin) public Withdrawable(_admin) {}

    receive() external payable {}

    function updateSwapImplementation(address _swapImpl) external onlyAdmin {
        require(_swapImpl != address(0), "invalid swap impl");
        emit UpdatedSwapImplementation(swapImplementation, _swapImpl);
        swapImplementation = _swapImpl;
    }

    function updateAaveLendingPoolData(
        IAaveLendingPoolV2 poolV2,
        IProtocolDataProvider provider,
        IAaveLendingPoolV1 poolV1,
        address lendingPoolCoreV1,
        uint16 referalCode,
        IWeth weth,
        IERC20Ext[] calldata tokens
    ) external override onlyAdmin {
        require(weth != IWeth(0), "invalid weth");
        aaveLendingPool.lendingPoolV2 = poolV2;
        aaveLendingPool.provider = provider;
        aaveLendingPool.lendingPoolV1 = poolV1;
        aaveLendingPool.lendingPoolCoreV1 = lendingPoolCoreV1;
        aaveLendingPool.referalCode = referalCode;
        aaveLendingPool.weth = weth;

        address[] memory aTokensV1 = new address[](tokens.length);
        address[] memory aTokensV2 = new address[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            if (poolV1 != IAaveLendingPoolV1(0)) {
                // update data for pool v1
                try
                    ILendingPoolCore(poolV1.core()).getReserveATokenAddress(address(tokens[i]))
                returns (address aToken) {
                    aTokensV1[i] = aToken;
                } catch {}
                aaveLendingPool.aTokensV1[tokens[i]] = aTokensV1[i];
            }
            if (poolV2 != IAaveLendingPoolV2(0)) {
                address token =
                    tokens[i] == ETH_TOKEN_ADDRESS ? address(weth) : address(tokens[i]);
                // update data for pool v2
                try poolV2.getReserveData(token) returns (DataTypes.ReserveData memory data) {
                    aTokensV2[i] = data.aTokenAddress;
                } catch {}
                aaveLendingPool.aTokensV2[tokens[i]] = aTokensV2[i];
            }
        }

        // do token approvals
        if (lendingPoolCoreV1 != address(0)) {
            for (uint256 j = 0; j < aTokensV1.length; j++) {
                safeApproveAllowance(lendingPoolCoreV1, tokens[j]);
            }
        }
        if (poolV2 != IAaveLendingPoolV2(0)) {
            for (uint256 j = 0; j < aTokensV1.length; j++) {
                safeApproveAllowance(address(poolV2), tokens[j]);
            }
        }

        emit UpdatedAaveLendingPool(
            poolV2,
            provider,
            poolV1,
            lendingPoolCoreV1,
            referalCode,
            weth,
            tokens,
            aTokensV1,
            aTokensV2
        );
    }

    function updateCompoundData(
        address _comptroller,
        address _cEth,
        address[] calldata _cTokens
    ) external override onlyAdmin {
        require(_comptroller != address(0), "invalid _comptroller");
        require(_cEth != address(0), "invalid cEth");

        compoundData.comptroller = _comptroller;
        compoundData.cTokens[ETH_TOKEN_ADDRESS] = _cEth;

        IERC20Ext[] memory tokens;
        if (_cTokens.length > 0) {
            // add specific markets
            tokens = new IERC20Ext[](_cTokens.length);
            for (uint256 i = 0; i < _cTokens.length; i++) {
                require(_cTokens[i] != address(0), "invalid cToken");
                tokens[i] = IERC20Ext(ICompErc20(_cTokens[i]).underlying());
                require(tokens[i] != IERC20Ext(0), "invalid underlying token");
                compoundData.cTokens[tokens[i]] = _cTokens[i];

                // do token approvals
                safeApproveAllowance(_cTokens[i], tokens[i]);
            }
            emit UpdatedCompoudData(_comptroller, _cEth, _cTokens, tokens);
        } else {
            // add all markets
            ICompErc20[] memory markets = IComptroller(_comptroller).getAllMarkets();
            tokens = new IERC20Ext[](markets.length);
            address[] memory cTokens = new address[](markets.length);
            for (uint256 i = 0; i < markets.length; i++) {
                if (address(markets[i]) == _cEth) {
                    tokens[i] = ETH_TOKEN_ADDRESS;
                    cTokens[i] = _cEth;
                    continue;
                }
                require(markets[i] != ICompErc20(0), "invalid cToken");
                tokens[i] = IERC20Ext(markets[i].underlying());
                require(tokens[i] != IERC20Ext(0), "invalid underlying token");
                cTokens[i] = address(markets[i]);
                compoundData.cTokens[tokens[i]] = cTokens[i];

                // do token approvals
                safeApproveAllowance(_cTokens[i], tokens[i]);
            }
            emit UpdatedCompoudData(_comptroller, _cEth, cTokens, tokens);
        }
    }

    /// @dev deposit to lending platforms like AAVE, COMPOUND
    ///     expect amount of token should already be in the contract
    function depositTo(
        LendingPlatform platform,
        address payable onBehalfOf,
        IERC20Ext token,
        uint256 amount
    ) external override onlySwapImpl {
        require(getBalance(token, address(this)) >= amount, "low balance");
        if (platform == LendingPlatform.AAVE_V1) {
            IAaveLendingPoolV1 poolV1 = aaveLendingPool.lendingPoolV1;
            IERC20Ext aToken = IERC20Ext(aaveLendingPool.aTokensV1[token]);
            require(aToken != IERC20Ext(0), "aToken not found");

            // deposit and compute received aToken amount
            uint256 aTokenBalanceBefore = aToken.balanceOf(address(this));
            poolV1.deposit{value: token == ETH_TOKEN_ADDRESS ? amount : 0}(
                address(token),
                amount,
                aaveLendingPool.referalCode
            );
            uint256 aTokenBalanceAfter = aToken.balanceOf(address(this));
            // transfer all received aToken back to the sender
            aToken.safeTransfer(onBehalfOf, aTokenBalanceAfter.sub(aTokenBalanceBefore));
        } else if (platform == LendingPlatform.AAVE_V2) {
            if (token == ETH_TOKEN_ADDRESS) {
                // wrap eth -> weth, then deposit
                IWeth weth = aaveLendingPool.weth;
                IAaveLendingPoolV2 pool = aaveLendingPool.lendingPoolV2;
                weth.deposit{value: amount}();
                pool.deposit(address(weth), amount, onBehalfOf, aaveLendingPool.referalCode);
            } else {
                IAaveLendingPoolV2 pool = aaveLendingPool.lendingPoolV2;
                pool.deposit(address(token), amount, onBehalfOf, aaveLendingPool.referalCode);
            }
        } else {
            // Compound
            address cToken = compoundData.cTokens[token];
            require(cToken != address(0), "token is not supported by Compound");
            uint256 cTokenBalanceBefore = IERC20Ext(cToken).balanceOf(address(this));
            if (token == ETH_TOKEN_ADDRESS) {
                ICompEth(cToken).mint{value: amount}();
            } else {
                require(ICompErc20(cToken).mint(amount) == 0, "can not mint cToken");
            }
            uint256 cTokenBalanceAfter = IERC20Ext(cToken).balanceOf(address(this));
            IERC20Ext(cToken).safeTransfer(
                onBehalfOf,
                cTokenBalanceAfter.sub(cTokenBalanceBefore)
            );
        }
    }

    /// @dev borrow from lending platforms like AAVE v2, COMPOUND
    function borrowFrom(
        LendingPlatform platform,
        address payable onBehalfOf,
        IERC20Ext token,
        uint256 borrowAmount,
        uint256 interestRateMode
    ) external override onlySwapImpl {
        require(platform != LendingPlatform.AAVE_V1, "Aave V1 not supported");

        if (platform == LendingPlatform.AAVE_V2) {
            IAaveLendingPoolV2 poolV2 = aaveLendingPool.lendingPoolV2;
            poolV2.borrow(
                address(token),
                borrowAmount,
                interestRateMode,
                aaveLendingPool.referalCode,
                onBehalfOf
            );
        }
    }

    /// @dev withdraw from lending platforms like AAVE, COMPOUND
    ///     expect amount of aToken or cToken should already be in the contract
    function withdrawFrom(
        LendingPlatform platform,
        address payable onBehalfOf,
        IERC20Ext token,
        uint256 amount,
        uint256 minReturn
    ) external override onlySwapImpl returns (uint256 returnedAmount) {
        address lendingToken = getLendingToken(platform, token);

        uint256 tokenBalanceBefore;
        uint256 tokenBalanceAfter;
        if (platform == LendingPlatform.AAVE_V1) {
            // burn aToken to withdraw underlying token
            tokenBalanceBefore = getBalance(token, address(this));
            IAToken(lendingToken).redeem(amount);
            tokenBalanceAfter = getBalance(token, address(this));
            returnedAmount = tokenBalanceAfter.sub(tokenBalanceBefore);
            require(returnedAmount >= minReturn, "low returned amount");
            // transfer token to user
            transferToken(onBehalfOf, token, returnedAmount);
        } else if (platform == LendingPlatform.AAVE_V2) {
            if (token == ETH_TOKEN_ADDRESS) {
                // withdraw weth, then convert to eth for user
                address weth = address(aaveLendingPool.weth);
                // withdraw underlying token from pool
                tokenBalanceBefore = IERC20Ext(weth).balanceOf(address(this));
                returnedAmount = aaveLendingPool.lendingPoolV2.withdraw(
                    weth,
                    amount,
                    address(this)
                );
                tokenBalanceAfter = IERC20Ext(weth).balanceOf(address(this));
                require(
                    tokenBalanceAfter.sub(tokenBalanceBefore) >= returnedAmount,
                    "invalid return"
                );
                require(returnedAmount >= minReturn, "low returned amount");
                // convert weth to eth and transfer to sender
                IWeth(weth).withdraw(returnedAmount);
                (bool success, ) = onBehalfOf.call{value: returnedAmount}("");
                require(success, "transfer eth to sender failed");
            } else {
                // withdraw token directly to user's wallet
                tokenBalanceBefore = getBalance(token, onBehalfOf);
                returnedAmount = aaveLendingPool.lendingPoolV2.withdraw(
                    address(token),
                    amount,
                    onBehalfOf
                );
                tokenBalanceAfter = getBalance(token, onBehalfOf);
                // valid received amount in user's wallet
                require(
                    tokenBalanceAfter.sub(tokenBalanceBefore) >= returnedAmount,
                    "invalid return"
                );
                require(returnedAmount >= minReturn, "low returned amount");
            }
        } else {
            // COMPOUND
            // burn cToken to withdraw underlying token
            tokenBalanceBefore = getBalance(token, address(this));
            require(ICompErc20(lendingToken).redeem(amount) == 0, "unable to redeem");
            tokenBalanceAfter = getBalance(token, address(this));
            returnedAmount = tokenBalanceAfter.sub(tokenBalanceBefore);
            require(returnedAmount >= minReturn, "low returned amount");
            // transfer underlying token to user
            transferToken(onBehalfOf, token, returnedAmount);
        }
    }

    /// @dev repay borrows to lending platforms like AAVE, COMPOUND
    ///     expect amount of token should already be in the contract
    ///     if amount > payAmount, (amount - payAmount) will be sent back to user
    function repayBorrowTo(
        LendingPlatform platform,
        address payable onBehalfOf,
        IERC20Ext token,
        uint256 amount,
        uint256 payAmount,
        uint256 rateMode // only for aave v2
    ) external override onlySwapImpl {
        require(amount >= payAmount, "invalid pay amount");
        require(getBalance(token, address(this)) >= amount, "bad token balance");

        if (amount > payAmount) {
            // transfer back token
            transferToken(payable(onBehalfOf), token, amount - payAmount);
        }
        if (platform == LendingPlatform.AAVE_V1) {
            IAaveLendingPoolV1 poolV1 = aaveLendingPool.lendingPoolV1;

            poolV1.repay{value: token == ETH_TOKEN_ADDRESS ? payAmount : 0}(
                address(token),
                payAmount,
                onBehalfOf
            );
        } else if (platform == LendingPlatform.AAVE_V2) {
            IAaveLendingPoolV2 poolV2 = aaveLendingPool.lendingPoolV2;
            if (token == ETH_TOKEN_ADDRESS) {
                IWeth weth = aaveLendingPool.weth;
                weth.deposit{value: payAmount}();
                require(
                    poolV2.repay(address(weth), payAmount, rateMode, onBehalfOf) == payAmount,
                    "wrong paid amount"
                );
            } else {
                require(
                    poolV2.repay(address(token), payAmount, rateMode, onBehalfOf) == payAmount,
                    "wrong paid amount"
                );
            }
        } else {
            // compound
            address cToken = compoundData.cTokens[token];
            require(cToken != address(0), "token is not supported by Compound");
            if (token == ETH_TOKEN_ADDRESS) {
                ICompEth(cToken).repayBorrowBehalf{value: payAmount}(onBehalfOf);
            } else {
                require(
                    ICompErc20(cToken).repayBorrowBehalf(onBehalfOf, payAmount) == 0,
                    "compound repay error"
                );
            }
        }
    }

    function claimComp(
        address[] calldata holders,
        ICompErc20[] calldata cTokens,
        bool borrowers,
        bool suppliers
    ) external override onlySwapImpl {
        require(holders.length > 0, "no holders");
        IComptroller comptroller = IComptroller(compoundData.comptroller);
        if (cTokens.length == 0) {
            // claim for all markets
            ICompErc20[] memory markets = comptroller.getAllMarkets();
            comptroller.claimComp(holders, markets, borrowers, suppliers);
        } else {
            comptroller.claimComp(holders, cTokens, borrowers, suppliers);
        }
        emit ClaimedComp(holders, cTokens, borrowers, suppliers);
    }

    function getLendingToken(LendingPlatform platform, IERC20Ext token)
        public
        view
        override
        returns (address)
    {
        if (platform == LendingPlatform.AAVE_V1) {
            return aaveLendingPool.aTokensV1[token];
        } else if (platform == LendingPlatform.AAVE_V2) {
            return aaveLendingPool.aTokensV2[token];
        }
        return compoundData.cTokens[token];
    }

    /** @dev Calculate the current user debt and return
    */
    function storeAndRetrieveUserDebtCurrent(
        LendingPlatform platform,
        address _reserve,
        address _user
    ) external override returns (uint256 debt) {
        if (platform == LendingPlatform.AAVE_V1 || platform == LendingPlatform.AAVE_V2) {
            debt = getUserDebtStored(platform, _reserve, _user);
            return debt;
        }
        ICompErc20 cToken = ICompErc20(compoundData.cTokens[IERC20Ext(_reserve)]);
        debt = cToken.borrowBalanceCurrent(_user);
    }

    /** @dev Return the stored user debt from given platform
    *   to get the latest data of user's debt for repaying, should call
    *   storeAndRetrieveUserDebtCurrent function, esp for Compound platform
    */
    function getUserDebtStored(
        LendingPlatform platform,
        address _reserve,
        address _user
    ) public view override returns (uint256 debt) {
        if (platform == LendingPlatform.AAVE_V1) {
            uint256 originationFee;
            IAaveLendingPoolV1 pool = aaveLendingPool.lendingPoolV1;
            (, debt, , , , , originationFee, , , ) = pool.getUserReserveData(_reserve, _user);
            debt = debt.add(originationFee);
        } else if (platform == LendingPlatform.AAVE_V2) {
            IProtocolDataProvider provider = aaveLendingPool.provider;
            (, uint256 stableDebt, uint256 variableDebt, , , , , , ) =
                provider.getUserReserveData(_reserve, _user);
            debt = stableDebt > 0 ? stableDebt : variableDebt;
        } else {
            ICompErc20 cToken = ICompErc20(compoundData.cTokens[IERC20Ext(_reserve)]);
            debt = cToken.borrowBalanceStored(_user);
        }
    }

    function safeApproveAllowance(address spender, IERC20Ext token) internal {
        if (token != ETH_TOKEN_ADDRESS && token.allowance(address(this), spender) == 0) {
            token.safeApprove(spender, MAX_ALLOWANCE);
        }
    }

    function transferToken(
        address payable recipient,
        IERC20Ext token,
        uint256 amount
    ) internal {
        if (token == ETH_TOKEN_ADDRESS) {
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "failed to transfer eth");
        } else {
            token.safeTransfer(recipient, amount);
        }
    }
}
