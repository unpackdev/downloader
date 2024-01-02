// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

import "./ICurvePool.sol";
import "./ICurvePool.sol";

import "./IsfrxETH.sol";
import "./IWstETH.sol";

contract TryLSDGateway {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    // Event to be emitted when a user deposits through the Gateway
    event Deposit(address indexed sender, address indexed owner, uint256 ethAmount, uint256 shares);

    event Withdraw(
        address indexed sender, address indexed receiver, address indexed owner, uint256 ethAmount, uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    // should not send eth directly to this contract, use swapAndDeposit function
    error NotPayable();

    // Minimum amount of eth sent when deposit
    // 0x4b1175db
    error TooLittleEthError();

    // minimum amount of shares not met on swap and deposit
    // 0x8517304e
    error MinSharesSlippageError();

    // Minimum amount of shares sent on withdraw
    // 0xe8471aeb
    error TooLittleSharesError();

    // minimum amount of shares not met on withdraw and swap
    // 0xfe0d2edb
    error MinEthSlippageError();

    // transferFrom failed while withdrawing
    error TransferFromFailed();

    // failed to transfer eth back to user after withdraw and swap
    error FailedToSendEth();

    /*//////////////////////////////////////////////////////////////
                    VARIABLES & EXTERNAL CONTRACTS
    //////////////////////////////////////////////////////////////*/

    // eth mainnet wsteth
    IWstETH internal immutable _WSTETH = IWstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    // eth mainnet steth
    IERC20 internal immutable _STETH = IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);

    // eth mainnet reth
    IERC20 internal immutable _RETH = IERC20(0xae78736Cd615f374D3085123A210448E74Fc6393);

    // eth mainnet sfrxeth
    IsfrxETH internal immutable _SFRXETH = IsfrxETH(0xac3E018457B222d93114458476f3E3416Abbe38F);
    // eth mainnet frxeth
    IERC20 internal immutable _FRXETH = IERC20(0x5E8422345238F34275888049021821E8E08CAa1f);

    // all the curve pools needed for swaps
    ICurvePool1 internal immutable _ETHTOSTETH = ICurvePool1(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);
    ICurvePool2 internal immutable _ETHTORETH = ICurvePool2(0x0f3159811670c117c372428D4E69AC32325e4D0F);
    ICurvePool1 internal immutable _ETHTOFRXETH = ICurvePool1(0xa1F8A6807c402E4A15ef4EBa36528A3FED24E577);

    // curve tryLSD mainnet pool
    ICurvePool2 internal immutable _TRYLSD = ICurvePool2(0x2570f1bD5D2735314FC102eb12Fc1aFe9e6E7193);

    // Used to prevent a loop where pool would send eth to the gateway and trigger a deposit
    bool internal _startedWithdraw;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        // unlimited approve will be used to add liquidity to the tryLSD pool
        _WSTETH.approve(address(_TRYLSD), type(uint256).max);
        _RETH.approve(address(_TRYLSD), type(uint256).max);
        _SFRXETH.approve(address(_TRYLSD), type(uint256).max);

        // unlimited approve will be used to wrap steth to wsteth
        _STETH.approve(address(_WSTETH), type(uint256).max);
        // unlimited approve will be used to wrap frxeth to sfrxeth
        _FRXETH.approve(address(_SFRXETH), type(uint256).max);

        // unlimited approve will be used to swap steth to eth
        _STETH.approve(address(_ETHTOSTETH), type(uint256).max);
        // unlimited approve will be used to swap reth to eth
        _RETH.approve(address(_ETHTORETH), type(uint256).max);
        // unlimited approve will be used to swap frxeth to eth
        _FRXETH.approve(address(_ETHTOFRXETH), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                            PAYABLE LOGIC
    //////////////////////////////////////////////////////////////*/

    function handleReceive() public payable {
        // should not send eth directly to this contract, use swapAndDeposit function
        if (_startedWithdraw == false) revert NotPayable();

        return;
    }

    fallback() external payable {
        handleReceive();
    }

    receive() external payable {
        handleReceive();
    }

    /*//////////////////////////////////////////////////////////////
                            DEPOSIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function calculatePoolShares(uint256 depositAmount) public view returns (uint256 shares) {
        uint256 singleSwapAmount = depositAmount / 3;
        // we do this to avoid collecting dust due to rounding
        uint256 lastSwapAmount = depositAmount / 3 + (depositAmount % 3);

        // for get_dy asset 0 is eth, asset 1 is steth
        uint256 stethAmount = _ETHTOSTETH.get_dy(0, 1, singleSwapAmount);
        // calculate the amount of wsteth we get for stethAmount of eth
        uint256 wstethAmount = _WSTETH.getWstETHByStETH(stethAmount);
        // for get_dy asset 0 is eth, asset 1 is reth
        uint256 rethAmount = _ETHTORETH.get_dy(0, 1, singleSwapAmount);
        // for get_dy asset 0 is eth, asset 1 is frxeth
        uint256 frxethAmount = _ETHTOFRXETH.get_dy(0, 1, lastSwapAmount);
        // calculate the amount of sfrxeth we get for frxethAmount of eth
        uint256 sfrxethAmount = _SFRXETH.convertToShares(frxethAmount);

        // finally calculate the amount of pool shares we get for the 3 tokens
        shares = _TRYLSD.calc_token_amount([wstethAmount, rethAmount, sfrxethAmount], true);
    }

    function swapAndDeposit(address owner, uint256 minShares) public payable returns (uint256 shares) {
        // should send more than 0 eth
        if (msg.value == 0) revert TooLittleEthError();

        uint256 singleSwapAmount = msg.value / 3;
        // we do this to avoid collecting dust due to rounding
        uint256 lastSwapAmount = msg.value / 3 + (msg.value % 3);

        // exchange from eth to steth, target amount and minAmount (for slippage)
        uint256 stethAmount = _ETHTOSTETH.exchange{value: singleSwapAmount}(
            0,
            1,
            singleSwapAmount,
            0 // min amount set to 0 because we check pool shares for slippage
        );
        // then wrap to wsteth
        uint256 wstethAmount = _WSTETH.wrap(stethAmount);
        // exchange from eth to steth, target amount and minAmount (for slippage)
        uint256 rethAmount = _ETHTORETH.exchange_underlying{value: singleSwapAmount}(
            0,
            1,
            singleSwapAmount,
            0 // min amount set to 0 because we check pool shares for slippage
        );
        // exchange from eth to steth, target amount and minAmount (for slippage)
        uint256 frxethAmount = _ETHTOFRXETH.exchange{value: lastSwapAmount}(
            0,
            1,
            lastSwapAmount,
            0 // min amount set to 0 because we check pool shares for slippage
        );
        // then wrap to sfrxeth
        uint256 sfrxethAmount = _SFRXETH.deposit(frxethAmount, address(this));

        // add liquidity to pool
        shares = _TRYLSD.add_liquidity(
            [wstethAmount, rethAmount, sfrxethAmount],
            0, // min shares set to 0 because I check myself for slippage
            false,
            owner
        );

        // Check slippage
        if (shares <= minShares) revert MinSharesSlippageError();

        // emit deposit event
        emit Deposit(msg.sender, owner, msg.value, shares);
    }

    /*//////////////////////////////////////////////////////////////
                            WITHDRAW LOGIC
    //////////////////////////////////////////////////////////////*/

    function calculateEth(uint256 shares) public view returns (uint256 ethAmount) {
        uint256 totalSupply = _TRYLSD.totalSupply();

        uint256 wstethAmount = (_TRYLSD.balances(0) * shares) / totalSupply;
        uint256 rethAmount = (_TRYLSD.balances(1) * shares) / totalSupply;
        uint256 sfrxethAmount = (_TRYLSD.balances(2) * shares) / totalSupply;

        // calculate the amount of eth we get for singleSwapAmount of wsteth
        // for get_dy asset 0 is eth, asset 1 is frxeth
        ethAmount = _ETHTOSTETH.get_dy(1, 0, _WSTETH.getStETHByWstETH(wstethAmount));
        // calculate the amount of eth we get for singleSwapAmount of reth
        // for get_dy asset 0 is eth, asset 1 is frxeth
        ethAmount += _ETHTORETH.get_dy(1, 0, rethAmount);
        // calculate the amount of eth we get for singleSwapAmount of sfrxeth
        // for get_dy asset 0 is eth, asset 1 is frxeth
        ethAmount += _ETHTOFRXETH.get_dy(1, 0, _SFRXETH.convertToAssets(sfrxethAmount));
    }

    function withdrawAndSwap(address receiver, uint256 shares, uint256 minEth)
        public
        payable
        returns (uint256 ethAmount)
    {
        // this variable is to prevent a loop where pool would send eth to the gateway and trigger a deposit
        _startedWithdraw = true;

        // should send more than 0 shares
        if (shares == 0) revert TooLittleSharesError();

        bool success = _TRYLSD.transferFrom(msg.sender, address(this), shares);

        // this might be useless as transferFrom will revert itself if it fails
        if (success == false) revert TransferFromFailed();

        uint256[3] memory amounts =
            _TRYLSD.remove_liquidity(shares, [uint256(0), uint256(0), uint256(0)], false, address(this));

        // unwrap wsteth to steth
        uint256 stethAmount = _WSTETH.unwrap(amounts[0]);
        // exchange steth to eth
        uint256 stethToEthAmount = _ETHTOSTETH.exchange(
            1, // from steth
            0, // to eth
            stethAmount, // amount we got from unwrapping wsteth
            0 // min amount set to 0 because we check final eth amount for slippage
        );

        // exchange reth to eth
        uint256 rethToEthAmount = _ETHTORETH.exchange_underlying(
            1, // from reth
            0, // to eth
            amounts[1],
            0 // min amount set to 0 because we check final eth amount for slippage
        );

        // redeem frxeth from sfrxeth
        uint256 frxethAmount = _SFRXETH.redeem(amounts[2], address(this), address(this));
        // exchange frxeth to eth
        uint256 frxethToEthAmount = _ETHTOFRXETH.exchange(
            1, // from frxeth
            0, // to eth
            frxethAmount,
            0 // min amount set to 0 because we check final eth amount for slippage
        );

        ethAmount = stethToEthAmount + rethToEthAmount + frxethToEthAmount;

        // Check slippage
        if (ethAmount <= minEth) revert MinEthSlippageError();

        (bool sent,) = receiver.call{value: ethAmount}("");

        if (sent == false) revert FailedToSendEth();

        // emit withdraw event
        emit Withdraw(msg.sender, receiver, msg.sender, ethAmount, shares);

        // this variable is to prevent a loop where pool would send eth to the gateway and trigger a deposit
        _startedWithdraw = false;
    }
}
