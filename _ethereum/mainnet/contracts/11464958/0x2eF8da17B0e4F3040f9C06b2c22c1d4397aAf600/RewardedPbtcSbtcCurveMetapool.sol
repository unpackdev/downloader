pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IERC1820Registry.sol";
import "./IERC777Recipient.sol";
import "./ICurveDepositPBTC.sol";
import "./ICurveGaugeV2.sol";


contract RewardedPbtcSbtcCurveMetapool is IERC777Recipient, Ownable {
    using SafeERC20 for IERC20;

    // prettier-ignore
    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    uint256 private constant SLIPPAGE_BASE_UNIT = 10**18;

    IERC20 public pbtc;
    IERC20 public pnt;
    IERC20 public pBTCsbtcCRV;
    IERC20 public crv;
    ICurveDepositPBTC public depositPbtc;
    ICurveGaugeV2 public pBTCsbtcCRVGauge;

    uint256 public allowedSlippage;

    event AllowedSlippageChanged(uint256 slippage);

    /**
     * @param _depositPbtc MetaPool address
     * @param _pBTCsbtcCRVGauge Curve Gauge address
     * @param _pbtc pbtc address
     * @param _pnt pnt address in order to be able to collect the reward
     */
    constructor(
        address _depositPbtc,
        address _pBTCsbtcCRVGauge,
        address _pbtc,
        address _pnt
    ) public {
        depositPbtc = ICurveDepositPBTC(_depositPbtc);
        pBTCsbtcCRVGauge = ICurveGaugeV2(_pBTCsbtcCRVGauge);
        crv = IERC20(pBTCsbtcCRVGauge.crv_token());
        pbtc = IERC20(_pbtc);
        pnt = IERC20(_pnt);
        pBTCsbtcCRV = IERC20(depositPbtc.token());
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
     * @notice Remove tokens from the Gauge in order to get PNT and CRV,
     *         remove liquidty from pBTC/sBTC Curve Metapool and then
     *         transfer all back to the msg.sender.
     */
    function unstake() public returns (bool) {
        uint256 pBTCsbtcCRVGaugeSenderBalance = pBTCsbtcCRVGauge.balanceOf(msg.sender);
        require(
            pBTCsbtcCRVGauge.allowance(msg.sender, address(this)) >= pBTCsbtcCRVGaugeSenderBalance,
            "RewardedPbtcSbtcCurveMetapool: amount not approved"
        );
        pBTCsbtcCRVGauge.transferFrom(msg.sender, address(this), pBTCsbtcCRVGaugeSenderBalance);
        // NOTE: collect CRV and PNT
        pBTCsbtcCRVGauge.withdraw(pBTCsbtcCRVGaugeSenderBalance);

        uint256 crvAmount = crv.balanceOf(address(this));
        crv.transfer(msg.sender, crvAmount);
        uint256 pntAmount = pnt.balanceOf(address(this));
        pnt.transfer(msg.sender, pntAmount);

        uint256 pBTCsbtcCRVAmount = pBTCsbtcCRV.balanceOf(address(this));
        pBTCsbtcCRV.safeApprove(address(depositPbtc), pBTCsbtcCRVAmount);
        // prettier-ignore
        uint256 maxAllowedMinAmount = pBTCsbtcCRVAmount - ((pBTCsbtcCRVAmount * allowedSlippage) / (SLIPPAGE_BASE_UNIT * 100));
        uint256 pbtcAmount = depositPbtc.remove_liquidity_one_coin(pBTCsbtcCRVAmount, 0, maxAllowedMinAmount);
        pbtc.transfer(msg.sender, pbtcAmount);
        return true;
    }

    /**
     * @notice Add liquidity into Curve pBTC/SBTC Metapool,
     *         put the minted pBTC/sbtcCRV tokens into the Gauge in
     *         order to earn CRV and PNT since the Gauge will forward
     *         the deposited tokens within Unipool
     *
     * @param _user user address
     * @param _amount pBTC amount to put into the meta pool
     */
    function _stakeFor(address _user, uint256 _amount) internal returns (bool) {
        uint256 maxAllowedMinAmount = _amount - ((_amount * allowedSlippage) / (SLIPPAGE_BASE_UNIT * 100));
        pbtc.safeApprove(address(depositPbtc), _amount);
        uint256 pBTCsbtcCRVAmount = depositPbtc.add_liquidity([_amount, 0, 0, 0], maxAllowedMinAmount);
        pBTCsbtcCRV.safeApprove(address(pBTCsbtcCRVGauge), pBTCsbtcCRVAmount);
        pBTCsbtcCRVGauge.deposit(pBTCsbtcCRVAmount, address(this));
        uint256 pBTCsbtcCRVGaugeAmount = pBTCsbtcCRVGauge.balanceOf(address(this));
        pBTCsbtcCRVGauge.transfer(_user, pBTCsbtcCRVGaugeAmount);
        return true;
    }
}
