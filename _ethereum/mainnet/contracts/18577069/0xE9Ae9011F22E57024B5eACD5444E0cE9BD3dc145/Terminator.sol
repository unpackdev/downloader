/**
 * SPDX-License-Identifier: unlicensed
 * Web: https://t5000.xyz/
 * Community: https://t.me/T5000Enter
 */
pragma solidity =0.8.17;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

library FixedPoint {
    uint8 public constant RESOLUTION = 112;

    function mulDecode(uint224 x, uint y) internal pure returns (uint) {
        return (x * y) >> RESOLUTION;
    }

    function fraction(uint numerator, uint denominator) internal pure returns (uint) {
        if (numerator == 0) return 0;

        require(denominator > 0, "FixedPoint: division by zero");
        require(numerator <= type(uint144).max, "FixedPoint: numerator too big");

        return (numerator << RESOLUTION) / denominator;
    }
}

abstract contract Auth {
    address public _owner;
    mapping(address => bool) public isAuthorized;
    address[] public wereAuthorized;

    constructor(address owner) {
        _owner = owner;
        isAuthorized[owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Auth: owner only");
        _;
    }

    modifier authorized() {
        require(isAuthorized[msg.sender], "Auth: authorized only");
        _;
    }

    function setAuthorization(address address_, bool authorization) external onlyOwner {
        isAuthorized[address_] = authorization;

        bool newAddress = true;

        for (uint i = 0; i < wereAuthorized.length; i++) {
            if (wereAuthorized[i] == address_) {
                newAddress = false;
            }
        }

        if (newAddress) {
            wereAuthorized.push(address_);
        }
    }

    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    function transferOwnership(address payable newOwner) external onlyOwner {
        require(newOwner != address(0), "Auth: owner address cannot be zero");
        isAuthorized[newOwner] = true;
        _transferOwnership(newOwner);
    }

    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal {
        _owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }

    event OwnershipTransferred(address owner);
}

contract Terminator is IERC20, Auth {
    string public constant name = "Terminator";
    string public constant symbol = "$T5000";
    uint8 public constant decimals = 4;
    uint public constant totalSupply = 1 * 10**6 * 10**decimals;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    uint private ecosystemFee = 2;
    uint private marketingFee = 2;
    uint private treasuryFee = 2;
    uint public fee;

    event FeesSet(uint ecosystem, uint marketing, uint treasury);

    function setFees(
        uint ecosystem,
        uint marketing,
        uint treasury
    ) external authorized {
        fee = ecosystem + marketing + treasury;
        require(fee <= 20, "Terminator: fee cannot be more than 20%");

        ecosystemFee = ecosystem;
        marketingFee = marketing;
        treasuryFee = treasury;

        emit FeesSet(ecosystem, marketing, treasury);
    }

    address private constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private weth;

    constructor() Auth(msg.sender) {
        weth = IUniswapV2Router02(router).WETH();
        fee = ecosystemFee + marketingFee + treasuryFee;

        isFeeExempt[msg.sender] = true;

        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function approve(address spender, uint amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint amount) external override returns (bool) {
        return doTransfer(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external override returns (bool) {
        if (allowance[sender][msg.sender] != type(uint).max) {
            require(allowance[sender][msg.sender] >= amount, "Terminator: insufficient allowance");
            allowance[sender][msg.sender] = allowance[sender][msg.sender] - amount;
        }

        return doTransfer(sender, recipient, amount);
    }

    function doTransfer(
        address sender,
        address recipient,
        uint amount
    ) internal returns (bool) {
        require(balanceOf[sender] >= amount, "Terminator: insufficient balance");

        balanceOf[sender] = balanceOf[sender] - amount;

        uint amountAfterFee = amount;

        if (!distributingFee) {
            if ((isPool[sender] && !isFeeExempt[recipient]) || (isPool[recipient] && !isFeeExempt[sender])) {
                amountAfterFee = takeFee(sender, amount);
            } else {
                distributeFeeIfApplicable(amount);
            }
        }

        balanceOf[recipient] = balanceOf[recipient] + amountAfterFee;

        emit Transfer(sender, recipient, amountAfterFee);
        return true;
    }

    function takeFee(address sender, uint amount) internal returns (uint) {
        uint feeAmount = (amount * fee) / 100 / 2;
        balanceOf[address(this)] = balanceOf[address(this)] + feeAmount;

        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    uint private feeDistributionTransactionThreshold = 1 * 10**18;
    uint private feeDistributionBalanceThreshold = 1 * 10**18;
    uint private priceUpdateTimeThreshold = 900;

    function distributeFeeIfApplicable(uint amount) internal {
        updateTokenPriceIfApplicable();

        if (
            FixedPoint.mulDecode(tokenPrice, amount) >= feeDistributionTransactionThreshold &&
            FixedPoint.mulDecode(tokenPrice, balanceOf[address(this)]) >= feeDistributionBalanceThreshold
        ) {
            distributeFee();
        }
    }

    bool private distributingFee;

    function distributeFee() public {
        require(distributingFee == false, "Terminator: reentry prohibited");
        distributingFee = true;

        uint tokensToSell = balanceOf[address(this)];

        if (tokensToSell > 0) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = weth;

            allowance[address(this)][router] = tokensToSell;

            IUniswapV2Router02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokensToSell,
                0,
                path,
                address(this),
                block.timestamp
            );
        }

        uint amount = address(this).balance;

        if (amount > 0) {
            bool success;

            if (ecosystemFee != 0) {
                uint amountEcosystem = (amount * ecosystemFee) / fee;
                (success, ) = payable(ecosystemFeeReceiver).call{ value: amountEcosystem, gas: 30000 }("");
            }

            uint amountMarketing = (amount * marketingFee) / fee;
            (success, ) = payable(marketingFeeReceiver1).call{ value: amountMarketing / 2, gas: 30000 }("");
            (success, ) = payable(marketingFeeReceiver2).call{ value: amountMarketing / 2, gas: 30000 }("");

            uint amountTreasury = (amount * treasuryFee) / fee;
            (success, ) = payable(treasuryFeeReceiver).call{ value: amountTreasury, gas: 30000 }("");
        }

        distributingFee = false;
    }

    uint224 private tokenPrice = 0;
    uint private tokenPriceTimestamp;
    uint private tokenPriceCumulativeLast;

    function updateTokenPriceIfApplicable() internal {
        if (tokenPriceTimestamp != 0) {
            uint timeElapsed = block.timestamp - tokenPriceTimestamp;

            if (timeElapsed > priceUpdateTimeThreshold) {
                uint tokenPriceCumulative = getCumulativeTokenPrice();

                if (tokenPriceCumulativeLast != 0) {
                    tokenPrice = uint224((tokenPriceCumulative - tokenPriceCumulativeLast) / timeElapsed);
                }

                tokenPriceCumulativeLast = tokenPriceCumulative;
                tokenPriceTimestamp = block.timestamp;
            }
        }
    }

    function getCumulativeTokenPrice() internal view returns (uint) {
        uint cumulativePrice;

        if (IUniswapV2Pair(pair).token0() == address(this)) {
            cumulativePrice = IUniswapV2Pair(pair).price0CumulativeLast();
        } else {
            cumulativePrice = IUniswapV2Pair(pair).price1CumulativeLast();
        }

        if (cumulativePrice != 0) {
            uint32 blockTimestamp = uint32(block.timestamp % 2**32);

            (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();

            if (blockTimestampLast != blockTimestamp) {
                uint32 timeElapsed = blockTimestamp - blockTimestampLast;

                if (IUniswapV2Pair(pair).token0() == address(this)) {
                    cumulativePrice += FixedPoint.fraction(reserve1, reserve0) * timeElapsed;
                } else {
                    cumulativePrice += FixedPoint.fraction(reserve0, reserve1) * timeElapsed;
                }
            }
        }

        return cumulativePrice;
    }

    mapping(address => bool) private isPool;

    event IsPool(address indexed addr, bool indexed isPool);

    function setIsPool(address contractAddress, bool contractIsPool) public onlyOwner {
        require(contractAddress != address(0), "Terminator: pool address cannot be zero");
        isPool[contractAddress] = contractIsPool;
        emit IsPool(contractAddress, contractIsPool);
    }

    address private pair;

    function setPair(address pairAddress) external onlyOwner {
        require(pairAddress != address(0), "Terminator: DEx pair address cannot be zero");
        pair = pairAddress;
        setIsPool(pairAddress, true);

        tokenPriceTimestamp = block.timestamp;
    }

    event FeeDistributionThresholdsSet(
        uint transactionThreshold,
        uint balanceThreshold,
        uint tokenPriceUpdateTimeThreshold
    );

    function setFeeDistributionThresholds(
        uint transactionThreshold,
        uint balanceThreshold,
        uint tokenPriceUpdateTimeThreshold
    ) external authorized {
        require(tokenPriceUpdateTimeThreshold > 0, "Terminator: price update time threshold cannot be zero");

        feeDistributionTransactionThreshold = transactionThreshold;
        feeDistributionBalanceThreshold = balanceThreshold;
        priceUpdateTimeThreshold = tokenPriceUpdateTimeThreshold;

        emit FeeDistributionThresholdsSet(transactionThreshold, balanceThreshold, tokenPriceUpdateTimeThreshold);
    }

    mapping(address => bool) private isFeeExempt;

    event IsFeeExempt(address indexed addr, bool indexed isFeeExempt);

    function setIsFeeExempt(address excemptAddress, bool isExempt) external authorized {
        isFeeExempt[excemptAddress] = isExempt;
        emit IsFeeExempt(excemptAddress, isExempt);
    }

    address private ecosystemFeeReceiver;
    address private marketingFeeReceiver1;
    address private marketingFeeReceiver2;
    address private treasuryFeeReceiver;

    event FeeReceiversSet(
        address ecosystemFeeReceiver,
        address marketingFeeReceiver1,
        address marketingFeeReceiver2,
        address treasuryFeeReceiver
    );

    function setFeeReceivers(
        address ecosystem,
        address marketing1,
        address marketing2,
        address treasury
    ) external authorized {
        require(
            ecosystem != address(0) && marketing1 != address(0) && marketing2 != address(0) && treasury != address(0),
            "Terminator: zero address provided"
        );

        ecosystemFeeReceiver = ecosystem;
        marketingFeeReceiver1 = marketing1;
        marketingFeeReceiver2 = marketing2;
        treasuryFeeReceiver = treasury;

        emit FeeReceiversSet(ecosystem, marketing1, marketing2, treasury);
    }

    receive() external payable {}

    fallback() external payable {}
}