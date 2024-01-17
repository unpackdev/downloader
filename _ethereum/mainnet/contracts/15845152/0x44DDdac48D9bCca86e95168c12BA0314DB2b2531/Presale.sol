//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

interface Aggregator {
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

contract Presale is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    uint256 public salePrice;
    uint256 public totalTokens;
    uint256 public inSale;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public claimStart;
    address public saleToken;
    uint256 public baseDecimals;
    uint256 public usdRaised;
    uint256 public refPercent;
    uint public numberOfParticipants;

    IERC20Upgradeable public USDCInterface;
    Aggregator internal aggregatorInterface;
    // https://docs.chain.link/docs/ethereum-addresses/ => (ETH / USD)

    mapping(address => uint256) public userDeposits;
    mapping(address => bool) public hasClaimed;

    mapping(address => uint256) public userRefUSDCEarned;
    mapping(address => uint256) public userRefETHEarned;

    mapping(address => mapping(address => bool)) public invitedUsers;
    mapping(address => uint256) public countInvitedUsers;

    address public fundWallet;
    
    event SaleTimeSet(uint256 _start, uint256 _end, uint256 timestamp);

    event SaleTimeUpdated(
        bytes32 indexed key,
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );

    event TokensBought(
        address indexed user,
        uint256 indexed tokensBought,
        address indexed purchaseToken,
        uint256 amountPaid,
        uint256 timestamp,
        uint256 usdValue,
        address ref,
        uint256 refAmount
    );

    event TokensAdded(
        address indexed token,
        uint256 noOfTokens,
        uint256 timestamp
    );
    event TokensClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    event ClaimStartUpdated(
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _oracle,
        address _usdc,
        uint256 _startTime,
        uint256 _endTime
    ) external initializer {
        require(_oracle != address(0), "Zero aggregator address");
        require(_usdc != address(0), "Zero USDC address");
        require(
            _startTime > block.timestamp && _endTime > _startTime,
            "Invalid time"
        );
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        salePrice = 0.001 * (10**18); //0.001 USD
        totalTokens = 9_667_000_000;
        inSale = totalTokens;
        baseDecimals = (10**18);
        aggregatorInterface = Aggregator(_oracle);
        USDCInterface = IERC20Upgradeable(_usdc);
        startTime = _startTime;
        endTime = _endTime;
        usdRaised = 0;
        refPercent = 5;
        fundWallet = owner();
        emit SaleTimeSet(startTime, endTime, block.timestamp);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function calculatePrice(uint256 _amount)
        public
        view
        returns (uint256 totalValue)
    {
        uint256 totalSold = totalTokens - inSale;

        if (totalSold + _amount <= 1_000_000_000) {
            return (_amount * salePrice);
        } else {
            uint256 extra = (totalSold + _amount) - 1_000_000_000;
            uint256 _salePrice = salePrice;

            if (totalSold >= 1_000_000_000) {
                _salePrice =
                    (_salePrice + (0.00025 * (10**18))) +
                    (((totalSold - 1_000_000_000) / 1_000_000_000) *
                        (0.0002 * (10**18)));

                uint256 period = _amount / 1_000_000_000;

                if (period == 0) {
                    return (_amount * (_salePrice));
                } else {
                    while (period > 0) {
                        totalValue = totalValue + (1_000_000_000 * _salePrice);
                        _amount -= 1_000_000_000;
                        _salePrice += (0.00025 * (10**18));
                        period--;
                    }

                    if (_amount > 0) {
                        totalValue += (_amount * _salePrice);
                    }
                }
            } else {
                totalValue = (_amount - extra) * _salePrice;
                if (extra <= 1_000_000_000) {
                    return totalValue + (extra * ((_salePrice * 125) / 100));
                } else {
                    while (extra >= 1_000_000_000) {
                        _salePrice += (0.00025 * (10**18));
                        totalValue = totalValue + (1_000_000_000 * _salePrice);
                        extra -= 1_000_000_000;
                    }

                    if (extra > 0) {
                        _salePrice += (0.00025 * (10**18));
                        totalValue += (extra * _salePrice);
                    }
                    return totalValue;
                }
            }
        }
    }

    function changeSaleTimes(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(_startTime > 0 || _endTime > 0, "Invalid parameters");
        if (_startTime > 0) {
            require(block.timestamp < startTime, "Sale already started");
            require(block.timestamp < _startTime, "Sale time in past");
            uint256 prevValue = startTime;
            startTime = _startTime;
            emit SaleTimeUpdated(
                bytes32("START"),
                prevValue,
                _startTime,
                block.timestamp
            );
        }

        if (_endTime > 0) {
            require(block.timestamp < endTime, "Sale already ended");
            require(_endTime > startTime, "Invalid endTime");
            uint256 prevValue = endTime;
            endTime = _endTime;
            emit SaleTimeUpdated(
                bytes32("END"),
                prevValue,
                _endTime,
                block.timestamp
            );
        }
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterface.latestRoundData();
        price = (price * (10**10));
        return uint256(price);
    }

    modifier checkSaleState(uint256 amount) {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Invalid time for buying"
        );
        require(amount > 0 && amount <= inSale, "Invalid sale amount");
        _;
    }

    function buyWithUSDC(uint256 amount, address ref)
        external
        checkSaleState(amount)
        whenNotPaused
        returns (bool)
    {
        uint256 usdPrice = calculatePrice(amount);
        usdPrice = usdPrice / (10**12);
        inSale -= amount;
        if(userDeposits[_msgSender()] == 0){
            numberOfParticipants += 1;
        }
        userDeposits[_msgSender()] += (amount * baseDecimals);
        uint256 ourAllowance = USDCInterface.allowance(
            _msgSender(),
            address(this)
        );
        usdRaised = usdRaised + usdPrice;
        require(usdPrice <= ourAllowance, "Make sure to add enough allowance");
        
        uint256 amountUsdForReferral = 0;
        if(ref != address(0)){
            require(msg.sender != ref, "can't refer yourself");
            
            amountUsdForReferral = usdPrice * refPercent / 100;
            uint256 amountUsdForPool = usdPrice - amountUsdForReferral;
            
            (bool successPool, ) = address(USDCInterface).call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    _msgSender(),
                    fundWallet,
                    amountUsdForPool
                )
            );
            require(successPool, "Token payment failed");

            (bool successReferral, ) = address(USDCInterface).call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    _msgSender(),
                    ref,
                    amountUsdForReferral
                )
            );
            require(successReferral, "Token payment referral failed");
            userRefUSDCEarned[ref] += amountUsdForReferral;
            if(invitedUsers[ref][msg.sender] == false) {
                invitedUsers[ref][msg.sender] = true;
                countInvitedUsers[ref] += 1;
            }
        }else{
            (bool success, ) = address(USDCInterface).call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    _msgSender(),
                    fundWallet,
                    usdPrice
                )
            );
            require(success, "Token payment failed");
        }

        emit TokensBought(
            _msgSender(),
            amount,
            address(USDCInterface),
            usdPrice,
            block.timestamp,
            usdPrice,
            ref,
            amountUsdForReferral
        );
        return true;
    }

    function buyWithEth(uint256 amount, address ref)
        external
        payable
        checkSaleState(amount)
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        uint256 usdPrice = calculatePrice(amount);
        uint256 ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
        require(msg.value >= ethAmount, "Less payment");
        uint256 excess = msg.value - ethAmount;
        inSale -= amount;
        if(userDeposits[_msgSender()] == 0){
            numberOfParticipants += 1;
        }
        userDeposits[_msgSender()] += (amount * baseDecimals);
        uint256 usdPriceValue = usdPrice / (10**12);
        usdRaised = usdRaised + usdPriceValue;

        uint256 amountETHForReferral = 0;
        if(ref != address(0)){
            require(msg.sender != ref, "can't refer yourself");
            amountETHForReferral = ethAmount * refPercent / 100;
            uint256 amountETHForPool = ethAmount - amountETHForReferral;
            
            sendValue(payable(fundWallet), amountETHForPool);
            sendValue(payable(ref), amountETHForReferral);

            userRefETHEarned[ref] += amountETHForReferral;
            if(invitedUsers[ref][msg.sender] == false) {
                invitedUsers[ref][msg.sender] = true;
                countInvitedUsers[ref] += 1;
            }
        }else{
            sendValue(payable(fundWallet), ethAmount);
        }

        if (excess > 0) sendValue(payable(_msgSender()), excess);

        emit TokensBought(
            _msgSender(),
            amount,
            address(0),
            ethAmount,
            block.timestamp,
            usdPriceValue,
            ref,
            amountETHForReferral
        );
        return true;
    }

    function ethBuyHelper(uint256 amount)
        external
        view
        returns (uint256 ethAmount)
    {
        uint256 usdPrice = calculatePrice(amount);
        ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
    }

    function usdcBuyHelper(uint256 amount)
        external
        view
        returns (uint256 usdPrice)
    {
        usdPrice = calculatePrice(amount);
        usdPrice = usdPrice / (10**12);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    function startClaim(
        uint256 _claimStart,
        uint256 noOfTokens,
        address _saleToken
    ) external onlyOwner returns (bool) {
        require(
            _claimStart > endTime && _claimStart > block.timestamp,
            "Invalid claim start time"
        );
        require(
            noOfTokens >= ((totalTokens - inSale) * baseDecimals),
            "Tokens less than sold"
        );
        require(_saleToken != address(0), "Zero token address");
        require(claimStart == 0, "Claim already set");
        claimStart = _claimStart;
        saleToken = _saleToken;
        IERC20Upgradeable(_saleToken).transferFrom(
            _msgSender(),
            address(this),
            noOfTokens
        );
        emit TokensAdded(saleToken, noOfTokens, block.timestamp);
        return true;
    }

    function changeClaimStart(uint256 _claimStart)
        external
        onlyOwner
        returns (bool)
    {
        require(claimStart > 0, "Initial claim data not set");
        require(_claimStart > endTime, "Sale in progress");
        require(_claimStart > block.timestamp, "Claim start in past");
        uint256 prevValue = claimStart;
        claimStart = _claimStart;
        emit ClaimStartUpdated(prevValue, _claimStart, block.timestamp);
        return true;
    }

    function claim() external whenNotPaused returns (bool) {
        require(saleToken != address(0), "Sale token not added");
        require(block.timestamp >= claimStart, "Claim has not started yet");
        require(!hasClaimed[_msgSender()], "Already claimed");
        hasClaimed[_msgSender()] = true;
        uint256 amount = userDeposits[_msgSender()];
        require(amount > 0, "Nothing to claim");
        delete userDeposits[_msgSender()];
        IERC20Upgradeable(saleToken).transfer(_msgSender(), amount);
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
        return true;
    }

    function changeFundWallet(address _wallet)
        external
        onlyOwner
        returns (bool)
    {
        fundWallet = _wallet;
    }

}