// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC20Upgradeable.sol";

import "./structs.sol";
import "./IQNFT.sol";
import "./IQNFTGov.sol";
import "./IQNFTSettings.sol";
import "./IQSettings.sol";

/**
 * @author fantasy
 */
contract QNFTGov is IQNFTGov, ContextUpgradeable, ReentrancyGuardUpgradeable {
    event VoteGovernanceAddress(
        address indexed voter,
        address indexed multisig
    );
    event WithdrawToGovernanceAddress(
        address indexed user,
        address indexed multisig
    );
    event SafeWithdraw(address indexed owner, address indexed multisig);
    event UpdateVote(
        address indexed user,
        uint256 originAmount,
        uint256 currentAmount
    );

    // constants
    uint8 public VOTE_QUORUM; // default: 70%
    uint32 public MIN_VOTE_DURATION; // default: 1 week
    uint32 public SAFE_VOTE_END_DURATION; // default: 3 weeks

    // vote options
    uint256 public totalUsers;
    mapping(address => uint256) public voteResult; // vote amount of give multisig wallet
    mapping(address => address) public voteAddressByVoter; // vote address of given user
    mapping(address => bool) public canVote; // vote amount of given user

    IQSettings public settings;

    modifier onlyManager() {
        require(
            settings.getManager() == msg.sender,
            "QNFTGov: caller is not the manager"
        );
        _;
    }

    modifier onlyQnft() {
        require(
            settings.getQNft() == msg.sender,
            "QNFTGov: caller is not QNFT"
        );
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function initialize(
        address _settings,
        uint8 _voteQuorum,
        uint32 _minVoteDuration,
        uint32 _safeVoteEndDuration
    ) external initializer {
        __Context_init();
        __ReentrancyGuard_init();

        settings = IQSettings(_settings);
        VOTE_QUORUM = _voteQuorum;
        MIN_VOTE_DURATION = _minVoteDuration;
        SAFE_VOTE_END_DURATION = _safeVoteEndDuration;
    }

    /**
     * @dev votes on a given multisig wallet with the locked qstk balance of the user
     */
    function voteGovernanceAddress(address multisig) external {
        (bool mintStarted, bool mintFinished, , ) = voteStatus();
        require(mintStarted, "QNFTGov: mint not started");
        require(mintFinished, "QNFTGov: NFT sale not ended");

        require(
            canVote[msg.sender],
            "QNFTGov: caller has no locked qstk balance"
        );

        if (voteAddressByVoter[msg.sender] != address(0x0)) {
            voteResult[voteAddressByVoter[msg.sender]]--;
        }

        voteResult[multisig]++;
        voteAddressByVoter[msg.sender] = multisig;

        emit VoteGovernanceAddress(msg.sender, multisig);
    }

    /**
     * @dev withdraws to the governance address if it has enough vote amount
     */
    function withdrawToGovernanceAddress(address payable multisig)
        external
        nonReentrant
    {
        (, , bool ableToWithdraw, ) = voteStatus();
        require(ableToWithdraw, "QNFTGov: wait until vote end time");

        require(
            voteResult[multisig] * 100 >= totalUsers * VOTE_QUORUM,
            "QNFTGov: specified multisig address is not voted enough"
        );

        IQNFT(settings.getQNft()).withdrawETH(multisig);

        emit WithdrawToGovernanceAddress(msg.sender, multisig);
    }

    /**
     * @dev withdraws to multisig wallet by manager - need to pass the safe vote end duration
     */
    function safeWithdraw(address payable multisig)
        external
        onlyManager
        nonReentrant
    {
        (, , , bool ableToSafeWithdraw) = voteStatus();
        require(ableToSafeWithdraw, "QNFTGov: wait until safe vote end time");

        IQNFT(settings.getQNft()).withdrawETH(multisig);

        emit SafeWithdraw(msg.sender, multisig);
    }

    /**
     * @dev updates the votes amount of the given user
     */
    function updateVote(
        address user,
        uint256 originAmount, // original amount before change
        uint256 currentAmount // current amount after change
    ) external override onlyQnft {
        if (originAmount == currentAmount) {
            return;
        }

        if (originAmount == 0) {
            canVote[user] = true;
            totalUsers++;
        } else if (currentAmount == 0) {
            if (voteAddressByVoter[user] != address(0x0)) {
                voteResult[voteAddressByVoter[user]]--;
                voteAddressByVoter[user] = address(0x0);
            }
            canVote[user] = false;
            totalUsers--;
        }

        emit UpdateVote(user, originAmount, currentAmount);
    }

    /**
     * @dev sets QSettings contract address
     */
    function setSettings(IQSettings _settings) external onlyManager {
        settings = _settings;
    }

    /**
     * @dev returns the current vote status
     */
    function voteStatus()
        public
        view
        returns (
            bool mintStarted,
            bool mintFinished,
            bool ableToWithdraw,
            bool ableToSafeWithdraw
        )
    {
        mintStarted = IQNFTSettings(settings.getQNftSettings()).mintStarted();
        mintFinished = IQNFTSettings(settings.getQNftSettings()).mintFinished();
        if (mintStarted && mintFinished) {
            uint256 mintEndTime =
                IQNFTSettings(settings.getQNftSettings()).mintEndTime();

            ableToWithdraw = block.timestamp >= mintEndTime + MIN_VOTE_DURATION;
            ableToSafeWithdraw =
                block.timestamp >= mintEndTime + SAFE_VOTE_END_DURATION;
        }
    }
}
