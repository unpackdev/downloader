// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./ITokamakStaker.sol";
import "./ITON.sol";
import "./IIStake1Vault.sol";
import "./IIIDepositManager.sol";
import "./IISeigManager.sol";
import "./SafeMath.sol";

import "./AccessibleCommon.sol";

import "./StakeTONStorage.sol";
import "./ISwapRouter.sol";

interface IERC20BASE2 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IIWTON2 {
    function swapToTON(uint256 wtonAmount) external returns (bool);
}

interface ITokamakRegistry2 {
    function getTokamak()
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address
        );

    function getUniswap()
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            address
        );
}

/// @title The connector that integrates tokamak
contract TokamakStakeUpgrade2 is
    StakeTONStorage,
    AccessibleCommon,
    ITokamakStaker
{
    using SafeMath for uint256;

    modifier nonZero(address _addr) {
        require(_addr != address(0), "TokamakStaker: zero address");
        _;
    }

    modifier sameTokamakLayer(address _addr) {
        require(tokamakLayer2 == _addr, "TokamakStaker:different layer");
        _;
    }

    modifier lock() {
        require(_lock == 0, "TokamakStaker:LOCKED");
        _lock = 1;
        _;
        _lock = 0;
    }

    modifier onlyClosed() {
        require(IIStake1Vault(vault).saleClosed(), "TokamakStaker: not closed");
        _;
    }

    /// @dev event on set the registry address
    /// @param registry the registry address
    event SetRegistry(address registry);

    /// @dev event on set the tokamak Layer2 address
    /// @param layer2 the tokamak Layer2 address
    event SetTokamakLayer2(address layer2);

    /// @dev event on staking the staked TON in layer2 in tokamak
    /// @param layer2 the layer2 address in tokamak
    /// @param amount the amount that stake to layer2
    event TokamakStaked(address layer2, uint256 amount);

    /// @dev event on request unstaking the wtonAmount in layer2 in tokamak
    /// @param layer2 the layer2 address in tokamak
    /// @param amount the amount requested to unstaking
    event TokamakRequestedUnStaking(address layer2, uint256 amount);

    /// @dev event on process unstaking in layer2 in tokamak
    /// @param layer2 the layer2 address in tokamak
    /// @param rn the number of requested unstaking
    /// @param receiveTON if is true ,TON , else is WTON
    event TokamakProcessedUnStaking(
        address layer2,
        uint256 rn,
        bool receiveTON
    );

    /// @dev event on request unstaking the amount of all in layer2 in tokamak
    /// @param layer2 the layer2 address in tokamak
    event TokamakRequestedUnStakingAll(address layer2);

    /// @dev exchange WTON to TOS using uniswap v3
    /// @param caller the sender
    /// @param amountIn the input amount
    /// @return amountOut the amount of exchanged out token

    event ExchangedWTONtoTOS(
        address caller,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @dev set registry address
    /// @param _registry new registry address
    function setRegistry(address _registry)
        external
        onlyOwner
        nonZero(_registry)
    {
        stakeRegistry = _registry;

        emit SetRegistry(stakeRegistry);
    }

    /// @dev set the tokamak Layer2 address
    /// @param _layer2 new the tokamak Layer2 address
    function setTokamakLayer2(address _layer2) external override onlyOwner {
        require(
            _layer2 != address(0) && tokamakLayer2 != _layer2,
            "TokamakStaker:tokamakLayer2 zero "
        );
        tokamakLayer2 = _layer2;

        emit SetTokamakLayer2(_layer2);
    }

    /// @dev get the addresses that used in uniswap interfaces
    /// @return uniswapRouter the address of uniswapRouter
    /// @return npm the address of positionManagerAddress
    /// @return ext the address of ext
    /// @return fee the amount of fee
    function getUniswapInfo()
        external
        view
        override
        returns (
            address uniswapRouter,
            address npm,
            address ext,
            uint256 fee,
            address uniswapRouterV2
        )
    {
        return ITokamakRegistry2(stakeRegistry).getUniswap();
    }

    /// @dev Change the TON holded in contract have to WTON, or change WTON to TON.
    /// @param amount the amount to be changed
    /// @param toWTON if it's true, TON->WTON , else WTON->TON
    function swapTONtoWTON(uint256 amount, bool toWTON) external override lock {
        checkTokamak();

        if (toWTON) {
            require(
                swapProxy != address(0),
                "TokamakStaker: swapProxy is zero"
            );
            require(
                IERC20BASE2(ton).balanceOf(address(this)) >= amount,
                "TokamakStaker: swapTONtoWTON ton balance is insufficient"
            );
            bytes memory data = abi.encode(swapProxy, swapProxy);
            require(
                ITON(ton).approveAndCall(wton, amount, data),
                "TokamakStaker:swapTONtoWTON approveAndCall fail"
            );
        } else {
            require(
                IERC20BASE2(wton).balanceOf(address(this)) >= amount,
                "TokamakStaker: swapTONtoWTON wton balance is insufficient"
            );
            require(
                IIWTON2(wton).swapToTON(amount),
                "TokamakStaker:swapToTON fail"
            );
        }
    }

    /// @dev If the tokamak addresses is not set, set the addresses.
    function checkTokamak() public {
        if (ton == address(0)) {
            (
                address _ton,
                address _wton,
                address _depositManager,
                address _seigManager,
                address _swapProxy
            ) = ITokamakRegistry2(stakeRegistry).getTokamak();

            ton = _ton;
            wton = _wton;
            depositManager = _depositManager;
            seigManager = _seigManager;
            swapProxy = _swapProxy;
        }
        require(
            ton != address(0) &&
                wton != address(0) &&
                seigManager != address(0) &&
                depositManager != address(0) &&
                swapProxy != address(0),
            "TokamakStaker:tokamak zero"
        );
    }

    /// @dev  staking the staked TON in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    /// @param stakeAmount the amount that stake to layer2
    function tokamakStaking(address _layer2, uint256 stakeAmount)
        external
        override
        lock
        nonZero(stakeRegistry)
        nonZero(_layer2)
        onlyClosed
    {
        require(block.number <= endBlock, "TokamakStaker:period end");
        require(stakeAmount > 0, "TokamakStaker:stakeAmount is zero");

        defiStatus = uint256(LibTokenStake1.DefiStatus.DEPOSITED);

        checkTokamak();

        uint256 globalWithdrawalDelay =
            IIIDepositManager(depositManager).globalWithdrawalDelay();
        require(
            block.number < endBlock.sub(globalWithdrawalDelay),
            "TokamakStaker:period(withdrawalDelay) end"
        );

        if (tokamakLayer2 == address(0)) tokamakLayer2 = _layer2;
        else {
            if (
                IISeigManager(seigManager).stakeOf(
                    tokamakLayer2,
                    address(this)
                ) >
                0 ||
                IIIDepositManager(depositManager).pendingUnstaked(
                    tokamakLayer2,
                    address(this)
                ) >
                0
            ) {
                require(
                    tokamakLayer2 == _layer2,
                    "TokamakStaker:different layer"
                );
            } else {
                if (tokamakLayer2 != _layer2) tokamakLayer2 = _layer2;
            }
        }

        require(
            IERC20BASE2(ton).balanceOf(address(this)) >= stakeAmount,
            "TokamakStaker: ton balance is insufficient"
        );
        toTokamak = toTokamak.add(stakeAmount);
        bytes memory data = abi.encode(depositManager, _layer2);
        require(
            ITON(ton).approveAndCall(wton, stakeAmount, data),
            "TokamakStaker:approveAndCall fail"
        );

        emit TokamakStaked(_layer2, stakeAmount);
    }

    function version() external pure returns (string memory) {
        return "phase1.upgrade.v2";
    }

    /// @dev  request unstaking the amount excluding principal   in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    /// @param wtonAmount Exists for existing interfaces. not used.
    function tokamakRequestUnStaking(address _layer2, uint256 wtonAmount)
        external
        override
        lock
        nonZero(stakeRegistry)
        nonZero(_layer2)
        onlyClosed
        sameTokamakLayer(_layer2)
    {
        defiStatus = uint256(LibTokenStake1.DefiStatus.REQUESTWITHDRAW);
        requestNum = requestNum.add(1);
        checkTokamak();

        uint256 stakeOf =
            IISeigManager(seigManager).stakeOf(_layer2, address(this));
        require(stakeOf > 0, "TokamakStaker: stakeOf is zero");

        uint256 principalAmount = totalStakedAmount.mul(10**9);

        uint256 availableAmount = 0;
        if (principalAmount > 0 && principalAmount < stakeOf.sub(100)) {
            availableAmount = stakeOf.sub(principalAmount).sub(100);
        }

        require(
            availableAmount > 0,
            "TokamakStaker: no withdraw-able amount not yet"
        );

        IIIDepositManager(depositManager).requestWithdrawal(
            _layer2,
            availableAmount
        );

        emit TokamakRequestedUnStaking(_layer2, availableAmount);
    }

    /// @dev  Check whether unstaking is possible in layer2
    /// @param _layer2 the layer2 address in tokamak
    /// @return canUnStakingAmount available unStaking amount
    function canTokamakRequestUnStaking(address _layer2)
        external
        view
        returns (uint256 canUnStakingAmount)
    {
        canUnStakingAmount = 0;
        if (
            tokamakLayer2 != address(0) &&
            tokamakLayer2 == _layer2 &&
            seigManager != address(0)
        ) {
            uint256 stakeOf =
                IISeigManager(seigManager).stakeOf(_layer2, address(this));
            if (
                stakeOf > 0 &&
                totalStakedAmount > 0 &&
                totalStakedAmount.mul(10**9) < stakeOf
            ) {
                canUnStakingAmount = stakeOf.sub(totalStakedAmount.mul(10**9));
            }
        }
    }

    /// @dev  request unstaking the amount of all in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    function tokamakRequestUnStakingAll(address _layer2)
        external
        override
        lock
        nonZero(stakeRegistry)
        nonZero(_layer2)
        onlyClosed
        sameTokamakLayer(_layer2)
    {
        defiStatus = uint256(LibTokenStake1.DefiStatus.REQUESTWITHDRAW);
        requestNum = requestNum.add(1);
        checkTokamak();

        uint256 globalWithdrawalDelay =
            IIIDepositManager(depositManager).globalWithdrawalDelay();

        uint256 stakeOf =
            IISeigManager(seigManager).stakeOf(_layer2, address(this));
        require(stakeOf > 0, "TokamakStaker: stakeOf is zero");

        uint256 interval = globalWithdrawalDelay / 14;

        require(
            block.number > endBlock.sub(globalWithdrawalDelay).sub(interval),
            "TokamakStaker:The executable block has not passed"
        );

        IIIDepositManager(depositManager).requestWithdrawalAll(_layer2);

        emit TokamakRequestedUnStakingAll(_layer2);
    }

    /// @dev  Check whether unstakingAll is possible in layer2
    /// @param _layer2 the layer2 address in tokamak
    /// @return can whether can tokamakRequestUnStakingAll
    function canTokamakRequestUnStakingAll(address _layer2)
        external
        view
        returns (bool can)
    {
        can = false;
        if (
            tokamakLayer2 != address(0) &&
            tokamakLayer2 == _layer2 &&
            depositManager != address(0) &&
            seigManager != address(0)
        ) {
            uint256 globalWithdrawalDelay =
                IIIDepositManager(depositManager).globalWithdrawalDelay();
            uint256 interval = globalWithdrawalDelay / 14;
            uint256 stakeOf =
                IISeigManager(seigManager).stakeOf(_layer2, address(this));
            if (
                stakeOf > 0 &&
                block.number > endBlock.sub(globalWithdrawalDelay).sub(interval)
            ) can = true;
        }
    }

    /// @dev  Check whether unstakingAll is possible in layer2
    /// @param _layer2 the layer2 address in tokamak
    /// @return _block  the block to can tokamakRequestUnStakingAll
    function canTokamakRequestUnStakingAllBlock(address _layer2)
        external
        view
        returns (uint256 _block)
    {
        if (
            tokamakLayer2 != address(0) &&
            tokamakLayer2 == _layer2 &&
            depositManager != address(0)
        ) {
            uint256 globalWithdrawalDelay =
                IIIDepositManager(depositManager).globalWithdrawalDelay();
            uint256 interval = globalWithdrawalDelay / 14;

            if (endBlock > globalWithdrawalDelay.add(interval))
                _block = endBlock.sub(globalWithdrawalDelay).sub(interval);
        }
    }

    /// @dev process unstaking in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    function tokamakProcessUnStaking(address _layer2)
        external
        override
        lock
        nonZero(stakeRegistry)
        onlyClosed
        sameTokamakLayer(_layer2)
    {
        defiStatus = uint256(LibTokenStake1.DefiStatus.WITHDRAW);

        checkTokamak();

        uint256 num = 0;
        uint256 pamount = 0;
        (num, pamount) = canTokamakProcessUnStakingCount(_layer2);

        require(num > 0 && pamount > 0, "TokamakStaker: no able request");
        fromTokamak = fromTokamak.add(pamount);
        if (requestNum >= num) requestNum = requestNum.sub(num);

        // receiveTON = false . to WTON
        IIIDepositManager(depositManager).processRequests(_layer2, num, true);

        emit TokamakProcessedUnStaking(_layer2, num, true);
    }

    /// @dev TokamakProcessUnStaking Number and amount of withdrawals possible
    /// @param _layer2 the layer2 address in tokamak
    function canTokamakProcessUnStakingCount(address _layer2)
        public
        view
        nonZero(stakeRegistry)
        nonZero(_layer2)
        onlyClosed
        sameTokamakLayer(_layer2)
        returns (uint256 count, uint256 amount)
    {
        uint128 num = 0;
        uint128 pamount = 0;
        uint256 startIndex =
            IIIDepositManager(depositManager).withdrawalRequestIndex(
                _layer2,
                address(this)
            );
        uint256 numPendingRequests =
            IIIDepositManager(depositManager)
                .numPendingRequests(_layer2, address(this))
                .add(startIndex);

        for (uint256 i = startIndex; i < numPendingRequests; i++) {
            uint128 _block = 0;
            uint128 _amount = 0;
            bool processed = false;
            (_block, _amount, processed) = IIIDepositManager(depositManager)
                .withdrawalRequest(_layer2, address(this), i);

            if (
                processed == false &&
                (uint256(_block) > 0 && uint256(_block) < block.number)
            ) {
                num++;
                pamount += _amount;
            } else {
                break;
            }
        }

        return (uint256(num), uint256(pamount));
    }

    /// @dev exchange holded WTON to TOS using uniswap
    /// @param _amountIn the input amount
    /// @param _amountOutMinimum the minimun output amount
    /// @param _deadline deadline
    /// @param _sqrtPriceLimitX96 sqrtPriceLimitX96
    /// @param _kind the function type, if 0, use exactInputSingle function, else if, use exactInput function
    /// @return amountOut the amount of exchanged out token
    function exchangeWTONtoTOS(
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint256 _deadline,
        uint160 _sqrtPriceLimitX96,
        uint256 _kind
    ) external override lock onlyClosed returns (uint256 amountOut) {
        require(block.number <= endBlock, "TokamakStaker: period end");
        require(_kind < 2, "TokamakStaker: not available kind");
        checkTokamak();

        {
            uint256 _amountWTON = IERC20BASE2(wton).balanceOf(address(this));
            uint256 _amountTON = IERC20BASE2(ton).balanceOf(address(this));
            uint256 stakeOf = 0;
            if (tokamakLayer2 != address(0)) {
                stakeOf = IISeigManager(seigManager).stakeOf(
                    tokamakLayer2,
                    address(this)
                );
                stakeOf = stakeOf.add(
                    IIIDepositManager(depositManager).pendingUnstaked(
                        tokamakLayer2,
                        address(this)
                    )
                );
            }
            uint256 holdAmount = _amountWTON;
            if (_amountTON > 0)
                holdAmount = holdAmount.add(_amountTON.mul(10**9));
            require(
                holdAmount >= _amountIn,
                "TokamakStaker: wton insufficient"
            );

            if (stakeOf > 0) holdAmount = holdAmount.add(stakeOf);

            require(
                holdAmount > totalStakedAmount.mul(10**9) &&
                    holdAmount.sub(totalStakedAmount.mul(10**9)) >= _amountIn,
                "TokamakStaker:insufficient"
            );
            if (_amountWTON < _amountIn) {
                bytes memory data = abi.encode(swapProxy, swapProxy);
                uint256 swapTON = _amountIn.sub(_amountWTON).div(10**9);
                require(
                    ITON(ton).approveAndCall(wton, swapTON, data),
                    "TokamakStaker:exchangeWTONtoTOS approveAndCall fail"
                );
            }
        }

        toUniswapWTON = toUniswapWTON.add(_amountIn);
        (address uniswapRouter, , , uint256 _fee, ) =
            ITokamakRegistry2(stakeRegistry).getUniswap();
        require(uniswapRouter != address(0), "TokamakStaker:uniswap zero");
        require(
            IERC20BASE2(wton).approve(uniswapRouter, _amountIn),
            "TokamakStaker:can't approve uniswapRouter"
        );

        //if (_kind == 0) {
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: wton,
                tokenOut: token,
                fee: uint24(_fee),
                recipient: address(this),
                deadline: _deadline,
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMinimum,
                sqrtPriceLimitX96: _sqrtPriceLimitX96
            });
        amountOut = ISwapRouter(uniswapRouter).exactInputSingle(params);
        /*
        } else if (_kind == 1) {
            ISwapRouter.ExactInputParams memory params =
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(
                        wton,
                        uint24(_fee),
                        wethAddress,
                        uint24(_fee),
                        token
                    ),
                    recipient: address(this),
                    deadline: _deadline,
                    amountIn: _amountIn,
                    amountOutMinimum: _amountOutMinimum
                });
            amountOut = ISwapRouter(uniswapRouter).exactInput(params);
        } */

        emit ExchangedWTONtoTOS(msg.sender, _amountIn, amountOut);
    }
}
