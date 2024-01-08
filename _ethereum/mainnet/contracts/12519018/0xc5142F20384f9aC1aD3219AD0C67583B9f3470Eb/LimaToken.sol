pragma solidity ^0.6.12;

import "./ERC20Pausable.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./AddressArrayUtils.sol";

import "./ILimaSwap.sol";
import "./ILimaTokenHelper.sol";

/**
 * @title LimaToken
 * @author Lima Protocol
 *
 * Standard LimaToken.
 */
contract LimaToken is ERC20PausableUpgradeSafe, ReentrancyGuardUpgradeSafe {
    using AddressArrayUtils for address[];
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Create(address _from, uint256 _amount, uint16 indexed _referral);
    event Redeem(address _from, uint256 _amount, uint16 indexed _referral);
    event RebalanceExecute(address _oldToken, address _newToken);

    // address public owner;
    ILimaTokenHelper public limaTokenHelper; //limaTokenStorage
    mapping(address => uint256) internal userLastDeposit;

    // new storage
    uint256 public annualizedFee;
    uint256 public lastAnnualizedFeeClaimed;

    event AnnualizedFeeSet(uint256 fee);
    event FeeCharged(uint256 amount);

    /**
     * @dev Initializes contract
     */
    function initialize(
        string memory name,
        string memory symbol,
        address _limaTokenHelper,
        uint256 _underlyingAmount,
        uint256 _limaAmount
    ) public initializer {
        limaTokenHelper = ILimaTokenHelper(_limaTokenHelper);

        __ERC20_init(name, symbol);
        __ERC20Pausable_init();
        __ReentrancyGuard_init();

        if (_underlyingAmount > 0 && _limaAmount > 0) {
            IERC20(limaTokenHelper.currentUnderlyingToken()).safeTransferFrom(
                _msgSender(),
                address(this),
                _underlyingAmount
            );
            _mint(_msgSender(), _limaAmount);
        }
    }

    /* ============ Modifiers ============ */

    modifier onlyUnderlyingToken(address _token) {
        _isOnlyUnderlyingToken(_token);
        _;
    }

    function _isOnlyUnderlyingToken(address _token) internal view {
        // Internal function used to reduce bytecode size
        require(
            limaTokenHelper.isUnderlyingTokens(_token),
            "LM1" //"Only token that are part of Underlying Tokens"
        );
    }

    modifier onlyInvestmentToken(address _investmentToken) {
        // Internal function used to reduce bytecode size
        _isOnlyInvestmentToken(_investmentToken);
        _;
    }

    function _isOnlyInvestmentToken(address _investmentToken) internal view {
        // Internal function used to reduce bytecode size
        require(
            limaTokenHelper.isInvestmentToken(_investmentToken),
            "LM7" //nly token that are approved to invest/payout.
        );
    }

    /**
     * @dev Throws if called by any account other than the limaGovernance.
     */
    modifier onlyLimaGovernanceOrOwner() {
        _isOnlyLimaGovernanceOrOwner();
        _;
    }

    function _isOnlyLimaGovernanceOrOwner() internal view {
        require(
            limaTokenHelper.limaGovernance() == _msgSender() ||
                limaTokenHelper.owner() == _msgSender(),
            "LM2" // "Ownable: caller is not the limaGovernance or owner"
        );
    }

    modifier onlyAmunUsers() {
        _isOnlyAmunUser();
        _;
    }

    function _isOnlyAmunUser() internal view {
        if (limaTokenHelper.isOnlyAmunUserActive()) {
            require(
                limaTokenHelper.isAmunUser(_msgSender()),
                "LM3" //"AmunUsers: msg sender must be part of amunUsers."
            );
        }
    }

    modifier onlyAmunOracles() {
        require(limaTokenHelper.isAmunOracle(_msgSender()), "LM3");
        _;
    }

    /* ============ View ============ */

    function getUnderlyingTokenBalance() public view returns (uint256 balance) {
        return
            IERC20(limaTokenHelper.currentUnderlyingToken()).balanceOf(
                address(this)
            );
    }

    function getUnderlyingTokenBalanceOf(uint256 _amount)
        public
        view
        returns (uint256 balanceOf)
    {
        return getUnderlyingTokenBalance().mul(_amount).div(totalSupply());
    }

    /* ============ Lima Manager ============ */

    function mint(address account, uint256 amount)
        public
        onlyLimaGovernanceOrOwner
    {
        _mint(account, amount);
    }

    // pausable functions
    function pause() external onlyLimaGovernanceOrOwner {
        _pause();
    }

    function unpause() external onlyLimaGovernanceOrOwner {
        _unpause();
    }

    function _approveLimaSwap(address _token, uint256 _amount) internal {
        if (
            IERC20(_token).allowance(
                address(this),
                address(limaTokenHelper.limaSwap())
            ) < _amount
        ) {
            IERC20(_token).safeApprove(address(limaTokenHelper.limaSwap()), 0);
            IERC20(_token).safeApprove(
                address(limaTokenHelper.limaSwap()),
                limaTokenHelper.MAX_UINT256()
            );
        }
    }

    function _swap(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _minimumReturn
    ) internal returns (uint256 returnAmount) {
        if (address(_from) != address(_to) && _amount > 0) {
            _approveLimaSwap(_from, _amount);

            returnAmount = limaTokenHelper.limaSwap().swap(
                address(this),
                _from,
                _to,
                _amount,
                _minimumReturn
            );
            return returnAmount;
        }
        return _amount;
    }

    function _unwrap(
        address _token,
        uint256 _amount,
        address _recipient
    ) internal {
        if (_amount > 0) {
            _approveLimaSwap(_token, _amount);
            limaTokenHelper.limaSwap().unwrap(_token, _amount, _recipient);
        }
    }

    /**
     * @dev Swaps token to new token
     */
    function swap(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _minimumReturn
    ) public onlyLimaGovernanceOrOwner returns (uint256 returnAmount) {
        return _swap(_from, _to, _amount, _minimumReturn);
    }

    /**
     * @dev Rebalances LimaToken
     * Will do swaps of potential governancetoken, underlying token to token that provides higher return
     */
    function rebalance(
        address _bestToken,
        uint256 _minimumReturnGov,
        uint256 _minimumReturn
    ) external onlyAmunOracles() {
        require(
            limaTokenHelper.lastRebalance() +
                limaTokenHelper.rebalanceInterval() <
                now,
            "LM5" //"Rebalance only every 24 hours"
        );
        limaTokenHelper.setLastRebalance(now);

        address govToken = limaTokenHelper.getGovernanceToken();

        //swap gov
        if (govToken != address(0)) {
            _swap(
                govToken,
                _bestToken,
                IERC20(govToken).balanceOf(address(this)),
                _minimumReturnGov
            );
        }

        //swap underlying
        _swap(
            limaTokenHelper.currentUnderlyingToken(),
            _bestToken,
            getUnderlyingTokenBalance(),
            _minimumReturn
        );

        emit RebalanceExecute(
            limaTokenHelper.currentUnderlyingToken(),
            _bestToken
        );

        limaTokenHelper.setCurrentUnderlyingToken(_bestToken);
    }

    /**
     * @dev Redeem the value of LimaToken in _payoutToken.
     * @param _payoutToken The address of token to payout with.
     * @param _amount The amount to redeem.
     * @param _recipient The user address to redeem from/to.
     * @param _minimumReturn The minimum amount to return or else revert.
     */
    function forceRedeem(
        address _payoutToken,
        uint256 _amount,
        address _recipient,
        uint256 _minimumReturn
    ) external onlyLimaGovernanceOrOwner returns (bool) {
        return
            _redeem(
                _recipient,
                _payoutToken,
                _amount,
                _recipient,
                _minimumReturn,
                0 // no referral when forced
            );
    }

    /* ============ User ============ */

    /**
     * @dev Creates new token for holder by converting _investmentToken value to LimaToken
     * Note: User need to approve _amount on _investmentToken to this contract
     * @param _investmentToken The address of token to invest with.
     * @param _amount The amount of investment token to create lima token from.
     * @param _recipient The address to transfer the lima token to.
     * @param _minimumReturn The minimum amount of lending tokens to return or else revert.
     * @param _referral partners may receive referral fees
     */
    function create(
        address _investmentToken,
        uint256 _amount,
        address _recipient,
        uint256 _minimumReturn,
        uint16 _referral
    )
        external
        nonReentrant
        onlyInvestmentToken(_investmentToken)
        onlyAmunUsers
        returns (bool)
    {
        require(
            block.number + 2 > userLastDeposit[_msgSender()],
            "cannot withdraw within the same block"
        );
        userLastDeposit[tx.origin] = block.number;
        uint256 balance = getUnderlyingTokenBalance();
        require(balance != 0, "balance cant be zero");
        IERC20(_investmentToken).safeTransferFrom(
            _msgSender(),
            address(this),
            _amount
        );

        chargeOutstandingAnnualizedFee();

        _amount = _swap(
            _investmentToken,
            limaTokenHelper.currentUnderlyingToken(),
            _amount,
            0
        );

        _amount = totalSupply().mul(_amount).div(balance);

        require(_amount > 0, "zero");
        require(
            _amount >= _minimumReturn,
            "return must reach minimum expected"
        );

        _mint(_recipient, _amount);

        emit Create(_msgSender(), _amount, _referral);
        return true;
    }

    function _redeem(
        address _investor,
        address _payoutToken,
        uint256 _amount,
        address _recipient,
        uint256 _minimumReturn,
        uint16 _referral
    ) internal nonReentrant onlyInvestmentToken(_payoutToken) returns (bool) {
        require(
            block.number + 2 > userLastDeposit[_msgSender()],
            "cannot withdraw within the same block"
        );

        chargeOutstandingAnnualizedFee();

        userLastDeposit[tx.origin] = block.number;
        uint256 underlyingAmount = getUnderlyingTokenBalanceOf(_amount);
        _burn(_investor, _amount);

        emit Redeem(_msgSender(), _amount, _referral);

        _amount = _swap(
            limaTokenHelper.currentUnderlyingToken(),
            _payoutToken,
            underlyingAmount,
            0
        );
        require(_amount > 0, "zero");

        require(
            _amount >= _minimumReturn,
            "return must reach minimum _amount expected"
        );

        IERC20(_payoutToken).safeTransfer(_recipient, _amount);

        return true;
    }

    /**
     * @dev Redeem the value of LimaToken in _payoutToken.
     * @param _payoutToken The address of token to payout with.
     * @param _amount The amount of lima token to redeem.
     * @param _recipient The address to transfer the payout token to.
     * @param _minimumReturn The minimum amount to return for _payoutToken or else revert.
     * @param _referral partners may receive referral fees
     */
    function redeem(
        address _payoutToken,
        uint256 _amount,
        address _recipient,
        uint256 _minimumReturn,
        uint16 _referral
    ) external returns (bool) {
        return
            _redeem(
                _msgSender(),
                _payoutToken,
                _amount,
                _recipient,
                _minimumReturn,
                _referral
            );
    }

    /**
     * Annual fee
     */

    function calcOutStandingAnnualizedFee() public view returns (uint256) {
        uint256 totalSupply = totalSupply();

        if (
            annualizedFee == 0 ||
            limaTokenHelper.feeWallet() == address(0) ||
            lastAnnualizedFeeClaimed == 0
        ) {
            return 0;
        }

        uint256 timePassed = block.timestamp.sub(lastAnnualizedFeeClaimed);

        return
            totalSupply.mul(annualizedFee).div(10**18).mul(timePassed).div(
                365 days
            );
    }

    function chargeOutstandingAnnualizedFee() public {
        uint256 outStandingFee = calcOutStandingAnnualizedFee();

        lastAnnualizedFeeClaimed = block.timestamp;

        // if there is any fee to mint and the beneficiary is set
        // note: limaTokenHelper.feeWallet() is already checked in calc function
        if (outStandingFee != 0) {
            _mint(limaTokenHelper.feeWallet(), outStandingFee);
        }

        emit FeeCharged(outStandingFee);
    }

    function setAnnualizedFee(uint256 _fee) external onlyLimaGovernanceOrOwner {
        chargeOutstandingAnnualizedFee();
        annualizedFee = _fee;
        emit AnnualizedFeeSet(_fee);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return "Amun Lending Autopilot";
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory) {
        return "DROP";
    }
}
