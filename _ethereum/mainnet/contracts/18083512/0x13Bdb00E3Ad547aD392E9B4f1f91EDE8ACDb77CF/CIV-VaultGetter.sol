// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./SafeMath.sol";
import "./Math.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./FixedPoint.sol";
import "./ICivFund.sol";
import "./UniswapV2OracleLibrary.sol";
import "./CIV-TimeOracle.sol";

////////////////// ERROR CODES //////////////////
/*
    ERR_VG.1 = "Msg.sender is not the Vault";
    ERR_VG.2 = "Can't get first pair";
    ERR_VG.3 = "Can't get second pair";
    ERR_VG.4 = "Epoch not yet expired";
    ERR_VG.5 = "Nothing to withdraw";
    ERR_VG.6 = "Wait for the previos epoch to settle before requesting withdraw";
*/

contract CivVaultGetter is ReentrancyGuard {
    using SafeMath for uint;
    using FixedPoint for *;

    ICivVault public civVault;
    /// @notice Uniswap Factory address
    address public constant UNISWAP_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // to be adjusted for mainnet
    /// @notice Wrapped ETH Address
    address public constant WETH_ADDRESS =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // to be adjusted for mainnet
    /// @notice Dead Address
    address public constant NULL_ADDRESS =
        0x0000000000000000000000000000000000000000;
    /// @notice Uniswap TWAP Period
    uint public constant PERIOD = 24 hours;

    /// @notice Each Strategy Uniswap Pair Info List
    mapping(uint => PairInfo[]) public pairInfo;

    /// @notice Each Strategy time Oracle
    mapping(uint => TimeOracle) public timeOracle;

    modifier onlyVault() {
        require(msg.sender == address(civVault), "ERR_VG.1");
        _;
    }

    constructor(address _civVaultAddress) {
        civVault = ICivVault(_civVaultAddress);
    }

    /// @notice Add new uniswap pair info to pairInfo list
    /// @dev Interal function
    /// @param _id Strategy Id
    /// @param _pair Uniswap Pair Interface
    function addPair(uint _id, IUniswapV2Pair _pair) internal {
        (, , uint32 blockTimestampLast) = _pair.getReserves();
        (
            uint price0Cumulative,
            uint price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(_pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        FixedPoint.uq112x112 memory price0Average = FixedPoint.uq112x112(
            uint224(
                (price0Cumulative - _pair.price0CumulativeLast()) / timeElapsed
            )
        );
        FixedPoint.uq112x112 memory price1Average = FixedPoint.uq112x112(
            uint224(
                (price1Cumulative - _pair.price1CumulativeLast()) / timeElapsed
            )
        );
        pairInfo[_id].push(
            PairInfo({
                pair: _pair,
                price0CumulativeLast: price0Cumulative,
                price1CumulativeLast: price1Cumulative,
                token0: _pair.token0(),
                token1: _pair.token1(),
                price0Average: price0Average,
                price1Average: price1Average,
                blockTimestampLast: blockTimestamp
            })
        );
    }

    /// @notice Deploy new Time Oracle for the strategy
    /// @param _id Strategy Id
    /// @param _epochDuration Epoch Duration
    function addTimeOracle(uint _id, uint _epochDuration) external onlyVault {
        timeOracle[_id] = new TimeOracle(_epochDuration);
    }

    /// @notice Add new uniswap pair info to pairInfo list from token pair address
    /// @param _id Strategy Id
    /// @param _token0 Token0 Address
    /// @param _token1 Token1 Address
    function addUniPair(
        uint _id,
        address _token0,
        address _token1
    ) external nonReentrant onlyVault {
        IUniswapV2Factory factory = IUniswapV2Factory(UNISWAP_FACTORY);
        address pairAddress = factory.getPair(_token1, _token0);

        if (pairAddress == NULL_ADDRESS) {
            pairAddress = factory.getPair(_token1, WETH_ADDRESS);
            require(pairAddress != NULL_ADDRESS, "ERR_VG.2");
            IUniswapV2Pair _pairA = IUniswapV2Pair(pairAddress);
            addPair(_id, _pairA);
            pairAddress = factory.getPair(_token0, WETH_ADDRESS);
            require(pairAddress != NULL_ADDRESS, "ERR_VG.3");
            IUniswapV2Pair _pairB = IUniswapV2Pair(pairAddress);
            addPair(_id, _pairB);
        } else {
            IUniswapV2Pair _pair = IUniswapV2Pair(pairAddress);
            addPair(_id, _pair);
        }
    }

    /// @notice Update Uniswap LP token price
    /// @dev Anyone can call this function but we update price after PERIOD of time
    /// @param _id Strategy Id
    /**
     * @param _index PairInfo index
     *              We can have 1 or 2 index
     *              If Deposit/Guarantee Token Pair exists on uniswap there's only 1 pairInfo
     *              If Deposit/Guarantee Token Pair does not exist on uniswap, we have 2 pairInfo
     *              Deposit/WETH Pair and Guarantee/WETH token pair to get price
     */
    function update(uint _id, uint _index) public {
        PairInfo storage info = pairInfo[_id][_index];
        (
            uint price0Cumulative,
            uint price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(info.pair));
        uint32 timeElapsed = blockTimestamp - info.blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        if (timeElapsed < PERIOD) return;

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        info.price0Average = FixedPoint.uq112x112(
            uint224(
                (price0Cumulative - info.price0CumulativeLast) / timeElapsed
            )
        );
        info.price0CumulativeLast = price0Cumulative;
        info.price1Average = FixedPoint.uq112x112(
            uint224(
                (price1Cumulative - info.price1CumulativeLast) / timeElapsed
            )
        );
        info.price1CumulativeLast = price1Cumulative;
        info.blockTimestampLast = blockTimestamp;
    }

    /// @notice Update Uniswap LP token price for all pairs
    /// @dev Anyone can call this function but we update price after PERIOD of time
    /// @param _id Strategy Id
    function updateAll(uint _id) public {
        for (uint i = 0; i < pairInfo[_id].length; i++) update(_id, i);
    }

    /// @notice Set new epochDuration for Strategy
    /// @dev Only the Getter can call this function from timeOracle
    /// @param _id Strategy Id
    /// @param _newEpochDuration new epochDuration
    function setEpochDuration(uint _id, uint _newEpochDuration) public {
        timeOracle[_id].setEpochDuration(_newEpochDuration);
    }

    /**
     * @dev Get the current period for a Strategy
     * @param _id The ID of the Strategy
     * @return currentPeriodStartTime The end time for the current period
     */
    function getCurrentPeriod(
        uint _id
    ) external view returns (uint currentPeriodStartTime) {
        return timeOracle[_id].getCurrentPeriod();
    }

    /// @dev Get Guarantee amount for deposit to the vault
    /// @param _id Strategy Id
    /// @param _amount Amount to deposit in the vault
    /// @return amount Guarantee Token Amount needs for deposit in a given strategy
    function getDepositGuarantee(
        uint _id,
        uint _amount
    ) external view returns (uint) {
        return
            (getPrice(_id, _amount) *
                civVault.getStrategyInfo(_id).guaranteeFee) /
            civVault.feeBase();
    }

    /// @dev Get available deposit amount based of user's guarantee amount
    /// @param _id Strategy Id
    /// @param _user User address
    /// @return amount Current Available Deposit amount regarding users's current guarantee token balance in a given strategy
    function getAllowedDeposit(
        uint _id,
        address _user
    ) external view returns (uint) {
        IERC20Extended guarantee = IERC20Extended(
            address(civVault.getStrategyInfo(_id).guaranteeToken)
        );
        return
            (getReversePrice(_id, guarantee.balanceOf(_user)) *
                civVault.feeBase()) /
            civVault.getStrategyInfo(_id).guaranteeFee;
    }

    /// @dev Get Guarantee Token symbol and decimal
    /// @param _id Strategy Id
    /// @return symbol Guarantee Token Symbol in a given strategy
    /// @return decimals Guarantee Token Decimal in a given strategy
    function getGuaranteeTokenInfo(
        uint _id
    ) external view returns (string memory symbol, uint decimals) {
        IERC20Extended guarantee = IERC20Extended(
            address(civVault.getStrategyInfo(_id).guaranteeToken)
        );
        symbol = guarantee.symbol();
        decimals = guarantee.decimals();
    }

    /// @dev Get claimable guarantee token amount
    /// @param _id Strategy Id
    /// @param _user userAddress
    /// @return amount Current claimable guarantee token amount
    function getClaimableGuaranteeToken(
        uint _id,
        address _user
    ) external view returns (uint) {
        StrategyInfo memory strategy = civVault.getStrategyInfo(_id);
        UserInfo memory user = civVault.getUserInfo(_id, _user);
        uint endIndex = user.numberOfLocks;
        uint unLocked;
        for (uint i = user.startingIndexGuarantee; i < endIndex; i++) {
            if (
                block.timestamp <
                civVault.getGuaranteeInfo(_id, _user, i).lockStartTime +
                    strategy.lockPeriod
            ) {
                break;
            }
            unLocked += civVault.getGuaranteeInfo(_id, _user, i).lockAmount;
        }

        return unLocked;
    }

    /**
     * @dev Retrieves the current balance of the user's guarantee token, fund representative token, and liquidity strategy token in a specific strategy.
     * @param _id The ID of the strategy from which to retrieve user balance information.
     * @param _user The user EOA
     * @return guaranteeBalance The balance of the user's guarantee token in the given strategy.
     * @return representTokenBalance The balance of the user's fund representative token in the given strategy.
     * @return assetTokenBalance The balance of the user's liquidity strategy token in the given strategy.
     * @return guaranteeAddress The contract address of the guarantee token in the given strategy.
     * @return representTokenAddress The contract address of the fund representative token in the given strategy.
     * @return assetTokenAddress The contract address of the liquidity strategy token in the given strategy.
     */
    function getUserBalances(
        uint _id,
        address _user
    )
        external
        view
        returns (
            uint guaranteeBalance,
            uint representTokenBalance,
            uint assetTokenBalance,
            address guaranteeAddress,
            address representTokenAddress,
            address assetTokenAddress
        )
    {
        guaranteeAddress = address(
            civVault.getStrategyInfo(_id).guaranteeToken
        );
        IERC20 guarantee = IERC20(guaranteeAddress);
        guaranteeBalance = guarantee.balanceOf(_user);

        representTokenAddress = address(
            civVault.getStrategyInfo(_id).fundRepresentToken
        );
        IERC20 representToken = IERC20(representTokenAddress);
        representTokenBalance = representToken.balanceOf(_user);

        assetTokenAddress = address(civVault.getStrategyInfo(_id).assetToken);
        IERC20 assetToken = IERC20(assetTokenAddress);
        assetTokenBalance = assetToken.balanceOf(_user);

        return (
            guaranteeBalance,
            representTokenBalance,
            assetTokenBalance,
            guaranteeAddress,
            representTokenAddress,
            assetTokenAddress
        );
    }

    /// @notice get net values for new VPS for a certain epoch
    /// @param _id Strategy Id
    /// @param _newVPS New Value Per Share
    /// @param _epochId Epoch Id
    /// @return _epochs array of unclaimed epochs
    function getNetValues(
        uint _id,
        uint _newVPS,
        uint _epochId
    ) public view returns (uint, uint) {
        EpochInfo memory epoch = civVault.getEpochInfo(_id, _epochId);
        StrategyInfo memory strategy = civVault.getStrategyInfo(_id);
        require(
            block.timestamp >=
                epoch.epochStartTime +
                    epoch.duration,
            "ERR_VG.4"
        );
        uint currentWithdrawAssets = _newVPS * epoch.totWithdrawnShares;
        uint decimals = uint(strategy.fundRepresentToken.decimals());
        uint multiplier = 10 ** decimals;
        uint newShares = (epoch.totDepositedAssets * multiplier) / _newVPS;

        return (currentWithdrawAssets, newShares);
    }

    /// @notice get unclaimed withdrawed token epochs
    /// @param _id Strategy Id
    /// @return _epochs array of unclaimed epochs
    function getUnclaimedTokens(
        uint _id,
        address _user
    ) public view returns (uint) {
        uint lastEpoch = civVault.getUserInfo(_id, _user).lastEpoch;
        require(lastEpoch > 0, "ERR_VG.5");
        EpochInfo memory epoch = civVault.getEpochInfo(_id, lastEpoch);
        require(epoch.VPS > 0, "ERR_VG.6");
        uint withdrawInfo = civVault
            .getUserInfoEpoch(_id, _user, lastEpoch)
            .withdrawInfo;

        return
            (withdrawInfo * epoch.currentWithdrawAssets) /
            epoch.totWithdrawnShares;
    }

    /// @notice Get Price of the each strategy's guarantee token amount based on deposit token amount
    /// @dev Public Function
    /// @param _id Strategy Id
    /// @param _amountIn deposit token amount
    /// @return amountOut Price of the token1 in a given strategy
    function getPrice(
        uint _id,
        uint _amountIn
    ) public view virtual returns (uint amountOut) {
        StrategyInfo memory strategyInfo = civVault.getStrategyInfo(_id);
        PairInfo[] memory curPairInfo = pairInfo[_id];
        if (curPairInfo.length == 1) {
            if (address(strategyInfo.assetToken) == curPairInfo[0].token0)
                amountOut = curPairInfo[0]
                    .price0Average
                    .mul(_amountIn)
                    .decode144();
            else
                amountOut = curPairInfo[0]
                    .price1Average
                    .mul(_amountIn)
                    .decode144();
        } else {
            FixedPoint.uq112x112 memory value;
            if (address(strategyInfo.guaranteeToken) == curPairInfo[0].token0) {
                value = curPairInfo[0].price1Average;
            } else {
                value = curPairInfo[0].price0Average;
            }
            if (address(strategyInfo.assetToken) == curPairInfo[1].token0) {
                value = value.muluq(curPairInfo[1].price1Average.reciprocal());
            } else {
                value = value.muluq(curPairInfo[1].price0Average.reciprocal());
            }
            amountOut = value.mul(_amountIn).decode144();
        }
    }

    /// @notice Get Price of the each strategy's deposit token amount based on guarantee token amount
    /// @dev Public Function
    /// @param _id Strategy Id
    /// @param _amountIn guarantee token amount
    /// @return amountOut Price of the token0 in a given strategy
    function getReversePrice(
        uint _id,
        uint _amountIn
    ) public view virtual returns (uint amountOut) {
        StrategyInfo memory strategyInfo = civVault.getStrategyInfo(_id);
        PairInfo[] memory curPairInfo = pairInfo[_id];
        if (curPairInfo.length == 1) {
            if (address(strategyInfo.guaranteeToken) == curPairInfo[0].token0)
                amountOut = curPairInfo[0]
                    .price0Average
                    .mul(_amountIn)
                    .decode144();
            else
                amountOut = curPairInfo[0]
                    .price1Average
                    .mul(_amountIn)
                    .decode144();
        } else {
            FixedPoint.uq112x112 memory value;
            if (address(strategyInfo.assetToken) == curPairInfo[0].token0) {
                value = curPairInfo[0].price1Average;
            } else {
                value = curPairInfo[0].price0Average;
            }
            if (address(strategyInfo.guaranteeToken) == curPairInfo[1].token0) {
                value = value.muluq(curPairInfo[1].price1Average.reciprocal());
            } else {
                value = value.muluq(curPairInfo[1].price0Average.reciprocal());
            }
            amountOut = value.mul(_amountIn).decode144();
        }
    }
}
