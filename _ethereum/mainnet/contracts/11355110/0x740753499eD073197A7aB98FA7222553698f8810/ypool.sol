pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";

import "./Rewards.sol";
import "./Token.sol";
import "./IToken.sol";
// import "./IOneSplitAudit.sol";
import "./IUniswapV2Router02.sol";

import "./Gauge.sol";
import "./Mintr.sol";
import "./Curve.sol";
import "./ProfitNotifier.sol";

contract crvypoolStrategy is ProfitNotifier {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant curveYPool = address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
    address public constant mainAsset = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);
    address public constant curveMinter = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    address public constant curveYGauge = address(0xFA712EE4788C042e2B7BB55E6cb8ec569C4530c1);
    address public constant uniswapRouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address public constant yUSDT = address(0x83f798e925BcD4017Eb265844FDDAbb448f1707D);
    address[] public CRV2USDT;

    address public vault;
    address public governance;
    address public agent;

    constructor(address _vault, address _agent) {
        vault = _vault;
        governance = msg.sender;
        agent = _agent;

        CRV2USDT = [crv, weth, usdt];
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
        return Gauge(curveYGauge).balanceOf(address(this));
    }

    function underlyingBalance() public view returns(uint256){
        return IERC20(mainAsset).balanceOf(address(this)).add(underlyingBalanceGauge());
    }

    function _withdrawStrategy(uint256 _amount) internal returns(uint256) {
        uint256 _before = IERC20(mainAsset).balanceOf(address(this));
        Gauge(curveYGauge).withdraw(_amount);
        uint256 _after = IERC20(mainAsset).balanceOf(address(this));
        return _after.sub(_before);
    }

    function _withdrawStrategyAll() internal {
        uint256 _staked = Gauge(curveYGauge).balanceOf(address(this));
        Gauge(curveYGauge).withdraw(_staked);
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
            IERC20(mainAsset).safeApprove(curveYGauge, 0);
            IERC20(mainAsset).safeApprove(curveYGauge, _balance);
            Gauge(curveYGauge).deposit(_balance);
        }
    }

    function _harvestProfits() internal {
        uint256 _balanceBeforeUSDT = IERC20(usdt).balanceOf(address(this));
        Mintr(curveMinter).mint(curveYGauge);
        uint256 _crvBalance = IERC20(crv).balanceOf(address(this));
        if(_crvBalance > 0){
            IERC20(crv).safeApprove(uniswapRouter, 0);
            IERC20(crv).safeApprove(uniswapRouter, _crvBalance);
            IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(_crvBalance, uint256(0), CRV2USDT, address(this), block.timestamp.add(1800));
            uint256 _balanceAfterUSDT = IERC20(usdt).balanceOf(address(this));
            notifyProfit(_balanceBeforeUSDT, _balanceAfterUSDT, usdt);
            uint256 _profit = IERC20(usdt).balanceOf(address(this));
            if(_profit > 0){

                // Convert to yUSDT
                IERC20(usdt).safeApprove(yUSDT, 0);
                IERC20(usdt).safeApprove(yUSDT, _profit);
                yERC20(yUSDT).deposit(_profit);
                // Deposit to pool
                uint256 _yBal = IERC20(yUSDT).balanceOf(address(this));
                IERC20(yUSDT).safeApprove(curveYPool, 0);
                IERC20(yUSDT).safeApprove(curveYPool, _yBal);
                ICurveFi(curveYPool).add_liquidity([uint256(0), uint256(0), _yBal, uint256(0)], 0);
            }
        }
    }

    function harvestProfits() public {
        require(msg.sender == agent || msg.sender == governance, '!governance');
        _harvestProfits();
        deposit();
    }
}