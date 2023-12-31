pragma solidity ^0.8.4;

// SPDX-License-Identifier: BSL-1.1

import "./Ownable.sol";
import "./IDarwin.sol";

import "./IDarwinSwapRouter.sol";
import "./IDarwinSwapPair.sol";
import "./IDarwinSwapFactory.sol";
import "./IERC20.sol";
import "./IDarwinLiquidityBundles.sol";
import "./IMasterChef.sol";

contract DarwinLiquidityBundles is Ownable, IDarwinLiquidityBundles {

    /*///////////////////////////////////////////////////////////////
                                Variables
    //////////////////////////////////////////////////////////////*/

    IDarwinSwapFactory public darwinFactory;
    IDarwinMasterChef public masterChef;
    IDarwinSwapRouter public darwinRouter;
    address public WETH;
    uint256 public constant LOCK_PERIOD = 365 days;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    // User address -> LP Token address -> User info
    mapping(address => mapping(address => User)) public userInfo;
    // Token address -> total amount of LP for this bundle
    mapping(address => uint256) public totalLpAmount;

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() {
        darwinFactory = IDarwinSwapFactory(msg.sender);
    }

    function initialize(address _darwinRouter, IDarwinMasterChef _masterChef, address _WETH) external {
        require(msg.sender == address(darwinFactory), "DarwinLiquidityBundles: INVALID");
        masterChef = _masterChef;
        darwinRouter = IDarwinSwapRouter(_darwinRouter);
        WETH = _WETH;
    }

    function tokenInfo(address _token) public view returns (uint tokenAmount, uint priceInWeth) {
        tokenAmount = IERC20(_token).balanceOf(address(this));

        if (darwinFactory.getPair(_token, WETH) == address(0)) {
            return (tokenAmount, 0);
        }

        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = WETH;

        // get pair price in WETH on DarwinSwap
        try darwinRouter.getAmountsOut(10 ** IERC20(_token).decimals(), path) returns (uint256[] memory prices) {
            priceInWeth = prices[1];
        } catch {
            priceInWeth = 0;
        }
    }

    /// @notice Enter a Bundle
    /// @dev This functions takes an amount of ETH from a user and pairs it with a X amount of _token (already present in the contract), and locks it for a year. After the lock ends, the user will be able to not only withdraw the ETH he provided, but also the respective token amount.
    /// @param _token The bundle token address
    /// @param _desiredTokenAmount The amount of the token to pair ETH with
    function enterBundle(
        address _token,
        uint _desiredTokenAmount
    ) external payable {
        (uint tokenAmount, uint priceInWeth) = tokenInfo(_token);
        if (_desiredTokenAmount > tokenAmount) {
            _desiredTokenAmount = tokenAmount;
        }

        uint256 ethValue = (_desiredTokenAmount * priceInWeth) / (10 ** IERC20(_token).decimals());
        require(msg.value >= ethValue, "DarwinLiquidityBundles: INSUFFICIENT_ETH");
        if (ethValue == 0) {
            ethValue = msg.value;
        }

        IERC20(_token).approve(address(darwinRouter), _desiredTokenAmount);
        (uint amountToken, uint amountETH, uint liquidity) = darwinRouter.addLiquidityETH{value: ethValue}(
            _token,
            _desiredTokenAmount,
            0,
            0,
            address(this),
            block.timestamp + 600
        );

        User storage user = userInfo[msg.sender][_token];

        totalLpAmount[_token] += liquidity;
        user.lpAmount += liquidity;
        user.lockEnd = block.timestamp + LOCK_PERIOD;
        user.bundledEth += amountETH;
        user.bundledToken += amountToken;

        // refund dust ETH, if any
        if (msg.value > amountETH) {
            (bool success,) = payable(msg.sender).call{value: (msg.value - amountETH)}("");
            require(success, "DarwinLiquidityBundles: ETH_TRANSFER_FAILED");
        }

        if (address(masterChef) != address(0)) {
            address pair = darwinFactory.getPair(_token, WETH);
            if (masterChef.poolExistence(IERC20(pair))) {
                IERC20(pair).approve(address(masterChef), liquidity);
                masterChef.depositByLPToken(IERC20(pair), liquidity, false, 0);
                user.inMasterchef = true;
            }
        }

        emit EnterBundle(msg.sender, amountToken, amountETH, block.timestamp, block.timestamp + LOCK_PERIOD);
    }

    /// @notice Exit from a Bundle
    /// @dev If the lock period of the interested user on the interested token has ended, withdraws the bundled LP and burns eventual earned darwin (if the bundle was an inMasterchef one)
    /// @param _token The bundle token address
    function exitBundle(
        address _token
    ) external {
        User storage user = userInfo[msg.sender][_token];

        require(user.lockEnd <= block.timestamp, "DarwinLiquidityBundles: LOCK_NOT_ENDED");
        require(user.lpAmount > 0, "DarwinLiquidityBundles: NO_BUNDLED_LP");

        // If pool exists on masterchef and bundle is staked on it, withdraw from it
        uint lpAmount;
        if (address(masterChef) != address(0)) {
            address pair = darwinFactory.getPair(_token, WETH);
            if (masterChef.poolExistence(IERC20(pair)) && user.inMasterchef) {
                lpAmount = IERC20(pair).balanceOf(address(this));
                uint pid;
                IDarwinMasterChef.PoolInfo[] memory poolInfo = masterChef.poolInfo();
                for (uint i = 0; i < poolInfo.length; i++) {
                    if (address(poolInfo[i].lpToken) == pair) {
                        pid = i;
                    }
                }
                masterChef.withdrawByLPToken(IERC20(pair), masterChef.userInfo(pid, address(this)).amount);
                lpAmount = IERC20(pair).balanceOf(address(this)) - lpAmount;
                user.inMasterchef = false;
                // Burn eventual earned darwin
                if (masterChef.darwin().balanceOf(address(this)) > 0) {
                    IDarwin(address(masterChef.darwin())).burn(masterChef.darwin().balanceOf(address(this)));
                }
            }
        }
        if (lpAmount == 0) {
            lpAmount = user.lpAmount;
        }

        IERC20(darwinFactory.getPair(_token, WETH)).approve(address(darwinRouter), lpAmount);
        (uint256 amountToken, uint256 amountETH) = darwinRouter.removeLiquidityETH(
            _token,
            lpAmount,
            0,
            0,
            address(msg.sender),
            block.timestamp + 600
        );

        totalLpAmount[_token] -= user.lpAmount;
        user.lpAmount = 0;
        user.bundledEth = 0;
        user.bundledToken = 0;

        emit ExitBundle(msg.sender, amountToken, amountETH, block.timestamp);
    }

    /// @notice Harvest Darwin from an inMasterchef bundle, and re-lock the bundle for a year
    /// @dev If the lock period of the interested user on the interested token has ended, withdraws the earned Darwin and locks the bundle in for 1 more year
    /// @param _token The bundle token address
    function harvestAndRelock(
        address _token
    ) external {
        User storage user = userInfo[msg.sender][_token];

        require(user.lockEnd <= block.timestamp, "DarwinLiquidityBundles: LOCK_NOT_ENDED");
        require(user.lpAmount > 0 && user.inMasterchef, "DarwinLiquidityBundles: NO_BUNDLE_OR_NOT_IN_MASTERCHEF");

        address pair = darwinFactory.getPair(_token, WETH);
        masterChef.withdrawByLPToken(IERC20(pair), 0);

        // Send eventual earned darwin to user
        uint amountDarwin = masterChef.darwin().balanceOf(address(this));
        if (amountDarwin > 0) {
            masterChef.darwin().transfer(msg.sender, amountDarwin);
        }

        // Re-lock for 1 year
        user.lockEnd = block.timestamp + LOCK_PERIOD;

        emit HarvestAndRelock(msg.sender, amountDarwin, block.timestamp);
    }

    /// @notice Updates a LP token by destructuring it and eventually swapping
    /// @param _lpToken The interested LP token address
    function update(address _lpToken) external {
        IDarwinSwapPair pair = IDarwinSwapPair(_lpToken);
        uint liquidity = IERC20(address(pair)).balanceOf(address(this));
        if (liquidity > 0) {
            IERC20(address(pair)).approve(address(darwinRouter), liquidity);
            address token = pair.token0() == WETH ? pair.token1() : pair.token0();
            address weth = pair.token0() == WETH ? pair.token0() : pair.token1();
            if (weth == WETH) {
                (, uint amountETH) = darwinRouter.removeLiquidityETH(token, liquidity, 0, 0, address(this), block.timestamp + 600);
                address[] memory path = new address[](2);
                path[0] = WETH;
                path[1] = token;
                darwinRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountETH}(0, path, address(this), block.timestamp + 600);
            } else {
                darwinRouter.removeLiquidity(token, weth, liquidity, 0, 0, address(this), block.timestamp + 600);
            }
        }
    }

    // How much TOKEN and ETH is being holded in the bundle
    function holdings(address _user, address _token) external view returns(uint256 eth, uint256 token) {
        User memory user = userInfo[_user][_token];
        (uint reserve0, uint reserve1,) = IDarwinSwapPair(darwinFactory.getPair(_token, WETH)).getReserves();
        uint reserveEth = IDarwinSwapPair(darwinFactory.getPair(_token, WETH)).token0() == darwinRouter.WETH() ? reserve0 : reserve1;
        uint reserveToken = IDarwinSwapPair(darwinFactory.getPair(_token, WETH)).token0() == darwinRouter.WETH() ? reserve1 : reserve0;
        reserveEth = (reserveEth * user.lpAmount) / IERC20(darwinFactory.getPair(_token, WETH)).totalSupply();
        reserveToken = (reserveToken * user.lpAmount) / IERC20(darwinFactory.getPair(_token, WETH)).totalSupply();
        eth = reserveEth;
        token = reserveToken;
    }

    // (For bundles that have a respective masterchef farm) - How much pending darwin for this bundle
    function pendingDarwin(address _user, address _token) external view returns(uint256) {
        if (address(masterChef) != address(0)) {
            User memory user = userInfo[_user][_token];
            if (user.inMasterchef) {
                uint pid;
                IDarwinMasterChef.PoolInfo[] memory poolInfo = masterChef.poolInfo();
                for (uint i = 0; i < poolInfo.length; i++) {
                    if (address(poolInfo[i].lpToken) == darwinFactory.getPair(_token, WETH)) {
                        pid = i;
                    }
                }
                if (totalLpAmount[_token] > 0) {
                    return (masterChef.pendingDarwin(pid, address(this)) * user.lpAmount) / totalLpAmount[_token];
                } else {
                    return 0;
                }
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }

    // (For bundles that didn't have a respective masterchef farm at first but after bundling they have one) - Stake bundled LP in MasterChef to earn darwin
    function stakeBundleInMasterChef(address _token) external {
        User storage user = userInfo[msg.sender][_token];
        require(user.lpAmount > 0 && !user.inMasterchef, "DarwinLiquidityBundles: NO_BUNDLE_OR_ALREADY_STAKED");
        
        address pair = darwinFactory.getPair(_token, WETH);
        require (masterChef.poolExistence(IERC20(pair)), "DarwinLiquidityBundles: NO_SUCH_POOL_IN_MASTERCHEF");
        
        IERC20(pair).approve(address(masterChef), user.lpAmount);
        masterChef.depositByLPToken(IERC20(pair), user.lpAmount, false, 0);
        user.inMasterchef = true;

        emit StakeInMasterchef(msg.sender, user.lpAmount, block.timestamp);
    }


    receive() external payable {}
}