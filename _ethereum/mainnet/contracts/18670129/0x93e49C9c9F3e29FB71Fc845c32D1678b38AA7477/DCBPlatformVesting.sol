// SPDX-License-Identifier: MIT

//** DCB vesting Contract */
//** Author Aaron & Aceson : DCB 2023.2 */

pragma solidity 0.8.19;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./Initializable.sol";
import "./IUniswapV2Router02.sol";

import "./IDCBPlatformVesting.sol";
import "./DateTime.sol";

interface ICrowdFunding {
    function userAllocation(address user)
        external
        view
        returns (uint8 tier, uint8 multi, uint256 shares, bool active);
}

contract DCBPlatformVesting is Ownable, DateTime, Initializable, IDCBPlatformVesting {
    using SafeERC20 for IERC20;

    VestingPool public vestingPool;

    // refund total values
    uint256 public totalVestedValue;
    uint256 public totalRefunded;
    uint256 public totalVestedToken;
    uint256 public totalReturnedToken;
    uint256 public totalTokenOnSale;
    uint256 public platformFee;

    uint256 public gracePeriod;
    address public innovator;
    address public paymentReceiver;

    address public router;
    address[] public path;
    bool public claimed;
    uint256[] public refundFees;
    uint32 internal nativeChainId;

    IERC20 public vestedToken;
    IERC20 public paymentToken;
    address public factory;

    event CrowdfundingInitialized(ContractSetup c, VestingSetup p, BuybackSetup b);
    event CrowdFundingSet(ContractSetup c);
    event TokenClaimInitialized(address _token, VestingSetup p);
    event VestingStrategyAdded(uint256 _cliff, uint256 _start, uint256 _duration, uint256 _initialUnlockPercent);
    event RaisedFundsClaimed(uint256 payment, uint256 remaining);
    event BuybackAndBurn(uint256 amount);
    event SetVestingParams(uint256 _cliff, uint256 _start, uint256 _duration, uint256 _initialUnlockPercent);

    modifier onlyInnovator() {
        require(msg.sender == innovator, "Invalid access");
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory");
        _;
    }

    modifier userInWhitelist(address _wallet) {
        require(vestingPool.hasWhitelist[_wallet].active, "Not in whitelist");
        _;
    }

    function initializeCrowdfunding(
        ContractSetup calldata c,
        VestingSetup calldata p,
        BuybackSetup calldata b
    )
        external
        initializer
    {
        innovator = c._innovator;
        paymentReceiver = c._paymentReceiver;
        vestedToken = IERC20(c._vestedToken);
        paymentToken = IERC20(c._paymentToken);
        gracePeriod = c._gracePeriod;
        totalTokenOnSale = c._totalTokenOnSale;
        nativeChainId = c._nativeChainId;
        refundFees = c._refundFees;

        router = b.router;
        path = b.path;

        paymentToken.approve(router, type(uint256).max);
        _transferOwnership(msg.sender);
        factory = msg.sender;
        platformFee = 800; // 8%

        addVestingStrategy(p._cliff, p._startTime, p._duration, p._initialUnlockPercent);

        emit CrowdfundingInitialized(c, p, b);
    }

    function setCrowdFundingParams(ContractSetup calldata c, uint256 _platformFee) external onlyFactory {
        require(block.timestamp < vestingPool.start, "Vesting already started");

        innovator = c._innovator;
        paymentReceiver = c._paymentReceiver;
        vestedToken = IERC20(c._vestedToken);
        paymentToken = IERC20(c._paymentToken);
        gracePeriod = c._gracePeriod;
        totalTokenOnSale = c._totalTokenOnSale;
        refundFees = c._refundFees;
        platformFee = _platformFee;

        paymentToken.approve(router, type(uint256).max);

        emit CrowdFundingSet(c);
    }

    function initializeTokenClaim(
        address _token,
        VestingSetup calldata p,
        uint32 _nativeChainId
    )
        external
        initializer
    {
        vestedToken = IERC20(_token);
        _transferOwnership(msg.sender);
        factory = msg.sender;
        nativeChainId = _nativeChainId;

        addVestingStrategy(p._cliff, p._startTime, p._duration, p._initialUnlockPercent);

        emit TokenClaimInitialized(_token, p);
    }

    function addVestingStrategy(
        uint256 _cliff,
        uint256 _start,
        uint256 _duration,
        uint256 _initialUnlockPercent
    )
        internal
        returns (bool)
    {
        vestingPool.cliff = _start + _cliff;
        vestingPool.start = _start;
        vestingPool.duration = _duration;
        vestingPool.initialUnlockPercent = _initialUnlockPercent;

        emit VestingStrategyAdded(_cliff, _start, _duration, _initialUnlockPercent);
        return true;
    }

    function setVestingParams(
        uint256 _cliff,
        uint256 _start,
        uint256 _duration,
        uint256 _initialUnlockPercent
    )
        external
        onlyFactory
    {
        require(block.timestamp < vestingPool.start, "Vesting already started");

        addVestingStrategy(_cliff, _start, _duration, _initialUnlockPercent);

        emit SetVestingParams(_cliff, _start, _duration, _initialUnlockPercent);
    }

    function setToken(address _token) external onlyFactory {
        vestedToken = IERC20(_token);
    }

    function rescueTokens(address _receiver, uint256 _amount) external onlyFactory {
        require(
            block.timestamp < vestingPool.start || vestedToken.balanceOf(address(this)) - totalVestedToken >= _amount,
            "Invalid amount"
        );
        vestedToken.transfer(_receiver, _amount);
    }

    function refund() external userInWhitelist(msg.sender) {
        uint256 idx = vestingPool.hasWhitelist[msg.sender].arrIdx;
        WhitelistInfo storage whitelist = vestingPool.whitelistPool[idx];

        require(
            block.timestamp < vestingPool.start + gracePeriod && block.timestamp > vestingPool.start,
            "Not in grace period"
        );
        require(!whitelist.refunded, "user already refunded");
        require(whitelist.distributedAmount == 0, "user already claimed");

        (uint256 tier, uint256 multi,,) = ICrowdFunding(address(owner())).userAllocation(msg.sender);
        uint256 refundFee = refundFees[tier];

        if (multi > 1) {
            uint256 multiReduction = (multi - 1) * 50;
            refundFee = refundFee > multiReduction ? refundFee - multiReduction : 0;
        }

        uint256 fee = whitelist.value * refundFee / 10_000;
        uint256 refundAmount = whitelist.value - fee;

        whitelist.refunded = true;
        whitelist.refundDate = uint256(block.timestamp);
        totalRefunded += whitelist.value;
        totalReturnedToken += whitelist.amount;

        // Transfer BUSD to user sub some percent of fee
        paymentToken.safeTransfer(msg.sender, refundAmount);
        if (fee > 0) {
            if (block.chainid == nativeChainId) {
                _doBuybackAndBurn(fee);
            } else {
                paymentToken.safeTransfer(paymentReceiver, fee);
            }
        }

        emit Refund(msg.sender, refundAmount);
    }

    function transferOwnership(address newOwner) public override(Ownable, IDCBPlatformVesting) onlyOwner {
        super.transferOwnership(newOwner);
    }

    function claimRaisedFunds() external onlyInnovator {
        require(block.timestamp > gracePeriod + vestingPool.start, "grace period in progress");
        require(!claimed, "already claimed");

        // payment amount = total value - total refunded
        uint256 amountPayment = totalVestedValue - totalRefunded;
        // calculate fee of 5%
        uint256 decubateFee = amountPayment * platformFee / 10_000;

        amountPayment -= decubateFee;

        // amount of project tokens to return = amount not sold + amount refunded
        uint256 amountTokenToReturn = totalTokenOnSale - totalVestedToken + totalReturnedToken;

        claimed = true;

        // transfer payment + refunded tokens to project
        if (amountPayment > 0) {
            paymentToken.safeTransfer(innovator, amountPayment);
        }
        if (amountTokenToReturn > 0) {
            vestedToken.safeTransfer(innovator, amountTokenToReturn);
        }

        // transfer crowdfunding fee to payment receiver wallet
        if (decubateFee > 0) {
            paymentToken.safeTransfer(paymentReceiver, decubateFee);
        }

        emit RaisedFundsClaimed(amountPayment, amountTokenToReturn);
    }

    function getWhitelist(address _wallet) external view userInWhitelist(_wallet) returns (WhitelistInfo memory) {
        uint256 idx = vestingPool.hasWhitelist[_wallet].arrIdx;
        return vestingPool.whitelistPool[idx];
    }

    function getTotalToken(address _addr) external view returns (uint256) {
        IERC20 _token = IERC20(_addr);
        return _token.balanceOf(address(this));
    }

    function hasWhitelist(address _wallet) external view returns (bool) {
        return vestingPool.hasWhitelist[_wallet].active;
    }

    function getVestAmount(address _wallet) external view returns (uint256) {
        return calculateVestAmount(_wallet);
    }

    function getReleasableAmount(address _wallet) external view returns (uint256) {
        return calculateReleasableAmount(_wallet);
    }

    function getWhitelistPool() external view returns (WhitelistInfo[] memory) {
        return vestingPool.whitelistPool;
    }

    function claimDistribution(address _wallet) public returns (bool) {
        uint256 idx = vestingPool.hasWhitelist[_wallet].arrIdx;
        WhitelistInfo storage whitelist = vestingPool.whitelistPool[idx];

        require(!whitelist.refunded, "user already refunded");

        uint256 releaseAmount = calculateReleasableAmount(_wallet);

        require(releaseAmount > 0, "Zero amount");

        whitelist.distributedAmount = whitelist.distributedAmount + releaseAmount;

        vestedToken.safeTransfer(_wallet, releaseAmount);

        emit Claim(_wallet, releaseAmount, block.timestamp);

        return true;
    }

    function setTokenClaimWhitelist(address _wallet, uint256 _amount) public onlyOwner {
        require(!vestingPool.hasWhitelist[_wallet].active, "Already registered");
        _setWhitelist(_wallet, _amount, 0);
    }

    function setCrowdfundingWhitelist(address _wallet, uint256 _amount, uint256 _value) public onlyOwner {
        uint256 paymentAmount = !vestingPool.hasWhitelist[_wallet].active
            ? _value
            : _value - vestingPool.whitelistPool[vestingPool.hasWhitelist[_wallet].arrIdx].value;
        paymentToken.safeTransferFrom(_wallet, address(this), paymentAmount);
        _setWhitelist(_wallet, _amount, _value);
    }

    function _setWhitelist(address _wallet, uint256 _amount, uint256 _value) internal {
        HasWhitelist storage whitelist = vestingPool.hasWhitelist[_wallet];

        if (!whitelist.active) {
            whitelist.active = true;
            whitelist.arrIdx = vestingPool.whitelistPool.length;

            vestingPool.whitelistPool.push(
                WhitelistInfo({
                    wallet: _wallet,
                    amount: _amount,
                    distributedAmount: 0,
                    value: _value,
                    joinDate: block.timestamp,
                    refundDate: 0,
                    refunded: false
                })
            );

            totalVestedValue += _value;
            totalVestedToken += _amount;
        } else {
            WhitelistInfo storage w = vestingPool.whitelistPool[whitelist.arrIdx];

            totalVestedValue += _value - w.value;
            totalVestedToken += _amount - w.amount;

            w.amount = _amount;
            w.value = _value;
        }

        emit SetWhitelist(_wallet, _amount, _value);
    }

    function _doBuybackAndBurn(uint256 amount) internal {
        IUniswapV2Router02 _router = IUniswapV2Router02(router);
        uint256[] memory amountsOut = _router.getAmountsOut(amount, path);
        uint256 amountOut = (amountsOut[amountsOut.length - 1] * 99) / 100; //1% slippage
        _router.swapExactTokensForTokens(amount, amountOut, path, address(0xdead), block.timestamp);

        emit BuybackAndBurn(amount);
    }

    function getVestingInfo() public view returns (VestingInfo memory) {
        return VestingInfo({
            cliff: vestingPool.cliff,
            start: vestingPool.start,
            duration: vestingPool.duration,
            initialUnlockPercent: vestingPool.initialUnlockPercent
        });
    }

    function calculateVestAmount(address _wallet) internal view userInWhitelist(_wallet) returns (uint256 amount) {
        uint256 idx = vestingPool.hasWhitelist[_wallet].arrIdx;
        uint256 _amount = vestingPool.whitelistPool[idx].amount;
        VestingPool storage vest = vestingPool;

        if (block.timestamp < vest.start) {
            return 0;
        } else if (block.timestamp >= vest.start && block.timestamp < vest.cliff) {
            return (_amount * vest.initialUnlockPercent / 1000);
        } else if (block.timestamp >= vest.cliff) {
            return calculateVestAmountForLinear(_amount, vest);
        }
    }

    function calculateVestAmountForLinear(uint256 _amount, VestingPool storage vest) internal view returns (uint256) {
        uint256 initial = _amount * vest.initialUnlockPercent / 1000;

        uint256 remaining = _amount - initial;

        if (block.timestamp >= vest.cliff + vest.duration) {
            return _amount;
        } else {
            return initial + remaining * (block.timestamp - vest.cliff) / vest.duration;
        }
    }

    function calculateReleasableAmount(address _wallet) internal view userInWhitelist(_wallet) returns (uint256) {
        uint256 idx = vestingPool.hasWhitelist[_wallet].arrIdx;
        return calculateVestAmount(_wallet) - (vestingPool.whitelistPool[idx].distributedAmount);
    }
}
