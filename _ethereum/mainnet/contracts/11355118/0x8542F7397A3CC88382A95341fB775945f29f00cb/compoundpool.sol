pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";

import "./Rewards.sol";
import "./Token.sol";
import "./CTokenInterfaces.sol";
// import "./IOneSplitAudit.sol";
import "./IUniswapV2Router02.sol";

import "./Gauge.sol";
import "./Mintr.sol";
import "./Curve.sol";
import "./ProfitNotifier.sol";

contract crvcomppoolStrategy is ProfitNotifier {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant curvecompPool = address(0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56);
    address public constant mainAsset = address(0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2);
    address public constant curveMinter = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    address public constant curvecompGauge = address(0x7ca5b0a2910B33e9759DC7dDB0413949071D7575);
    address public constant uniswapRouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address public constant cDai = address(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    address[] public CRV2DAI;

    address public vault;
    address public governance;
    address public agent;

    constructor(address _vault, address _agent) {
        vault = _vault;
        governance = msg.sender;
        agent = _agent;

        CRV2DAI = [crv, weth, dai];
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
        return Gauge(curvecompGauge).balanceOf(address(this));
    }

    function underlyingBalance() public view returns(uint256){
        return IERC20(mainAsset).balanceOf(address(this)).add(underlyingBalanceGauge());
    }

    function _withdrawStrategy(uint256 _amount) internal returns(uint256) {
        uint256 _before = IERC20(mainAsset).balanceOf(address(this));
        Gauge(curvecompGauge).withdraw(_amount);
        uint256 _after = IERC20(mainAsset).balanceOf(address(this));
        return _after.sub(_before);
    }

    function _withdrawStrategyAll() internal {
        uint256 _staked = Gauge(curvecompGauge).balanceOf(address(this));
        Gauge(curvecompGauge).withdraw(_staked);
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
            IERC20(mainAsset).safeApprove(curvecompGauge, 0);
            IERC20(mainAsset).safeApprove(curvecompGauge, _balance);
            Gauge(curvecompGauge).deposit(_balance);
        }
    }

    function _harvestProfits() internal {
        uint256 _balanceBeforeDAI = IERC20(dai).balanceOf(address(this));
        Mintr(curveMinter).mint(curvecompGauge);
        uint256 _crvBalance = IERC20(crv).balanceOf(address(this));
        if(_crvBalance > 0){
            IERC20(crv).safeApprove(uniswapRouter, 0);
            IERC20(crv).safeApprove(uniswapRouter, _crvBalance);
            IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(_crvBalance, uint256(0), CRV2DAI, address(this), block.timestamp.add(1800));
            uint256 _balanceAfterDAI = IERC20(dai).balanceOf(address(this));
            notifyProfit(_balanceBeforeDAI, _balanceAfterDAI, dai);
            uint256 _profit = IERC20(dai).balanceOf(address(this));
            if(_profit > 0){

                // Convert to cDai
                IERC20(dai).safeApprove(cDai, 0);
                IERC20(dai).safeApprove(cDai, _profit);
                CErc20Interface(cDai).mint(_profit);
                // Deposit to pool
                uint256 _cBal = IERC20(cDai).balanceOf(address(this));
                IERC20(cDai).safeApprove(curvecompPool, 0);
                IERC20(cDai).safeApprove(curvecompPool, _cBal);
                ICurveFi(curvecompPool).add_liquidity([_cBal, uint256(0)], 0);
            }
        }
    }

    function harvestProfits() public {
        require(msg.sender == agent || msg.sender == governance, '!governance');
        _harvestProfits();
        deposit();
    }
}