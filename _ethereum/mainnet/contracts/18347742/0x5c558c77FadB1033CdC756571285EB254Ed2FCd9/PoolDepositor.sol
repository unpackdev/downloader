// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Interfaces.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Address.sol";

/**
 * @title   PoolDepositor
 * @author  WombexFinance
 * @notice  Allows to deposit underlying tokens and wrap them in lp tokens
 */
contract PoolDepositor is Ownable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    struct ApprovePool {
        address pool;
        address[] tokens;
    }

    address public weth;
    address public booster;
    address public voterProxy;
    address public masterWombat;
    mapping (address => uint256) public lpTokenToPid;

    /**
     * @param _weth             WETH
     * @param _booster          Booster
     * @param _masterWombat     MasterWombat
     */
    constructor(address _weth, address _booster, address _masterWombat) public Ownable() {
        weth =  _weth;
        booster =  _booster;
        voterProxy = IBooster(_booster).voterProxy();
        masterWombat = _masterWombat;
    }

    function updateBooster() public onlyOwner {
        booster = IStaker(voterProxy).operator();
    }

    /**
     * @notice Approve spending of router tokens by pool
     * @dev Needs to be done after asset deployment for router to be able to support the tokens
     */
    function approveSpendingMultiplePools(uint256[] calldata pids) public onlyOwner {
        for (uint256 i; i < pids.length; i++) {
            IBooster.PoolInfo memory p = IBooster(booster).poolInfo(pids[i]);
            uint256 wmPid = IStaker(voterProxy).lpTokenToPid(p.gauge, p.lptoken);

            address[] memory tokens = new address[](2);
            tokens[0] = p.lptoken;
            tokens[1] = IAsset(p.lptoken).underlyingToken();

            address[] memory boosterTokens = new address[](1);
            boosterTokens[0] = p.lptoken;

            approveSpendingByPool(tokens, IAsset(p.lptoken).pool());
            approveSpendingByPool(boosterTokens, booster);
        }
    }

    /**
     * @notice Approve spending of router tokens by pool
     * @dev Needs to be done after asset deployment for router to be able to support the tokens
     * @param tokens    array of tokens to be approved
     * @param pool      to be approved to spend
     */
    function approveSpendingByPool(address[] memory tokens, address pool) public onlyOwner {
        for (uint256 i; i < tokens.length; i++) {
            if (IERC20(tokens[i]).allowance(address(this), pool) != 0) {
                IERC20(tokens[i]).safeApprove(pool, 0);
            }
            IERC20(tokens[i]).safeApprove(pool, type(uint256).max);
        }
    }

    /**
     * @notice Approve spending of router tokens by pool and booster
     * @dev Needs to be done after asset deployment for router to be able to support the tokens
     * @param tokens    array of tokens to be approved
     * @param pool      to be approved to spend
     */
    function approveSpendingByPoolAndBooster(address[] memory tokens, address pool) public onlyOwner {
        approveSpendingByPool(tokens, pool);
        approveSpendingByPool(tokens, booster);
    }

    function resqueTokens(address[] calldata _tokens, address _recipient) external onlyOwner {
        for (uint256 i; i < _tokens.length; i++) {
            IERC20(_tokens[i]).safeTransfer(_recipient, IERC20(_tokens[i]).balanceOf(address(this)));
        }
    }

    function resqueNative(address payable _recipient) external onlyOwner {
        _recipient.sendValue(address(this).balance);
    }

    function setBoosterLpTokensPid() external {
        uint256 poolLength = IBooster(booster).poolLength();

        for (uint256 i = 0; i < poolLength; i++) {
            IBooster.PoolInfo memory p = IBooster(booster).poolInfo(i);
            lpTokenToPid[p.lptoken] = i;
        }
    }

    receive() external payable {}

    function depositNative(address _lptoken, uint256 _minLiquidity, uint256 _deadline, bool _stake) external payable {
        uint256 amount = msg.value;
        IWETH(weth).deposit{value: amount}();
        _deposit(_lptoken, weth, amount, _minLiquidity, _deadline, _stake);
    }

    function withdrawNative(address _lptoken, address _underlying, uint256 _amount, uint256 _minOut, uint256 _deadline, address payable _recipient) external {
        uint256 wethBalanceBefore = IERC20(weth).balanceOf(address(this));
        _withdraw(_lptoken, _underlying, _amount, _minOut, _deadline, address(this));
        uint256 wethAmount = IERC20(weth).balanceOf(address(this)) - wethBalanceBefore;

        IWETH(weth).withdraw(wethAmount);
        _recipient.sendValue(wethAmount);
    }

    function deposit(address _lptoken, uint256 _amount, uint256 _minLiquidity, uint256 _deadline, bool _stake) public {
        address underlying = IAsset(_lptoken).underlyingToken();
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), _amount);
        _deposit(_lptoken, underlying, _amount, _minLiquidity, _deadline, _stake);
    }

    function _deposit(address _lptoken, address _underlying, uint256 _amount, uint256 _minLiquidity, uint256 _deadline, bool _stake) internal {
        address pool = IAsset(_lptoken).pool();
        uint256 balanceBefore = IERC20(_lptoken).balanceOf(address(this));
        IPool(pool).deposit(_underlying, _amount, _minLiquidity, address(this), _deadline, false);
        uint256 resultLpAmount = IERC20(_lptoken).balanceOf(address(this)) - balanceBefore;

        IBooster(booster).depositFor(lpTokenToPid[_lptoken], resultLpAmount, _stake, msg.sender);
    }

    function withdraw(address _lptoken, uint256 _amount, uint256 _minOut, uint256 _deadline, address _recipient) public {
        _withdraw(_lptoken, IAsset(_lptoken).underlyingToken(), _amount, _minOut, _deadline, _recipient);
    }

    function withdrawFromOtherAsset(address _lptoken, address _underlying, uint256 _amount, uint256 _minOut, uint256 _deadline, address _recipient) public {
        _withdraw(_lptoken, _underlying, _amount, _minOut, _deadline, _recipient);
    }

    function _withdraw(address _lptoken, address _underlying, uint256 _amount, uint256 _minOut, uint256 _deadline, address _recipient) internal {
        IRewards(getLpTokenCrvRewards(_lptoken)).withdraw(_amount, address(this), msg.sender);

        address pool = IAsset(_lptoken).pool();
        address lpTokenUnderlying = IAsset(_lptoken).underlyingToken();
        if (lpTokenUnderlying == _underlying) {
            IPool(pool).withdraw(_underlying, _amount, _minOut, _recipient, _deadline);
        } else {
            IPool(pool).withdrawFromOtherAsset(lpTokenUnderlying, _underlying, _amount, _minOut, _recipient, _deadline);
        }
    }

    function getLpTokenCrvRewards(address _lptoken) public view returns(address) {
        IBooster.PoolInfo memory p = IBooster(booster).poolInfo(lpTokenToPid[_lptoken]);
        return p.crvRewards;
    }

    function getDepositAmountOut(
        address _lptoken,
        uint256 _amount
    ) external view returns (uint256 liquidity, uint256 reward) {
        reward = 0; // backward compatibility with clients
        address pool = IAsset(_lptoken).pool();
        address underlying = IAsset(_lptoken).underlyingToken();
        liquidity = staticCallAndGetUint(pool, abi.encodeWithSelector(IPool.quotePotentialDeposit.selector, underlying, _amount));
    }

    function getTokenDecimals(address _token) public view returns (uint8 decimals) {
        try ERC20(_token).decimals() returns (uint8 _decimals) {
            decimals = _decimals;
        } catch {
            decimals = uint8(18);
        }
    }

    function staticCallAndGetUint(address _contract, bytes memory _argsData) public view returns (uint256 amount){
        (bool success, bytes memory data) = _contract.staticcall(_argsData);
        require(success, "staticCallAndGetUint call failed");

        assembly {
            amount := mload(add(data, 32))
        }
    }

    function getWithdrawAmountOut(
        address _lptoken,
        address _tokenOut,
        uint256 _amount
    ) external view returns (uint256 amount, uint256 fee) {
        fee = 0; // backward compatibility with clients
        address pool = IAsset(_lptoken).pool();
        address lpTokenUnderlying = IAsset(_lptoken).underlyingToken();
        if (_tokenOut == lpTokenUnderlying) {
            amount = staticCallAndGetUint(pool, abi.encodeWithSelector(IPool.quotePotentialWithdraw.selector, lpTokenUnderlying, _amount));
        } else {
            amount = staticCallAndGetUint(pool, abi.encodeWithSelector(IPool.quotePotentialWithdrawFromOtherAsset.selector, lpTokenUnderlying, _tokenOut, _amount));
        }
    }
}
