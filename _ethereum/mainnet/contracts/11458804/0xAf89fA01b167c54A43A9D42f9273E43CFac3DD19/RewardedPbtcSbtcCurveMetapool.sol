pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IERC1820Registry.sol";
import "./IERC777Recipient.sol";
import "./ICurveDepositPBTC.sol";
import "./ICurveGaugeV2.sol";
import "./ModifiedUnipoolV2.sol";


contract RewardedPbtcSbtcCurveMetapool is IERC777Recipient, Ownable {
    using SafeERC20 for IERC20;

    // prettier-ignore
    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    uint256 private constant SLIPPAGE_BASE_UNIT = 10**18;

    IERC20 public pbtc;
    IERC20 public metaToken;
    IERC20 public crv;
    ICurveDepositPBTC public depositPbtc;
    ICurveGaugeV2 public gauge;
    ModifiedUnipoolV2 public modifiedUnipool;

    uint256 public allowedSlippage;

    event Staked(address indexed user, uint256 amount, uint256 metaTokenAmount);
    event Unstaked(address indexed user, uint256 amount, uint256 metaTokenAmount);
    event AllowedSlippageChanged(uint256 slippage);

    /**
     * @param _depositPbtc MetaPool address
     * @param _gauge Curve Gauge address
     * @param _modifiedUnipool ModifiedUnipoolV2 address
     * @param _pbtc pbtc address
     */
    constructor(
        address _depositPbtc,
        address _gauge,
        address _modifiedUnipool,
        address _pbtc
    ) public {
        depositPbtc = ICurveDepositPBTC(_depositPbtc);
        gauge = ICurveGaugeV2(_gauge);
        crv = IERC20(gauge.crv_token());
        pbtc = IERC20(_pbtc);
        metaToken = IERC20(depositPbtc.token());
        modifiedUnipool = ModifiedUnipoolV2(_modifiedUnipool);
        _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }

    /**
     *  @param _allowedSlippage new max allowed in percentage (1% = 10 ** 18)
     */
    function setAllowedSlippage(uint256 _allowedSlippage) external onlyOwner {
        allowedSlippage = _allowedSlippage;
        emit AllowedSlippageChanged(_allowedSlippage);
    }

    /**
     * @notice ERC777 hook invoked when this contract receives a token.
     */
    function tokensReceived(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _userData,
        bytes calldata _operatorData
    ) external {
        if (_from == address(depositPbtc)) return;
        require(msg.sender == address(pbtc), "RewardedPbtcSbtcCurveMetapool: Invalid token");
        require(_amount > 0, "RewardedPbtcSbtcCurveMetapool: amount must be greater than 0");
        _stakeFor(_from, _amount);
    }

    /**
     * @notice Remove Gauge tokens from Modified Unipool (earning PNT),
     *         withdraw pBTC/sbtcCRV (earning CRV) from the Gauge and then
     *         remove liquidty from pBTC/sBTC Curve Metapool and then
     *         transfer all back to the msg.sender.
     *         User must approve this contract to to withdraw the corresponing
     *         amount of his metaToken balance in behalf of him.
     */
    function unstake() public returns (bool) {
        uint256 gaugeTokenSenderBalance = modifiedUnipool.balanceOf(msg.sender);
        require(
            modifiedUnipool.allowance(msg.sender, address(this)) >= gaugeTokenSenderBalance,
            "RewardedPbtcSbtcCurveMetapool: amount not approved"
        );
        modifiedUnipool.withdrawFrom(msg.sender, gaugeTokenSenderBalance);
        // NOTE: collect Modified Unipool rewards
        modifiedUnipool.getReward(msg.sender);

        // NOTE: collect CRV
        uint256 gaugeTokenAmount = gauge.balanceOf(address(this));
        gauge.withdraw(gaugeTokenAmount);
        uint256 crvAmount = crv.balanceOf(address(this));
        crv.transfer(msg.sender, crvAmount);

        uint256 metaTokenAmount = metaToken.balanceOf(address(this));
        metaToken.safeApprove(address(depositPbtc), metaTokenAmount);
        // prettier-ignore
        uint256 maxAllowedMinAmount = metaTokenAmount - ((metaTokenAmount * allowedSlippage) / (SLIPPAGE_BASE_UNIT * 100));
        uint256 pbtcAmount = depositPbtc.remove_liquidity_one_coin(metaTokenAmount, 0, maxAllowedMinAmount);
        pbtc.transfer(msg.sender, pbtcAmount);
        emit Unstaked(msg.sender, pbtcAmount, metaTokenAmount);
        return true;
    }

    /**
     * @notice Collect all available rewards
     *
     * @param _addr address to claim for
     */
    function claimRewards(address _addr) public returns (bool) {
        modifiedUnipool.getReward(_addr);
        gauge.claim_rewards(_addr);
        return true;
    }

    /**
     * @notice Add liquidity into Curve pBTC/SBTC Metapool,
     *         put the minted pBTC/sbtcCRV tokens into the Gauge in
     *         order to earn CRV and then put the Liquidi Gauge tokens
     *         into Unipool in order to get the PNT reward.
     *
     * @param _user user address
     * @param _amount pBTC amount to put into the meta pool
     */
    function _stakeFor(address _user, uint256 _amount) internal returns (bool) {
        uint256 maxAllowedMinAmount = _amount - ((_amount * allowedSlippage) / (SLIPPAGE_BASE_UNIT * 100));
        pbtc.safeApprove(address(depositPbtc), _amount);
        uint256 metaTokenAmount = depositPbtc.add_liquidity([_amount, 0, 0, 0], maxAllowedMinAmount);

        metaToken.safeApprove(address(gauge), metaTokenAmount);
        gauge.deposit(metaTokenAmount, address(this));

        uint256 gaugeTokenAmount = gauge.balanceOf(address(this));
        gauge.approve(address(modifiedUnipool), gaugeTokenAmount);
        modifiedUnipool.stakeFor(_user, gaugeTokenAmount);
        emit Staked(_user, _amount, metaTokenAmount);
        return true;
    }
}
