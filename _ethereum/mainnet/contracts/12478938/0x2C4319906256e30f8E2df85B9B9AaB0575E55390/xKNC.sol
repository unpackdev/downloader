pragma solidity 0.6.2;

import "./SafeERC20.sol";
import "./ERC20.sol";
import "./Initializable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

import "./IKyberNetworkProxy.sol";
import "./IKyberStaking.sol";
import "./IKyberDAO.sol";
import "./IKyberFeeHandler.sol";
import "./INewKNC.sol";
import "./IRewardsDistributor.sol";

/*
 * xKNC KyberDAO Pool Token
 * Communal Staking Pool with Stated Governance Position
 */
contract xKNC is
    Initializable,
    ERC20UpgradeSafe,
    OwnableUpgradeSafe,
    PausableUpgradeSafe,
    ReentrancyGuardUpgradeSafe
{
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    address private constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    ERC20 private knc;
    IKyberDAO private kyberDao;
    IKyberStaking private kyberStaking;
    IKyberNetworkProxy private kyberProxy;
    IKyberFeeHandler[] private kyberFeeHandlers;

    address[] private kyberFeeTokens;

    uint256 private constant PERCENT = 100;
    uint256 private constant MAX_UINT = 2**256 - 1;
    uint256 private constant INITIAL_SUPPLY_MULTIPLIER = 10;

    uint256 private withdrawableEthFees;
    uint256 private withdrawableKncFees;

    string public mandate;

    address private manager;
    address private manager2;

    struct FeeDivisors {
        uint256 mintFee;
        uint256 burnFee;
        uint256 claimFee;
    }

    FeeDivisors public feeDivisors;

    event FeeDivisorsSet(uint256 mintFee, uint256 burnFee, uint256 claimFee);

    enum FeeTypes {MINT, BURN, CLAIM}

    // vars added for v3
    bool private v3Initialized;
    IRewardsDistributor private rewardsDistributor;
    
    // addresses are locked from transfer after minting or burning
    uint256 private constant BLOCK_LOCK_COUNT = 6;
    // last block for which this address is timelocked
    mapping(address => uint256) public lastLockedBlock;

    function initialize(
        string memory _symbol,
        string memory _mandate,
        IKyberStaking _kyberStaking,
        IKyberNetworkProxy _kyberProxy,
        ERC20 _knc,
        IKyberDAO _kyberDao,
        uint256 mintFee,
        uint256 burnFee,
        uint256 claimFee
    ) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __ERC20_init_unchained("xKNC", _symbol);

        mandate = _mandate;
        kyberStaking = _kyberStaking;
        kyberProxy = _kyberProxy;
        knc = _knc;
        kyberDao = _kyberDao;

        _setFeeDivisors(mintFee, burnFee, claimFee);
    }

    /*
     * @notice Called by users buying with ETH
     * @dev Swaps ETH for KNC, deposits to Staking contract
     * @dev: Mints pro rata xKNC tokens
     * @param: kyberProxy.getExpectedRate(eth => knc)
     */
    function mint(uint256 minRate)
        external
        payable
        whenNotPaused
        notLocked(msg.sender)
    {
        require(msg.value > 0, "Must send eth with tx");
        lock(msg.sender);
        // ethBalBefore checked in case of eth still waiting for exch to KNC
        uint256 ethBalBefore = getFundEthBalanceWei().sub(msg.value);
        uint256 fee = _administerEthFee(FeeTypes.MINT, ethBalBefore);

        uint256 ethValueForKnc = msg.value.sub(fee);
        uint256 kncBalanceBefore = getFundKncBalanceTwei();

        _swapEtherToKnc(ethValueForKnc, minRate);
        _deposit(getAvailableKncBalanceTwei());

        uint256 mintAmount = _calculateMintAmount(kncBalanceBefore);

        return super._mint(msg.sender, mintAmount);
    }

    /*
     * @notice Called by users buying with KNC
     * @notice Users must submit ERC20 approval before calling
     * @dev Deposits to Staking contract
     * @dev: Mints pro rata xKNC tokens
     * @param: Number of KNC to contribue
     */
    function mintWithToken(uint256 kncAmountTwei)
        external
        whenNotPaused
        notLocked(msg.sender)
    {
        require(kncAmountTwei > 0, "Must contribute KNC");
        lock(msg.sender);
        knc.safeTransferFrom(msg.sender, address(this), kncAmountTwei);

        uint256 kncBalanceBefore = getFundKncBalanceTwei();
        _administerKncFee(kncAmountTwei, FeeTypes.MINT);

        _deposit(getAvailableKncBalanceTwei());

        uint256 mintAmount = _calculateMintAmount(kncBalanceBefore);

        return super._mint(msg.sender, mintAmount);
    }

    /*
     * @notice Called by users burning their xKNC
     * @dev Calculates pro rata KNC and redeems from Staking contract
     * @dev: Exchanges for ETH if necessary and pays out to caller
     * @param tokensToRedeem
     * @param redeemForKnc bool: if true, redeem for KNC; otherwise ETH
     * @param kyberProxy.getExpectedRate(knc => eth)
     */
    function burn(
        uint256 tokensToRedeemTwei,
        bool redeemForKnc,
        uint256 minRate
    ) external nonReentrant notLocked(msg.sender) {
        require(
            balanceOf(msg.sender) >= tokensToRedeemTwei,
            "Insufficient balance"
        );
        lock(msg.sender);

        uint256 proRataKnc =
            getFundKncBalanceTwei().mul(tokensToRedeemTwei).div(totalSupply());
        _withdraw(proRataKnc);
        super._burn(msg.sender, tokensToRedeemTwei);

        if (redeemForKnc) {
            uint256 fee = _administerKncFee(proRataKnc, FeeTypes.BURN);
            knc.safeTransfer(msg.sender, proRataKnc.sub(fee));
        } else {
            // safeguard to not overcompensate _burn sender in case eth still awaiting for exch to KNC
            uint256 ethBalBefore = getFundEthBalanceWei();
            kyberProxy.swapTokenToEther(
                knc,
                getAvailableKncBalanceTwei(),
                minRate
            );

            _administerEthFee(FeeTypes.BURN, ethBalBefore);

            uint256 valToSend = getFundEthBalanceWei().sub(ethBalBefore);
            (bool success, ) = msg.sender.call.value(valToSend)("");
            require(success, "Burn transfer failed");
        }
    }

    /*
     * @notice Calculates proportional issuance according to KNC contribution
     * @notice Fund starts at ratio of INITIAL_SUPPLY_MULTIPLIER/1 == xKNC supply/KNC balance
     * and approaches 1/1 as rewards accrue in KNC
     * @param kncBalanceBefore used to determine ratio of incremental to current KNC
     */
    function _calculateMintAmount(uint256 kncBalanceBefore)
        private
        view
        returns (uint256 mintAmount)
    {
        uint256 kncBalanceAfter = getFundKncBalanceTwei();
        if (totalSupply() == 0)
            return kncBalanceAfter.mul(INITIAL_SUPPLY_MULTIPLIER);

        mintAmount = (kncBalanceAfter.sub(kncBalanceBefore))
            .mul(totalSupply())
            .div(kncBalanceBefore);
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

    /*
     * @notice KyberDAO deposit
     */
    function _deposit(uint256 amount) private {
        kyberStaking.deposit(amount);
    }

    /*
     * @notice KyberDAO withdraw
     */
    function _withdraw(uint256 amount) private {
        kyberStaking.withdraw(amount);
    }

    /*
     * @notice Vote on KyberDAO campaigns
     * @dev Admin calls with relevant params for each campaign in an epoch
     * @param proposalId: DAO proposalId
     * @param optionBitMask: voting option
     */
    function vote(uint256 proposalId, uint256 optionBitMask)
        external
        onlyOwnerOrManager
    {
        kyberDao.submitVote(proposalId, optionBitMask);
    }

    /*
     * @notice Claim reward from previous epoch
     * @dev Admin calls with relevant params
     * @dev ETH/other asset rewards swapped into KNC
     * @param cycle - sourced from Kyber API
     * @param index - sourced from Kyber API
     * @param tokens - ERC20 fee tokens
     * @param merkleProof - sourced from Kyber API
     * @param minRates - kyberProxy.getExpectedRate(eth/token => knc)
     */
    function claimReward(
        uint256 cycle,
        uint256 index,
        IERC20[] calldata tokens,
        uint256[] calldata cumulativeAmounts,
        bytes32[] calldata merkleProof,
        uint256[] calldata minRates
    ) external onlyOwnerOrManager {
        require(tokens.length == minRates.length, "Must be equal length");

        rewardsDistributor.claim(
            cycle,
            index,
            address(this),
            tokens,
            cumulativeAmounts,
            merkleProof
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            if (address(tokens[i]) == address(knc)) {
                continue;
            } else if (address(tokens[i]) == ETH_ADDRESS) {
                _swapEtherToKnc(getFundEthBalanceWei(), minRates[i]);
            } else {
                _swapTokenToKnc(
                    address(tokens[i]),
                    tokens[i].balanceOf(address(this)),
                    minRates[i]
                );
            }
        }

        _administerKncFee(getAvailableKncBalanceTwei(), FeeTypes.CLAIM);
        _deposit(getAvailableKncBalanceTwei());
    }

    function _swapEtherToKnc(uint256 amount, uint256 minRate) private {
        kyberProxy.swapEtherToToken.value(amount)(knc, minRate);
    }

    function _swapTokenToKnc(
        address fromAddress,
        uint256 amount,
        uint256 minRate
    ) private {
        kyberProxy.swapTokenToToken(ERC20(fromAddress), amount, knc, minRate);
    }

    /*
     * @notice Returns ETH balance belonging to the fund
     */
    function getFundEthBalanceWei() public view returns (uint256) {
        return address(this).balance.sub(withdrawableEthFees);
    }

    /*
     * @notice Returns KNC balance staked to DAO
     */
    function getFundKncBalanceTwei() public view returns (uint256) {
        return kyberStaking.getLatestStakeBalance(address(this));
    }

    /*
     * @notice Returns KNC balance available to stake
     */
    function getAvailableKncBalanceTwei() public view returns (uint256) {
        return knc.balanceOf(address(this)).sub(withdrawableKncFees);
    }

    function _administerEthFee(FeeTypes _type, uint256 ethBalBefore)
        private
        returns (uint256 fee)
    {
        uint256 feeRate = getFeeRate(_type);
        if (feeRate == 0) return 0;

        fee = (getFundEthBalanceWei().sub(ethBalBefore)).div(feeRate);
        withdrawableEthFees = withdrawableEthFees.add(fee);
    }

    function _administerKncFee(uint256 _kncAmount, FeeTypes _type)
        private
        returns (uint256 fee)
    {
        uint256 feeRate = getFeeRate(_type);
        if (feeRate == 0) return 0;

        fee = _kncAmount.div(feeRate);
        withdrawableKncFees = withdrawableKncFees.add(fee);
    }

    function getFeeRate(FeeTypes _type) public view returns (uint256) {
        if (_type == FeeTypes.MINT) return feeDivisors.mintFee;
        if (_type == FeeTypes.BURN) return feeDivisors.burnFee;
        if (_type == FeeTypes.CLAIM) return feeDivisors.claimFee;
    }

    /* UTILS */

    /*
     * @notice Called by admin on deployment for KNC
     * @dev Approves Kyber Proxy contract to trade KNC
     * @param Token to approve on proxy contract
     * @param Pass _reset as true if resetting allowance to zero
     */
    function approveKyberProxyContract(address _token, bool _reset)
        external
        onlyOwnerOrManager
    {
        _approveKyberProxyContract(_token, _reset);
    }

    function _approveKyberProxyContract(address _token, bool _reset) private {
        uint256 amount = _reset ? 0 : MAX_UINT;
        IERC20(_token).approve(address(kyberProxy), amount);
    }

    /*
     * @notice Called by admin on deployment
     * @dev (1 / feeDivisor) = % fee on mint, burn, ETH claims
     * @dev ex: A feeDivisor of 334 suggests a fee of 0.3%
     * @param feeDivisors[mint, burn, claim]:
     */
    function setFeeDivisors(
        uint256 _mintFee,
        uint256 _burnFee,
        uint256 _claimFee
    ) external onlyOwner {
        _setFeeDivisors(_mintFee, _burnFee, _claimFee);
    }

    function _setFeeDivisors(
        uint256 _mintFee,
        uint256 _burnFee,
        uint256 _claimFee
    ) private {
        require(
            _mintFee >= 100 || _mintFee == 0,
            "Mint fee must be zero or equal to or less than 1%"
        );
        require(_burnFee >= 100, "Burn fee must be equal to or less than 1%");
        require(_claimFee >= 10, "Claim fee must be less than 10%");
        feeDivisors.mintFee = _mintFee;
        feeDivisors.burnFee = _burnFee;
        feeDivisors.claimFee = _claimFee;

        emit FeeDivisorsSet(_mintFee, _burnFee, _claimFee);
    }

    function withdrawFees() external onlyOwner {
        uint256 ethFees = withdrawableEthFees;
        uint256 kncFees = withdrawableKncFees;

        withdrawableEthFees = 0;
        withdrawableKncFees = 0;

        (bool success, ) = msg.sender.call.value(ethFees)("");
        require(success, "Burn transfer failed");

        knc.safeTransfer(owner(), kncFees);
    }

    function setManager(address _manager) external onlyOwner {
        manager = _manager;
    }

    function setManager2(address _manager2) external onlyOwner {
        manager2 = _manager2;
    }

    function pause() external onlyOwnerOrManager {
        _pause();
    }

    function unpause() external onlyOwnerOrManager {
        _unpause();
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

    /*
     * @notice Fallback to accommodate claimRewards function
     */
    receive() external payable {
        require(msg.sender != tx.origin, "Errant ETH deposit");
    }

    function migrateV3(
        address _newKnc,
        IKyberDAO _newKyberDao,
        IKyberStaking _newKyberStaking,
        IRewardsDistributor _rewardsDistributor
    ) external onlyOwnerOrManager {
        require(!v3Initialized, "Initialized already");
        v3Initialized = true;

        _withdraw(getFundKncBalanceTwei());
        knc.approve(_newKnc, MAX_UINT);
        INewKNC(_newKnc).mintWithOldKnc(knc.balanceOf(address(this)));

        knc = ERC20(_newKnc);
        kyberDao = _newKyberDao;
        kyberStaking = _newKyberStaking;
        rewardsDistributor = _rewardsDistributor;

        knc.approve(address(kyberStaking), MAX_UINT);
        _deposit(getAvailableKncBalanceTwei());
    }

    function setRewardsDistributor(IRewardsDistributor _rewardsDistributor)
        external
        onlyOwner
    {
        rewardsDistributor = _rewardsDistributor;
    }

    function getRewardDistributor()
        external
        view
        returns (IRewardsDistributor)
    {
        return rewardsDistributor;
    }
}
