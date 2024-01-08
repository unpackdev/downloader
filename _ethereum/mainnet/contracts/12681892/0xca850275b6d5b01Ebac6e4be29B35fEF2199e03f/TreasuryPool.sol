// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "./SafeERC20.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./AddressArray.sol";
import "./ILfi.sol";
import "./ILtoken.sol";
import "./IDsecDistribution.sol";
import "./IFarmingPool.sol";
import "./ITreasuryPool.sol";

contract TreasuryPool is Pausable, ReentrancyGuard, ITreasuryPool {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using AddressArray for address[];

    uint256 public constant ROUNDING_TOLERANCE = 9999999999 wei;

    uint256 public immutable lpRewardPerEpoch;
    uint256 public immutable teamRewardPerEpoch;
    address public immutable teamAccount;

    address public governanceAccount;
    address public lfiAddress;
    address public underlyingAssetAddress;
    address public ltokenAddress;
    address public dsecDistributionAddress;

    uint256 public totalUnderlyingAssetAmount = 0;
    uint256 public totalLtokenAmount = 0;

    address[] private _farmingPoolAddresses;
    uint256 public totalLoanedUnderlyingAssetAmount = 0;

    ILfi private _lfi;
    IERC20 private _underlyingAsset;
    ILtoken private _ltoken;
    IDsecDistribution private _dsecDistribution;

    constructor(
        address lfiAddress_,
        address underlyingAssetAddress_,
        address ltokenAddress_,
        address dsecDistributionAddress_,
        uint256 lpRewardPerEpoch_,
        uint256 teamRewardPerEpoch_,
        address teamAccount_
    ) {
        require(
            lfiAddress_ != address(0),
            "TreasuryPool: LFI address is the zero address"
        );
        require(
            underlyingAssetAddress_ != address(0),
            "TreasuryPool: underlying asset address is the zero address"
        );
        require(
            ltokenAddress_ != address(0),
            "TreasuryPool: LToken address is the zero address"
        );
        require(
            dsecDistributionAddress_ != address(0),
            "TreasuryPool: dsec distribution address is the zero address"
        );
        require(
            teamAccount_ != address(0),
            "TreasuryPool: team account is the zero address"
        );

        governanceAccount = msg.sender;
        lfiAddress = lfiAddress_;
        underlyingAssetAddress = underlyingAssetAddress_;
        ltokenAddress = ltokenAddress_;
        dsecDistributionAddress = dsecDistributionAddress_;
        lpRewardPerEpoch = lpRewardPerEpoch_;
        teamRewardPerEpoch = teamRewardPerEpoch_;
        teamAccount = teamAccount_;

        _lfi = ILfi(lfiAddress);
        _underlyingAsset = IERC20(underlyingAssetAddress);
        _ltoken = ILtoken(ltokenAddress);
        _dsecDistribution = IDsecDistribution(dsecDistributionAddress);
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "TreasuryPool: sender not authorized");
        _;
    }

    modifier onlyFarmingPool() {
        require(
            _farmingPoolAddresses.contains(msg.sender),
            "TreasuryPool: sender not a farming pool"
        );
        _;
    }

    function farmingPoolAddresses() external view returns (address[] memory) {
        return _farmingPoolAddresses;
    }

    function addLiquidity(uint256 amount) external override nonReentrant {
        require(amount != 0, "TreasuryPool: can't add 0");
        require(!paused(), "TreasuryPool: deposit while paused");

        uint256 ltokenAmount;
        uint256 length = _farmingPoolAddresses.length;
        if (length > 0) {
            uint256 totalBorrowerInterestEarning = 0;
            for (uint256 i = 0; i < length; i++) {
                IFarmingPool farmingPool =
                    IFarmingPool(_farmingPoolAddresses[i]);
                // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1
                // https://github.com/crytic/slither/wiki/Detector-Documentation#calls-inside-a-loop
                // slither-disable-next-line reentrancy-benign,calls-loop
                uint256 borrowerInterestEarning =
                    farmingPool.computeBorrowerInterestEarning();
                totalBorrowerInterestEarning = totalBorrowerInterestEarning.add(
                    borrowerInterestEarning
                );
            }
            ltokenAmount = _divExchangeRate(
                amount,
                totalBorrowerInterestEarning
            );
        } else {
            ltokenAmount = amount;
        }

        totalUnderlyingAssetAmount = totalUnderlyingAssetAmount.add(amount);
        totalLtokenAmount = totalLtokenAmount.add(ltokenAmount);

        // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
        // slither-disable-next-line reentrancy-events
        emit AddLiquidity(
            msg.sender,
            underlyingAssetAddress,
            ltokenAddress,
            amount,
            ltokenAmount,
            block.timestamp
        );

        _underlyingAsset.safeTransferFrom(msg.sender, address(this), amount);
        _dsecDistribution.addDsec(msg.sender, amount);
        _ltoken.mint(msg.sender, ltokenAmount);
    }

    function removeLiquidity(uint256 amount) external override nonReentrant {
        uint256 totalUnderlyingAssetAvailable =
            getTotalUnderlyingAssetAvailableCore();

        require(amount != 0, "TreasuryPool: can't remove 0");
        require(!paused(), "TreasuryPool: withdraw while paused");
        require(
            totalUnderlyingAssetAvailable > 0,
            "TreasuryPool: insufficient liquidity"
        );
        require(
            _ltoken.balanceOf(msg.sender) >= amount,
            "TreasuryPool: insufficient LToken"
        );

        uint256 underlyingAssetAmount;
        uint256 length = _farmingPoolAddresses.length;
        if (length > 0) {
            underlyingAssetAmount = 0;
            uint256 totalBorrowerInterestEarning = 0;
            for (uint256 i = 0; i < length; i++) {
                IFarmingPool farmingPool =
                    IFarmingPool(_farmingPoolAddresses[i]);
                // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1
                // https://github.com/crytic/slither/wiki/Detector-Documentation#calls-inside-a-loop
                // slither-disable-next-line reentrancy-benign,calls-loop
                uint256 borrowerInterestEarning =
                    farmingPool.computeBorrowerInterestEarning();
                totalBorrowerInterestEarning = totalBorrowerInterestEarning.add(
                    borrowerInterestEarning
                );
            }
            underlyingAssetAmount = _mulExchangeRate(
                amount,
                totalBorrowerInterestEarning
            );
        } else {
            underlyingAssetAmount = amount;
        }
        if (
            _isRoundingToleranceGreaterThan(
                underlyingAssetAmount,
                totalUnderlyingAssetAvailable
            )
        ) {
            underlyingAssetAmount = totalUnderlyingAssetAvailable;
        }
        require(
            totalUnderlyingAssetAvailable >= underlyingAssetAmount,
            "TreasuryPool: insufficient liquidity"
        );

        totalUnderlyingAssetAmount = totalUnderlyingAssetAmount.sub(
            underlyingAssetAmount
        );
        totalLtokenAmount = totalLtokenAmount.sub(amount);

        // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
        // slither-disable-next-line reentrancy-events
        emit RemoveLiquidity(
            msg.sender,
            ltokenAddress,
            underlyingAssetAddress,
            amount,
            underlyingAssetAmount,
            block.timestamp
        );

        _ltoken.burn(msg.sender, amount);
        _dsecDistribution.removeDsec(msg.sender, underlyingAssetAmount);
        _underlyingAsset.safeTransfer(msg.sender, underlyingAssetAmount);
    }

    function redeemProviderReward(uint256 fromEpoch, uint256 toEpoch)
        external
        override
    {
        require(fromEpoch <= toEpoch, "TreasuryPool: invalid epoch range");
        require(!paused(), "TreasuryPool: redeem while paused");

        uint256 totalRewardAmount = 0;
        for (uint256 i = fromEpoch; i <= toEpoch; i++) {
            // https://github.com/crytic/slither/wiki/Detector-Documentation#calls-inside-a-loop
            // slither-disable-next-line calls-loop
            if (_dsecDistribution.hasRedeemedDsec(msg.sender, i)) {
                break;
            }

            // https://github.com/crytic/slither/wiki/Detector-Documentation#calls-inside-a-loop
            // slither-disable-next-line calls-loop
            uint256 rewardAmount =
                _dsecDistribution.redeemDsec(msg.sender, i, lpRewardPerEpoch);
            totalRewardAmount = totalRewardAmount.add(rewardAmount);
        }

        if (totalRewardAmount == 0) {
            return;
        }

        emit RedeemProviderReward(
            msg.sender,
            fromEpoch,
            toEpoch,
            lfiAddress,
            totalRewardAmount,
            block.timestamp
        );

        _lfi.redeem(msg.sender, totalRewardAmount);
    }

    function redeemTeamReward(uint256 fromEpoch, uint256 toEpoch)
        external
        override
        onlyBy(teamAccount)
    {
        require(fromEpoch <= toEpoch, "TreasuryPool: invalid epoch range");
        require(!paused(), "TreasuryPool: redeem while paused");

        uint256 totalRewardAmount = 0;
        for (uint256 i = fromEpoch; i <= toEpoch; i++) {
            // https://github.com/crytic/slither/wiki/Detector-Documentation#calls-inside-a-loop
            // slither-disable-next-line calls-loop
            if (_dsecDistribution.hasRedeemedTeamReward(i)) {
                break;
            }

            // https://github.com/crytic/slither/wiki/Detector-Documentation#calls-inside-a-loop
            // slither-disable-next-line calls-loop
            _dsecDistribution.redeemTeamReward(i);
            totalRewardAmount = totalRewardAmount.add(teamRewardPerEpoch);
        }

        if (totalRewardAmount == 0) {
            return;
        }

        emit RedeemTeamReward(
            teamAccount,
            fromEpoch,
            toEpoch,
            lfiAddress,
            totalRewardAmount,
            block.timestamp
        );

        _lfi.redeem(teamAccount, totalRewardAmount);
    }

    function loan(uint256 amount) external override onlyFarmingPool() {
        require(
            amount <= getTotalUnderlyingAssetAvailableCore(),
            "TreasuryPool: insufficient liquidity"
        );

        totalLoanedUnderlyingAssetAmount = totalLoanedUnderlyingAssetAmount.add(
            amount
        );

        emit Loan(amount, msg.sender, block.timestamp);

        _underlyingAsset.safeTransfer(msg.sender, amount);
    }

    function repay(uint256 principal, uint256 interest)
        external
        override
        onlyFarmingPool()
    {
        if (
            _isRoundingToleranceGreaterThan(
                principal,
                totalLoanedUnderlyingAssetAmount
            )
        ) {
            principal = totalLoanedUnderlyingAssetAmount;
        }

        require(
            principal <= totalLoanedUnderlyingAssetAmount,
            "TreasuryPool: invalid amount"
        );

        uint256 totalAmount = principal.add(interest);
        totalLoanedUnderlyingAssetAmount = totalLoanedUnderlyingAssetAmount.sub(
            principal
        );
        totalUnderlyingAssetAmount = totalUnderlyingAssetAmount.add(interest);

        emit Repay(principal, interest, msg.sender, block.timestamp);

        _underlyingAsset.safeTransferFrom(
            msg.sender,
            address(this),
            totalAmount
        );
    }

    function estimateUnderlyingAssetsFor(uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        uint256 ltokenAmount;
        uint256 length = _farmingPoolAddresses.length;
        if (length > 0) {
            uint256 totalBorrowerInterestEarning = 0;
            for (uint256 i = 0; i < length; i++) {
                IFarmingPool farmingPool =
                    IFarmingPool(_farmingPoolAddresses[i]);
                // https://github.com/crytic/slither/wiki/Detector-Documentation#calls-inside-a-loop
                // slither-disable-next-line calls-loop
                uint256 borrowerInterestEarning =
                    farmingPool.estimateBorrowerInterestEarning();
                totalBorrowerInterestEarning = totalBorrowerInterestEarning.add(
                    borrowerInterestEarning
                );
            }
            ltokenAmount = _divExchangeRate(
                amount,
                totalBorrowerInterestEarning
            );
        } else {
            ltokenAmount = amount;
        }

        return ltokenAmount;
    }

    function estimateLtokensFor(uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        uint256 underlyingAssetAmount;
        uint256 length = _farmingPoolAddresses.length;
        if (length > 0) {
            uint256 totalBorrowerInterestEarning = 0;
            for (uint256 i = 0; i < length; i++) {
                IFarmingPool farmingPool =
                    IFarmingPool(_farmingPoolAddresses[i]);
                // https://github.com/crytic/slither/wiki/Detector-Documentation#calls-inside-a-loop
                // slither-disable-next-line calls-loop
                uint256 borrowerInterestEarning =
                    farmingPool.estimateBorrowerInterestEarning();
                totalBorrowerInterestEarning = totalBorrowerInterestEarning.add(
                    borrowerInterestEarning
                );
            }
            underlyingAssetAmount = _mulExchangeRate(
                amount,
                totalBorrowerInterestEarning
            );
        } else {
            underlyingAssetAmount = amount;
        }

        return underlyingAssetAmount;
    }

    /**
     * @return The utilisation rate, it represents as percentage in 64.64-bit fixed
     *         point number e.g. 0x50FFFFFED35A2FA158 represents 80.99999993% with
     *         an invisible decimal point in between 0x50 and 0xFFFFFED35A2FA158.
     */
    function getUtilisationRate() external view override returns (uint256) {
        // https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
        // slither-disable-next-line incorrect-equality
        if (totalUnderlyingAssetAmount == 0) {
            return 0;
        }

        // https://github.com/crytic/slither/wiki/Detector-Documentation#too-many-digits
        // slither-disable-next-line too-many-digits
        require(
            totalLoanedUnderlyingAssetAmount <
                0x0010000000000000000000000000000000000000000,
            "TreasuryPool: overflow"
        );

        uint256 dividend = totalLoanedUnderlyingAssetAmount.mul(100) << 64;
        return dividend.div(totalUnderlyingAssetAmount);
    }

    function getTotalUnderlyingAssetAvailableCore()
        internal
        view
        returns (uint256)
    {
        return totalUnderlyingAssetAmount.sub(totalLoanedUnderlyingAssetAmount);
    }

    function getTotalUnderlyingAssetAvailable()
        external
        view
        override
        returns (uint256)
    {
        return getTotalUnderlyingAssetAvailableCore();
    }

    function setGovernanceAccount(address newGovernanceAccount)
        external
        onlyBy(governanceAccount)
    {
        require(
            newGovernanceAccount != address(0),
            "TreasuryPool: new governance account is the zero address"
        );

        governanceAccount = newGovernanceAccount;
    }

    function addFarmingPoolAddress(address address_)
        external
        onlyBy(governanceAccount)
    {
        require(
            address_ != address(0),
            "TreasuryPool: address is the zero address"
        );
        require(
            !_farmingPoolAddresses.contains(address_),
            "TreasuryPool: address is already a farming pool"
        );

        _farmingPoolAddresses.push(address_);
    }

    function removeFarmingPoolAddress(address address_)
        external
        onlyBy(governanceAccount)
    {
        require(
            address_ != address(0),
            "TreasuryPool: address is the zero address"
        );

        uint256 index = _farmingPoolAddresses.indexOf(address_);
        require(
            index > 0,
            "TreasuryPool: address not an existing farming pool"
        );

        _farmingPoolAddresses.removeAt(index);
    }

    function pause() external onlyBy(governanceAccount) {
        _pause();
    }

    function unpause() external onlyBy(governanceAccount) {
        _unpause();
    }

    function _divExchangeRate(uint256 amount, uint256 borrowerInterestEarning)
        private
        view
        returns (uint256)
    {
        if (totalLtokenAmount > 0) {
            // amount/((totalUnderlyingAssetAmount+borrowerInterestEarning)/totalLtokenAmount)
            return
                amount.mul(totalLtokenAmount).div(
                    totalUnderlyingAssetAmount.add(borrowerInterestEarning)
                );
        } else {
            return amount;
        }
    }

    function _mulExchangeRate(uint256 amount, uint256 borrowerInterestEarning)
        private
        view
        returns (uint256)
    {
        if (totalLtokenAmount > 0) {
            // amount*((totalUnderlyingAssetAmount+borrowerInterestEarning)/totalLtokenAmount)
            return
                amount
                    .mul(
                    totalUnderlyingAssetAmount.add(borrowerInterestEarning)
                )
                    .div(totalLtokenAmount);
        } else {
            return amount;
        }
    }

    function _isRoundingToleranceGreaterThan(uint256 expected, uint256 actual)
        private
        pure
        returns (bool)
    {
        return expected > actual && expected.sub(actual) <= ROUNDING_TOLERANCE;
    }
}
