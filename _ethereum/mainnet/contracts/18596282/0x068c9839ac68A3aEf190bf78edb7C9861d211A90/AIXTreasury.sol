// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./IUniswapV2Router02.sol";
import "./ReentrancyGuardUpgradeable.sol";

interface IOnRewardsReceived {
    function onRewardsAIXReceived() external;
    function onRewardsETHReceived() external;
}

/// @title AIXTreasury
/// @notice A contract for managing the distribution of AIX tokens and ETH based on predefined shares.
contract AIXTreasury is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    event TransferETH(address indexed to, uint256 value);
    event AnyoneCanDistributeSet(bool value);
    event ReceiversSet(Receiver[] aixReceivers, Receiver[] ethReceivers);
    event Distributed(address indexed token, address indexed receiver, uint256 amount);
    event TokensSwapped(uint256 aixAmount, uint256 ethAmount);

    // 0xfbd454f36a7e1a388bd6fc3ab10d434aa4578f811acbbcf33afb1c697486313c
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    uint256 public constant DENOMINATOR = 10_000;

    IERC20 public aix;
    IUniswapV2Router02 public uniswapRouter;
    address public weth;
    bool public anyoneCanDistribute;

    struct Receiver {
        uint256 share;
        address receiver;
        bool doCallback;
    }

    Receiver[] public aixReceivers;
    Receiver[] public ethReceivers;
    uint256 public totalAixShares;
    uint256 public totalEthShares;

    /// @notice Initializes the contract with the given parameters.
    /// @param _aix The address of the AIX token.
    /// @param _uniswapRouter The address of the Uniswap V2 router.
    /// @param _weth The address of the wrapped ETH token.
    /// @param _aixReceivers An array of AIX receivers with their corresponding shares.
    /// @param _ethReceivers An array of ETH receivers with their corresponding shares.
    function initialize(
        IERC20 _aix,
        address _uniswapRouter,
        address _weth,
        Receiver[] memory _aixReceivers,
        Receiver[] memory _ethReceivers
    ) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        aix = _aix;
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        weth = _weth;
        _setReceivers(_aixReceivers, _ethReceivers);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DISTRIBUTOR_ROLE, msg.sender);
    }

    /// @notice Sets the `anyoneCanDistribute` flag which allows or prevents anyone from distributing tokens.
    /// @param value The new value of the `anyoneCanDistribute` flag.
    function setAnyoneCanDistribute(bool value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        anyoneCanDistribute = value;
        emit AnyoneCanDistributeSet(value);
    }

    /// @notice Sets the AIX and ETH receivers along with their shares.
    /// @param _aixReceivers An array of AIX receivers with their corresponding shares.
    /// @param _ethReceivers An array of ETH receivers with their corresponding shares.
    function setReceivers(Receiver[] memory _aixReceivers, Receiver[] memory _ethReceivers) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setReceivers(_aixReceivers, _ethReceivers);
    }

    /// @notice Internal function to set the AIX and ETH receivers along with their shares.
    /// @param _aixReceivers An array of AIX receivers with their corresponding shares.
    /// @param _ethReceivers An array of ETH receivers with their corresponding shares.
    function _setReceivers(Receiver[] memory _aixReceivers, Receiver[] memory _ethReceivers) internal {
        uint256 sumSharesAix = 0;
        uint256 sumSharesEth = 0;
        delete aixReceivers;
        delete ethReceivers;

        for (uint256 i = 0; i < _aixReceivers.length; i++) {
            require(_aixReceivers[i].share != 0, "AIXTreasuryUpgradeable: Wrong AIX share");
            sumSharesAix += _aixReceivers[i].share;
            aixReceivers.push(_aixReceivers[i]);
        }

        for (uint256 i = 0; i < _ethReceivers.length; i++) {
            require(_ethReceivers[i].share != 0, "AIXTreasuryUpgradeable: Wrong ETH share");
            sumSharesEth += _ethReceivers[i].share;
            ethReceivers.push(_ethReceivers[i]);
        }

        require(sumSharesAix + sumSharesEth == DENOMINATOR, "AIXTreasuryUpgradeable: Wrong total shares");

        totalAixShares = sumSharesAix;
        totalEthShares = sumSharesEth;

        emit ReceiversSet(aixReceivers, ethReceivers);
    }

    /// @notice Distributes the AIX tokens and ETH according to the predefined shares.
    function distribute(uint256 amount, uint256 minETHPerAIXPrice) external nonReentrant {
        if (amount == 0) {
            amount = aix.balanceOf(address(this));
            if (amount == 0) {
                return;
            }
        }
        if (!anyoneCanDistribute) {
            require(hasRole(DISTRIBUTOR_ROLE, msg.sender), "AIXTreasuryUpgradeable: Not a distributor");
        }

        uint256 aixBalance = aix.balanceOf(address(this));
        require(aixBalance >= amount, "AIXTreasuryUpgradeable: Insufficient AIX balance");

        // Distribute AIX tokens
        for (uint256 i = 0; i < aixReceivers.length; ++i) {
            address _receiver = aixReceivers[i].receiver;
            uint256 _share = aixReceivers[i].share;
            uint256 amountShare = (amount * _share) / DENOMINATOR;
            aix.safeTransfer(_receiver, amountShare);
            if (aixReceivers[i].doCallback) {
                IOnRewardsReceived(_receiver).onRewardsAIXReceived();
            }
            emit Distributed(address(aix), _receiver, amountShare);
        }

        // Convert remaining AIX to ETH and distribute
        uint256 remainingAIX = amount * totalEthShares / DENOMINATOR;
        if (remainingAIX > 0) {
            aix.safeApprove(address(uniswapRouter), remainingAIX);
            address[] memory path = new address[](2);
            path[0] = address(aix);
            path[1] = weth;

            uint256 ethOut = (remainingAIX * minETHPerAIXPrice) / (10**18);
            uint256[] memory amounts = uniswapRouter.swapExactTokensForETH(
                remainingAIX,
                ethOut,
                path,
                address(this),
                block.timestamp
            );
            require(amounts[1] >= ethOut, "AIXTreasuryUpgradeable: Insufficient output amount");
            emit TokensSwapped(remainingAIX, amounts[1]);

            uint256 totalETH = address(this).balance;
            for (uint256 i = 0; i < ethReceivers.length; ++i) {
                address _receiver = ethReceivers[i].receiver;
                uint256 _share = ethReceivers[i].share;
                uint256 amountShare = (totalETH * _share) / totalEthShares;
                safeTransferETH(_receiver, amountShare);
                if (ethReceivers[i].doCallback) {
                    IOnRewardsReceived(_receiver).onRewardsETHReceived();
                }
                emit Distributed(address(0), _receiver, amountShare);
            }
        }
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "ETH transfer failed");
        emit TransferETH(to, value);
    }

    /// @notice Allows the contract to receive ETH.
    receive() external payable {}
}
