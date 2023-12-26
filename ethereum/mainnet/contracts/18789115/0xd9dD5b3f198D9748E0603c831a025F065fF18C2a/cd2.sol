// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract CrowdsaleERC20 is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // The token being sold
    IERC20 private _token;
    address payable private _wallet;

    uint256 public cap;
    uint256 public leastBuy;
    uint256 public rate;
    uint256 public weiRaised;
    uint256 public openingTime;
    uint256 public closingTime;
    uint256 public releaseCooldown;
    uint256 public releaseBatchs;
    address public raiseToken;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public totalBalance;
    mapping(address => uint256) public refs;
    mapping(address => uint256) public refAmounts;
    mapping(address => bool) public donated;
    mapping(address => uint256) public lastWithdraw;

    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );
    event TimedCrowdsaleExtended(
        uint256 prevClosingTime,
        uint256 newClosingTime
    );
    event TokensReferred(
        address indexed purchaser,
        address indexed beneficiary,
        address indexed referral,
        uint256 value,
        uint256 amount
    );

    modifier onlyWhileOpen() {
        require(isOpen(), "TimedCrowdsale: not open");
        _;
    }

    constructor(
        address raiseToken_,
        uint256 rate_,
        address payable wallet_,
        address token_,
        uint256 cap_,
        uint256 leastBuy_,
        uint256 openingTime_,
        uint256 closingTime_
    ) {
        require(rate_ > 0, "Crowdsale: rate is 0"); //1u=100  whose rate is 10**14
        require(wallet_ != address(0), "Crowdsale: wallet is the zero address");
        require(token_ != address(0), "Crowdsale: token is the zero address");
        require(cap_ > 0, "CappedCrowdsale: cap is 0");
        require(
            openingTime_ >= block.timestamp,
            "TimedCrowdsale: opening time is before current time"
        );
        require(
            closingTime_ > openingTime_,
            "TimedCrowdsale: opening time is not before closing time"
        );

        raiseToken = raiseToken_;
        rate = rate_;
        _wallet = wallet_;
        _token = IERC20(token_);
        cap = cap_;
        leastBuy = leastBuy_;
        openingTime = openingTime_;
        closingTime = closingTime_; //block.timestamp + 48 hours
        releaseCooldown = 30 days;
        releaseBatchs = 20;
    }

    receive() external payable {}

    function buyTokens(
        uint256 amount,
        address beneficiary,
        address referral
    ) public payable nonReentrant {
        _preValidatePurchase(beneficiary, amount);

        // calculate token amount to be created
        uint256 tokensAmount = _getTokenAmount(amount);

        // update state
        weiRaised += amount;

        _processPurchase(beneficiary, tokensAmount);
        emit TokensPurchased(_msgSender(), beneficiary, amount, tokensAmount);

        _updatePurchasingState(beneficiary, amount);

        _forwardFunds(amount);
        _postValidatePurchase(beneficiary, amount);

        if (referral != address(0) && referral != _msgSender()) {
            refs[referral] += 1;
            refAmounts[referral] += amount;
            emit TokensReferred(
                _msgSender(),
                beneficiary,
                referral,
                amount,
                tokensAmount
            );
        }

        donated[beneficiary] = true;
    }

    function _preValidatePurchase(
        address beneficiary,
        uint256 weiAmount
    ) internal view whenNotPaused onlyWhileOpen {
        require(
            beneficiary != address(0),
            "Crowdsale: beneficiary is the zero address"
        );
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        require(
            (weiRaised + weiAmount) <= cap,
            "CappedCrowdsale: cap exceeded"
        );
        require(weiAmount > leastBuy, "CappedCrowdsale: not enough to buy");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    function _postValidatePurchase(
        address beneficiary,
        uint256 weiAmount
    ) internal view {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    function _processPurchase(
        address beneficiary,
        uint256 tokenAmount
    ) internal {
        balances[beneficiary] += tokenAmount;
        totalBalance[beneficiary] += tokenAmount;
    }

    function _updatePurchasingState(
        address beneficiary,
        uint256 weiAmount
    ) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _getTokenAmount(
        uint256 weiAmount
    ) internal view returns (uint256) {
        return weiAmount * rate;
    }

    // function _getTokenAmount() internal pure returns (uint256) {
    //     return 5000000 * (10 ** 6);
    // }

    function _forwardFunds(uint256 amount) internal {
        IERC20(raiseToken).safeTransferFrom(_msgSender(), _wallet, amount);
    }

    function capReached() public view returns (bool) {
        return weiRaised >= cap;
    }

    function isOpen() public view returns (bool) {
        return block.timestamp >= openingTime && block.timestamp <= closingTime;
    }

    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > closingTime;
    }

    function extendTime(uint256 newClosingTime) public onlyOwner {
        require(!hasClosed(), "TimedCrowdsale: already closed");
        // solhint-disable-next-line max-line-length
        require(
            newClosingTime > closingTime,
            "TimedCrowdsale: new closing time is before current closing time"
        );

        emit TimedCrowdsaleExtended(closingTime, newClosingTime);
        closingTime = newClosingTime;
    }

    function withdrawTokens(address beneficiary) public {
        require(hasClosed(), "PostDeliveryCrowdsale: not closed");
        uint256 amount = balances[beneficiary];
        require(
            amount > 0,
            "PostDeliveryCrowdsale: beneficiary is not due any tokens"
        );
        require(
            lastWithdraw[beneficiary] + releaseCooldown < block.timestamp,
            "Not yet claimable"
        );

        lastWithdraw[beneficiary] = block.timestamp;
        uint amoutToRelease = totalBalance[beneficiary] / releaseBatchs;
        balances[beneficiary] -= amoutToRelease;
        _token.safeTransfer(beneficiary, amoutToRelease);
    }

    function rescure() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (_msgSender()).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function rescure(address t) public onlyOwner {
        IERC20(t).safeTransfer(
            _msgSender(),
            IERC20(t).balanceOf(address(this))
        );
    }
}
