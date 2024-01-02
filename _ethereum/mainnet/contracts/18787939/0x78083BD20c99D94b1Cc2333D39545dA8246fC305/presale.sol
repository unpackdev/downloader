/**
 *Submitted for verification at Etherscan.io on 2023-07-22
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract presale is Ownable {
    AggregatorV3Interface internal priceFeed;

    uint256[] public priceperusd = [
        16670000000000000000,
        12500000000000000000,
        10000000000000000000
    ];
    uint256[] public tokenlimit = [
        18000000000000000000000000,
        27000000000000000000000000,
        15000000000000000000000000
    ];
    uint256 public constant totalTokenAmount = 60000000000000000000000000;
    uint256 public constant stages = 6; // Number Of Stages
    uint256 public tokenAmountPerStage;
    uint256 public lastStagetime;
    uint256 public stage = 0;
    uint256 public tokenSold = 0;
    IERC20 public MIST = IERC20(0xE14Eaf34827ba4E191215b35005373014A6DCDFC);
    mapping(address => Purchase[]) public purchases;
    mapping(address => uint256) public referralBalances;

    struct Purchase {
        uint256 stage;
        uint256 amount;
        bool claimed;
    }
    bool public isPresaleOpen = true;
    bool public isClaimable = false;

    constructor() {
        tokenAmountPerStage = totalTokenAmount / stages;
        lastStagetime = block.timestamp;
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    }

  

    function getLatestPriceETH() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price / 100000000;
    }

    function PurchaseWithETH() public payable {
        int256 latestPrice = getLatestPriceETH();

        uint256 nativeprice = uint256(latestPrice);
        require(isPresaleOpen, "Presale end");
        uint256 maxETHAllowred = msg.value * nativeprice;
        require(maxETHAllowred <= 1000000000000000000000 , "Maximun of 1000 USDT/ETH Allowed");
        uint256 tokensToBuy = msg.value * (priceperusd[stage] * nativeprice);

        tokenSold += (tokensToBuy / 1000000000000000000);
        purchases[msg.sender].push(
            Purchase(stage, tokensToBuy / 1000000000000000000, false)
        );

        if (tokenSold >= tokenlimit[stage]) {
            stage++;
            tokenSold = 0;
            lastStagetime = block.timestamp;
        }
 require(
            MIST.transfer(msg.sender, tokensToBuy / 1000000000000000000),
            "Token transfer failed"
        );
        address payable owner = payable(owner());
        owner.transfer(msg.value);
    }

 

    function getPurchaseInfo(address walletAddress)
        public
        view
        returns (Purchase[] memory)
    {
        return purchases[walletAddress];
    }

    function EndPresale(bool status) public onlyOwner {
        isPresaleOpen = status;
    }

  

    function withdrawLeftover() external onlyOwner {
        uint256 balance = MIST.balanceOf(address(this));
        require(balance > 0, "No token available");
        MIST.transfer(owner(), balance);
    }
}