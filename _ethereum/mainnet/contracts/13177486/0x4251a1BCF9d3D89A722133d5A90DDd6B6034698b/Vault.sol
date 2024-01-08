// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Configurable.sol";
import "./EmaOracle.sol";
import "./ONE.sol";
import "./ONS.sol";
import "./Constant.sol";
import "./SafeERC20.sol";
import "./IVault.sol";


interface IAETH is IERC20 {
    function ratio() external view returns (uint256);
}


contract Vault is Constant, Configurable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using EmaOracle for EmaOracle.Observations;

    bytes32 internal constant _periodTwapOne_           = 'periodTwapOne';
    bytes32 internal constant _periodTwapOns_           = 'periodTwapOns';
    bytes32 internal constant _periodTwapAEth_          = 'periodTwapAEth';
    //bytes32 internal constant _thresholdReserve_        = 'thresholdReserve';
    bytes32 internal constant _initialMintQuota_        = 'initialMintQuota';
    bytes32 internal constant _rebaseInterval_          = 'rebaseInterval';
    bytes32 internal constant _rebaseThreshold_         = 'rebaseThreshold';
    bytes32 internal constant _rebaseCap_               = 'rebaseCap';
    bytes32 internal constant _burnOneThreshold_        = 'burnOneThreshold';

    address public oneMinter;
    ONE public one;
    ONS public ons;
    address public onb;
    IAETH public aEth;
    address public WETH;
    uint public begin;
    uint public span;
    EmaOracle.Observations public twapOne;
    EmaOracle.Observations public twapOns;
    EmaOracle.Observations public twapAEth;
    uint public totalEthValue;
    uint public rebaseTime;
    IERC20 public aETHb;

    bytes32 internal constant _mintOneThreshold_        = 'mintOneThreshold';

    event Mint(address acct, uint oneVol, uint8 isAETHc);
    event Burn(address acct, uint oneVol, address token);

    bytes32 internal constant _mintMaxPoolPercent_      = 'mintMaxPoolPercent'; // 90000 == 90%
    uint internal constant _mintMaxPoolPercentDecimals_ = 1e5; // 100%

    function __Vault_init(address governor_, address _oneMinter, ONE _one, ONS _ons, address _onb, IAETH _aEth, address _WETH, uint _begin, uint _span) external initializer {
        __Governable_init_unchained(governor_);
        __Vault_init_unchained(_oneMinter, _one, _ons, _onb, _aEth, _WETH, _begin, _span);
    }

    function __Vault_init_unchained(address _oneMinter, ONE _one, ONS _ons, address _onb, IAETH _aETHc, address _WETH, uint _begin, uint _span) internal governance {
        oneMinter = _oneMinter;
        one = _one;
        ons = _ons;
        onb = _onb;
        aEth = _aETHc;
        WETH = _WETH;
        begin = _begin;
        span = _span;
        //config[_thresholdReserve_]  = 0.8 ether;
        config[_ratioAEthWhenMint_] = 0.9 ether;
        config[_periodTwapOne_]     =  8 hours;
        config[_periodTwapOns_]     = 15 minutes;
        config[_periodTwapAEth_]    = 15 minutes;
        config[_initialMintQuota_]  = 10000 ether;
        config[_rebaseInterval_]    = 8 hours;
        config[_rebaseThreshold_]   = 1.05 ether;
        config[_rebaseCap_]         = 0.05 ether;   // 5%
        rebaseTime = now;
        config[_burnOneThreshold_]  = 1.0 ether;
    }

    function resetParametersV2(IAETH _aETHb) external governance {
        config[_burnOneThreshold_]  = 1.05 ether;
        aETHb = _aETHb;
    }

    function getBurnOneThreshold() public view returns (uint) {
        return config[_burnOneThreshold_];
    }

    function getMintOneThreshold() public view returns (uint) {
        return config[_mintOneThreshold_];
    }

    function getMintMaxPoolPercent() public view returns (uint) {
        return config[_mintMaxPoolPercent_];
    }

    function getTokenPoolWeight(IERC20 token) public view returns (uint) {
        return token.balanceOf(address(this));
    }

    function getMaxPoolWeight() public view returns (uint) {
        return getTokenPoolWeight(aEth).add(getTokenPoolWeight(aETHb));
    }

    function setBurnOneThreshold(uint burnOneThreshold) external governance {
        config[_burnOneThreshold_] = burnOneThreshold;
    }

    function setMintOneThreshold(uint mintOneThreshold) external governance {
        config[_mintOneThreshold_] = mintOneThreshold;
    }

    function setMintMaxPoolPercent(uint mintMaxPoolPercent) external governance {
        config[_mintMaxPoolPercent_] = mintMaxPoolPercent;
    }

    function twapInit(address swapFactory) external governance {
        twapOne.initialize(swapFactory, config[_periodTwapOne_], address(one), address(aEth));
        twapOns.initialize(swapFactory, config[_periodTwapOns_], address(ons), address(aEth));
        twapAEth.initialize(swapFactory, config[_periodTwapAEth_], address(aEth), WETH);
    }

    modifier updateTwap {
        twapOne.update(config[_periodTwapOne_], address(one), address(aEth));
        twapOns.update(config[_periodTwapOns_], address(ons), address(aEth));
        twapAEth.update(config[_periodTwapAEth_], address(aEth), WETH);
        _;
    }

    modifier oneMinPriceCheck {
        require(onePriceLo() > getMintOneThreshold(), 'ONE price is not high enough to mint');
        _;
    }

    modifier oneMaxPriceCheck {
        require(onePriceHi() < getBurnOneThreshold(), 'ONE price is not low enough to burn');
        _;
    }

    modifier mintMaxPoolPercentCheck(IERC20 token, uint amountToMint) {
        uint maxPoolWeight = getMaxPoolWeight();
        if (getMintMaxPoolPercent() != 0 && maxPoolWeight != 0) {
            uint ratio = getTokenPoolWeight(token).add(amountToMint).mul(_mintMaxPoolPercentDecimals_).div(maxPoolWeight.add(amountToMint));
            require(ratio < getMintMaxPoolPercent(), "Too many tokens in the pool");
        }
        _;
    }

    modifier redeemMaxPoolPercentCheck(IERC20 token, uint amountToRedeem) {
        uint maxPoolWeight = getMaxPoolWeight();
        if (getMintMaxPoolPercent() != 0 && maxPoolWeight != 0) {
            uint ratio = getTokenPoolWeight(token).sub(amountToRedeem).mul(_mintMaxPoolPercentDecimals_).div(maxPoolWeight.sub(amountToRedeem));
            require(ratio > _mintMaxPoolPercentDecimals_.sub(getMintMaxPoolPercent()), "Too low tokens in the pool");
        }
        _;
    }

    function E2B(uint vol) external {

    }

    function B2E(uint vol) external {

    }

    function onsValueOnlyPercentage(uint amount) public pure returns (uint){
        return amount.mul(45).div(10000);
    }

    function receiveOnsInPercentage(address from, uint amt) internal {
        ons.transferFrom(from, address(this), oneToOnsAmount(onsValueOnlyPercentage(amt)));
    }

    function mintONEaETHc(uint amt) external updateTwap oneMinPriceCheck mintMaxPoolPercentCheck(aEth, amt) {
        emit Mint(msg.sender, amt, 1);

        receiveAETHcFrom(msg.sender, amt);
        receiveOnsInPercentage(msg.sender, amt);
        one.mint_(msg.sender, amt);
    }

    function mintONEaETHb(uint amt) external updateTwap oneMinPriceCheck mintMaxPoolPercentCheck(aETHb, amt) {
        emit Mint(msg.sender, amt, 0);

        receiveAETHbFrom(msg.sender, amt);
        receiveOnsInPercentage(msg.sender, amt);
        one.mint_(msg.sender, amt);
    }

    function burnONEaETHc(uint amt) external updateTwap oneMaxPriceCheck redeemMaxPoolPercentCheck(aEth, amt) {
        emit Burn(msg.sender, amt, address(aEth));

        one.burn_(msg.sender, amt);
        receiveOnsInPercentage(msg.sender, amt);
        _sendAETHcTo(msg.sender, amt);
    }

    function burnONEaETHb(uint amt) external updateTwap oneMaxPriceCheck redeemMaxPoolPercentCheck(aETHb, amt) {
        emit Burn(msg.sender, amt, address(aETHb));

        one.burn_(msg.sender, amt);
        receiveOnsInPercentage(msg.sender, amt);
        _sendAETHbTo(msg.sender, amt);
    }

    function burnONB(uint vol) external {

    }

    function onePriceNow() public view returns (uint price) {
        price = twapOne.consultNow( address(one), 1 ether, address(aEth));
        price = twapAEth.consultNow(address(aEth), price,  address(WETH));
    }
    function onePriceEma() public view returns (uint price) {
        price = twapOne.consultEma( config[_periodTwapOne_],  address(one), 1 ether, address(aEth));
        price = twapAEth.consultEma(config[_periodTwapAEth_], address(aEth), price, address(WETH));
    }
    function onePriceHi() public view returns (uint) {
        return Math.max(onePriceNow(), onePriceEma());
    }
    function onePriceLo() public view returns (uint) {
        return Math.min(onePriceNow(), onePriceEma());
    }

    function oneToOnsNow(uint amountOne) public view returns (uint price) {
        price = twapOne.consultNow( address(one), amountOne, address(aEth));
        price = twapOns.consultNow(address(aEth), price,  address(ons));
    }
    function oneToOnsEma(uint amountOne) public view returns (uint price) {
        price = twapOne.consultEma( config[_periodTwapOne_],  address(one), amountOne, address(aEth));
        price = twapOns.consultEma(config[_periodTwapOns_], address(aEth), price,  address(ons));
    }

    function oneToOnsAmount(uint amountOne) public view returns (uint) {
        return Math.max(oneToOnsNow(amountOne), oneToOnsEma(amountOne));
    }

    event Rebase(uint aEthVol, uint aEthRatio, uint onsVol, uint onsRatio, uint oneVol);

    function receiveAETHcFrom(address from, uint vol) public {
        aEth.transferFrom(from, address(this), vol);
        //        totalEthValue = totalEthValue.add(vol.mul(1e18).div(aEth.ratio()));
    }

    function receiveAETHbFrom(address from, uint vol) public {
        aETHb.transferFrom(from, address(this), vol);
    }

    function _sendAETHcTo(address to, uint vol) internal {
        //        totalEthValue = totalEthValue.sub(vol.mul(1e18).div(aEth.ratio()));
        aEth.transfer(to, vol);
    }

    function _sendAETHbTo(address to, uint vol) internal {
        aETHb.transfer(to, vol);
    }
}
