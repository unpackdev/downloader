// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ERC721Enumerable.sol";
import "SafeMath.sol";
import "Counters.sol";
import "Ownable.sol";
import "Pausable.sol";

import "BPC.sol";
import "BPCSenderRecipient.sol";
import "ExternalFuncs.sol";

contract BPCLottery is ERC721, ERC777SenderRecipientMock, Ownable, Pausable {
    //using ExternalFuncs for *;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    IERC777 private m_bpc;
    bool private m_bpc_is_set;
    modifier isTokenSet() {
        require(m_bpc_is_set, "ERC777 is not set");
        _;
    }
    address private m_company_account;

    Counters.Counter private m_ticket_id;
    Counters.Counter private m_lottery_id;
    uint256 private m_ticket_price;
    bool private is_lottery_open;

    uint256 private constant m_duration = 7 days;

    struct Winner {
        uint256 ticket_id;
        address addr;
        bool isSet;
    }

    mapping(uint256 => uint256) private m_lottery_id_pot;
    mapping(uint256 => uint256) private m_lottery_id_expires_at;
    mapping(uint256 => bool) private m_lottery_id_paid;
    mapping(uint256 => Winner) private m_lottery_id_winner;

    event WinnerAnnounced(
        address winner,
        uint256 winner_id,
        uint256 lottery_id,
        uint256 prize_size
    );
    event WinnerPaid(address winner, uint256 lottery_id, uint256 prize_size);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _ticket_price,
        address _company_account
    ) ERC721(_name, _symbol) {
        m_company_account = _company_account;
        // ERC-777 receiver init
        // See https://forum.openzeppelin.com/t/simple-erc777-token-example/746
        _erc1820.setInterfaceImplementer(
            address(this),
            _TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );

        m_ticket_price = _ticket_price != 0
            ? _ticket_price
            : 5000000000000000000; // 5 * 10^18

        m_lottery_id_expires_at[m_lottery_id.current()] = block.timestamp.add(
            m_duration
        );
        m_lottery_id_paid[m_lottery_id.current()] = false;

        is_lottery_open = true;
        m_bpc_is_set = false;
    }

    function setERC777(address _bpc) public onlyOwner {
        require(_bpc != address(0), "BPC address cannot be 0");
        require(
            !m_bpc_is_set,
            "You have already set BPC address, can't do it again"
        );
        m_bpc = IERC777(_bpc);
        m_bpc_is_set = true;
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unPause() public onlyOwner whenPaused {
        _unpause();
    }

    //function paused() public view comes as a base class method of Pausable

    function setTicketPrice(uint256 new_ticket_price)
        public
        onlyOwner
        isTokenSet
    {
        require(new_ticket_price > 0, "Ticket price should be greater than 0");
        m_ticket_price = new_ticket_price;
    }

    //when not paused
    function getTicketPrice() public view returns (uint256) {
        require(!paused(), "Lottery is paused, please come back later");
        return m_ticket_price;
    }

    //when not paused
    function buyTicket(uint256 bpc_tokens_amount, address participant)
        public
        isTokenSet
    {
        require(!paused(), "Lottery is paused, please come back later");
        require(
            m_bpc.isOperatorFor(msg.sender, participant),
            "You MUST be an operator for participant"
        );
        require(
            bpc_tokens_amount.mod(m_ticket_price) == 0,
            "Tokens amount should be a multiple of a Ticket Price"
        );
        require(
            m_bpc.balanceOf(participant) >= bpc_tokens_amount,
            "You should have enough of Tokens in your Wallet"
        );

        m_bpc.operatorSend(
            participant,
            address(this),
            bpc_tokens_amount,
            bytes(""),
            bytes("")
        );
        m_lottery_id_pot[m_lottery_id.current()] = m_lottery_id_pot[
            m_lottery_id.current()
        ].add(bpc_tokens_amount);

        uint256 tickets_count = bpc_tokens_amount.div(m_ticket_price);
        for (uint256 i = 0; i != tickets_count; ++i) {
            m_ticket_id.increment();
            _mint(participant, m_ticket_id.current());
        }
    }

    //when not paused
    function getCurrentLotteryTicketsCount(address participant)
        public
        view
        returns (uint256)
    {
        require(!paused(), "Lottery is paused, please come back later");
        require(
            m_bpc.isOperatorFor(msg.sender, participant),
            "You MUST be an operator for participant"
        );
        return this.balanceOf(participant);
    }

    function getCurrentLotteryId() public view returns (uint256) {
        return m_lottery_id.current();
    }

    function getCurrentLotteryPot() public view returns (uint256) {
        return m_lottery_id_pot[m_lottery_id.current()];
    }

    function announceWinnerAndRevolve() public onlyOwner isTokenSet {
        require(isLotteryPeriodOver(), "The current lottery is still running");
        forceAnnounceWinnerAndRevolve();
    }

    function forceAnnounceWinnerAndRevolve() public onlyOwner isTokenSet {
        uint256 prize_size = m_lottery_id_pot[m_lottery_id.current()].div(2);
        uint256 id = m_lottery_id.current();

        if (!m_lottery_id_winner[id].isSet) {
            m_lottery_id_winner[id] = setWinner(prize_size);
        }

        if (!isEmptyWinner(m_lottery_id_winner[id]) && !m_lottery_id_paid[id]) {
            splitPotWith(m_lottery_id_winner[id].addr, prize_size);
            m_lottery_id_paid[id] = true;
            m_lottery_id_pot[id] = 0;
        }

        if (!paused()) {
            revolveLottery();
        }
    }

    function isLotteryPeriodOver() private view returns (bool) {
        return
            m_lottery_id_expires_at[m_lottery_id.current()] < block.timestamp;
    }

    function getWinner(uint256 id) public view returns (address) {
        require(
            m_lottery_id_winner[id].isSet,
            "Lottery Id Winner or Lottery Id not found"
        );
        return m_lottery_id_winner[id].addr;
    }

    function setWinner(uint256 prize_size) private returns (Winner memory) {
        Winner memory winner;
        winner.isSet = true;

        if (m_ticket_id.current() != 0) {
            winner.ticket_id = prng().mod(m_ticket_id.current()).add(1);
            winner.addr = this.ownerOf(winner.ticket_id);
            emit WinnerAnnounced(
                winner.addr,
                winner.ticket_id,
                m_lottery_id.current(),
                prize_size
            );
        } else {
            winner.ticket_id = 0;
            winner.addr = address(0);
        }
        return winner;
    }

    function isEmptyWinner(Winner memory winner) private pure returns (bool) {
        return winner.addr == address(0);
    }

    function splitPotWith(address winner_address, uint256 prize_size) private {
        m_bpc.operatorSend(
            address(this),
            winner_address,
            prize_size,
            bytes(""),
            bytes("")
        );
        m_bpc.operatorSend(
            address(this),
            m_company_account,
            prize_size,
            bytes(""),
            bytes("")
        );
        emit WinnerPaid(winner_address, m_lottery_id.current(), prize_size);
    }

    function revolveLottery() private {
        uint256 size = m_ticket_id.current();

        if (size != 0) {
            for (uint256 i = 1; i <= size; ++i) {
                _burn(i);
            }
        }

        m_ticket_id.reset();

        m_lottery_id.increment();
        m_lottery_id_expires_at[m_lottery_id.current()] = block.timestamp.add(
            m_duration
        );
    }

    function prng() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        m_ticket_id.current()
                    )
                )
            );
    }
}
