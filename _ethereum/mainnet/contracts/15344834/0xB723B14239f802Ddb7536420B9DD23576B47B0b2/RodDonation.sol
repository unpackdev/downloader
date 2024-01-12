// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";

contract RodDonation is Pausable, ReentrancyGuard, Ownable {
    using Address for address payable;
    using SafeERC20 for IERC20;

    // ERC20 gift token contract being held
    IERC20 private _giftToken;

    // percent of amount that gift release immediately
    uint8 private _releasePercent;

    // timestamp when gift release is enabled
    uint256 private _releaseTime;

    //gift balance of donor
    mapping(address => uint256) private _balances;

    //locked amount of donor
    mapping (address => uint256) private _baseAmount;

    //saved ratio of gift/token
    mapping(address => uint256) private _acceptableTokens;

    //total amount of reserved gift token
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

    //PRECISION for ratio of _acceptableTokens
    uint256 constant PRECISION = 10000;

    /**
    * @notice Placeholder token address for ETH donations. This address is used in various other
    * projects as a stand-in for ETH
    */
    address constant ETH_TOKEN_PLACHOLDER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
    * @notice Required parameters for each release
    */
    struct Release {
        address donor; // address of donate
        uint256 amount; // amount of gift tokens to release
    }

    /**
    * @dev Emitted on each donation
    */
    event DonationReceived(
        address indexed donor,
        address indexed token,
        uint256 indexed amount
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
    * @dev Emitted when a token or ETH is withdrawn from the contract
    */
    event TokenWithdrawn(address indexed token, uint256 indexed amount, address indexed dest);

    constructor(address gifttoken_) {
        _giftToken = IERC20(gifttoken_);
        _releasePercent = 20;
        //two years 63072000 = 2 * 365 * 24 * 60 * 60
        _releaseTime = block.timestamp + 63072000;

        name = "ROD-Locked";
        symbol = "RODL";
        decimals = 18;
    }

    function donate(address tokenAddress_, uint256 amount_) public payable {
        donate(tokenAddress_, amount_, _msgSender());
    }

    /**
    * @dev We assume the token approvals were already executed. To be aware that unit of amount_
    */
    function donate(address tokenAddress_, uint256 amount_, address beneficiary_) public payable nonReentrant whenNotPaused {
        require(amount_ > 0, "donate: amount canot be zero");
        require(beneficiary_ != address(0), "donate: beneficiary is the zero address");
        uint256 ratio = _acceptableTokens[tokenAddress_];
        require(ratio > 0, "donate: the token is not acceptable");

        if (tokenAddress_ != ETH_TOKEN_PLACHOLDER) {
            IERC20(tokenAddress_).safeTransferFrom(_msgSender(), address(this), amount_);
        } else {
            require(msg.value == amount_, "donate: Mismatch amount & ETH sent");
        }

        emit DonationReceived(_msgSender(), tokenAddress_, amount_);

        uint256 giftAmount = amount_ * ratio / PRECISION;
        uint256 giftAmountReleased = giftAmount * _releasePercent / 100;
        uint256 giftAmountLeft = giftAmount - giftAmountReleased;

        _giftToken.safeTransfer(beneficiary_, giftAmountReleased);
        emit Transfer(address(this), beneficiary_, giftAmountReleased);

        totalSupply += giftAmountLeft;
        _balances[beneficiary_] += giftAmountLeft;
        _baseAmount[beneficiary_] += giftAmountLeft;
    }

    /**
    * @dev Donor try to transfer the gift token to himself
    */
    function releaseGift(uint256 amount_) external {
        releaseGift(_msgSender(), _msgSender(), amount_);
    }

    /**
    * @dev Donor try to transfer the gift token to other
    */
    function transfer(address to_, uint256 amount_) external returns (bool) {
        releaseGift(_msgSender(), to_, amount_);
        return true;
    }

    /**
    * @dev The owner of contract can transfer the gift token to donor at any time
    */
    function releaseGiftByOwner(address from_, uint256 amount_) external onlyOwner {
        releaseGift(from_, from_, amount_);
    }

    /**
    * @dev BulkTransactions for the owner of contract can transfer the gift token to donor at any time
    */
    function releaseGiftByOwner(Release[] calldata releases_) external onlyOwner {
        for (uint256 i = 0; i < releases_.length; i++) {
            releaseGift(releases_[i].donor, releases_[i].donor, releases_[i].amount);
        }
    }

    function releaseGift(address from_, address to_, uint256 amount_) internal nonReentrant whenNotPaused {
        require(from_ != address(0), "releaseGift: transfer from the zero address");
        require(to_ != address(0), "releaseGift: transfer to the zero address");

        uint256 availableAmount;
        uint256 fromBalance = _balances[from_];
        if (owner() == _msgSender()) {
            availableAmount = fromBalance;
        } else {
            availableAmount = availableAmountOf(from_);
        }
        require(availableAmount >= amount_, "releaseGift: transfer amount exceeds available amount");
        _balances[from_] = fromBalance - amount_;
        totalSupply -= amount_;
        _giftToken.safeTransfer(to_, amount_);
        if (from_ == to_) {
            emit Transfer(address(this), to_, amount_);
        } else {
            emit Transfer(from_, to_, amount_);
        }
    }

    /**
     * @dev Returns the available amount of gift tokens owned by `account`.
     */
    function availableAmountOf(address account) public view returns (uint256) {
        if (block.timestamp < releaseTime()) {
            return 0;
        }
        //if less then 1 rod, return all
        if (_balances[account] < 1000000000000000000) {
            return _balances[account];
        }
        // seconds of one month 2592000 = (30 * 24 * 60 * 60)
        uint256 months = 1 + (block.timestamp - releaseTime()) / 2592000;
        if (months > 12) {
            months = 12;
        }

        uint256 usedAmount = _baseAmount[account] - _balances[account];
        uint256 permittedAmount = _baseAmount[account] * months / 12;
        if (usedAmount >= permittedAmount) {
            return 0;
        } else {
            return permittedAmount - usedAmount;
        }
    }

    /**
    * @notice Transfers tokens of the input adress to the recipient. 
    * @param tokenAddress_ address of token to send
    * @param dest_ destination address to send tokens to
    * @param amount_ amount of the token to withdraw
    */
    function withdrawToken(address tokenAddress_, address dest_, uint256 amount_) external onlyOwner nonReentrant {
        if (tokenAddress_ == address(_giftToken)) {
            uint256 balance = _giftToken.balanceOf(address(this));
            require(balance >= amount_, "withdrawToken: withdraw amount exceeds balance");
            unchecked {
                balance -= amount_;
            }
            require(balance >= totalSupply, "withdrawToken: withdraw amount exceeds available amount");
        }
        emit TokenWithdrawn(tokenAddress_, amount_, dest_);
        IERC20(tokenAddress_).safeTransfer(dest_, amount_);
    }

    /**
    * @notice Transfers Ether to the specified address
    * @param dest_ destination address to send ETH to
    * @param amount_ amount of ETH to withdraw
    */
    function withdrawEther(address payable dest_, uint256 amount_) external onlyOwner nonReentrant {
        //uint256 balance = address(this).balance;
        emit TokenWithdrawn(ETH_TOKEN_PLACHOLDER, amount_, dest_);
        dest_.sendValue(amount_);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

      /**
     * @dev Returns the token being held.
     */
    function giftToken() public view returns (IERC20) {
        return _giftToken;
    }

    /**
     * @dev Returns the releasePercent.
     */
    function releasePercent() public view  returns (uint8) {
        return _releasePercent;
    }

    /**
     * @dev Returns the time when the tokens are released in seconds since Unix epoch (i.e. Unix timestamp).
     */
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    /**
     * @dev Returns the amount of gift tokens owned by `account`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Returns the base amount of gift tokens owned by `account`.
     */
    function baseAmountOf(address account) public view returns (uint256) {
        return _baseAmount[account];
    }

    /**
     * @dev Returns the ratio of the token:giftToken.
     */
    function ratioOf(address tokenAddress_) public view returns (uint256) {
        return _acceptableTokens[tokenAddress_];
    }

    /**
     * @dev set acceptable tokens, ratio = 0 means the token is not acceptable.
     * Can only be called by the current owner.
     */
    function setAcceptableToken(address tokenAddress_, uint256 ratio_) public onlyOwner {
        _acceptableTokens[tokenAddress_] = ratio_;
    }

    /**
     * @dev set release percent.
     * Can only be called by the current owner.
     */
    function setReleasePercent(uint8 percent_) public onlyOwner {
        require(percent_ <= 100, "RodDonation: cannot greater then 100");
        _releasePercent = percent_;
    }

    /**
     * @dev set release time.
     * Can only be called by the current owner.
     */
    function setReleaseTime(uint256 releaseTime_) public onlyOwner {
        require(releaseTime_ > block.timestamp, "RodDonation: release time is before current time");
        _releaseTime = releaseTime_;
    }

    /**
    * Default function; Gets called when data is sent but does not match any other function
    */
    fallback() external payable {
        donate(ETH_TOKEN_PLACHOLDER, msg.value);
    }

    /**
    * Default function; Gets called when Ether is deposited with no data
    */
    receive() external payable {
        donate(ETH_TOKEN_PLACHOLDER, msg.value);
    }
}
