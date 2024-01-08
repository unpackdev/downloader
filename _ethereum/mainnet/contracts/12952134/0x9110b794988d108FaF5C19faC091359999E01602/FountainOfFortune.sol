//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./IFountainOfFortune.sol";
import "./IWETH.sol";
import "./Counters.sol";
import "./VRFConsumerBase.sol";

/**
 * @title Fountain Of Fortune
 * @author Myobu Devs
 */
contract FountainOfFortune is
    VRFConsumerBase(
        0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
        0x514910771AF9Ca656af840dff83E8264EcF986CA
    ),
    IFountainOfFortune,
    ERC721("Fountain of Fortune", "FOF")
{
    /// @dev Using counters for lottery ID's
    using Counters for Counters.Counter;

    /**
     * @dev
     * _myobu: The Myobu token contract
     * _WETH: The WETH contract used to wrap ETH
     * _chainlinkKeyHash: The chainlink key hash
     * _chainlinkFee: The amount of link to pay for random numbers
     * _feeReceiver: Where all the ticket sale fees will be sent to
     * _tokenID: Used to mint NFTs, increases for each NFT minted
     * _lastClaimedTokenID: Used to store the last tokenID that fees were claimed for
     * _rewardClaimed: Used to store if the reward has been claimed for the current lottery, resets per lottery
     * _inClaimReward: Used to store if its waiting for an oracle response, so claimReward() can't be called multiple times
     * and waste all the LINK in the contract
     * _lotteryID: A counter of how much lotteries there have been, increases by 1 each new lottery
     * _lottery: A mapping of Lottery ID => The lottery struct that stores information
     * _ticketsBought: A mapping of Address => Lottery ID => Amount of tickets bought
     */
    IERC20 private _myobu;
    // solhint-disable-next-line
    IWETH private _WETH;
    bytes32 private _chainlinkKeyHash;
    uint256 private _chainlinkFee;
    address private _feeReceiver;
    uint256 private _tokenID;
    uint256 private _lastClaimedTokenID;
    bool private _rewardClaimed;
    bool private _inClaimReward;
    Counters.Counter private _lotteryID;
    mapping(uint256 => Lottery) private _lottery;
    mapping(address => mapping(uint256 => uint256)) private _ticketsBought;

    /**
     * @dev Modifier that requires that there is no lottery ongoing (ended)
     */
    modifier onlyEnded {
        require(
            _lottery[_lotteryID.current()].endTimestamp <= block.timestamp,
            "FoF: Lottery needs to have ended for this"
        );
        _;
    }

    /**
     * @dev Modifier that requires that there is a lottery in progress (on)
     */
    modifier onlyOn {
        require(
            _lottery[_lotteryID.current()].endTimestamp > block.timestamp,
            "FoF: No lottery is on right now"
        );
        _;
    }

    /**
     * @dev Defines the Myobu and WETH token contracts, the chainlink fee and keyhash
     */
    constructor() {
        _myobu = IERC20(0x75D12E4F91Df721faFCae4c6cD1d5280381370AC);
        _feeReceiver = address(0xdD5FD50DcB8Db2B41357f8E655b941A04b566Cb5);
        _WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        _chainlinkKeyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        _chainlinkFee = 2e18;
        /// @dev So the owner can be able to start the lottery
        _rewardClaimed = true;
        /// @dev Start ID's at 1
        _tokenID = 1;
        _lastClaimedTokenID = 1;
    }

    /**
     * @dev Attempt to transfer ETH, if failed wrap the ETH and send WETH. So that the
     * transfer always succeeds
     * @param to: The address to send ETH to
     * @param amount: The amount to send
     */
    function transferOrWrapETH(address to, uint256 amount) internal {
        // solhint-disable-next-line
        if (!payable(to).send(amount)) {
            _WETH.deposit{value: amount}();
            _WETH.transfer(to, amount);
        }
    }

    /**
     * @dev Make the lottery tickets untransferable
     * So that nobody makes a new address, buys myobu and then sends the tickets to another address
     * And then sells the myobu. And if he wins the lottery, it won't count it.
     *
     * While it could transfer the ticketsBought, that would make it so anyone can buy tickets, and
     * send to someone else. And then if the person that it was sent to wins from their
     * old lottery tickets, they wouldn't get the reward because not enough myobu to cover
     * the new tickets that they have been sent
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal pure override {
        /// @dev Only mint or burn is allowed
        require(
            from == address(0) || to == address(0),
            "FoF: Cannot transfer tickets"
        );
    }

    /**
     * @return The amount of myobu that someone needs to hold to buy lottery tickets
     * @param user: The address
     * @param amount: The amount of tickets
     */
    function myobuNeededForTickets(address user, uint256 amount)
        public
        view
        override
        returns (uint256)
    {
        uint256 minimumMyobuBalance = _lottery[_lotteryID.current()]
        .minimumMyobuBalance;
        uint256 myobuNeededForEachTicket = _lottery[_lotteryID.current()]
        .myobuNeededForEachTicket;
        uint256 ticketsBought_ = _ticketsBought[user][_lotteryID.current()];
        uint256 totalTickets = (ticketsBought_ + amount) - 1;
        uint256 _myobuNeededForTickets = totalTickets * myobuNeededForEachTicket;
        return minimumMyobuBalance + _myobuNeededForTickets;
    }

    /**
     * @dev Buys tickets with ETH, requires that he has at least (myobuNeededForTickets()) myobu,
     * and then loops over how much tickets he needs and mints the ERC721 tokens
     * If there is too much ETH sent, refund unneeded ETH
     * Emits TicketsBought()
     */
    function buyTickets() external payable override onlyOn {
        uint256 ticketPrice = _lottery[_lotteryID.current()].ticketPrice;
        uint256 amountOfTickets = msg.value / ticketPrice;
        require(amountOfTickets != 0, "FoF: Not enough ETH");
        require(
            _myobu.balanceOf(_msgSender()) >=
                myobuNeededForTickets(_msgSender(), amountOfTickets),
            "FoF: You don't have enough $MYOBU"
        );
        uint256 neededETH = amountOfTickets * ticketPrice;
        /// @dev Refund unneeded eth
        if (msg.value > neededETH) {
            transferOrWrapETH(_msgSender(), msg.value - neededETH);
        }
        uint256 tokenID_ = _tokenID;
        _tokenID += amountOfTickets;
        _ticketsBought[_msgSender()][_lotteryID.current()] += amountOfTickets;
        for (uint256 i = tokenID_; i < amountOfTickets + tokenID_; i++) {
            _mint(_msgSender(), i);
        }
        emit TicketsBought(_msgSender(), amountOfTickets, ticketPrice);
    }

    /**
     * @dev Function to calculate how much fees that will be taken
     * @return The amount of fees that will be taken
     * @param currentTokenID: The latest tokenID
     * @param ticketPrice: The price of 1 ticket
     * @param ticketFee: The percentage of the ticket to take as a fee
     * @param lastClaimedTokenID_: The last token ID that fees have been claimed for
     */
    function calculateFees(
        uint256 currentTokenID,
        uint256 ticketPrice,
        uint256 ticketFee,
        uint256 lastClaimedTokenID_
    ) public pure override returns (uint256) {
        uint256 unclaimedTicketSales = currentTokenID - lastClaimedTokenID_;
        return ((unclaimedTicketSales * ticketPrice) * ticketFee) / 10000;
    }

    /**
     * @return The amount of unclaimed fees, can be claimed using claimFees()
     */
    function unclaimedFees() public view override returns (uint256) {
        return
            calculateFees(
                _tokenID,
                _lottery[_lotteryID.current()].ticketPrice,
                _lottery[_lotteryID.current()].ticketFee,
                _lastClaimedTokenID
            );
    }

    /**
     * @return The amount of fees taken for the current lottery
     */
    function claimedFees() public view override returns (uint256) {
        return
            calculateFees(
                _lastClaimedTokenID,
                _lottery[_lotteryID.current()].ticketPrice,
                _lottery[_lotteryID.current()].ticketFee,
                _lottery[_lotteryID.current()].startingTokenID
            );
    }

    /**
     * @dev Function that claims fees, saves gas so that its doesn't happen per ticket buy.
     * Emits FeesClaimed()
     */
    function claimFees() public override {
        uint256 fee = unclaimedFees();
        _lastClaimedTokenID = _tokenID;
        transferOrWrapETH(_feeReceiver, fee);
        emit FeesClaimed(fee, _msgSender());
    }

    /**
     * @dev Function that distributes the reward, requests for randomness, completes at fulfillRandomness()
     * If nobody bought a ticket, makes rewardsClaimed true and returns nothing
     * Checks for _inClaimReward so that its not called more than once, wasting LINK.
     */
    function claimReward()
        external
        override
        onlyEnded
        returns (bytes32 requestId)
    {
        require(!_rewardClaimed, "FoF: Reward already claimed");
        require(!_inClaimReward, "FoF: Reward is being claimed");
        /// @dev So it doesn't fail if nobody bought any tickets
        if (_lottery[_lotteryID.current()].startingTokenID == _tokenID) {
            _rewardClaimed = true;
            return 0;
        }
        require(
            LINK.balanceOf(address(this)) >= _chainlinkFee,
            "FoF: Put some LINK into the contract"
        );
        _inClaimReward = true;
        return requestRandomness(_chainlinkKeyHash, _chainlinkFee);
    }

    /**
     * @dev Gets a winner and sends him the jackpot, if he doesn't have myobu at the time of winning
     * send the _feeReceiver the jackpot
     * Emits LotteryWon();
     */
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        /// @dev Get a random number in range of the token IDs
        uint256 x = _lottery[_lotteryID.current()].startingTokenID;
        uint256 y = _tokenID;
        /// @dev The winning token ID
        uint256 resultInRange = x + (randomness % (y - x));
        address winner = ownerOf(resultInRange);
        uint256 amountWon = jackpot();
        uint256 myobuNeeded = myobuNeededForTickets(winner, 0);
        if (_myobu.balanceOf(winner) < myobuNeeded) {
            /// @dev He sold his myobu, give the jackpot to the fee receiver and deduct based on the percentage to keep
            uint256 amountToKeepForNextLottery = (amountWon *
                _lottery[_lotteryID.current()]
                .percentageToKeepOnNotEnoughMyobu) / 10000;
            amountWon -= amountToKeepForNextLottery;
            winner = _feeReceiver;
        }
        transferOrWrapETH(winner, amountWon);
        _rewardClaimed = true;
        delete _inClaimReward;
        emit LotteryWon(winner, amountWon, resultInRange);
    }

    /**
     * @dev Starts a new lottery, Can only be done by the owner.
     * Emits LotteryCreated()
     * @param lotteryLength: How long the lottery will be in seconds
     * @param ticketPrice: The price of a ticket in ETH
     * @param ticketFee: The percentage of the ticket price that is sent to the fee receiver
     * @param percentageToKeepForNextLottery: The percentage that will be kept as reward for the lottery after
     * @param minimumMyobuBalance: The minimum amount of myobu someone needs to buy tickets or get the reward
     * @param myobuNeededForEachTicket: The amount of myobu that someone needs to hold for each ticket they buy
     * @param percentageToKeepOnNotEnoughMyobu: If someone doesn't have myobu at the time of winning, this will define the
     * percentage of the reward that will be kept in the contract for the next lottery
     */
    function createLottery(
        uint256 lotteryLength,
        uint256 ticketPrice,
        uint256 ticketFee,
        uint256 percentageToKeepForNextLottery,
        uint256 minimumMyobuBalance,
        uint256 myobuNeededForEachTicket,
        uint256 percentageToKeepOnNotEnoughMyobu
    ) external onlyOwner onlyEnded {
        /// @dev Cannot execute it now, must be executed seperately
        require(
            _rewardClaimed,
            "FoF: Claim the reward before starting a new lottery"
        );
        require(
            percentageToKeepForNextLottery + ticketFee < 10000,
            "FoF: You can not take everything or more as a fee"
        );
        require(
            lotteryLength <= 2629744,
            "FoF: Must be under or equal to 1 month"
        );
        /// @dev Check if fees haven't been claimed, if they haven't claim them
        if (unclaimedFees() != 0) {
            claimFees();
        }
        /// @dev For the new lottery
        _lotteryID.increment();
        uint256 newLotteryID = _lotteryID.current();
        _lottery[newLotteryID] = Lottery(
            _tokenID,
            block.timestamp,
            block.timestamp + lotteryLength,
            ticketPrice,
            ticketFee,
            minimumMyobuBalance,
            percentageToKeepForNextLottery,
            myobuNeededForEachTicket,
            percentageToKeepOnNotEnoughMyobu
        );
        delete _rewardClaimed;
        emit LotteryCreated(
            newLotteryID,
            lotteryLength,
            ticketPrice,
            ticketFee,
            minimumMyobuBalance,
            percentageToKeepForNextLottery,
            myobuNeededForEachTicket,
            percentageToKeepOnNotEnoughMyobu
        );
    }

    /**
     * @dev Returns the amount of tokens to keep for the next lottery
     */
    function toNextLottery() public view override returns (uint256) {
        uint256 percentageToKeepForNextLottery = _lottery[_lotteryID.current()]
        .percentageToKeepForNextLottery;
        uint256 totalFees = claimedFees();
        return
            ((address(this).balance + totalFees) *
                percentageToKeepForNextLottery) / 10000;
    }

    /**
     * @return The current jackpot
     * @dev Balance - The percentage for the next lottery - Unclaimed Fees
     */
    function jackpot() public view override returns (uint256) {
        uint256 balance = address(this).balance;
        uint256 _unclaimedFees = unclaimedFees();
        uint256 amountToKeepForNextLottery = toNextLottery();
        return balance - amountToKeepForNextLottery - _unclaimedFees;
    }

    /**
     * @dev Function so that anyone can contribute to the jackpot when there is a lottery ongoing
     */
    // solhint-disable-next-line
    receive() external payable onlyOn {}

    /// @dev Getter functions : Start

    /**
     * @return The Myobu Token
     */
    function myobu() external view override returns (IERC20) {
        return _myobu;
    }

    /**
     * @return The amount of link to pay for a VRF call
     */
    function chainlinkFee() external view override returns (uint256) {
        return _chainlinkFee;
    }

    /**
     * @return Where all the ticket fees will be sent to
     */
    function feeReceiver() external view override returns (address) {
        return _feeReceiver;
    }

    /**
     * @return The current lottery ID
     */
    function currentLotteryID() external view override returns (uint256) {
        return _lotteryID.current();
    }

    /**
     * @dev The current token ID
     */
    function tokenID() external view override returns (uint256) {
        return _tokenID;
    }

    /**
     * @return The info of a lottery (A struct)
     * See the Lottery struct for more info
     * @param lotteryID: The ID of the lottery to get info for
     */
    function lottery(uint256 lotteryID)
        external
        view
        override
        returns (Lottery memory)
    {
        return _lottery[lotteryID];
    }

    /**
     * @return Returns if the reward has been claimed, can only be viewed when there is no
     * lottery in progress or will return false.
     */
    function rewardClaimed() external view override onlyEnded returns (bool) {
        return _rewardClaimed;
    }

    /**
     * @return The last token ID fees have been claimed on for the current lottery
     */
    function lastClaimedTokenID() external view override returns (uint256) {
        return _lastClaimedTokenID;
    }

    /**
     * @return The amount of tickets someone bought
     * @param user: The address
     * @param lotteryID: The ID of the lottery
     */
    function ticketsBought(address user, uint256 lotteryID)
        external
        view
        override
        returns (uint256)
    {
        return _ticketsBought[user][lotteryID];
    }

    /// @dev Getter functions : End

    /**
     * @dev If there is unneeded LINK in the contract, the owner can recover them using this function
     */
    function recoverLINK(uint256 amount) external onlyOwner {
        LINK.transfer(_msgSender(), amount);
    }

    /// @dev Optional functions, commented out by default

    /**
     * @dev In case the Myobu token gets changed later on, the owner can call this to change it
     * @param newMyobu: The new myobu token contract
    function setMyobu(IERC20 newMyobu) external onlyOwner {
        _myobu = newMyobu;
    }
     */


    /**
     * @dev Sets the address that receives all the fees
     * @param newFeeReceiver: The new address that will recieve all the fees
    function setFeeReceiver(address newFeeReceiver) external onlyOwner {
        _feeReceiver = newFeeReceiver;
    }
     */

    /**
     * @dev Changes the chainlink VRF oracle fee in case it needs to be changed later on
     * @param newChainlinkFee: The new amount of LINK to pay for a VRF Oracle call
     */
    function setChainlinkFee(uint256 newChainlinkFee) external onlyOwner {
        _chainlinkFee = newChainlinkFee;
    }

    /**
     * @dev Extends the duration of the current lottery and checks if its the new duration is over 1 month, reverts if it is
     * @param extraTime: The time in seconds to extend it by
     */
    function extendCurrentLottery(uint256 extraTime) external onlyOwner onlyOn {
        uint256 currentLotteryEnd = _lottery[_lotteryID.current()].endTimestamp;
        uint256 currentLotteryStart = _lottery[_lotteryID.current()]
        .startTimestamp;
        require(
            currentLotteryEnd + extraTime <= currentLotteryStart + 2629744,
            "FoF: Must be under or equal to 1 month"
        );
        _lottery[_lotteryID.current()].endTimestamp += extraTime;
    }
}
