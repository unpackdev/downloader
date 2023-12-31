// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface USDTInterface {
    function balanceOf(address who) external returns (uint256);

    function transfer(address to, uint256 value) external;

    function allowance(address owner, address spender)
        external
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

    function approve(address spender, uint256 value) external;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Context {
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    // function transferOwnership(address newOwner) public onlyOwner {
    //     _transferOwnership(newOwner);
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */

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

interface IStake {
    function stakeFromPresale(address buyer, uint256 amount)
        external
        returns (bool);

    function getWallet() external view returns (address);

    function getAddress() external view returns (address);
}

interface IPresaleV1 {
    function balanceOf(address account) external view returns (uint256);
}

contract PresaleWPEPE is Ownable {
    using SafeMath for uint256;
    address payable private _wallet;
    address public _brigdeBuyTokenFromBSC;
    address private _walletToken;
    IERC20 private token;
    USDTInterface private usdtToken;
    IStake private stake;
    IPresaleV1 presaleV1;

    AggregatorV3Interface internal aggregatorETHInterface;
    AggregatorV3Interface internal aggregatorUSDTInterface;

    mapping(address => uint256) private buyers;
    mapping(address => uint256) private claimers;
    mapping(address => address) private refOfs;
    mapping(string => bool) private hashBuyBSC;

    mapping(uint256 => Stage) private stages;

    bool inSell = true;
    bool inClaim = false;
    bool inStake = false;
    bool inRefReward = true;
    uint256 totalClaimed;
    uint256 currentStage;
    uint256 refPercent = 30; // Current is 3%
    uint256 public decimals_token = 18;
    uint256 public decimals_usdt = 6;

    event BuyToken(
        address buyer,
        uint256 amountOut,
        uint256 amountIn,
        string buyFrom,
        string chain,
        string hashBSC
    );
    event SetUSDTToken(USDTInterface tokenAddress);
    event SetPriceByUSD(uint256 stage, uint256 newPrice);
    event SetInSell(bool _inSell);
    event SetInClaim(bool _inClaimed);
    event SetInStake(bool _inStake);
    event SetCurrentStage(uint256 stage);
    event SetIStake(IStake stake);
    event Claim(address buyer, uint256 amount);
    event Stake(address buyer, uint256 amount);

    struct Stage {
        uint256 totalRaise;
        uint256 raised;
        uint256 priceInUSDStage;
    }

    constructor(
        address payable wallet,
        IERC20 icotoken,
        USDTInterface usdtTokenAddress,
        address _oracleETHperUSD,
        address _oracleUSDTbyUSD,
        address walletToken,
        IPresaleV1 _presaleV1
    ) {
        _wallet = wallet;
        token = icotoken;
        usdtToken = usdtTokenAddress;
        aggregatorETHInterface = AggregatorV3Interface(_oracleETHperUSD);
        aggregatorUSDTInterface = AggregatorV3Interface(_oracleUSDTbyUSD);
        _walletToken = walletToken;
        presaleV1 = _presaleV1;
        currentStage = 1;
        stages[1] = Stage(362865000 * (10**18), 0, 0.00031 * (10**18));
        stages[2] = Stage(1195320000 * (10**18), 0, 0.00033 * (10**18));
        stages[3] = Stage(2305260000 * (10**18), 0, 0.00035 * (10**18));
        stages[4] = Stage(4482450000 * (10**18), 0, 0.00037 * (10**18));
        stages[5] = Stage(5741805000 * (10**18), 0, 0.00039 * (10**18));
        stages[6] = Stage(7257300000 * (10**18), 0, 0.00041 * (10**18));
    }

    function setToken(IERC20 _token) public onlyOwner {
        token = _token;
    }

    function setIpresaleV1(IPresaleV1 _presaleV1) public onlyOwner {
        presaleV1 = _presaleV1;
    }

    function getPresaleV1() public view returns (IPresaleV1) {
        return presaleV1;
    }

    function setCurrentStage(uint256 stage) public onlyOwner {
        currentStage = stage;
        emit SetCurrentStage(stage);
    }

    function setAggregatorETHInterface(address _aggregatorETHInterface)
        public
        onlyOwner
    {
        aggregatorETHInterface = AggregatorV3Interface(_aggregatorETHInterface);
    }

    function setAggregatorUSDTInterface(address _aggregatorUSDTInterface)
        public
        onlyOwner
    {
        aggregatorUSDTInterface = AggregatorV3Interface(
            _aggregatorUSDTInterface
        );
    }

    function setRefPercent(uint256 newPercent) public onlyOwner {
        refPercent = newPercent;
    }

    function setStageInfo(
        uint256 stageId,
        uint256 _totalRaise,
        uint256 _raised,
        uint256 _priceInUSDStage
    ) public onlyOwner {
        stages[stageId] = Stage(_totalRaise, _raised, _priceInUSDStage);
    }

    function setBrigdeBuyTokenFromBSCAddress(address brigdeBuyTokenFromBSC)
        public
    {
        _brigdeBuyTokenFromBSC = brigdeBuyTokenFromBSC;
    }

    function getBrigdeBuyTokenFromBSCAddress() public view returns (address) {
        return _brigdeBuyTokenFromBSC;
    }

    function getAggregatorETHInterface()
        public
        view
        returns (AggregatorV3Interface)
    {
        return aggregatorETHInterface;
    }

    function getAggregatorUSDTInterface()
        public
        view
        returns (AggregatorV3Interface)
    {
        return aggregatorUSDTInterface;
    }

    function setStakeContract(IStake _stake) public onlyOwner {
        stake = _stake;
        emit SetIStake(_stake);
    }

    function setInSell(bool _inSell) public onlyOwner {
        inSell = _inSell;
        emit SetInSell(_inSell);
    }

    function setInClaim(bool _inClaim) public onlyOwner {
        inClaim = _inClaim;
        emit SetInClaim(_inClaim);
    }

    function setInStake(bool _inStake) public onlyOwner {
        inStake = _inStake;
        emit SetInStake(_inStake);
    }

    function setInRefReward(bool _inRefReward) public onlyOwner {
        inRefReward = _inRefReward;
    }

    function setPriceByUSD(uint256 stage, uint256 newPrice) public onlyOwner {
        stages[stage].priceInUSDStage = newPrice;
        emit SetPriceByUSD(stage, newPrice);
    }

    function setDecimalsToken(uint256 _decimals) public onlyOwner {
        decimals_token = _decimals;
    }

    function setDecimalsUSDT(uint256 _decimals) public onlyOwner {
        decimals_usdt = _decimals;
    }

    function setTotalRaise(uint256 stage, uint256 _totalRaise)
        public
        onlyOwner
    {
        stages[stage].totalRaise = _totalRaise;
    }

    function setUSDTToken(USDTInterface token_address) public onlyOwner {
        usdtToken = token_address;
        emit SetUSDTToken(token_address);
    }

    function stakeContract() public view returns (IStake) {
        return stake;
    }

    function getNextStagePrice() public view returns (uint256) {
        Stage memory nextStage = stages[currentStage + 1];
        if (nextStage.priceInUSDStage == 0) {
            return stages[currentStage].priceInUSDStage;
        } else {
            return nextStage.priceInUSDStage;
        }
    }

    function getTotalRaise() public view returns (uint256) {
        return stages[currentStage].totalRaise;
    }

    function getRaised() public view returns (uint256) {
        return stages[currentStage].raised;
    }

    function getTotalRaiseStage(uint256 stage) public view returns (uint256) {
        return stages[stage].totalRaise;
    }

    function getRaisedStage(uint256 stage) public view returns (uint256) {
        return stages[stage].raised;
    }

    function getRefOf(address _address) public view returns (address) {
        return refOfs[_address];
    }

    function getPriceInUSD(uint256 stage) public view returns (uint256) {
        return stages[stage].priceInUSDStage;
    }

    function getPriceInUSD() public view returns (uint256) {
        return stages[currentStage].priceInUSDStage;
    }

    function getCurrentStage() public view returns (uint256) {
        return currentStage;
    }

    function balanceOf(address account) external view returns (uint256) {
        return buyers[account] + presaleV1.balanceOf(account);
    }

    function getClaimed(address buyer) public view returns (uint256) {
        return claimers[buyer];
    }

    function getInSell() public view returns (bool) {
        return inSell;
    }

    function getInClaim() public view returns (bool) {
        return inClaim;
    }

    function getInStake() public view returns (bool) {
        return inStake;
    }

    function getUSDTToken() public view returns (USDTInterface) {
        return usdtToken;
    }

    function getToken() public view returns (IERC20) {
        return token;
    }

    function getAddress() public view returns (address) {
        return address(this);
    }

    function getTokenAmountETH(uint256 amountEth)
        public
        view
        returns (uint256)
    {
        uint256 lastEthPriceByUSD = getLatestPriceEthPerUSD();
        return (amountEth * lastEthPriceByUSD) / getPriceInUSD(currentStage);
    }

    function getTokenAmountUSDT(uint256 amountUSDT)
        public
        view
        returns (uint256)
    {
        uint256 lastUSDTPriceByUSD = getLatestPriceUSDTPerUSD();
        return
            (amountUSDT * 10**12 * lastUSDTPriceByUSD) /
            getPriceInUSD(currentStage);
    }

    function getLatestPriceEthPerUSD() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorETHInterface.latestRoundData();
        price = (price * (10**10));
        return uint256(price);
    }

    function getLatestPriceUSDTPerUSD() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorUSDTInterface.latestRoundData();
        price = (price * (10**10));
        return uint256(price);
    }

    function getRewardForRefOf(uint256 dolar) public view returns (uint256) {
        return (dolar * refPercent) / 1000;
    }

    function buyToken(
        address buyer,
        address transferTo,
        uint256 amount,
        uint256 amountIn,
        string memory buyFrom,
        string memory chain,
        address refOf,
        string memory hashBSC
    ) private returns (bool) {
        buyers[transferTo] = buyers[transferTo].add(amount);
        uint256 inDolar = ((amount * getPriceInUSD(currentStage)) /
            (10**decimals_token));
        stages[currentStage].raised = stages[currentStage].raised.add(amount);
        checkNextStage();
        if (inRefReward) {
            if (refOfs[buyer] == address(0) && refOf != address(0)) {
                refOfs[buyer] = refOf;
            }
            if (refOfs[buyer] != address(0)) {
                uint256 priceUSDT = getLatestPriceUSDTPerUSD();
                uint256 usd = ((inDolar * (10**decimals_usdt)) * refPercent) /
                    (priceUSDT * 1000);
                usdtToken.transfer(refOfs[buyer], usd);
            }
        }

        emit BuyToken(buyer, amount, amountIn, buyFrom, chain, hashBSC);
        return true;
    }

    function buyTokenByEth(address refOf) external payable {
        uint256 ethAmount = msg.value;
        uint256 amount = getTokenAmountETH(ethAmount);
        require(amount > 0, "Amount is zero");
        require(inSell, "Invalid time for buying");
        // if (ethAmount > msg.sender.balance) {
        //     revert();
        // }
        (_wallet).transfer(ethAmount);
        buyToken(
            msg.sender,
            msg.sender,
            amount,
            ethAmount,
            "ETH",
            "ETH",
            refOf,
            ""
        );
    }

    function buyTokenByEthAndStake(address refOf) external payable {
        uint256 ethAmount = msg.value;
        uint256 amount = getTokenAmountETH(ethAmount);
        require(amount > 0, "Amount is zero");
        require(inSell, "Invalid time for buying");
        // if (ethAmount > msg.sender.balance) {
        //     revert();
        // }
        (_wallet).transfer(ethAmount);

        require(
            buyToken(
                msg.sender,
                stake.getWallet(),
                amount,
                ethAmount,
                "ETH",
                "ETH",
                refOf,
                ""
            ),
            "Buy token error"
        );
        require(
            stake.stakeFromPresale(msg.sender, amount),
            "Stake token error"
        );
    }

    function buyTokenByUSDT(uint256 amountUSDT, address refOf) external {
        uint256 amount = getTokenAmountUSDT(amountUSDT);
        require(amount > 0, "Amount is zero");
        require(inSell, "Invalid time for buying");
        uint256 ourAllowance = usdtToken.allowance(_msgSender(), address(this));
        require(
            amountUSDT <= ourAllowance,
            "Make sure to add enough allowance"
        );

        usdtToken.transferFrom(msg.sender, _wallet, amountUSDT);
        buyToken(
            msg.sender,
            msg.sender,
            amount,
            amountUSDT,
            "USDT",
            "ETH",
            refOf,
            ""
        );
    }

    function buyTokenByUSDTAndStake(uint256 amountUSDT, address refOf)
        external
    {
        uint256 amount = getTokenAmountUSDT(amountUSDT);
        require(amount > 0, "Amount is zero");
        require(inSell, "Invalid time for buying");
        uint256 ourAllowance = usdtToken.allowance(_msgSender(), address(this));
        require(
            amountUSDT <= ourAllowance,
            "Make sure to add enough allowance"
        );

        usdtToken.transferFrom(msg.sender, _wallet, amountUSDT);
        require(
            buyToken(
                msg.sender,
                stake.getWallet(),
                amount,
                amountUSDT,
                "USDT",
                "ETH",
                refOf,
                ""
            ),
            "Buy token error"
        );
        require(
            stake.stakeFromPresale(msg.sender, amount),
            "Stake token error"
        );
    }

    function buyTokenFromBSC(
        address buyer,
        uint256 amount,
        uint256 amountBSC,
        string memory buyFrom,
        address refOf,
        string memory hash
    ) external {
        require(msg.sender == _brigdeBuyTokenFromBSC, "Only call by brigde");
        require(!hashBuyBSC[hash], "This hash was processed");
        require(
            buyToken(
                buyer,
                buyer,
                amount,
                amountBSC,
                buyFrom,
                "BSC",
                refOf,
                hash
            ),
            "Buy token error"
        );
        hashBuyBSC[hash] = true;
    }

    function checkNextStage() private {
        if (currentStage == 6) {
            return;
        }
        if (stages[currentStage].raised >= stages[currentStage].totalRaise) {
            currentStage = currentStage + 1;
        }
    }

    function claim() public returns (bool) {
        require(inClaim, "Invalid time for claim");
        uint256 amount = buyers[msg.sender];
        require(amount > 0, "You not have token to claim");
        require(
            token.balanceOf(address(this)) > amount,
            "Not enought token to send to you"
        );
        bool success = token.transfer(msg.sender, amount);
        require(success, "Transfer token error");
        buyers[msg.sender] = buyers[msg.sender].sub(
            amount,
            "transfer from buyers to wallet error"
        );
        claimers[msg.sender] = claimers[msg.sender].add(amount);
        totalClaimed = totalClaimed.add(amount);
        emit Claim(msg.sender, amount);
        return success;
    }

    function stakeFromStakeContract(address _buyer, uint256 _amount)
        public
        returns (bool)
    {
        require(
            msg.sender == stake.getAddress(),
            "Only call from stakecontract"
        );
        buyers[_buyer] = buyers[_buyer].sub(_amount);
        buyers[stake.getWallet()] = buyers[stake.getWallet()].add(_amount);
        emit Stake(_buyer, _amount);
        return true;
    }

    function getWallet() public view returns (address) {
        return _wallet;
    }

    function setWallet(address payable wallet) public onlyOwner {
        _wallet = wallet;
    }

    function withdraw() public onlyOwner {
        token.transfer(_walletToken, token.balanceOf(address(this)));
    }

    function withdrawRef() public onlyOwner {
        usdtToken.transfer(_wallet, usdtToken.balanceOf(address(this)));
    }
}