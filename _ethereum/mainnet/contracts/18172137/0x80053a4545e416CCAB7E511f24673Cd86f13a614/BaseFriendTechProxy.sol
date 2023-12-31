pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IFriendTech.sol";

contract BaseFriendTechProxy is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    event BuyShare(address maker, uint256 amount, uint256 blockTs);
    event SellAllShares(address taker, uint256 amount, uint256 blockTs);
    event SetL1AllowedBuyerAddress(address addr);
    event SetL1AllowedSellerAddress(address addr);
    event RefundCaller(address caller, uint256 amount,bool isWithdraw);

    address public constant FRIEND_TECH =
        0xCF205808Ed36593aa40a44F10c7f7C2F67d4A4d4;
    address public constant SHARES_SUBJECT =
        0xDB7B9F326c6fC0A728269a9c8fC8a2A4d03fe767;
    uint256 public constant SHARES_COUNT = 1;

    address public l1SharesBuyerContract;
    address public l1SharesSellerContract;

    mapping(address => uint256) public userHoldings;

    uint256[50] private _gap;

    function initialize() public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
    }
    
    function setL1SharesBuyerContractAddress(
        address _l1SharesBuyerContract
    ) public {
        l1SharesBuyerContract = _l1SharesBuyerContract;

        emit SetL1AllowedBuyerAddress(_l1SharesBuyerContract);
    }

    function withdrawEth(address to, uint256 amount) external onlyOwner {
        _refundCaller(to, amount, true);
    }

    function setL1SharesSellerContractAddress(
        address _l1SharesSellerContract
    ) public {
        l1SharesSellerContract = _l1SharesSellerContract;

        emit SetL1AllowedSellerAddress(_l1SharesSellerContract);
    }

    function _refundCaller(address to, uint256 amount, bool isWithdraw) private {
        payable(to).transfer(amount);

        emit RefundCaller(to, amount,isWithdraw);
    }

    function buyShares(address maker) public payable nonReentrant {
        require(
            msg.sender == l1SharesBuyerContract,
            "!l1SharesBuyerContract address"
        );

        bytes memory buySharesBytes = abi.encodeWithSignature(
            "buyShares(address,uint256)",
            SHARES_SUBJECT,
            SHARES_COUNT
        );

        uint256 shareBuyPrice = IFriendTech(FRIEND_TECH).getBuyPrice(
            SHARES_SUBJECT,
            SHARES_COUNT
        );
        uint256 protocolFeePercent = IFriendTech(FRIEND_TECH)
            .protocolFeePercent();
        uint256 subjectFeePercent = IFriendTech(FRIEND_TECH)
            .subjectFeePercent();

        uint256 protocolFee = (shareBuyPrice * protocolFeePercent) / 1 ether;
        uint256 subjectFee = (shareBuyPrice * subjectFeePercent) / 1 ether;
        uint256 totalPrice = shareBuyPrice + protocolFee + subjectFee;
        
        if (totalPrice <= msg.value) {
            (bool isSuccess, ) = FRIEND_TECH.call{value: totalPrice}(
                buySharesBytes
            );

            if (!isSuccess) {
                _refundCaller(maker, msg.value, false);
            } else {
                userHoldings[maker] = userHoldings[maker] + SHARES_COUNT;

                _refundCaller(maker, msg.value - totalPrice, false);
                emit BuyShare(maker, SHARES_COUNT, block.timestamp);
            }
        } else {
            _refundCaller(maker, msg.value, false);
        }
    }

    function sellAllShares(address taker) public payable nonReentrant {
        require(
            msg.sender == l1SharesSellerContract,
            "!l1SharesSellerContract address"
        );
        require(userHoldings[taker] > 0, "0 share balance");

        uint256 currentUserHoldings = userHoldings[taker];
        uint256 balanceBefore = address(this).balance;

        IFriendTech(FRIEND_TECH).sellShares(
            SHARES_SUBJECT,
            currentUserHoldings
        );
        uint256 balanceAfter = address(this).balance;

        payable(taker).transfer(balanceAfter - balanceBefore);

        userHoldings[taker] = 0;

        emit SellAllShares(taker, currentUserHoldings, block.timestamp);
    }

    receive() external payable {}
}
