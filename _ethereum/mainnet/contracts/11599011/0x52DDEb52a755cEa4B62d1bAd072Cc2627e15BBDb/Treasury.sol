// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.6.0;

import "./SafeMath.sol";

import "./Booty.sol";

import "./GovernanceInterface.sol";
import "./BootyInterface.sol";
import "./L7lLedgerInterface.sol";

/** 
 * @title Keeps withdrawable balances of players in ETH and tokens.
 *
 * @dev ETH funds are kept in standard openzeppelin Escrow contract to 
 * protect funds against re-entrancy attacks.
 *
 * Balances in other tokens, including L7L are kept in a separate ledger 
 * escrow-like contracts.
 */
contract Treasury {
    using SafeMath for uint256;

    bytes32 public constant NO_SHARES = keccak256(abi.encode("account has no shares"));
    bytes32 public constant NO_PAYMENT = keccak256(abi.encode("account is not due payment"));

    GovernanceInterface public immutable TrustedGovernance;
    L7lLedgerInterface public TrustedL7lLedger;
    BootyBuilder private TrustedBootyBuilder;

    address[] public allBooties;
    mapping(address => BootyInterface[]) public TrustedBooties;

    modifier onlyLotteries() {
        require(TrustedGovernance.lotteryContracts(msg.sender), "Only lottery");
        _;
    }

    modifier onlyLotteriesOrManager() {
        require(TrustedGovernance.lotteryContracts(msg.sender) || msg.sender == TrustedGovernance.manager(), "Only management");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == TrustedGovernance.owner(), "Only owner");
        _;
    }

    event L7lRewarded(
        address indexed player,
        uint256 reward
    );

    event AllL7lClaimed(
        address indexed player
    );

    event EthClaimed(
        address indexed player,
        uint256 unclaimedBooties
    );

    event EthClaimFailure(
        address indexed player,
        address booty,
        string error
    );

    /** 
     * @dev L7L DAO should be in charge of treasury smart-contract.
     *
     * @param _governance - orchestration contract
     * @param _ledger - L7L token ledger
     */
    constructor(address _governance, address _ledger) public {
        TrustedGovernance = GovernanceInterface(_governance);
        TrustedBootyBuilder = new BootyBuilder(address(this));
        TrustedL7lLedger = L7lLedgerInterface(_ledger);
    }

    /**
     * @dev Create new booty contract for lottery, free for assigment to any round.
     */
    function createBooty() external onlyLotteries returns(address) {
        address bootyAddr = TrustedBootyBuilder.createBooty(address(TrustedGovernance), msg.sender);
        allBooties.push(bootyAddr);
        return bootyAddr;
    }

    /**
     * @dev New booty contract was published.
     *
     * @param dest The creditor's address.
     * @param bootyContract Contract address where player has participated.
     */
    function registerPlayerBooty(address payable dest, address bootyContract) external onlyLotteries {
        TrustedBooties[address(dest)].push(BootyInterface(bootyContract));
    }

    /**
     * @dev Consolidate creditor's claimable ETH from all booties.
     *
     * @param dest The creditor's address.
     */
    function payments(address dest) external view returns(uint256) {
        BootyInterface[] memory booties = TrustedBooties[dest];
        uint256 len = booties.length;
        uint256 total;

        if (len == 0) return 0;

        for (uint32 i = 0; i <= len - 1; i++) {
            total = total.add(booties[i].unlockedBalanceOf(dest));
        }
        return total;
    }

    /**
     * @dev Withdraw all player's balance in ETH.
     *
     * Can potentially require several batches if players were not withdrawing for too many rounds.
     *
     * We use low-level call, because both contracts are trusted and we save gas on elimintation
     * of protective coding.
     *
     * We use 2 local counters to keep track of index and not to overflow 0 in while decrement.
     *
     * @param dest The creditor's address.
     */
    function withdrawPayments(address payable dest) public onlyLotteriesOrManager {
        address destAddr = address(dest);
        BootyInterface[] storage booties = TrustedBooties[destAddr]; 

        uint256 i = booties.length;
        require(i > 0, "nothing to withdraw");

        bool cleanupAllowed = true;

        while (i > 0 && gasleft() > 70000) {
            BootyInterface booty = booties[i - 1];
            address bootyAddr = address(booty);

            try booty.release(dest) {
                if (cleanupAllowed) booties.pop();
            } catch Error(string memory error) {
                bytes32 hashedError = keccak256(abi.encode(error));
                emit EthClaimFailure(destAddr, bootyAddr, error);

                if (cleanupAllowed && (hashedError == NO_SHARES || hashedError == NO_PAYMENT)) {
                    booties.pop();
                } else {
                    cleanupAllowed = false;
                }
            }

            i--;
        }

        emit EthClaimed(destAddr, i);
    }

    /**
     * @dev Player's balance in L7L.
     *
     * @param dest The creditor's address.
     */
    function balanceOfL7l(address dest) public view returns (uint256) {
        return TrustedL7lLedger.depositsOf(dest);
    }

    /**
     * @dev Credit player's balance in L7L.
     *
     * @param dest The creditor's address.
     * @param amount Credit amount in L7L.
     */
    function rewardL7l(address dest, uint256 amount) external onlyLotteries {
        TrustedL7lLedger.depositFor(dest, amount);
        emit L7lRewarded(dest, amount);
    }

    /**
     * @dev Withdraw all player's balance in L7L.
     *
     * @param dest The creditor's address.
     */
    function withdrawL7l(address dest) external {
        require(msg.sender == dest || msg.sender == TrustedGovernance.manager(), "Access denied");
        TrustedL7lLedger.withdraw(dest);
        emit AllL7lClaimed(dest);
    }

    /**
     * @dev Returns total amount of Booty contracts in Treasury.
     */
    function totalBooties() public view returns(uint) {
        return allBooties.length;
    }
}

/** 
 * @title Factory for Booty contacts.
 *
 * @dev We use this technical wrapper contract to reduce size of Treasury contract.
 */
contract BootyBuilder {
    address private immutable publisher;

    /** 
     * @dev Internal Treasury helper contract.
     */
    constructor(address _publisher) public {
        publisher = _publisher;
    }

    /**
     * @dev Create new booty contract for lottery.
     *
     * @param _governance Orchestration contract.
     * @param _lottery Lottery address for which the Booty is created.
     */
    function createBooty(address _governance, address _lottery) external returns(address) {
        require(msg.sender == publisher, "Unauthorized");
        Booty TrustedBooty = new Booty(_governance, _lottery);
        return address(TrustedBooty);
    }
}
