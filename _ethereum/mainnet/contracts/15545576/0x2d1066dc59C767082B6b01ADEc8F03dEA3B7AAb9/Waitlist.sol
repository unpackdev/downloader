// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./ECDSA.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IBlindAuctionInfo.sol";

contract Waitlist is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    IBlindAuctionInfo blindAuction;

    uint256 public winnersCount;
    address[] public usersEnteredWaitlist;
    mapping(address => bool) public isUserDeposited;
    uint256 public refundedUserCount;
    mapping(address => bool) public isUserRefunded;

    event UserEnteredWaitlist(address indexed user);
    event UserRefunded(address indexed user);

    function initialize(address _blindAuction) public initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        OwnableUpgradeable.__Ownable_init();
        blindAuction = IBlindAuctionInfo(_blindAuction);
    }

    // =============== Query ===============

    modifier auctionConcluding() {
        require(address(blindAuction) != address(0), "Contract not set");
        require(blindAuction.getAuctionState() == 2, "Auction not concluding");
        require(blindAuction.getFinalPrice() > 0, "Final price not set");
        _;
    }

    modifier auctionEnd() {
        require(address(blindAuction) != address(0), "Contract not set");
        require(blindAuction.getAuctionState() == 3, "Auction not ended");
        require(blindAuction.getFinalPrice() > 0, "Final price not set");
        _;
    }

    // get stock
    function getSpace() public view returns (uint256) {
        // 333 - 300
        uint256 space = blindAuction.getMaxWinnersCount() -
            blindAuction.getUsersCountWillReceiveAirdrop();
        return space;
    }

    function getUsersCountEnteredWaitlist() public view returns (uint256) {
        return usersEnteredWaitlist.length;
    }

    function getVacancy() public view returns (uint256) {
        uint256 space = getSpace();
        // 33 <= 50, 33 <= 33
        uint256 uc = getUsersCountEnteredWaitlist();
        if (space <= uc) {
            return 0;
        }
        // 33 - 20, 33 - 32
        return space - uc;
    }

    function getUsersEnteredWaitlist() public view returns (address[] memory) {
        return usersEnteredWaitlist;
    }

    function checkValidity(bytes calldata signature, string memory action)
        public
        view
        returns (bool)
    {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(abi.encodePacked(msg.sender, action))
                ),
                signature
            ) == blindAuction.getSigner(),
            "invalid signature"
        );
        return true;
    }

    // =============== User ===============

    function enterWaitlist() external payable auctionConcluding {
        require(getVacancy() > 0, "No more vacancy");
        require(
            msg.value == blindAuction.getFinalPrice(),
            "Invalid ETH amount"
        );
        require(!isUserDeposited[msg.sender], "Already entered");
        isUserDeposited[msg.sender] = true;
        usersEnteredWaitlist.push(msg.sender);
        emit UserEnteredWaitlist(msg.sender);
    }

    function refund(bytes calldata signature) external auctionEnd nonReentrant {
        require(isUserDeposited[msg.sender], "No deposit record");
        require(!isUserRefunded[msg.sender], "Already refunded");
        checkValidity(signature, "waitlist-refund");
        isUserRefunded[msg.sender] = true;
        refundedUserCount++;
        _withdraw(msg.sender, blindAuction.getFinalPrice());
    }

    // =============== Admin ===============
    function setBlindAuctionContract(address _blindAuction) external onlyOwner {
        require(address(_blindAuction) != address(0), "zero address");
        blindAuction = IBlindAuctionInfo(_blindAuction);
    }

    function setWinnersCount(uint256 _winnersCount) external onlyOwner {
        require(_winnersCount > getVacancy(), "Too many winners");
        winnersCount = _winnersCount;
    }

    function withdrawSales() public onlyOwner {
        require(winnersCount > 0, "Waitlist winners count not set");
        uint256 balance = address(this).balance;
        uint256 nonWinnersCount = usersEnteredWaitlist.length - winnersCount;
        uint256 refundReserveAmount = (nonWinnersCount - refundedUserCount) *
            blindAuction.getFinalPrice();
        uint256 balanceCanWithdraw = balance - refundReserveAmount;
        require(balanceCanWithdraw > 0, "No balance to withdraw");
        _withdraw(owner(), balanceCanWithdraw);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "cant withdraw");
    }
}
