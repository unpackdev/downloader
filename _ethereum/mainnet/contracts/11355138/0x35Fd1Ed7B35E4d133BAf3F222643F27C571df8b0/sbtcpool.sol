pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";

import "./Rewards.sol";
import "./Token.sol";
// import "./IOneSplitAudit.sol";
import "./IUniswapV2Router02.sol";

import "./Gauge.sol";
import "./Mintr.sol";
import "./Curve.sol";
import "./ProfitNotifier.sol";

contract sBTCCRVStrategy is ProfitNotifier {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant curvesPool = address(0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714);
    address public constant mainAsset = address(0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3); //renBTC-wBTC CRV LP token
    address public constant curveMinter = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    address public constant curvesGauge = address(0x705350c4BcD35c9441419DdD5d2f097d7a55410F);
    address public constant uniswapRouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant wbtc = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    address[] public CRV2WBTC;

    address public vault;
    address public governance;
    address public agent;

    constructor(address _vault, address _agent) {
        vault = _vault;
        governance = msg.sender;
        agent = _agent;

        CRV2WBTC = [crv, weth, wbtc];
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

    function underlyingBalanceGauge() public view returns(uint256){
        return Gauge(curvesGauge).balanceOf(address(this));
    }

    function underlyingBalance() public view returns(uint256){
        return IERC20(mainAsset).balanceOf(address(this)).add(underlyingBalanceGauge());
    }

    function _withdrawStrategy(uint256 _amount) internal returns(uint256) {
        uint256 _before = IERC20(mainAsset).balanceOf(address(this));
        Gauge(curvesGauge).withdraw(_amount);
        uint256 _after = IERC20(mainAsset).balanceOf(address(this));
        return _after.sub(_before);
    }

    function _withdrawStrategyAll() internal {
        uint256 _staked = Gauge(curvesGauge).balanceOf(address(this));
        Gauge(curvesGauge).withdraw(_staked);
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
        if(_balance > 0) {
            // Stake
            IERC20(mainAsset).safeApprove(curvesGauge, 0);
            IERC20(mainAsset).safeApprove(curvesGauge, _balance);
            Gauge(curvesGauge).deposit(_balance);
        }
    }

    function _harvestProfits() internal {
        uint256 _balanceBeforewBTC = IERC20(wbtc).balanceOf(address(this));
        Mintr(curveMinter).mint(curvesGauge);
        uint256 _crvBalance = IERC20(crv).balanceOf(address(this));
        if(_crvBalance > 0){
            IERC20(crv).safeApprove(uniswapRouter, 0);
            IERC20(crv).safeApprove(uniswapRouter, _crvBalance);
            IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(_crvBalance, uint256(0), CRV2WBTC, address(this), block.timestamp.add(1800));
            uint256 _balanceAfterwBTC = IERC20(wbtc).balanceOf(address(this));
            notifyProfit(_balanceBeforewBTC, _balanceAfterwBTC, wbtc);
            uint256 _profit = IERC20(wbtc).balanceOf(address(this));
            if(_profit > 0){
                IERC20(wbtc).safeApprove(curvesPool, 0);
                IERC20(wbtc).safeApprove(curvesPool, _profit);
                ICurveFi(curvesPool).add_liquidity([uint256(0), _profit, uint256(0)], 0); // Supply wBTC
            }
        }
    }

    function harvestProfits() public {
        require(msg.sender == agent || msg.sender == governance, '!governance');
        _harvestProfits();
        deposit();
    }
}