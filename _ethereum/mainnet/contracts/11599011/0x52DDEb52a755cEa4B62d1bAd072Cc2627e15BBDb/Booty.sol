// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.6.0;

import "./SafeMath.sol";

import "./GovernanceInterface.sol";

/** 
 * @title Keeps balance of players in ETH for specific lottery round.
 *
 * @dev This contract is a simplified fork of openzeppelin's PaymentSplitter
 * and RefundEscrow contracts.
 *
 * At the event of win it nullifies the loser side shares.
 */
contract Booty {
    using SafeMath for uint256;

    GovernanceInterface public TrustedGovernance;

    enum State { Free, Active, GreenWon, BlueWon, Draw }

    event RoundResolved(uint32 round, State state, uint256 total, uint256 winners);
    event BootyClaimed(address indexed player, uint256 amount);
    event Bet(address indexed player, uint256 amount, uint8 indexed side, uint32 indexed round);

    address public immutable lottery;
    uint32 public currentRound;
    uint32[] public rounds;
    uint public killableAfter;

    State public state = State.Free;
    
    uint256 public totalShares;
    uint256 public totalReleased;
    uint256 public totalGreen;
    uint256 public totalBlue;

    mapping(address => uint256) public greenShares;
    mapping(address => uint256) public blueShares;
    mapping(address => uint256) public released;

    address payable[] public bluePayees;
    address payable[] public greenPayees;

    modifier onlyDAO() {
        require(msg.sender == TrustedGovernance.owner(), "Only owner");
        _;
    }

    modifier onlyLottery() {
        require(msg.sender == lottery, "Only lottery");
        _;
    }

    modifier onlyActive() {
        require(state == State.Active, "Already resolved");
        _;
    }

    /**
     * @dev We don't know the future shareholders at contract deployment time
     * we'll know their total number at the end of the lottery.
     *
     * @param _governance Orchestration contract.
     * @param _lottery Lottery contract for which we hold balances.
     */
    constructor (address _governance, address _lottery) public {
        TrustedGovernance = GovernanceInterface(_governance);

        lottery = _lottery;
        killableAfter = now + TrustedGovernance.timeToClaimBooty();
    }

    /**
     * @dev Check how much wei user has lost in that round.
     *
     * @param _payee Address of user whose balance we are checking.
     */
    function losesOf(address _payee) public view returns (uint256) {
        State _state = state;
        if (_state == State.GreenWon) {
            return blueShares[_payee];
        } else if (_state == State.BlueWon) {
            return greenShares[_payee];
        } else {
            return 0;
        }
    }

    /**
     * @dev Check current balance of the user which he can withdraw.
     *
     * @param _payee Address of user whose balance we are checking.
     */
    function unlockedBalanceOf(address _payee) public view returns (uint256) {
        State _state = state;
        if (_state == State.GreenWon) {
            return balanceByShares(_payee, greenShares[_payee]);
        } else if (_state == State.BlueWon) {
            return balanceByShares(_payee, blueShares[_payee]);
        } else if (_state == State.Draw) {
            return sharesByState(_payee, _state);
        } else {
            return 0;
        }
    }

    /**
     * @dev Check current balance of the user which he can't withdraw.
     *
     * @param _payee Address of user whose balance we are checking.
     */
    function lockedBalanceOf(address _payee) public view returns (uint256) {
        State _state = state;
        if (_state == State.Active) {
            return blueShares[_payee].add(greenShares[_payee]);
        } else {
            return 0;
        }
    }

    /**
     * @dev Helper to check balance based on shares ownership.
     *
     * @param _payee Address of user whose balance we are checking.
     * @param _shares Eligible shares of user.
     */
    function balanceByShares(address _payee, uint256 _shares) public view returns (uint256) {
        return address(this).balance.add(totalReleased).mul(_shares).div(totalShares).sub(released[_payee]);
    }

    /**
     * @dev Helper to check shares of user based on current state.
     *
     * @param _payee Address of user whose balance we are checking.
     * @param _state Cached current game state.
     */
    function sharesByState(address _payee, State _state) public view returns (uint256) {
        if (_state == State.BlueWon) {
            return blueShares[_payee];
        } else if (_state == State.GreenWon) {
            return greenShares[_payee];
        } else if (_state == State.Draw) {
            return blueShares[_payee].add(greenShares[_payee]);
        } else {
            return 0;
        }
    }

    /**
     * @dev Register bet for Green.
     *
     * @param _sender Address on behalf of which the payment was done.
     */
    function greenBet(address payable _sender) external payable onlyActive onlyLottery {
        uint256 currentShares = greenShares[_sender];
        if (currentShares == 0) greenPayees.push(_sender);

        emit Bet(_sender, msg.value, 1, currentRound);
        totalGreen = totalGreen.add(msg.value);
        greenShares[_sender] = currentShares.add(msg.value);
        totalShares = totalShares.add(msg.value);
    }

    /**
     * @dev Register bet for Blue.
     *
     * @param _sender Address on behalf of which the payment was done.
     */
    function blueBet(address payable _sender) external payable onlyActive onlyLottery {
        uint256 currentShares = blueShares[_sender];
        if (currentShares == 0) bluePayees.push(_sender);

        emit Bet(_sender, msg.value, 0, currentRound);
        totalBlue = totalBlue.add(msg.value);
        blueShares[_sender] = currentShares.add(msg.value);
        totalShares = totalShares.add(msg.value);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     *
     * @param account Address which withdraws it's booty.
     */
    function release(address payable account) public {
        State _state = state;
        require(_state != State.Active, "not ready");

        address _payee = address(account);
        uint256 _shares = sharesByState(_payee, _state);
        require(_shares > 0, "account has no shares");
        
        uint256 _payment = balanceByShares(_payee, _shares);
        require(_payment != 0, "account is not due payment");

        released[_payee] = released[_payee].add(_payment);
        totalReleased = totalReleased.add(_payment);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = account.call{value: _payment}("");
        require(success, "unable to send value");

        emit BootyClaimed(_payee, _payment);
    }

    /**
     * @dev Blue won, nullify Green bets, allow releasing of funds.
     */
    function declareBlueWin() external onlyActive onlyLottery {
        totalShares = totalShares.sub(totalGreen);
        state = State.BlueWon;
        emit RoundResolved(rounds[rounds.length - 1], State.BlueWon, address(this).balance, totalBlue);
    }

    /**
     * @dev Green won, nullify Blue bets, allow releasing of funds.
     */
    function declareGreenWin() external onlyActive onlyLottery {
        totalShares = totalShares.sub(totalBlue);
        state = State.GreenWon;
        emit RoundResolved(rounds[rounds.length - 1], State.GreenWon, address(this).balance, totalGreen);
    }

    /**
     * @dev Game canceled, users can freely release their funds.
     */
    function declareDraw() external onlyActive {
        require(TrustedGovernance.isManagement(msg.sender) || msg.sender == lottery, "Only management or lottery");
        state = State.Draw;
        emit RoundResolved(rounds[rounds.length - 1], State.Draw, 0, 0);
    }

    /**
     * @dev Use new or recycled Booty contract for a new round.
     *
     * @param _round New round for the Booty.
     */
    function useForRound(uint32 _round) external onlyLottery {
        require(state == State.Free, "already used");
        newRound(_round);
    }

    /**
     * @dev Lottery can recycle empty Booty contract to save on gas fees.
     * In case Booty had singe market maker - generate relevant bet events.
     *
     * @param _round New round for the Booty.
     */
    function recycleForRound(uint32 _round) external onlyLottery returns (address, uint256, address, uint256) {
        require(readiness() == 0, "not empty, non recyclable");
        emit RoundResolved(rounds[rounds.length - 1], State.Draw, 0, 0);
        newRound(_round);

        address payable mmBlue;
        uint256 amBlue;
        if (bluePayees.length != 0) {
            mmBlue = bluePayees[0];
            amBlue = blueShares[mmBlue];
            emit Bet(mmBlue, amBlue, 0, _round);
        }

        address payable mmGreen;
        uint256 amGreen;
        if (greenPayees.length != 0) {
            mmGreen = greenPayees[0];
            amGreen = greenShares[mmGreen];
            emit Bet(mmGreen, amGreen, 1, _round);
        }

        return (mmBlue, amBlue, mmGreen, amGreen);
    }

    /**
     * @dev Set new round state.
     *
     * @param _round New round for the Booty.
     */
    function newRound(uint32 _round) private {
        currentRound = _round;
        rounds.push(_round);
        killableAfter = now + TrustedGovernance.timeToClaimBooty();
        state = State.Active;
    }

    /**
     * @dev Checks one of 3 possible booty states.
     *
     * 2 - ready for resolution;
     * 1 - not empty, undecided;
     * 0 - no bets or single participant, can be recycled.
     */
    function readiness() public view returns (uint8) {
        uint256 _tg = totalGreen;
        uint256 _tb = totalBlue;
        
        if (bluePayees.length == 1 && greenPayees.length == 1 && bluePayees[0] == greenPayees[0]) {
            return 0;
        } else if (_tg == 0 && _tb == 0) {
            return 0;
        } else if (_tg > 0 && _tb > 0) {
            return 2;
        } else {
            return 1;
        }
    }

    /**
     * @dev Management can pay fee for recycle if it's cheaper to recycle
     * Booty contract instead of making a new one which is ~2,6m gas.
     *
     * For manual payouts you can cycle over winner's party known by state 
     * (greenPayees or bluePayeers). Check pending payouts with combination 
     * of sharesByState and balanceByShares, then call release for the relevant addresses.
     */
    function forceRecycle() external onlyLottery {
        require(address(this).balance < 0.09 ether, "clear payouts first");

        for (uint32 i = 0; i < greenPayees.length; i++) {
            address _addr = address(greenPayees[i]);
            delete greenShares[_addr];
            if (released[_addr] > 0) delete released[_addr];
        }
        for (uint32 i = 0; i < bluePayees.length; i++) {
            address _addr = address(bluePayees[i]);
            delete blueShares[_addr];
            if (released[_addr] > 0) delete released[_addr];
        }

        delete totalShares;
        delete totalReleased;
        delete totalGreen;
        delete totalBlue;

        delete bluePayees;
        delete greenPayees;

        state = State.Free;
    }

    /** 
     * @dev Used for cleanup, players have 30 days to withdraw their holding.
     * empty booties can be killed at once.
     */
    function daoDie() external onlyDAO {
        if (address(this).balance > 0.09 ether) require(killableAfter < now, "yet to expire");
        
        selfdestruct(TrustedGovernance.beneficiary());
    }
}
