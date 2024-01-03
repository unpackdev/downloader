pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IMasterChef.sol";

import "./ProfitNotifier.sol";

contract sushiLPStrategy is ProfitNotifier {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant uniswapRouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant sushiRouter = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    address public constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    address public vault;
    address public governance;
    address public agent;
    
    address public mainAsset;
    address public sushiRewardToken;
    address public masterChef;
    uint256 public rewardPoolId;
    address public lpToken0;
    address public lpToken1;

    mapping(address => address[]) routes;

    constructor(
        address _vault,
        address _mainAsset,
        address _sushiRewardToken,
        address _masterChef,
        uint256 _rpid,
        address _agent
        ) {
        vault = _vault;
        governance = msg.sender;
        agent = _agent;

        mainAsset = _mainAsset;
        sushiRewardToken = _sushiRewardToken;
        masterChef = _masterChef;
        rewardPoolId = _rpid;

        address _lptoken;
        (_lptoken,,,) = IMasterChef(masterChef).poolInfo(rewardPoolId);
        require(_lptoken == mainAsset, 'MasterChef reward pool does not exist!');

        lpToken0 = IUniswapV2Pair(mainAsset).token0();
        lpToken1 = IUniswapV2Pair(mainAsset).token1();

        routes[lpToken0] = [sushiRewardToken, weth, lpToken0];
        routes[lpToken1] = [sushiRewardToken, lpToken1];
    }

    function setRewardForwarder(address _new) external {
        require(msg.sender == governance, '!governance');
        feeRewardForwarder = _new;
    }

    function setProfitSharingDenominator(uint256 _new) external {
        require(msg.sender == governance, '!governance');
        profitSharingDenominator = _new;
    }

    function setGovernance(address _gov) external {
        require(msg.sender == governance, '!governance');
        governance = _gov;
    }

    function setAgent(address _agent) external {
        require(msg.sender == governance, '!governance');
        agent = _agent;
    }

    function setVault(address _vault) external {
        require(msg.sender == governance, '!governance');
        vault = _vault;
    }

    function setRoute(address _token, address[] memory route) external {
        require(msg.sender == governance, '!governance');
        routes[_token] = route;
    }

    function underlyingBalanceStaked() public view returns(uint256){
        uint256 _balance;
        (_balance,) = IMasterChef(masterChef).userInfo(rewardPoolId, address(this));
        return _balance;
    }

    function underlyingBalance() public view returns(uint256){
        return IERC20(mainAsset).balanceOf(address(this)).add(underlyingBalanceStaked());
    }

    function _withdrawStrategy(uint256 _amount) internal returns(uint256) {
        uint256 _before = IERC20(mainAsset).balanceOf(address(this));
        IMasterChef(masterChef).withdraw(rewardPoolId, _amount);
        return IERC20(mainAsset).balanceOf(address(this)).sub(_before);
    }

    function _withdrawStrategyAll() internal {
        uint256 _staked = underlyingBalanceStaked();
        IMasterChef(masterChef).withdraw(rewardPoolId, _staked);
    }

    function withdraw(uint256 _amount) public {
        require(msg.sender == vault || msg.sender == governance, '!governance');
        uint256 _balance = IERC20(mainAsset).balanceOf(address(this));
        if(_amount > _balance){
            _amount = _withdrawStrategy(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        require(vault != address(0), 'burning funds');
        IERC20(mainAsset).safeTransfer(vault, _amount);
    }

    function liquidate() public {
        require(msg.sender == vault || msg.sender == governance, '!governance');
        // _harvestProfits();
        _withdrawStrategyAll();

        uint256 _balance = IERC20(mainAsset).balanceOf(address(this));
        require(vault != address(0), 'burning funds');
        IERC20(mainAsset).safeTransfer(vault, _balance);
    }

    function deposit() public {
        uint256 _balance = IERC20(mainAsset).balanceOf(address(this));
        if(_balance > 0){
            IERC20(mainAsset).safeApprove(masterChef, 0);
            IERC20(mainAsset).safeApprove(masterChef, _balance);
            IMasterChef(masterChef).deposit(rewardPoolId, _balance);
        }
    }

    function _harvestProfits() internal {
        uint256 _before = IERC20(mainAsset).balanceOf(address(this));
        _withdrawStrategyAll();
        uint256 _sushiBalance = IERC20(sushiRewardToken).balanceOf(address(this));
        if(_sushiBalance > 0){
            notifyProfit(0, _sushiBalance, sushiRewardToken);

            // Swap to lpTokens, then provide liquidity in exchange for mainAsset
            uint256 _remainingSushi = IERC20(sushiRewardToken).balanceOf(address(this));
            if(_remainingSushi > 0){
                IERC20(sushiRewardToken).safeApprove(uniswapRouter, 0);
                IERC20(sushiRewardToken).safeApprove(uniswapRouter, _remainingSushi);

                IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(_remainingSushi.div(2), uint256(0), routes[lpToken0], address(this), block.timestamp.add(1800));
                _remainingSushi = IERC20(sushiRewardToken).balanceOf(address(this));
                IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(_remainingSushi, uint256(0), routes[lpToken1], address(this), block.timestamp.add(1800));

                uint256 _token0bal = IERC20(lpToken0).balanceOf(address(this));
                uint256 _token1bal = IERC20(lpToken1).balanceOf(address(this));

                IERC20(lpToken0).safeApprove(sushiRouter, 0);
                IERC20(lpToken0).safeApprove(sushiRouter, _token0bal);
                IERC20(lpToken1).safeApprove(sushiRouter, 0);
                IERC20(lpToken1).safeApprove(sushiRouter, _token1bal);

                IUniswapV2Router02(sushiRouter).addLiquidity(lpToken0, lpToken1, _token0bal, _token1bal, 1, 1, address(this), block.timestamp.add(1800));
            }
        }
    }

    function harvestProfits() public {
        require(msg.sender == agent || msg.sender == governance, '!governance');
        _harvestProfits();
        deposit();
    }
}