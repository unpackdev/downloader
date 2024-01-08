pragma solidity 0.6.6;

import "./IAllocationStrategy.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./UniswapModule.sol";
import "./ICurveGaugeV2.sol";
import "./ICurveDepositPBTC.sol";
import "./ICurveMinter.sol";

/**
    @title pBTC allocation strategy
    @author Overall Finance
    @notice Used for allocating oToken funds pBtc sBtc Curve Pool
*/
contract PbtcCurveAllocationStrategy is IAllocationStrategy, UniswapModule, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public underlying;
    IERC20 public PNT;
    IERC20 public CRV;
    IERC20 public pBTCsbtcCRV;
    ICurveDepositPBTC public depositPbtc;
    ICurveGaugeV2 public pBTCsbtcCRVGauge;
    ICurveMinter public curveMinter;
    address public uniswapRouter;
    uint256 private constant SLIPPAGE_BASE_UNIT = 10**18;
    uint256 public allowedSlippage = 1500000000000000000;
    bool initialised;

    /**
        @notice Constructor
        @param _underlying Address of the underlying token
        @param _pntAddress Address of the PNT token
        @param _crvAddress Address of the CRV token
        @param _depositPbtc Address of the Curve pool deposit contract
        @param _pBTCsbtcCRV Address of the Curve contract
        @param _pBTCsbtcCRVGauge Address of the Curve contract
        @param _uniswapRouter Address of the UniswapV2Router
    */
    constructor(address _underlying, address _pntAddress, address _crvAddress, address _depositPbtc, address _pBTCsbtcCRV, address _pBTCsbtcCRVGauge, address _curveMinter, address _uniswapRouter) public {
        underlying = IERC20(_underlying);
        PNT = IERC20(_pntAddress);
        CRV = IERC20(_crvAddress);
        depositPbtc = ICurveDepositPBTC(_depositPbtc);
        pBTCsbtcCRV = IERC20(_pBTCsbtcCRV);
        pBTCsbtcCRVGauge = ICurveGaugeV2(_pBTCsbtcCRVGauge);
        curveMinter = ICurveMinter(_curveMinter);
        uniswapRouter = _uniswapRouter;
    }

    /**
        @notice Set maximum approves for used protocols
    */
    function setMaxApprovals() external {
        require(!initialised, "Already initialised");
        initialised = true;
        PNT.safeApprove(uniswapRouter, uint256(-1));
        CRV.safeApprove(uniswapRouter, uint256(-1));
        underlying.safeApprove(address(depositPbtc), uint256(-1));
        pBTCsbtcCRV.safeApprove(address(depositPbtc), uint256(-1));
        pBTCsbtcCRV.safeApprove(address(pBTCsbtcCRVGauge), uint256(-1));
    }

    /**
        @notice Get the amount of underlying in the BTC strategy
        @return Balance denominated in the underlying asset
    */
    function balanceOfUnderlying() external override returns (uint256) {
        uint256 curveGaugeBalance = pBTCsbtcCRVGauge.balanceOf(address(this));
        uint256 balance = _balanceOfUnderlying(curveGaugeBalance);
        return balance;
    }

    /**
        @notice Get the amount of underlying in the BTC strategy, while not modifying state
        @return Balance denominated in the underlying asset
    */
    function balanceOfUnderlyingView() public view override returns(uint256) {
        uint256 curveGaugeBalance = pBTCsbtcCRVGauge.balanceOf(address(this));
        uint256 balance = _balanceOfUnderlying(curveGaugeBalance);
        return balance;
    }

    /**
        @notice Get the amount of underlying in the BTC strategy, while not modifying state
        @return Balance denominated in the underlying asset
    */
    function _balanceOfUnderlying(uint256 curveGaugeAmount) internal view returns(uint256) {
        if (curveGaugeAmount == 0)
            return 0;
        uint256 balance = depositPbtc.calc_withdraw_one_coin(curveGaugeAmount, 0);
        return balance;
    }

    /**
        @notice Deposit the underlying token in the protocol
        @param _investAmount Amount of underlying tokens to hold
    */
    function investUnderlying(uint256 _investAmount) external override onlyOwner returns (uint256) {
        uint256 balanceBeforeInvestment = pBTCsbtcCRVGauge.balanceOf(address(this));
        uint256 maxAllowedMinAmount = _investAmount - ((_investAmount * allowedSlippage) / (SLIPPAGE_BASE_UNIT * 100));
        uint256 pBTCsbtcCRVAmount = depositPbtc.add_liquidity([_investAmount, 0, 0, 0], maxAllowedMinAmount);
        pBTCsbtcCRVGauge.deposit(pBTCsbtcCRVAmount, address(this));
        uint256 poolTokensAcquired = pBTCsbtcCRVGauge.balanceOf(address(this)).sub(balanceBeforeInvestment);
        uint256 investAmount = _balanceOfUnderlying(poolTokensAcquired);
        return investAmount;
    }

    /**
        @notice Redeeem the underlying asset from the protocol
        @param _redeemAmount Amount of oTokens to redeem
        @param _receiver Address of a receiver
    */
    function redeemUnderlying(uint256 _redeemAmount, address _receiver) external override onlyOwner returns(uint256) {
        uint256 redeemAmountGauge = depositPbtc.calc_token_amount([_redeemAmount, 0, 0, 0], false);
        pBTCsbtcCRVGauge.withdraw(redeemAmountGauge);

        uint256 pBTCsbtcCRVAmount = pBTCsbtcCRV.balanceOf(address(this));
        uint256 maxAllowedMinAmount = pBTCsbtcCRVAmount - ((pBTCsbtcCRVAmount * allowedSlippage) / (SLIPPAGE_BASE_UNIT * 100));
        uint256 pbtcAmount = depositPbtc.remove_liquidity_one_coin(pBTCsbtcCRVAmount, 0, maxAllowedMinAmount);

        underlying.safeTransfer(_receiver, pbtcAmount);
        return pbtcAmount;
    }

    /**
        @notice Redeem the entire balance from the underlying protocol
    */
    function redeemAll() external override onlyOwner {
        uint256 balance = pBTCsbtcCRVGauge.balanceOf(address(this));
        pBTCsbtcCRVGauge.withdraw(balance);

        uint256 pBTCsbtcCRVAmount = pBTCsbtcCRV.balanceOf(address(this));
        uint256 maxAllowedMinAmount = pBTCsbtcCRVAmount - ((pBTCsbtcCRVAmount * allowedSlippage) / (SLIPPAGE_BASE_UNIT * 100));
        uint256 pbtcAmount = depositPbtc.remove_liquidity_one_coin(pBTCsbtcCRVAmount, 0, maxAllowedMinAmount);

        underlying.safeTransfer(msg.sender, pbtcAmount);
    }

    /**
        @notice Claim and reinvest yield from protocols
        @param _amountOutMinCRV Minimal amount for a swap of CRV
        @param _amountOutMinPNT Minimal amount for a swap of PNT
        @param _deadline Deadline for a swap
    */
    function farmYield(uint256 _amountOutMinCRV, uint256 _amountOutMinPNT, uint256 _deadline) public {
        curveMinter.mint(address(pBTCsbtcCRVGauge));
        uint256 crvBalance = CRV.balanceOf(address(this));
        uint256[] memory swappedAmounts;
        uint256 farmedAmount;
        if (crvBalance > 0) {
            swappedAmounts = swapTokensThroughETH(address(CRV), address(underlying), crvBalance, _amountOutMinCRV, _deadline, uniswapRouter);
            farmedAmount = swappedAmounts[2];
        }
        pBTCsbtcCRVGauge.claim_rewards(address(this));
        uint256 pntBalance = PNT.balanceOf(address(this));
        if (pntBalance > 0) {
            swappedAmounts = swapTokensThroughETH(address(PNT), address(underlying), pntBalance, _amountOutMinPNT, _deadline, uniswapRouter);
            farmedAmount = farmedAmount.add(swappedAmounts[2]);
        }

        if (farmedAmount > 0) {
            uint256 maxAllowedMinAmount = farmedAmount - ((farmedAmount * allowedSlippage) / (SLIPPAGE_BASE_UNIT * 100));
            uint256 pBTCsbtcCRVAmount = depositPbtc.add_liquidity([farmedAmount, 0, 0, 0], maxAllowedMinAmount);
            pBTCsbtcCRVGauge.deposit(pBTCsbtcCRVAmount, address(this));
        }
    }
}
