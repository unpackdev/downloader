// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./ECDSA.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IBlindAuctionInfo.sol";

contract BlindAuction is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    IBlindAuctionInfo
{
    uint256 public DEPOSIT_AMOUNT; // = 0.5ether;
    uint256 public MAX_WINNERS_COUNT; // 333
    uint256 public finalPrice;
    uint8 public auctionState;
    address public signer;

    uint256 public depositedUserCount;
    mapping(address => bool) public isUserDeposited;
    address[] public usersWillReceiveAirdrop;
    mapping(address => bool) public isUserWillReceiveAirdrop;
    uint256 public refundedUserCount;
    mapping(address => bool) public isUserRefunded;

    uint256 public winnersCount;

    event UserDeposited(address indexed user);
    event UserWillReceiveAirdrop(address indexed user);
    event UserRefunded(address indexed user);

    function initialize(address _signer) public initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        OwnableUpgradeable.__Ownable_init();
        DEPOSIT_AMOUNT = 0.5 ether;
        MAX_WINNERS_COUNT = 333;
        signer = _signer;
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
            ) == signer,
            "invalid signature"
        );
        return true;
    }

    function deposit() external payable {
        require(auctionState == 1, "Auction not in bidding state");
        require(msg.value == DEPOSIT_AMOUNT, "Invalid ETH amount");
        require(!isUserDeposited[msg.sender], "Already deposited");
        isUserDeposited[msg.sender] = true;
        depositedUserCount++;
        emit UserDeposited(msg.sender);
    }

    function winnerDepositExtra(bytes calldata signature) external payable {
        require(auctionState == 2, "Auction not in concluding state");
        require(finalPrice >= DEPOSIT_AMOUNT, "finalPrice not yet set");
        require(msg.value == finalPrice - DEPOSIT_AMOUNT, "Invalid ETH amount");
        require(
            !isUserWillReceiveAirdrop[msg.sender],
            "Already deposited extra"
        );
        require(!isUserRefunded[msg.sender], "Already refunded");
        checkValidity(signature, "winner");
        isUserWillReceiveAirdrop[msg.sender] = true;
        usersWillReceiveAirdrop.push(msg.sender);
        emit UserWillReceiveAirdrop(msg.sender);
    }

    function refund(bytes calldata signature) external nonReentrant {
        require(
            auctionState == 2 || auctionState == 3,
            "Auction not in concluding or finished state"
        );
        require(isUserDeposited[msg.sender], "No deposit record");
        require(!isUserWillReceiveAirdrop[msg.sender], "Is a winner");
        require(!isUserRefunded[msg.sender], "Already refunded");
        checkValidity(signature, "refund");
        isUserRefunded[msg.sender] = true;
        refundedUserCount++;
        _withdraw(msg.sender, DEPOSIT_AMOUNT);
    }

    // =============== Admin ===============
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function withdrawSales() public onlyOwner {
        require(
            auctionState == 2 || auctionState == 3,
            "Auction not in concluding or finished state"
        );
        uint256 balance = address(this).balance;

        uint256 nonWinnersCount = depositedUserCount - winnersCount;
        uint256 refundReserveAmount = (nonWinnersCount - refundedUserCount) *
            DEPOSIT_AMOUNT;
        uint256 balanceCanWithdraw = balance - refundReserveAmount;
        require(balanceCanWithdraw > 0, "No balance to withdraw");
        _withdraw(owner(), balanceCanWithdraw);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "cant withdraw");
    }

    function changeDepositAmount(uint256 amount) external onlyOwner {
        require(auctionState == 0, "Auction already started");
        DEPOSIT_AMOUNT = amount;
    }

    function changeMaxWinnersCount(uint256 count) external onlyOwner {
        require(auctionState == 0, "Auction already started");
        MAX_WINNERS_COUNT = count;
    }

    function setFinalPrice(uint256 price) external onlyOwner {
        finalPrice = price;
    }

    // usually 333
    function setWinnersCount(uint256 _winnersCount) external onlyOwner {
        require(_winnersCount <= MAX_WINNERS_COUNT, "Too many winners");
        winnersCount = _winnersCount;
    }

    // 0 = not started
    // 1 = started, bidding
    // 2 = final price announced | winners should pay finalPrice - 0.5e | non-winners can refund | waitlist starts
    // 3 = auction end | receive unpaid winner deposits | non-winners can still refund | waitlist concludes + can refund
    function setAuctionState(uint8 state) external onlyOwner {
        auctionState = state;
    }

    function getUsersWillReceiveAirdrop()
        external
        view
        returns (address[] memory)
    {
        return usersWillReceiveAirdrop;
    }

    // =============== IBlindAuctionInfo ===============
    function getUsersCountWillReceiveAirdrop() external view returns (uint256) {
        return usersWillReceiveAirdrop.length;
    }

    function getMaxWinnersCount() external view returns (uint256) {
        return MAX_WINNERS_COUNT;
    }

    function getFinalPrice() external view returns (uint256) {
        return finalPrice;
    }

    function getAuctionState() external view returns (uint8) {
        return auctionState;
    }

    function getSigner() external view returns (address) {
        return signer;
    }
}
