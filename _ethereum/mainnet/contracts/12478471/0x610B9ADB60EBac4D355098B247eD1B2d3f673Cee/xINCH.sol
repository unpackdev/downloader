//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.2;

import "./SafeERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Initializable.sol";
import "./Pausable.sol";

import "./IGovernanceRewards.sol";
import "./IExchangeGovernance.sol";
import "./IGovernanceMothership.sol";
import "./IMooniswapPoolGovernance.sol";
import "./IMooniswapFactoryGovernance.sol";
import "./IOneInchLiquidityProtocol.sol";

contract xINCH is
    Initializable,
    ERC20UpgradeSafe,
    OwnableUpgradeSafe,
    PausableUpgradeSafe
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant LIQUIDATION_TIME_PERIOD = 4 weeks;
    uint256 private constant INITIAL_SUPPLY_MULTIPLIER = 10;
    uint256 private constant BUFFER_TARGET = 20; // 5% target
    uint256 private constant MAX_UINT = 2**256 - 1;

    uint256 public adminActiveTimestamp;
    uint256 public withdrawableOneInchFees;

    IERC20 private oneInch;

    IOneInchLiquidityProtocol private oneInchLiquidityProtocol;
    IMooniswapFactoryGovernance private factoryGovernance;
    IGovernanceMothership private governanceMothership;
    IExchangeGovernance private exchangeGovernance;
    IGovernanceRewards private governanceRewards;

    address private oneInchExchange;

    address private manager;
    address private manager2;

    address private constant ETH_ADDRESS = address(0);

    struct FeeDivisors {
        uint256 mintFee;
        uint256 burnFee;
        uint256 claimFee;
    }

    FeeDivisors public feeDivisors;

    string public mandate;
    
    // addresses are locked from transfer after minting or burning
    uint256 private constant BLOCK_LOCK_COUNT = 6;
    // last block for which this address is timelocked
    mapping(address => uint256) public lastLockedBlock;

    event Rebalance();
    event FeeDivisorsSet(uint256 mintFee, uint256 burnFee, uint256 claimFee);
    event FeeWithdraw(uint256 ethFee, uint256 inchFee);

    function initialize(
        string calldata _symbol,
        string calldata _mandate,
        IERC20 _oneInch,
        IGovernanceMothership _governanceMothership,
        IOneInchLiquidityProtocol _oneInchLiquidityProtocol,
        uint256 _mintFeeDivisor,
        uint256 _burnFeeDivisor,
        uint256 _claimFeeDivisor
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC20_init_unchained("xINCH", _symbol);

        mandate = _mandate;

        oneInch = _oneInch;
        governanceMothership = _governanceMothership;
        oneInchLiquidityProtocol = _oneInchLiquidityProtocol;

        _setFeeDivisors(_mintFeeDivisor, _burnFeeDivisor, _claimFeeDivisor);
    }

    /*
     * @dev Mint xINCH using ETH
     * @param minReturn: Min return to pass to 1Inch trade
     */
    function mint(uint256 minReturn)
        external
        payable
        whenNotPaused
        notLocked(msg.sender)
    {
        require(msg.value > 0, "Must send ETH");
        lock(msg.sender);

        uint256 fee = _calculateFee(msg.value, feeDivisors.mintFee);
        uint256 ethValue = msg.value.sub(fee);
        uint256 bufferBalanceBefore = getBufferBalance();
        oneInchLiquidityProtocol.swap.value(ethValue)(
            ETH_ADDRESS,
            address(oneInch),
            ethValue,
            minReturn,
            address(0)
        );

        _mintInternal(getBufferBalance().sub(bufferBalanceBefore));
    }

    /*
     * @dev Mint xINCH using INCH
     * @param oneInchAmount: INCH tokens to contribute
     */
    function mintWithToken(uint256 oneInchAmount)
        external
        whenNotPaused
        notLocked(msg.sender)
    {
        require(oneInchAmount > 0, "Must send token");
        lock(msg.sender);
        oneInch.safeTransferFrom(msg.sender, address(this), oneInchAmount);

        uint256 fee = _calculateFee(oneInchAmount, feeDivisors.mintFee);
        _incrementWithdrawableOneInchFees(fee);

        return _mintInternal(oneInchAmount.sub(fee));
    }

    function _mintInternal(uint256 _incrementalOneInch) private {
        uint256 mintAmount =
            calculateMintAmount(_incrementalOneInch, totalSupply());

        return super._mint(msg.sender, mintAmount);
    }

    function calculateMintAmount(
        uint256 incrementalOneInch,
        uint256 totalSupply
    ) public view returns (uint256 mintAmount) {
        if (totalSupply == 0)
            return incrementalOneInch.mul(INITIAL_SUPPLY_MULTIPLIER);
        uint256 previousNav = getNav().sub(incrementalOneInch);
        mintAmount = (incrementalOneInch).mul(totalSupply).div(previousNav);
    }

    /*
     * @dev Burn xINCH tokens
     * @notice Will fail if pro rata balance exceeds available liquidity
     * @param tokenAmount: xINCH tokens to burn
     * @param redeemForEth: Redeem for ETH or INCH
     * @param minReturn: Min return to pass to 1Inch trade
     */
    function burn(
        uint256 tokenAmount,
        bool redeemForEth,
        uint256 minReturn
    ) external notLocked(msg.sender) {
        require(tokenAmount > 0, "Must send xINCH");
        lock(msg.sender);

        uint256 stakedBalance = getStakedBalance();
        uint256 bufferBalance = getBufferBalance();
        uint256 inchHoldings = stakedBalance.add(bufferBalance);
        uint256 proRataInch = inchHoldings.mul(tokenAmount).div(totalSupply());

        require(proRataInch <= bufferBalance, "Insufficient exit liquidity");
        super._burn(msg.sender, tokenAmount);

        if (redeemForEth) {
            uint256 fee = _calculateFee(proRataInch, feeDivisors.burnFee);
            _incrementWithdrawableOneInchFees(fee);
            oneInchLiquidityProtocol.swapFor(
                address(oneInch),
                ETH_ADDRESS,
                proRataInch.sub(fee),
                minReturn,
                address(0),
                msg.sender
            );
        } else {
            uint256 fee = _calculateFee(proRataInch, feeDivisors.burnFee);
            _incrementWithdrawableOneInchFees(fee);
            oneInch.safeTransfer(msg.sender, proRataInch.sub(fee));
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
    /*                                            Management                                     */
    /* ========================================================================================= */

    function getNav() public view returns (uint256) {
        return getStakedBalance().add(getBufferBalance());
    }

    function getStakedBalance() public view returns (uint256) {
        return IERC20(address(governanceMothership)).balanceOf(address(this));
    }

    function getBufferBalance() public view returns (uint256) {
        return oneInch.balanceOf(address(this)).sub(withdrawableOneInchFees);
    }

    /*
     * @dev Admin function for claiming INCH rewards
     */
    function getReward() external onlyOwnerOrManager {
        _certifyAdmin();
        _getReward();
    }

    /*
     * @dev Public callable function for claiming INCH rewards
     */
    function getRewardExternal() external {
        _getReward();
    }

    function _getReward() private {
        uint256 bufferBalanceBefore = getBufferBalance();
        governanceRewards.getReward();

        uint256 bufferBalanceAfter = getBufferBalance();
        uint256 fee =
            _calculateFee(
                bufferBalanceAfter.sub(bufferBalanceBefore),
                feeDivisors.claimFee
            );
        _incrementWithdrawableOneInchFees(fee);
    }

    function _stake(uint256 _amount) private {
        governanceMothership.stake(_amount);
    }

    /*
     * @dev Admin function for unstaking beyond the scope of a rebalance
     */
    function adminUnstake(uint256 _amount) external onlyOwnerOrManager {
        _unstake(_amount);
    }

    /*
     * @dev Public callable function for unstaking in event of admin failure/incapacitation
     */
    function emergencyUnstake(uint256 _amount) external {
        require(
            adminActiveTimestamp.add(LIQUIDATION_TIME_PERIOD) < block.timestamp,
            "Liquidation time not elapsed"
        );
        _unstake(_amount);
    }

    function unstake(uint256 _amount) external onlyOwnerOrManager {
        _unstake(_amount);
    }

    function _unstake(uint256 _amount) private {
        governanceMothership.unstake(_amount);
    }

    /*
     * @dev Admin function for collecting reward and restoring target buffer balance
     */
    function rebalance() external onlyOwnerOrManager {
        _certifyAdmin();
        _getReward();
        _rebalance();
    }

    /*
     * @dev Public callable function for collecting reward and restoring target buffer balance
     */
    function rebalanceExternal() external {
        require(
            adminActiveTimestamp.add(LIQUIDATION_TIME_PERIOD) > block.timestamp,
            "Liquidation time elapsed; no more staking"
        );
        _getReward();
        _rebalance();
    }

    function _rebalance() private {
        uint256 stakedBalance = getStakedBalance();
        uint256 bufferBalance = getBufferBalance();
        uint256 targetBuffer =
            (stakedBalance.add(bufferBalance)).div(BUFFER_TARGET);

        if (bufferBalance > targetBuffer) {
            _stake(bufferBalance.sub(targetBuffer));
        } else {
            _unstake(targetBuffer.sub(bufferBalance));
        }

        emit Rebalance();
    }

    function _calculateFee(uint256 _value, uint256 _feeDivisor)
        internal
        pure
        returns (uint256 fee)
    {
        if (_feeDivisor > 0) {
            fee = _value.div(_feeDivisor);
        }
    }

    function _incrementWithdrawableOneInchFees(uint256 _feeAmount) private {
        withdrawableOneInchFees = withdrawableOneInchFees.add(_feeAmount);
    }

    /* ========================================================================================= */
    /*                                          Governance                                       */
    /* ========================================================================================= */

    function setFactoryGovernanceAddress(
        IMooniswapFactoryGovernance _factoryGovernance
    ) external onlyOwnerOrManager {
        factoryGovernance = _factoryGovernance;
    }

    function setGovernanceRewardsAddress(IGovernanceRewards _governanceRewards)
        external
        onlyOwnerOrManager
    {
        governanceRewards = _governanceRewards;
    }

    function setExchangeGovernanceAddress(
        IExchangeGovernance _exchangeGovernance
    ) external onlyOwnerOrManager {
        exchangeGovernance = _exchangeGovernance;
    }

    function defaultDecayPeriodVote(uint256 vote) external onlyOwnerOrManager {
        factoryGovernance.defaultDecayPeriodVote(vote);
    }

    function defaultFeeVote(uint256 vote) external onlyOwnerOrManager {
        factoryGovernance.defaultFeeVote(vote);
    }

    function defaultSlippageFeeVote(uint256 vote) external onlyOwnerOrManager {
        factoryGovernance.defaultSlippageFeeVote(vote);
    }

    function governanceShareVote(uint256 vote) external onlyOwnerOrManager {
        factoryGovernance.governanceShareVote(vote);
    }

    function referralShareVote(uint256 vote) external onlyOwnerOrManager {
        factoryGovernance.referralShareVote(vote);
    }

    function leftoverShareVote(uint256 govShare, uint256 refShare)
        external
        onlyOwnerOrManager
    {
        exchangeGovernance.leftoverShareVote(govShare, refShare);
    }

    function poolFeeVote(address pool, uint256 vote)
        external
        onlyOwnerOrManager
    {
        IMooniswapPoolGovernance(pool).feeVote(vote);
    }

    function poolSlippageFeeVote(address pool, uint256 vote)
        external
        onlyOwnerOrManager
    {
        IMooniswapPoolGovernance(pool).slippageFeeVote(vote);
    }

    function poolDecayPeriodVote(address pool, uint256 vote)
        external
        onlyOwnerOrManager
    {
        IMooniswapPoolGovernance(pool).decayPeriodVote(vote);
    }

    /* ========================================================================================= */
    /*                                              Utils                                        */
    /* ========================================================================================= */

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

        emit FeeDivisorsSet(_mintFeeDivisor, _burnFeeDivisor, _claimFeeDivisor);
    }

    function pauseContract() public onlyOwnerOrManager returns (bool) {
        _pause();
        return true;
    }

    function unpauseContract() public onlyOwnerOrManager returns (bool) {
        _unpause();
        return true;
    }

    /*
     * @notice Registers that admin is present and active
     * @notice If admin isn't certified within liquidation time period,
     * emergencyUnstake function becomes callable
     */
    function _certifyAdmin() private {
        adminActiveTimestamp = block.timestamp;
    }

    function setManager(address _manager) external onlyOwner {
        manager = _manager;
    }

    function setManager2(address _manager2) external onlyOwner {
        manager2 = _manager2;
    }

    function approveInch(address _toApprove) external onlyOwnerOrManager {
        require(_toApprove == address(oneInchLiquidityProtocol) || _toApprove == address(governanceMothership));
        oneInch.safeApprove(_toApprove, MAX_UINT);
    }

    /*
     * @notice Emergency function in case of errant transfer of
     * xINCH token directly to contract
     */
    function withdrawNativeToken() public onlyOwnerOrManager {
        uint256 tokenBal = balanceOf(address(this));
        if (tokenBal > 0) {
            IERC20(address(this)).safeTransfer(msg.sender, tokenBal);
        }
    }

    /*
     * @notice Withdraw function for ETH and INCH fees
     */
    function withdrawFees() public onlyOwner {
        uint256 ethBal = address(this).balance;
        (bool success, ) = msg.sender.call.value(ethBal)("");
        require(success, "Transfer failed");

        uint256 oneInchFees = withdrawableOneInchFees;
        withdrawableOneInchFees = 0;
        oneInch.safeTransfer(msg.sender, oneInchFees);

        emit FeeWithdraw(ethBal, oneInchFees);
    }

    modifier onlyOwnerOrManager {
        require(
            msg.sender == owner() ||
                msg.sender == manager ||
                msg.sender == manager2,
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
}
