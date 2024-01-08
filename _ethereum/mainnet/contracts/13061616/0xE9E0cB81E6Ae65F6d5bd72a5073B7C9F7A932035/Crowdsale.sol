// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./console.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IFarm.sol";
import "./Pool.sol";
import "./Whitelist.sol";

contract Crowdsale is Ownable {
    using SafeERC20 for IERC20;

    event Whitelisted(address indexed investor, uint256 ticket);

    event TokenBought(
        address indexed investor,
        uint256 value,
        uint256 ticket,
        uint256 amount
    );

    event TokenRedeemed(
        address indexed investor,
        uint256 value,
        uint256 amount
    );

    event TokenGrabbed(
        address indexed investor,
        uint256 quantity,
        uint256 amount
    );

    event Purged(address indexed owner, uint256 amount);

    bool public initialized;
    Pool public pool;

    uint256 public tokenLeft;
    uint256 public soldAmount;
    uint256 public totalRaise;
    uint256 public participants;

    IERC20 private _token;
    IFarm private _farm;

    mapping(address => Whitelist) public whitelist;

    function initialize(Pool memory _pool)
        external
        onlyOwner
        onlyUninitialized
    {
        pool = _pool;
        tokenLeft = _pool.tokenCount;
        initialized = true;
    }

    /// @dev loads the external contract addresses
    function addExternalAddresses(address farm, address token)
        external
        onlyOwner
    {
        _farm = IFarm(farm);
        _token = IERC20(token);
    }

    /// @dev Funds the IDO token to contract
    function fund(uint256 amount) external {
        _token.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @dev Inside IDO after the stage 1 finishes
    /// First come firts serve starts
    /// People who does not whitelisted can buy tokens
    function buyTheRest() external payable fcfs {
        uint256 value = msg.value;
        address investor = msg.sender;
        uint256 quantity = (value / pool.tokenValue) * 10**18;
        Whitelist storage wl = whitelist[investor];

        require(quantity <= tokenLeft, "Not enough token to buy");
        if (wl.wallet == address(0)) {
            wl.wallet = investor;
            wl.amount = value;
            wl.rewardedAmount = quantity;
        } else {
            wl.amount += value;
            wl.rewardedAmount += quantity;
        }

        tokenLeft -= quantity;
        soldAmount += quantity;
        totalRaise += value;
        participants += 1;

        emit TokenGrabbed(msg.sender, quantity, msg.value);
    }

    /// @param ticket No decimals variable
    /// @notice There are two external calls
    /// 1) returns the points that user farmed
    /// 2) Purchase tickets with points
    function addWhitelist(uint256 ticket) external {
        uint256 points = _farm.rewardedPoints(msg.sender);
        uint256 maxTickets = points / pool.ticketValue;
        uint256 spentTicket = pool.maxAmount / pool.ticketAmount;

        Whitelist storage wl = whitelist[msg.sender];
        require(
            spentTicket >= ticket,
            "you have exceeded the maximum amount of tickets you can buy"
        );
        require(maxTickets >= ticket, "You do not have enough points !");
        require(wl.wallet == address(0), "You already whitelisted ! ");

        uint256 _points = pool.ticketValue * ticket;
        require(_farm.payment(msg.sender, _points), "Payment succesfully done");

        wl.wallet = msg.sender;
        wl.ticket = ticket;
        emit Whitelisted(msg.sender, wl.ticket);
    }

    /// @notice Finalized means ALL IDO finished
    function redeem() external finalized {
        Whitelist storage wl = whitelist[msg.sender];

        require(wl.wallet != address(0), "Sender isn't in whitelist");
        require(wl.amount > 0, "No token bought");
        require(wl.rewardedAmount > 0, "Redeemed before");

        _token.safeTransfer(wl.wallet, wl.rewardedAmount);

        emit TokenRedeemed(msg.sender, wl.amount, wl.rewardedAmount);

        wl.rewardedAmount = 0;
        wl.amount = 0;
    }

    /// @notice If any case another erc20 token is being sent here
    function recoverTokens(address token) external onlyOwner {
        IERC20(token).transfer(
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
    }

    /// @notice To withdraw native tokens
    function withdraw() external onlyOwner finalized {
        (bool success, ) = _msgSender().call{value: address(this).balance}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /// @notice After whitelisted person has ticket and can buy IDO tokens
    function buy() public payable {
        Whitelist storage wl = whitelist[msg.sender];
        uint256 value = msg.value;
        uint256 spentTicket = value / pool.ticketAmount;

        require(spentTicket > 0, "You don't have enough ticket");
        require(block.timestamp >= pool.startTime, "Sale is not started yet");
        require(block.timestamp <= pool.fcfsTime, "Sale stage 1 is ended");
        require(wl.wallet != address(0), "You're not in whitelist");
        require(spentTicket <= wl.ticket, "You do not have enough ticket");
        require(wl.amount + value <= pool.maxAmount, "ETH exceeds max amount");

        uint256 rewardedAmount = (value / pool.tokenValue) * (10**18);
        wl.ticket -= spentTicket;
        wl.amount += value;
        wl.rewardedAmount += rewardedAmount;

        tokenLeft -= rewardedAmount;
        soldAmount += rewardedAmount;
        totalRaise += value;
        participants += 1;

        emit TokenBought(msg.sender, value, spentTicket, rewardedAmount);
    }

    /// @notice This is after IDO ends. Owner gets his tokens back
    function purge() public onlyOwner finalized {
        require(tokenLeft > 0, "No Unsold Token");
        _token.safeTransfer(msg.sender, tokenLeft);

        emit Purged(msg.sender, tokenLeft);
    }

    function getData()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 swapRate = (10**18) / pool.tokenValue;

        uint256 totalTicketAmount = pool.tokenCount / pool.tokenValue;
        totalTicketAmount = (totalTicketAmount * 1 ether) / pool.ticketAmount;
        uint256 maxUserTicketAmount = pool.maxAmount / pool.ticketAmount;
        ///ticket price dön returnde
        uint256 allocationPerTicket = (totalTicketAmount * 1 ether) /
            pool.tokenCount;
        uint256 personelMaxAl = pool.maxAmount / pool.tokenValue;
        uint256 maxAlPerUser = maxUserTicketAmount * pool.ticketValue;

        return (
            swapRate,
            totalTicketAmount,
            maxUserTicketAmount,
            allocationPerTicket,
            personelMaxAl,
            pool.ticketValue,
            maxAlPerUser
        );
    }

    modifier fcfs() {
        require(pool.fcfsTime <= block.timestamp, "Fcfs did not start");
        require(pool.fcfsEndTime > block.timestamp, "Fcfs did finish");
        _;
    }

    modifier finalized() {
        require(pool.endTime <= block.timestamp, "Crowdsale: Not Finished !");
        _;
    }

    modifier onlyUninitialized() {
        require(!initialized, "Crowdsale: already initialized");
        _;
    }
}
