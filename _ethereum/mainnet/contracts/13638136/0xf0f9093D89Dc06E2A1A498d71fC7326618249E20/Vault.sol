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
    bytes32 internal constant _belowTwentyPercent_      = 'belowTwentyPercent';
    bytes32 internal constant _twentyToThirtyPercent_   = 'twentyToThirtyPercent';
    bytes32 internal constant _thirtyToSeventyPercent_  = 'thirtyToSeventyPercent';
    bytes32 internal constant _seventyToEightyPercent_  = 'seventyToEightyPercent';
    bytes32 internal constant _aboveEightyPercent_      = 'aboveEightyPercent';

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

    function resetParametersFeesUpdate() external governance {
        // config[_belowTwentyPercent_] = 0;
        config[_twentyToThirtyPercent_] = 20;
        config[_thirtyToSeventyPercent_] = 45;
        config[_seventyToEightyPercent_] = 80;
        config[_aboveEightyPercent_] = 100;
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

    function getAETHcPoolWeight() public view returns (uint) {
        return aEth.balanceOf(address(this)).mul(1e18).div(aEth.ratio());
    }

    function getAETHbPoolWeight() public view returns (uint) {
        return aETHb.balanceOf(address(this));
    }

    function getMaxPoolWeight() public view returns (uint) {
        return getAETHcPoolWeight().add(getAETHbPoolWeight());
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

    function E2B(uint vol) external {

    }

    function B2E(uint vol) external {

    }

    function onsValueOnlyPercentage(uint amount, uint percent) public pure returns (uint){
        return amount.mul(percent).div(1e4);
    }

    function receiveOnsInPercentage(address from, uint amt, uint ratio) internal {
        ons.transferFrom(
            from,
            address(this),
            oneToOnsAmount(onsValueOnlyPercentage(amt, getOnsFees(ratio)))
        );
    }

    function mintPoolPercentCheck(uint tokenPoolWeight, uint maxPoolWeight) internal view returns (uint ratio) {
        require(maxPoolWeight != 0 && getMintMaxPoolPercent() != 0, 'Not enough pool weight');
        ratio = tokenPoolWeight.mul(_mintMaxPoolPercentDecimals_).div(maxPoolWeight);
        require(ratio <= getMintMaxPoolPercent(), "Too many tokens in the pool");
    }

    function redeemMaxPoolPercentCheck(uint tokenPoolWeight, uint maxPoolWeight) internal view returns (uint ratio) {
        require(maxPoolWeight != 0 && getMintMaxPoolPercent() != 0, 'Not enough pool weight');
        ratio = tokenPoolWeight.mul(_mintMaxPoolPercentDecimals_).div(maxPoolWeight);
        require(ratio >= _mintMaxPoolPercentDecimals_.sub(getMintMaxPoolPercent()), "Too low tokens in the pool");
    }

    function getOnsFees(uint ratio) public view returns (uint) {
        if (ratio >= 2e4 && ratio < 3e4) {
            return config[_twentyToThirtyPercent_];
        }
        if (ratio >= 3e4 && ratio < 7e4) {
            return config[_thirtyToSeventyPercent_];
        }
        if (ratio >= 7e4 && ratio < 8e4) {
            return config[_seventyToEightyPercent_];
        }
        if (ratio >= 8e4) {
            return config[_aboveEightyPercent_];
        }
        return config[_belowTwentyPercent_];
    }

    function mintONEaETHc(uint amt) external updateTwap oneMinPriceCheck {
        uint tokenWeight = aEth.balanceOf(address(this)).add(amt).mul(1e18).div(aEth.ratio());
        uint maxPoolWeight = tokenWeight.add(aETHb.balanceOf(address(this)));
        uint mintPoolRatio = mintPoolPercentCheck(tokenWeight, maxPoolWeight);
        uint ethValue = amt.mul(1e18).div(aEth.ratio());
        emit Mint(msg.sender, ethValue, 1);

        receiveAETHcFrom(msg.sender, amt);
        receiveOnsInPercentage(msg.sender, ethValue, mintPoolRatio);
        one.mint_(msg.sender, ethValue);
    }

    function mintONEaETHb(uint amt) external updateTwap oneMinPriceCheck {
        uint tokenWeight = aETHb.balanceOf(address(this)).add(amt);
        uint maxPoolWeight = tokenWeight.add(aEth.balanceOf(address(this)).mul(1e18).div(aEth.ratio()));
        uint mintPoolRatio = mintPoolPercentCheck(tokenWeight, maxPoolWeight);
        emit Mint(msg.sender, amt, 0);

        receiveAETHbFrom(msg.sender, amt);
        receiveOnsInPercentage(msg.sender, amt, mintPoolRatio);
        one.mint_(msg.sender, amt);
    }

    function burnONEaETHc(uint amt) external updateTwap oneMaxPriceCheck {
        uint tokenWeight = aEth.balanceOf(address(this)).mul(1e18).div(aEth.ratio()).sub(amt);
        uint maxPoolWeight = tokenWeight.add(aETHb.balanceOf(address(this)));
        uint ratio = redeemMaxPoolPercentCheck(tokenWeight, maxPoolWeight);
        emit Burn(msg.sender, amt, address(aEth));

        uint aETHcValue = amt.mul(aEth.ratio()).div(1e18);
        one.burn_(msg.sender, amt);
        receiveOnsInPercentage(msg.sender, amt, _mintMaxPoolPercentDecimals_.sub(ratio));
        _sendAETHcTo(msg.sender, aETHcValue);
    }

    function burnONEaETHb(uint amt) external updateTwap oneMaxPriceCheck {
        uint tokenWeight = aETHb.balanceOf(address(this)).sub(amt);
        uint maxPoolWeight = tokenWeight.add(aEth.balanceOf(address(this)).mul(1e18).div(aEth.ratio()));
        uint ratio = redeemMaxPoolPercentCheck(tokenWeight, maxPoolWeight);
        emit Burn(msg.sender, amt, address(aETHb));

        one.burn_(msg.sender, amt);
        receiveOnsInPercentage(msg.sender, amt, _mintMaxPoolPercentDecimals_.sub(ratio));
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

    function receiveAETHcFrom(address from, uint vol) internal {
        aEth.transferFrom(from, address(this), vol);
        //        totalEthValue = totalEthValue.add(vol.mul(1e18).div(aEth.ratio()));
    }

    function receiveAETHbFrom(address from, uint vol) internal {
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
