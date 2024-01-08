// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "./Adminable.sol";
import "./Initializable.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./PassportScoreVerifiable.sol";
import "./Bytes32.sol";

import "./ISablier.sol";
import "./BaseERC20.sol";
import "./IPermittableERC20.sol";
import "./SapphireTypes.sol";
import "./ISapphirePassportScores.sol";

/**
 * @notice An ERC20 that allows users to deposit a given token, where their
 *         balance is expressed in forms of shares. This will expose users to the
 *         increase and decrease of the balance of the token on the contract.
 *
 *         To withdraw their balance, users must first express their withdrawal
 *         intent, which will trigger a cooldown after which they will be able
 *         to reclaim their share.
 */
contract StakingAccrualERC20 is BaseERC20, PassportScoreVerifiable, Adminable, Initializable {

    /* ========== Libraries ========== */

    using Address for address;
    using SafeERC20 for IPermittableERC20;
    using SafeMath for uint256;
    using Bytes32 for bytes32;

    /* ========== Variables ========== */

    uint256 constant BASE = 1e18;

    uint256 public exitCooldownDuration;

    IPermittableERC20 public stakingToken;

    ISablier public sablierContract;
    uint256 public sablierStreamId;

    bytes32 private _proofProtocol;

    /**
     * @notice Cooldown duration to be elapsed for users to exit
     */

    mapping (address => uint256) public cooldowns;

    /* ========== Events ========== */

    event ExitCooldownDurationSet(uint256 _duration);

    event TokensRecovered(uint256 _amount);

    event Staked(address indexed _user, uint256 _amount);

    event ExitCooldownStarted(address indexed _user, uint256 _cooldownEndTimestamp);

    event Exited(address indexed _user, uint256 _amount);

    event SablierContractSet(address _sablierContract);

    event SablierStreamIdSet(uint256 _newStreamId);

    event FundsWithdrawnFromSablier(uint256 _streamId, uint256 _amount);

    event PassportScoresContractSet(address _passportScoresContract);

    event ProofProtocolSet(string _protocol);

    /* ========== Constructor (ignore) ========== */

    constructor ()
        public
        BaseERC20("", "", 18)
    {}

    /* ========== Restricted Functions ========== */

    function init(
        string calldata __name,
        string calldata __symbol,
        uint8 __decimals,
        address _stakingToken,
        uint256 _exitCooldownDuration,
        address _passportScoresContract,
        address _sablierContract
    )
        external
        onlyAdmin
        initializer
    {
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
        exitCooldownDuration = _exitCooldownDuration;

        require (
            _stakingToken.isContract(),
            "StakingAccrualERC20: staking token is not a contract"
        );

        require (
            _passportScoresContract.isContract(),
            "StakingAccrualERC20: the passport scores contract is invalid"
        );

        require (
            _sablierContract.isContract(),
            "StakingAccrualERC20: the sablier contract is invalid"
        );

        DOMAIN_SEPARATOR = _initDomainSeparator(
            __name,
            "1"
        );

        stakingToken = IPermittableERC20(_stakingToken);
        passportScoresContract = ISapphirePassportScores(_passportScoresContract);
        sablierContract = ISablier(_sablierContract);
    }

    /**
     * @notice Sets the exit cooldown duration
     */
    function setExitCooldownDuration(
        uint256 _duration
    )
        external
        onlyAdmin
    {
        require(
            exitCooldownDuration != _duration,
            "StakingAccrualERC20: the same cooldown is already set"
        );

        exitCooldownDuration = _duration;

        emit ExitCooldownDurationSet(exitCooldownDuration);
    }

    /**
     * @notice Recovers tokens from the totalShares

     */
    function recoverTokens(
        uint256 _amount
    )
        external
        onlyAdmin
    {
        uint256 contractBalance = stakingToken.balanceOf(address(this));

        require (
            _amount <= contractBalance,
            "StakingAccrualERC20: cannot recover more than the balance"
        );

        emit TokensRecovered(_amount);

        stakingToken.safeTransfer(
            getAdmin(),
            _amount
        );
    }

    function setPassportScoreContract(
        address _passportScoresContract
    )
        external
        onlyAdmin
    {
        require(
            address(passportScoresContract) != _passportScoresContract,
            "StakingAccrualERC20: the same passport scores address is already set"
        );

        require(
            _passportScoresContract.isContract(),
            "StakingAccrualERC20: the given address is not a contract"
        );

        passportScoresContract = ISapphirePassportScores(_passportScoresContract);

        emit PassportScoresContractSet(_passportScoresContract);
    }

    /**
     * @notice Sets the Sablier contract address
     */
    function setSablierContract(
        address _sablierContract
    )
        external
        onlyAdmin
    {
        require (
            _sablierContract.isContract(),
            "StakingAccrualERC20: address is not a contract"
        );

        sablierContract = ISablier(_sablierContract);

        emit SablierContractSet(_sablierContract);
    }

    /**
     * @notice Sets the Sablier stream ID
     */
    function setSablierStreamId(
        uint256 _sablierStreamId
    )
        external
        onlyAdmin
    {
        require (
            sablierStreamId != _sablierStreamId,
            "StakingAccrualERC20: the same stream ID is already set"
        );

        (, address recipient,,,,,,) = sablierContract.getStream(_sablierStreamId);

        require (
            recipient == address(this),
            "StakingAccrualERC20: incorrect stream ID"
        );

        sablierStreamId = _sablierStreamId;

        emit SablierStreamIdSet(sablierStreamId);
    }

    function setProofProtocol(
        bytes32 _protocol
    )
        external
        onlyAdmin
    {
        _proofProtocol = _protocol;

        emit ProofProtocolSet(_proofProtocol.toString());
    }

    /* ========== Mutative Functions ========== */

    function stake(
        uint256 _amount,
        SapphireTypes.ScoreProof memory _scoreProof
    )
        public
        checkScoreProof(_scoreProof, true, true)
    {
        require (
            _scoreProof.protocol == _proofProtocol,
            "StakingAccrualERC20: wrong protocol in proof"
        );

        claimStreamFunds();

        uint256 cooldownTimestamp = cooldowns[msg.sender];

        require (
            cooldownTimestamp == 0,
            "StakingAccrualERC20: cannot stake during cooldown period"
        );

        // Gets the amount of the staking token locked in the contract
        uint256 totalStakingToken = stakingToken.balanceOf(address(this));
        // Gets the amount of the staked token in existence
        uint256 totalShares = totalSupply();
        // If no the staked token exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalStakingToken == 0) {
            _mint(msg.sender, totalStakingToken.add(_amount));
        }
        // Calculate and mint the amount of stToken the Token is worth. The ratio will change overtime, as stToken is burned/minted and Token deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalStakingToken);
            _mint(msg.sender, what);
        }
        // Lock the staking token in the contract
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount);
    }

    function stakeWithPermit(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        SapphireTypes.ScoreProof memory _scoreProof
    )
        public
    {
        stakingToken.permit(
            msg.sender,
            address(this),
            _amount,
            _deadline,
            _v,
            _r,
            _s
        );
        stake(_amount, _scoreProof);
    }

    /**
     * @notice Starts the exit cooldown. After this call the user won't be able to
     *         stake until they exit.
     */
    function startExitCooldown()
        public
    {
        require (
            balanceOf(msg.sender) > 0,
            "StakingAccrualERC20: user has 0 balance"
        );

        require (
            cooldowns[msg.sender] == 0,
            "StakingAccrualERC20: exit cooldown already started"
        );

        cooldowns[msg.sender] = currentTimestamp().add(exitCooldownDuration);

        emit ExitCooldownStarted(msg.sender, cooldowns[msg.sender]);
    }

    /**
     * @notice Returns the staked tokens proportionally, as long as
     *         the caller's cooldown time has elapsed. Exiting resets
     *         the cooldown so the user can start staking again.
     */
    function exit()
        external
    {
        claimStreamFunds();

        uint256 cooldownTimestamp = cooldowns[msg.sender];
         // Gets the amount of stakedToken in existence
        uint256 totalShares = totalSupply();
        // Amount of shares to exit
        uint256 _share = balanceOf(msg.sender);

        require(
            _share > 0,
            "StakingAccrualERC20: user has 0 balance"
        );

        require(
            currentTimestamp() >= cooldownTimestamp,
            "StakingAccrualERC20: exit cooldown not elapsed"
        );
        require(
            cooldownTimestamp != 0,
            "StakingAccrualERC20: exit cooldown was not initiated"
        );

        // Calculates the amount of staking token the staked token is worth
        uint256 what = _share.mul(stakingToken.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        cooldowns[msg.sender] = 0;
        emit Exited(msg.sender, what);
        stakingToken.safeTransfer(msg.sender, what);
    }

    /**
     * @notice Withdraws from the sablier stream if possible
     */
    function claimStreamFunds()
        public
    {
        if (address(sablierContract) == address(0) || sablierStreamId == 0) {
            return;
        }

        // Get the balance of the stream. If the stream is complete, .balanceOf() will
        // throw. For that reason, we will use .staticcall() to check the balance.
        bytes memory payload = abi.encodeWithSignature(
            "balanceOf(uint256,address)",
            sablierStreamId,
            address(this)
        );
        (bool success, bytes memory returnData) = address(sablierContract).staticcall(payload);
        
        if (!success) {
            // The stream is finished
            return;
        }

        (uint256 availableBalance) = abi.decode(returnData, (uint256));

        sablierContract.withdrawFromStream(sablierStreamId, availableBalance);

        emit FundsWithdrawnFromSablier(sablierStreamId, availableBalance);
    }

    /* ========== View Functions ========== */

    function getExchangeRate() public view returns (uint256) {
        if (totalSupply() == 0) {
            return 0;
        }
        return stakingToken.balanceOf(address(this)).mul(1e18).div(totalSupply());
    }

    function toStakingToken(uint256 stTokenAmount) public view returns (uint256) {
        if (totalSupply() == 0) {
            return 0;
        }
        return stTokenAmount.mul(stakingToken.balanceOf(address(this))).div(totalSupply());
    }

    function toStakedToken(uint256 token) public view returns (uint256) {
        uint256 stakingBalance = stakingToken.balanceOf(address(this));
        if (stakingBalance == 0) {
            return 0;
        }
        return token.mul(totalSupply()).div(stakingBalance);
    }

    function currentTimestamp()
        public
        view
        returns (uint256)
    {
        return block.timestamp;
    }

    function getProofProtocol()
        external
        view
        returns (string memory)
    {
        return _proofProtocol.toString();
    }
}
