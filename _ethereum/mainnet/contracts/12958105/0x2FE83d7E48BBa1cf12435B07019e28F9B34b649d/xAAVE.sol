pragma solidity 0.6.2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ERC20.sol";

import "./Pausable.sol";

import "./IxTokenManager.sol";

interface IAaveProtoGovernance {
    function submitVoteByVoter(
        uint256 _proposalId,
        uint256 _vote,
        IERC20 _asset
    ) external;
}

interface IKyberNetworkProxy {
    function swapEtherToToken(ERC20 token, uint256 minConversionRate)
        external
        payable
        returns (uint256);

    function swapTokenToToken(
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        uint256 minConversionRate
    ) external returns (uint256);

    function swapTokenToEther(
        ERC20 token,
        uint256 tokenQty,
        uint256 minRate
    ) external payable returns (uint256);
}

interface IStakedAave {
    function stake(address to, uint256 amount) external;

    function redeem(address to, uint256 amount) external;

    function cooldown() external;

    function claimRewards(address to, uint256 amount) external;
}

interface IAaveGovernanceV2 {
    function submitVote(uint256 proposalId, bool support) external;
}

contract xAAVE is ERC20, Pausable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant DEC_18 = 1e18;
    uint256 private constant MAX_UINT = 2**256 - 1;
    uint256 private constant AAVE_BUFFER_TARGET = 20; // 5% target
    uint256 private constant INITIAL_SUPPLY_MULTIPLIER = 100;
    uint256 public constant LIQUIDATION_TIME_PERIOD = 4 weeks;

    uint256 public withdrawableAaveFees;
    uint256 public adminActiveTimestamp;

    address private manager;

    IERC20 private aave;
    IERC20 private votingAave;
    IStakedAave private stakedAave;
    IAaveProtoGovernance private governance;

    IKyberNetworkProxy private kyberProxy;

    bool public cooldownActivated;

    string public mandate;

    struct FeeDivisors {
        uint256 mintFee;
        uint256 burnFee;
        uint256 claimFee;
    }

    FeeDivisors public feeDivisors;

    IAaveGovernanceV2 private governanceV2;

    address private manager2;

    mapping(address => bool) private whitelist;

    uint256 private constant AFFILIATE_FEE_DIVISOR = 4;

    // addresses are locked from transfer after minting or burning
    uint256 private constant BLOCK_LOCK_COUNT = 6;
    // last block for which this address is timelocked
    mapping(address => uint256) public lastLockedBlock;

    IxTokenManager private xTokenManager;

    function initialize(
        IERC20 _aave,
        IERC20 _votingAave,
        IStakedAave _stakedAave,
        IAaveProtoGovernance _governance,
        IKyberNetworkProxy _kyberProxy,
        uint256 _mintFeeDivisor,
        uint256 _burnFeeDivisor,
        uint256 _claimFeeDivisor,
        string memory _symbol,
        string memory _mandate
    ) public initializer {
        __Ownable_init();
        __ERC20_init("xAAVE", _symbol);

        aave = _aave;
        votingAave = _votingAave;
        stakedAave = _stakedAave;
        governance = _governance;
        kyberProxy = _kyberProxy;
        mandate = _mandate;

        _setFeeDivisors(_mintFeeDivisor, _burnFeeDivisor, _claimFeeDivisor);
        _updateAdminActiveTimestamp();
    }

    /* ========================================================================================= */
    /*                                        Investor-Facing                                    */
    /* ========================================================================================= */

    /*
     * @dev Mint xAAVE using ETH
     * @param minRate: Kyber min rate ETH=>AAVE
     */
    function mint(uint256 minRate)
        public
        payable
        whenNotPaused
        notLocked(msg.sender)
    {
        require(msg.value > 0, "Must send ETH");
        lock(msg.sender);

        (uint256 stakedBalance, uint256 bufferBalance) = getFundBalances();

        uint256 fee = _calculateFee(msg.value, feeDivisors.mintFee);

        uint256 incrementalAave = kyberProxy.swapEtherToToken.value(
            msg.value.sub(fee)
        )(ERC20(address(aave)), minRate);
        return _mintInternal(bufferBalance, stakedBalance, incrementalAave);
    }

    /*
     * @dev Mint xAAVE using AAVE
     * @notice Must run ERC20 approval first
     * @param aaveAmount: AAVE to contribute
     * @param affiliate: optional recipient of 25% of fees
     */
    function mintWithToken(uint256 aaveAmount, address affiliate)
        public
        whenNotPaused
        notLocked(msg.sender)
    {
        require(aaveAmount > 0, "Must send AAVE");
        lock(msg.sender);

        (uint256 stakedBalance, uint256 bufferBalance) = getFundBalances();

        aave.safeTransferFrom(msg.sender, address(this), aaveAmount);

        uint256 fee = _calculateFee(aaveAmount, feeDivisors.mintFee);

        if (affiliate == address(0)) {
            _incrementWithdrawableAaveFees(fee);
        } else {
            require(whitelist[affiliate], "Invalid address");

            uint256 affiliateFee = fee.div(AFFILIATE_FEE_DIVISOR);
            aave.safeTransfer(affiliate, affiliateFee);
            _incrementWithdrawableAaveFees(fee.sub(affiliateFee));
        }

        uint256 incrementalAave = aaveAmount.sub(fee);
        return _mintInternal(bufferBalance, stakedBalance, incrementalAave);
    }

    function _mintInternal(
        uint256 _bufferBalance,
        uint256 _stakedBalance,
        uint256 _incrementalAave
    ) internal {
        uint256 totalSupply = totalSupply();
        uint256 allocationToStake = _calculateAllocationToStake(
            _bufferBalance,
            _incrementalAave,
            _stakedBalance,
            totalSupply
        );
        _stake(allocationToStake);

        uint256 aaveHoldings = _bufferBalance.add(_stakedBalance);
        uint256 mintAmount = calculateMintAmount(
            _incrementalAave,
            aaveHoldings,
            totalSupply
        );
        return super._mint(msg.sender, mintAmount);
    }

    /*
     * @dev Burn xAAVE tokens
     * @notice Will fail if redemption value exceeds available liquidity
     * @param redeemAmount: xAAVE to redeem
     * @param redeemForEth: if true, redeem xAAVE for ETH
     * @param minRate: Kyber.getExpectedRate AAVE=>ETH if redeemForEth true (no-op if false)
     */
    function burn(
        uint256 tokenAmount,
        bool redeemForEth,
        uint256 minRate
    ) public notLocked(msg.sender) {
        require(tokenAmount > 0, "Must send xAAVE");
        lock(msg.sender);

        (uint256 stakedBalance, uint256 bufferBalance) = getFundBalances();
        uint256 aaveHoldings = bufferBalance.add(stakedBalance);
        uint256 proRataAave = aaveHoldings.mul(tokenAmount).div(totalSupply());

        require(proRataAave <= bufferBalance, "Insufficient exit liquidity");
        super._burn(msg.sender, tokenAmount);

        if (redeemForEth) {
            uint256 ethRedemptionValue = kyberProxy.swapTokenToEther(
                ERC20(address(aave)),
                proRataAave,
                minRate
            );
            uint256 fee = _calculateFee(
                ethRedemptionValue,
                feeDivisors.burnFee
            );
            (bool success, ) = msg.sender.call.value(
                ethRedemptionValue.sub(fee)
            )("");
            require(success, "Transfer failed");
        } else {
            uint256 fee = _calculateFee(proRataAave, feeDivisors.burnFee);
            _incrementWithdrawableAaveFees(fee);
            aave.safeTransfer(msg.sender, proRataAave.sub(fee));
        }
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        notLocked(msg.sender)
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override notLocked(sender) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    /* ========================================================================================= */
    /*                                             NAV                                           */
    /* ========================================================================================= */

    function getAmountOfAssetHeld() public view returns (uint256) {
        return getFundHoldings();
    }

    function getFundHoldings() public view returns (uint256) {
        return getStakedBalance().add(getBufferBalance());
    }

    function getStakedBalance() public view returns (uint256) {
        return IERC20(address(stakedAave)).balanceOf(address(this));
    }

    function getBufferBalance() public view returns (uint256) {
        return aave.balanceOf(address(this)).sub(withdrawableAaveFees);
    }

    function getFundBalances() public view returns (uint256, uint256) {
        return (getStakedBalance(), getBufferBalance());
    }

    function getWithdrawableFees()
        public
        view
        returns (address[2] memory feeAssets, uint256[2] memory feeAmounts)
    {
        feeAssets[0] = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH
        feeAssets[1] = address(aave);
        feeAmounts[0] = address(this).balance;
        feeAmounts[1] = withdrawableAaveFees;
    }

    /*
     * @dev Helper function for mint, mintWithToken
     * @param incrementalAave: AAVE contributed
     * @param aaveHoldingsBefore: xAAVE buffer reserve + staked balance
     * @param totalSupply: xAAVE.totalSupply()
     */
    function calculateMintAmount(
        uint256 incrementalAave,
        uint256 aaveHoldingsBefore,
        uint256 totalSupply
    ) public view returns (uint256 mintAmount) {
        if (totalSupply == 0)
            return incrementalAave.mul(INITIAL_SUPPLY_MULTIPLIER);

        mintAmount = (incrementalAave).mul(totalSupply).div(aaveHoldingsBefore);
    }

    /*
     * @dev Helper function for mint, mintWithToken
     * @param _bufferBalanceBefore: xAAVE AAVE buffer balance pre-mint
     * @param _incrementalAave: AAVE contributed
     * @param _stakedBalance: xAAVE stakedAave balance pre-mint
     * @param _totalSupply: xAAVE.totalSupply()
     */
    function _calculateAllocationToStake(
        uint256 _bufferBalanceBefore,
        uint256 _incrementalAave,
        uint256 _stakedBalance,
        uint256 _totalSupply
    ) internal view returns (uint256) {
        if (_totalSupply == 0)
            return
                _incrementalAave.sub(_incrementalAave.div(AAVE_BUFFER_TARGET));

        uint256 bufferBalanceAfter = _bufferBalanceBefore.add(_incrementalAave);
        uint256 aaveHoldings = bufferBalanceAfter.add(_stakedBalance);

        uint256 targetBufferBalance = aaveHoldings.div(AAVE_BUFFER_TARGET);

        // allocate full incremental aave to buffer balance
        if (bufferBalanceAfter < targetBufferBalance) return 0;

        return bufferBalanceAfter.sub(targetBufferBalance);
    }

    /* ========================================================================================= */
    /*                                   Fund Management - Admin                                 */
    /* ========================================================================================= */

    /*
     * @notice xAAVE only stakes when cooldown is not active
     * @param _amount: allocation to staked balance
     */
    function _stake(uint256 _amount) private {
        if (_amount > 0 && !cooldownActivated) {
            stakedAave.stake(address(this), _amount);
        }
    }

    /*
     * @notice Admin-callable function in case of persistent depletion of buffer reserve
     * or emergency shutdown
     * @notice Incremental AAVE will only be allocated to buffer reserve
     */
    function cooldown() public onlyOwnerOrManager {
        _updateAdminActiveTimestamp();
        _cooldown();
    }

    /*
     * @notice Admin-callable function disabling cooldown and returning fund to
     * normal course of management
     */
    function disableCooldown() public onlyOwnerOrManager {
        _updateAdminActiveTimestamp();
        cooldownActivated = false;
    }

    /*
     * @notice Admin-callable function available once cooldown has been activated
     * and requisite time elapsed
     * @notice Called when buffer reserve is persistently insufficient to satisfy
     * redemption requirements
     * @param amount: AAVE to unstake
     */
    function redeem(uint256 amount) public onlyOwnerOrManager {
        _updateAdminActiveTimestamp();
        _redeem(amount);
    }

    /*
     * @notice Admin-callable function claiming staking rewards
     * @notice Called regularly on behalf of pool in normal course of management
     */
    function claim() public onlyOwnerOrManager {
        _updateAdminActiveTimestamp();
        _claim();
    }

    /*
     * @notice Records admin activity
     * @notice Because Aave staking "locks" capital in contract and only admin has power
     * to cooldown and redeem in normal course, this function certifies that admin
     * is still active and capital is accessible
     * @notice If not certified for a period exceeding LIQUIDATION_TIME_PERIOD,
     * emergencyCooldown and emergencyRedeem become available to non-admin caller
     */
    function _updateAdminActiveTimestamp() private {
        adminActiveTimestamp = block.timestamp;
    }

    /*
     * @notice Function for participating in Aave Governance
     * @notice Called regularly on behalf of pool in normal course of management
     * @param _proposalId:
     * @param _vote:
     */
    function vote(uint256 _proposalId, uint256 _vote)
        public
        onlyOwnerOrManager
    {
        governance.submitVoteByVoter(_proposalId, _vote, votingAave);
    }

    /*
     * @notice Callable in case of fee revenue or extra yield opportunities in non-AAVE ERC20s
     * @notice Reinvested in AAVE
     * @param tokens: Addresses of non-AAVE tokens with balance in xAAVE
     * @param minReturns: Kyber.getExpectedRate for non-AAVE tokens
     */
    function convertTokensToTarget(
        address[] calldata tokens,
        uint256[] calldata minReturns
    ) external onlyOwnerOrManager {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tokenBal = IERC20(tokens[i]).balanceOf(address(this));
            uint256 bufferBalancerBefore = getBufferBalance();

            kyberProxy.swapTokenToToken(
                ERC20(tokens[i]),
                tokenBal,
                ERC20(address(aave)),
                minReturns[i]
            );
            uint256 bufferBalanceAfter = getBufferBalance();

            uint256 fee = _calculateFee(
                bufferBalanceAfter.sub(bufferBalancerBefore),
                feeDivisors.claimFee
            );
            _incrementWithdrawableAaveFees(fee);
        }
    }

    /* ========================================================================================= */
    /*                                   Fund Management - Public                                */
    /* ========================================================================================= */

    /*
     * @notice If admin doesn't certify within LIQUIDATION_TIME_PERIOD,
     * admin functions unlock to public
     */
    modifier liquidationTimeElapsed {
        require(
            block.timestamp > adminActiveTimestamp.add(LIQUIDATION_TIME_PERIOD),
            "Liquidation time hasn't elapsed"
        );
        _;
    }

    /*
     * @notice First step in xAAVE unwind in event of admin failure/incapacitation
     */
    function emergencyCooldown() public liquidationTimeElapsed {
        _cooldown();
    }

    /*
     * @notice Second step in xAAVE unwind in event of admin failure/incapacitation
     * @notice Called after cooldown period, during unwind period
     */
    function emergencyRedeem(uint256 amount) public liquidationTimeElapsed {
        _redeem(amount);
    }

    /*
     * @notice Public callable function for claiming staking rewards
     */
    function claimExternal() public {
        _claim();
    }

    /* ========================================================================================= */
    /*                                   Fund Management - Private                               */
    /* ========================================================================================= */

    function _cooldown() private {
        cooldownActivated = true;
        stakedAave.cooldown();
    }

    function _redeem(uint256 _amount) private {
        stakedAave.redeem(address(this), _amount);
    }

    function _claim() private {
        uint256 bufferBalanceBefore = getBufferBalance();

        stakedAave.claimRewards(address(this), MAX_UINT);

        uint256 bufferBalanceAfter = getBufferBalance();
        uint256 claimed = bufferBalanceAfter.sub(bufferBalanceBefore);

        uint256 fee = _calculateFee(claimed, feeDivisors.claimFee);
        _incrementWithdrawableAaveFees(fee);
    }

    /* ========================================================================================= */
    /*                                         Fee Logic                                         */
    /* ========================================================================================= */

    function _calculateFee(uint256 _value, uint256 _feeDivisor)
        internal
        pure
        returns (uint256 fee)
    {
        if (_feeDivisor > 0) {
            fee = _value.div(_feeDivisor);
        }
    }

    function _incrementWithdrawableAaveFees(uint256 _feeAmount) private {
        withdrawableAaveFees = withdrawableAaveFees.add(_feeAmount);
    }

    /*
     * @notice Inverse of fee i.e., a fee divisor of 100 == 1%
     * @notice Three fee types
     * @dev Mint fee 0 or <= 2%
     * @dev Burn fee 0 or <= 1%
     * @dev Claim fee 0 <= 4%
     */
    function setFeeDivisors(
        uint256 mintFeeDivisor,
        uint256 burnFeeDivisor,
        uint256 claimFeeDivisor
    ) public onlyOwner {
        _setFeeDivisors(mintFeeDivisor, burnFeeDivisor, claimFeeDivisor);
    }

    function _setFeeDivisors(
        uint256 _mintFeeDivisor,
        uint256 _burnFeeDivisor,
        uint256 _claimFeeDivisor
    ) private {
        require(_mintFeeDivisor == 0 || _mintFeeDivisor >= 50, "Invalid fee");
        require(_burnFeeDivisor == 0 || _burnFeeDivisor >= 100, "Invalid fee");
        require(_claimFeeDivisor >= 25, "Invalid fee");
        feeDivisors.mintFee = _mintFeeDivisor;
        feeDivisors.burnFee = _burnFeeDivisor;
        feeDivisors.claimFee = _claimFeeDivisor;
    }

    /*
     * @notice Public callable function for claiming staking rewards
     */
    function withdrawFees() public {
        require(
            xTokenManager.isRevenueController(msg.sender),
            "Callable only by Revenue Controller"
        );
        (bool success, ) = msg.sender.call.value(address(this).balance)("");
        require(success, "Transfer failed");

        uint256 aaveFees = withdrawableAaveFees;
        withdrawableAaveFees = 0;
        aave.safeTransfer(msg.sender, aaveFees);
    }

    /* ========================================================================================= */
    /*                                           Utils                                           */
    /* ========================================================================================= */

    function pauseContract() public onlyOwnerOrManager returns (bool) {
        _pause();
        return true;
    }

    function unpauseContract() public onlyOwnerOrManager returns (bool) {
        _unpause();
        return true;
    }

    function approveStakingContract() public onlyOwnerOrManager {
        aave.safeApprove(address(stakedAave), MAX_UINT);
    }

    function approveKyberContract(address _token) public onlyOwnerOrManager {
        IERC20(_token).safeApprove(address(kyberProxy), MAX_UINT);
    }

    /*
     * @notice Callable by admin to ensure LIQUIDATION_TIME_PERIOD won't elapse
     */
    function certifyAdmin() public onlyOwnerOrManager {
        _updateAdminActiveTimestamp();
    }

    /*
     * @notice Emergency function in case of errant transfer of
     * xAAVE token directly to contract
     */
    function withdrawNativeToken() public onlyOwnerOrManager {
        uint256 tokenBal = balanceOf(address(this));
        if (tokenBal > 0) {
            IERC20(address(this)).safeTransfer(msg.sender, tokenBal);
        }
    }

    modifier onlyOwnerOrManager {
        require(
            msg.sender == owner() ||
                xTokenManager.isManager(msg.sender, address(this)),
            "Non-admin caller"
        );
        _;
    }

    /**
     *  BlockLock logic: Implements locking of mint, burn, transfer and transferFrom
     *  functions via a notLocked modifier.
     *  Functions are locked per address.
     */
    modifier notLocked(address lockedAddress) {
        require(
            lastLockedBlock[lockedAddress] <= block.number,
            "Function is temporarily locked for this address"
        );
        _;
    }

    /**
     * @dev Lock mint, burn, transfer and transferFrom functions
     *      for _address for BLOCK_LOCK_COUNT blocks
     */
    function lock(address _address) private {
        lastLockedBlock[_address] = block.number + BLOCK_LOCK_COUNT;
    }

    receive() external payable {
        require(msg.sender != tx.origin, "Errant ETH deposit");
    }

    function setVotingAaveAddress(IERC20 _votingAave) public onlyOwner {
        votingAave = _votingAave;
    }

    function setGovernanceV2Address(IAaveGovernanceV2 _governanceV2)
        public
        onlyOwner
    {
        if (address(governanceV2) == address(0)) {
            governanceV2 = _governanceV2;
        }
    }

    function voteV2(uint256 proposalId, bool support)
        public
        onlyOwnerOrManager
    {
        governanceV2.submitVote(proposalId, support);
    }

    function addToWhitelist(address _address) external onlyOwnerOrManager {
        whitelist[_address] = true;
    }

    function removeFromWhitelist(address _address) external onlyOwnerOrManager {
        whitelist[_address] = false;
    }

    function setxTokenManager(IxTokenManager _manager) external onlyOwner {
        require(
            address(xTokenManager) == address(0),
            "Cannot set manager twice"
        );
        xTokenManager = _manager;
    }
}
