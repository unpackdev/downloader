// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./IUniswapV2Router02.sol";
import "./ReentrancyGuardUpgradeable.sol";

interface IOnRewardsReceived {
    function onRewardsSAGEReceived() external;
    function onRewardsETHReceived() external;
}

/// @title SAGETreasury
/// @notice A contract for managing the distribution of SAGE tokens and ETH based on predefined shares.
contract SAGETreasury is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    event TransferETH(address indexed to, uint256 value);
    event AnyoneCanDistributeSet(bool value);
    event ReceiversSet(Receiver[] sageReceivers, Receiver[] ethReceivers);
    event Distributed(address indexed token, address indexed receiver, uint256 amount);
    event TokensSwapped(uint256 sageAmount, uint256 ethAmount);

    // 0xfbd454f36a7e1a388bd6fc3ab10d434aa4578f811acbbcf33afb1c697486313c
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    uint256 public constant DENOMINATOR = 10_000;

    IERC20 public sage;
    IUniswapV2Router02 public uniswapRouter;
    address public weth;
    bool public anyoneCanDistribute;

    struct Receiver {
        uint256 share;
        address receiver;
        bool doCallback;
    }

    Receiver[] public sageReceivers;
    Receiver[] public ethReceivers;
    uint256 public totalSageShares;
    uint256 public totalEthShares;

    /// @notice Initializes the contract with the given parameters.
    /// @param _sage The address of the SAGE token.
    /// @param _uniswapRouter The address of the Uniswap V2 router.
    /// @param _weth The address of the wrapped ETH token.
    /// @param _sageReceivers An array of SAGE receivers with their corresponding shares.
    /// @param _ethReceivers An array of ETH receivers with their corresponding shares.
    function initialize(
        IERC20 _sage,
        address _uniswapRouter,
        address _weth,
        Receiver[] memory _sageReceivers,
        Receiver[] memory _ethReceivers
    ) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        sage = _sage;
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        weth = _weth;
        _setReceivers(_sageReceivers, _ethReceivers);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DISTRIBUTOR_ROLE, msg.sender);
    }

    /// @notice Sets the `anyoneCanDistribute` flag which allows or prevents anyone from distributing tokens.
    /// @param value The new value of the `anyoneCanDistribute` flag.
    function setAnyoneCanDistribute(bool value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        anyoneCanDistribute = value;
        emit AnyoneCanDistributeSet(value);
    }

    /// @notice Sets the SAGE and ETH receivers along with their shares.
    /// @param _sageReceivers An array of SAGE receivers with their corresponding shares.
    /// @param _ethReceivers An array of ETH receivers with their corresponding shares.
    function setReceivers(Receiver[] memory _sageReceivers, Receiver[] memory _ethReceivers) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setReceivers(_sageReceivers, _ethReceivers);
    }

    /// @notice Internal function to set the SAGE and ETH receivers along with their shares.
    /// @param _sageReceivers An array of SAGE receivers with their corresponding shares.
    /// @param _ethReceivers An array of ETH receivers with their corresponding shares.
    function _setReceivers(Receiver[] memory _sageReceivers, Receiver[] memory _ethReceivers) internal {
        uint256 sumSharesSage = 0;
        uint256 sumSharesEth = 0;
        delete sageReceivers;
        delete ethReceivers;

        for (uint256 i = 0; i < _sageReceivers.length; i++) {
            require(_sageReceivers[i].share != 0, "SAGETreasuryUpgradeable: Wrong SAGE share");
            sumSharesSage += _sageReceivers[i].share;
            sageReceivers.push(_sageReceivers[i]);
        }

        for (uint256 i = 0; i < _ethReceivers.length; i++) {
            require(_ethReceivers[i].share != 0, "SAGETreasuryUpgradeable: Wrong ETH share");
            sumSharesEth += _ethReceivers[i].share;
            ethReceivers.push(_ethReceivers[i]);
        }

        require(sumSharesSage + sumSharesEth == DENOMINATOR, "SAGETreasuryUpgradeable: Wrong total shares");

        totalSageShares = sumSharesSage;
        totalEthShares = sumSharesEth;

        emit ReceiversSet(sageReceivers, ethReceivers);
    }

    /// @notice Distributes the SAGE tokens and ETH according to the predefined shares.
    function distribute(uint256 amount, uint256 minETHPerSAGEPrice) external nonReentrant {
        if (amount == 0) {
            amount = sage.balanceOf(address(this));
            if (amount == 0) {
                return;
            }
        }
        if (!anyoneCanDistribute) {
            require(hasRole(DISTRIBUTOR_ROLE, msg.sender), "SAGETreasuryUpgradeable: Not a distributor");
        }

        uint256 sageBalance = sage.balanceOf(address(this));
        require(sageBalance >= amount, "SAGETreasuryUpgradeable: Insufficient SAGE balance");

        // Distribute SAGE tokens
        for (uint256 i = 0; i < sageReceivers.length; ++i) {
            address _receiver = sageReceivers[i].receiver;
            uint256 _share = sageReceivers[i].share;
            uint256 amountShare = (amount * _share) / DENOMINATOR;
            sage.safeTransfer(_receiver, amountShare);
            if (sageReceivers[i].doCallback) {
                IOnRewardsReceived(_receiver).onRewardsSAGEReceived();
            }
            emit Distributed(address(sage), _receiver, amountShare);
        }

        // Convert remaining SAGE to ETH and distribute
        uint256 remainingSAGE = amount * totalEthShares / DENOMINATOR;
        if (remainingSAGE > 0) {
            sage.safeApprove(address(uniswapRouter), remainingSAGE);
            address[] memory path = new address[](2);
            path[0] = address(sage);
            path[1] = weth;

            uint256 ethOut = (remainingSAGE * minETHPerSAGEPrice) / (10**18);
            uint256[] memory amounts = uniswapRouter.swapExactTokensForETH(
                remainingSAGE,
                ethOut,
                path,
                address(this),
                block.timestamp
            );
            require(amounts[1] >= ethOut, "SAGETreasuryUpgradeable: Insufficient output amount");
            emit TokensSwapped(remainingSAGE, amounts[1]);

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
