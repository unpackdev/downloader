// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;
pragma abicoder v2;

import "./Governed.sol";
import "./IDividendPool.sol";
import "./AccessControlEnumerable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Pair.sol";
import "./IWETH9.sol";

contract FeeManager is Governed, AccessControlEnumerable {
    using SafeMath for uint256;

    bytes32 public constant FEE_MANAGER_ADMIN_ROLE =
        keccak256("FEE_MANAGER_ADMIN_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant DEX_ROLE = keccak256("DEX_ROLE");

    address public dividendPool;
    address public rewardToken;
    address public weth9;

    event DividendPoolUpdated(address pool);
    event RewardTokenUpdated(address pool);
    event FundRescued(address token, uint256 amount);
    event Rewarded(address token, uint256 amount, uint256 rewardAmount);

    constructor(
        address gov_,
        address dividendPool_,
        address rewardToken_,
        address weth9_
    ) {
        Governed.initialize(gov_);
        dividendPool = dividendPool_;
        rewardToken = rewardToken_;
        weth9 = weth9_;
        _setRoleAdmin(FEE_MANAGER_ADMIN_ROLE, FEE_MANAGER_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, FEE_MANAGER_ADMIN_ROLE);
        _setRoleAdmin(DEX_ROLE, FEE_MANAGER_ADMIN_ROLE);

        // deployer + self administration
        _setupRole(FEE_MANAGER_ADMIN_ROLE, gov_);
        _setupRole(FEE_MANAGER_ADMIN_ROLE, address(this));
    }

    modifier onlyAllowedDex(address dex) {
        require(hasRole(DEX_ROLE, dex), "Not an allowed dex");
        _;
    }

    receive() external payable {
        IWETH9(weth9).deposit{value: msg.value}();
    }

    function updateDividendPool(address dividendPool_) public governed {
        dividendPool = dividendPool_;
        emit DividendPoolUpdated(dividendPool_);
    }

    function updateRewardToken(address rewardToken_) public governed {
        rewardToken = rewardToken_;
        emit RewardTokenUpdated(rewardToken_);
    }

    function rescueFund(address erc20, uint256 amount) public governed {
        IERC20(erc20).transfer(gov(), amount);
        emit FundRescued(erc20, amount);
    }

    function rewindUniV2(address pair, uint256 amount)
        public
        onlyRole(EXECUTOR_ROLE)
    {
        IUniswapV2Pair(pair).transfer(pair, amount); // send liquidity to pair
        IUniswapV2Pair(pair).burn(address(this));
    }

    function swap(
        address dex,
        address srcToken,
        uint256 amount,
        bytes calldata swapData
    ) public onlyRole(EXECUTOR_ROLE) onlyAllowedDex(dex) {
        require(
            IERC20(srcToken).balanceOf(address(this)) >= amount,
            "FeeManager: NOT ENOUGH BALANCE"
        );
        require(srcToken != rewardToken, "FeeManager: SPENDING YAPE");
        uint256 prevBal = IERC20(rewardToken).balanceOf(address(this));
        IERC20(srcToken).approve(dex, amount);
        (bool success, bytes memory result) = dex.call(swapData);
        require(
            success,
            string(abi.encodePacked("failed to swap tokens: ", result))
        );
        uint256 swappedAmount = IERC20(rewardToken)
        .balanceOf(address(this))
        .sub(prevBal);
        IERC20(rewardToken).approve(dividendPool, swappedAmount);
        IDividendPool(dividendPool).distribute(rewardToken, swappedAmount);
        emit Rewarded(srcToken, amount, swappedAmount);
    }
}
