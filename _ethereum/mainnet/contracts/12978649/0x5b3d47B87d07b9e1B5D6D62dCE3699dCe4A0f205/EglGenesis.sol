pragma solidity 0.6.6;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

/** 
 * EGL Staking Notice
 * 
 * By agreeing to stake Ethereum:
 * - You agree that staked Ethereum will be locked up for a specified duration, will not be retrievable for that 
 * period, and that any staking of tokens has various associated risks.
 * 
 * - You are obligated to maintain balancer pool tokens  in a Balancer pool containing ETH and EGL for between 10 and
 * 52 weeks. The resulting balancer pool tokens will be held by the EGL smart contract, and gradually released to the
 * Genesis supporters, as specified further here: https://docs.egl.vote/protocol-overview/launch.
 * 
 * - You agree to consume EGL and utilize the tokens for voting purposes, as summarized here: 
 * https://docs.egl.vote/protocol-overview/voting. For users who fail to vote, the protocol may take certain actions by
 * default that may impact the price of the Ethereum gas limit and/or impact EGL. EGL is intended to be immediately 
 * consumed by advanced Ethereum developers and stakeholders; utilize it at your own discretion and risk. EGL is 
 * intended solely as a means of collective voting on the Ethereum gas limit; users should have no expectations of 
 * profits.
 * 
 * - You understand and agree that EGL is a decentralized, open source project, so that the parameters of the protocol 
 * and the code base itself can change, including core technical features and material properties of the token.
 * 
 * - While we hope it never happens, you understand and agree that the staking of tokens is a non-custodial arrangement 
 * that has technical and financial risks, including risk of inaccessibility, decreases in value, and complete loss. 
 * You understand and agree that under no circumstances shall the developers of this smart contract or contributors to 
 * EGL be liable for any loss or damage you might experience.
 * 
 * By staking Ethereum or accessing or otherwise using this smart contract, you agree that you have read and 
 * understood, and, as a condition of your use of the smart contract, you agree to be bound by these terms.
 */
contract EglGenesis is Initializable, OwnableUpgradeable, PausableUpgradeable {
    using SafeMathUpgradeable for uint;

    uint constant MIN_CONTRIBUTION_AMOUNT = 0.001 ether;

    uint public cumulativeBalance;
    uint public absoluteMaxContributorsCount;
    bool public canContribute;
    bool public canWithdraw;
    address[] public contributorsList;    
    mapping(address => Contributor) public contributors;

    uint private maxThreshold;

    struct Contributor {
        uint amount;
        uint cumulativeBalance;
        uint idx;
        uint date;
    }

    event Initialized(
        address owner, 
        bool canContribute,
        uint maxThreshold
    );

    event ContributionReceived(
        address contributor, 
        uint amount,
        uint cumulativeBalance,
        uint idx,        
        uint date
    );

    event ContributionWithdrawn(
        address contributor, 
        uint amount,
        uint date
    );

    event WithdAllowed(
        address owner, 
        uint date
    );

    event GenesisEnded(
        address owner,
        uint cumulativeBalance, 
        uint contractBalance,
        uint date
    );

    event ThresholdMet(
        uint contractBalance,
        uint date
    );

    /**
     * @dev Receive eth
     */
    receive() external payable whenNotPaused {
        require(canContribute, "GENESIS:GENESIS_ENDED");
        require(msg.value >= MIN_CONTRIBUTION_AMOUNT, "GENESIS:INVALID_AMOUNT");
        require(contributors[msg.sender].amount == 0, "GENESIS:ALREADY_CONTRIBUTED");

        contributorsList.push(msg.sender);
        cumulativeBalance = cumulativeBalance.add(msg.value);
        absoluteMaxContributorsCount = absoluteMaxContributorsCount.add(1);

        Contributor storage contributor = contributors[msg.sender];
        contributor.amount = msg.value;
        contributor.cumulativeBalance = cumulativeBalance;
        contributor.idx = absoluteMaxContributorsCount;
        contributor.date = now;        

        if (cumulativeBalance >= maxThreshold) {
            canContribute = false;
            emit ThresholdMet(cumulativeBalance, now);
        }            
        emit ContributionReceived(
            msg.sender, 
            contributor.amount, 
            contributor.cumulativeBalance, 
            contributor.idx, 
            contributor.date
        );
    }

    /**
     * @dev Initialize contract variables
     * 
     * @param _owner Address of wallet that will have administrative priviledges over the contract
     * @param _threshold Max amount of ETH to collect before automatically stopping collection
     */
    function initialize(address _owner, uint _threshold) external initializer {
        require(_owner != address(0), "GENESIS:INVALID_OWNER");
        require(_owner != address(this), "GENESIS:ADDRESS_IS_CONTRACT");

        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();

        transferOwnership(_owner);
        canContribute = true;
        maxThreshold = _threshold;
        emit Initialized(owner(), canContribute, _threshold);
    }

    /**
     * @dev Withdraw ETH contributed only if contributed and withdraw flag is set to 'true'
     */
    function withdraw() external whenNotPaused {
        require(canWithdraw, "GENESIS:WITHDRAW_NOT_ALLOWED");
        require(contributors[msg.sender].amount > 0, "GENESIS:NOT_CONTRIBUTED");

        uint amountToWithdraw = contributors[msg.sender].amount;
        uint contributorIdx = contributors[msg.sender].idx;
        delete contributors[msg.sender];
        delete contributorsList[contributorIdx - 1];
        
        cumulativeBalance = cumulativeBalance.sub(amountToWithdraw);

        (bool success, ) = msg.sender.call{ value: amountToWithdraw}("");
        require(success, "GENESIS:WITHDRAW_FAILED");        
        emit ContributionWithdrawn(msg.sender, amountToWithdraw, now);
    }

    /**
     * @dev Owner only function to set the withdraw flag to 'true'
     */
    function allowWithdraw() external onlyOwner whenNotPaused {
        require(cumulativeBalance > 0, "GENESIS:NO_BALANCE");
        require(cumulativeBalance < maxThreshold, "GENESIS:MAX_THRESHOLD_REACHED");
        require(canContribute, "GENESIS:GENESIS_ENDED");
        canWithdraw = true;
        canContribute = false;
        emit WithdAllowed(msg.sender, now);
    }

    /** 
     * @dev End genesis period and transfer contract balance to owner wallet
     */
    function endGenesis() external onlyOwner whenNotPaused {
        canContribute = false;
        (bool success, ) = msg.sender.call{ value: cumulativeBalance}("");
        require(success, "GENESIS: CLOSE_FAILED");
        emit GenesisEnded(msg.sender, cumulativeBalance, address(this).balance, now);
    }

    /**
     * @dev Ower only funciton to pause contract
     */
    function pauseGenesis() external onlyOwner whenNotPaused {
        _pause();
    }

    /** 
     * @dev Owner only function to unpause contract
     */
    function unpauseGenesis() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Do not allow owner to renounce ownership, only transferOwnership
     */
    function renounceOwnership() public override onlyOwner {
        revert("GENESIS:NO_RENOUNCE_OWNERSHIP");
    }
}