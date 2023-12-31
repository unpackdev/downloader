// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Crowdsale {
    using SafeMath for uint256;
    address public owner;
    address public tokenAddress; 
    uint256 public tokenStartPrice;
    uint256 public tokenMiddlePrice; 
    uint256 public tokenLastPrice; 
    uint256 public totalTokens; 
    uint256 public startTime;
    uint256 public enddays;
    uint256 public saleCount;
    uint256 public midCount;
    uint256 public lastSaleDays;

    event TokenPurchased(address buyer, uint256 amount);

    constructor(
        address _tokenAddress,
        uint256 _tokenStartPrice,
        uint256 _tokenMiddlePrice,
        uint256 _tokenLastPrice,
        uint256 _startTime,
        uint256 _enddays
    ) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        tokenStartPrice = _tokenStartPrice;
        tokenMiddlePrice = _tokenMiddlePrice;
        tokenLastPrice = _tokenLastPrice;
        startTime = _startTime;
        enddays = _enddays;
        saleCount = 0;
        midCount = 10;
        lastSaleDays = 7;
    }

    // Modifier to ensure the sender is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // Function to purchase tokens
    function purchaseTokens() public payable  {
        uint256 tokens = 0;
        if (block.timestamp > startTime && saleCount < midCount && (enddays - calculateDays(block.timestamp)) > lastSaleDays) {
            saleCount++;
            tokens = tokenStartPrice.mul(msg.value).div(1 ether);
        } else if (
            block.timestamp > startTime &&
            saleCount >= midCount &&
            (enddays - calculateDays(block.timestamp)) > lastSaleDays
        ) {
            tokens = tokenMiddlePrice.mul(msg.value).div(1 ether);
        } else if (enddays -  calculateDays(block.timestamp) <= lastSaleDays) {
            tokens = tokenLastPrice.mul(msg.value).div(1 ether);
        }
       
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, tokens);
        emit TokenPurchased(msg.sender, tokens);
    }

    function calculateDays(uint256 timestamp) public view returns (uint256) {
        require(
            timestamp >= startTime,
            "Timestamp should be greater than or equal to startTime"
        );

        // Calculate the difference in seconds and convert to days
        uint256 secondsDiff = timestamp - startTime;
        uint256 daysDiff = secondsDiff / 1 days;

        return daysDiff;
    }

    // Function to withdraw funds (only available to the owner)
    function withdrawFunds() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function updateStartPrice(uint256 _tokenStartPrice) public onlyOwner {
        tokenStartPrice = _tokenStartPrice;
    }

    function updateLastPrice(uint256 _tokenLastPrice) public onlyOwner {
        tokenLastPrice = _tokenLastPrice;
    }

    function updateMiddlePrice(uint256 _tokenMiddlePrice) public onlyOwner {
        tokenMiddlePrice = _tokenMiddlePrice;
    }
   

    function updateEndDays(uint256 _endDays) public onlyOwner {
        enddays = _endDays;
    }

    function updateMidCount(uint256 _count) public onlyOwner {
        midCount = _count;
    }

    function updateLastSaleDays(uint256 _days) public onlyOwner {
        lastSaleDays = _days;
    }

    function withdrawBalanceToken() public  onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function updateTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }

    receive() external payable {
        purchaseTokens();
    }
}