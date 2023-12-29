//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20Upgradeable.sol";
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

interface IQuoter {
    function quoteExactInput(
        bytes memory path,
        uint256 amountIn
    ) external returns (uint256 amountOut);

    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    function quoteExactOutput(
        bytes memory path,
        uint256 amountOut
    ) external returns (uint256 amountIn);

    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external view returns (uint256 amountIn);
}

interface StakingManager {
    function depositByPresale(address _user, uint256 _amount) external;
}

contract PresaleV1 is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    address public saleToken;
    address public paymentWallet;
    bool public dynamicSaleState;
    uint256 public baseDecimals;
    uint256 public directTotalTokensSold;
    uint256 public percent;
    uint256 public maxTokensToSell;

    IQuoter public quoter;
    Aggregator public aggregatorInterface;
    IERC20Upgradeable public USDTInterface;
    StakingManager public stakingManagerInterface;

    mapping(address => bool) public wertWhitelisted;

    uint256[] public percentages;
    address[] public wallets;

    event TokensBought(
        address indexed user,
        uint256 indexed tokensBought,
        address indexed purchaseToken,
        uint256 amountPaid,
        uint256 usdEq,
        uint256 timestamp
    );

    event Amount(uint256 value);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev To pause the presale
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev To unpause the presale
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev To get latest ETH price in 10**18 format
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterface.latestRoundData();
        price = (price * (10 ** 10));
        return uint256(price);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    /**
     * @dev to initialize staking manager with new addredd
     * @param _stakingManagerAddress address of the staking smartcontract
     */
    function setStakingManager(
        address _stakingManagerAddress
    ) external onlyOwner {
        require(
            _stakingManagerAddress != address(0),
            "staking manager cannot be inatialized with zero address"
        );
        stakingManagerInterface = StakingManager(_stakingManagerAddress);
        IERC20Upgradeable(saleToken).approve(
            _stakingManagerAddress,
            type(uint256).max
        );
    }

    function setDynamicSaleState(
        bool state,
        address _quoter
    ) external onlyOwner {
        dynamicSaleState = state;
        quoter = IQuoter(_quoter);
    }

    function fetchPrice(uint256 amountOut) public returns (uint256) {
        bytes memory data = abi.encodeWithSelector(
            quoter.quoteExactOutputSingle.selector,
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            0x25722Cd432d02895d9BE45f5dEB60fc479c8781E,
            3000,
            amountOut,
            0
        );
        (bool success, bytes memory result) = address(quoter).call(data);
        require(success, "Call to Quoter failed");
        uint256 amountIn = abi.decode(result, (uint256));
        emit Amount(amountIn);
        return amountIn + ((amountIn * percent) / 100);
    }

    function setPercent(uint256 _percent) external onlyOwner {
        percent = _percent;
    }

    function setMaxTokensToSell(uint256 _maxTokensToSell) external onlyOwner {
        maxTokensToSell = _maxTokensToSell;
    }

    function buyWithEth(
        uint256 amount
    ) external payable whenNotPaused nonReentrant returns (bool) {
        require(dynamicSaleState, "Dynamic sale not active");
        require(
            amount <= maxTokensToSell - directTotalTokensSold,
            "Amount exceeds max tokens to be sold"
        );
        directTotalTokensSold += amount;
        uint256 ethAmount = fetchPrice(amount * baseDecimals);
        require(msg.value >= ethAmount, "Less payment");
        uint256 excess = msg.value - ethAmount;
        splitETHValue(ethAmount);
        if (excess > 0) sendValue(payable(_msgSender()), excess);

        stakingManagerInterface.depositByPresale(
            _msgSender(),
            amount * baseDecimals
        );

        emit TokensBought(
            _msgSender(),
            amount,
            address(0),
            ethAmount,
            0,
            block.timestamp
        );
        return true;
    }

    function buyWithEthWert(
        address _user,
        uint256 amount
    ) external payable whenNotPaused nonReentrant returns (bool) {
        require(
            wertWhitelisted[_msgSender()],
            "User not whitelisted for this tx"
        );
        require(dynamicSaleState, "Dynamic sale not active");
        require(
            amount <= maxTokensToSell - directTotalTokensSold,
            "Amount exceeds max tokens to be sold"
        );
        directTotalTokensSold += amount;
        uint256 ethAmount = fetchPrice(amount * baseDecimals);
        require(msg.value >= ethAmount, "Less payment");
        uint256 excess = msg.value - ethAmount;
        splitETHValue(ethAmount);
        if (excess > 0) sendValue(payable(_user), excess);

        stakingManagerInterface.depositByPresale(_user, amount * baseDecimals);

        emit TokensBought(
            _user,
            amount,
            address(0),
            ethAmount,
            0,
            block.timestamp
        );
        return true;
    }

    function setSplits(
        address[] memory _wallets,
        uint256[] memory _percentages
    ) public onlyOwner {
        require(_wallets.length == _percentages.length, "Mismatched arrays");
        delete wallets;
        delete percentages;
        uint256 totalPercentage = 0;

        for (uint256 i = 0; i < _wallets.length; i++) {
            require(_percentages[i] > 0, "Percentage must be greater than 0");
            totalPercentage += _percentages[i];
            wallets.push(_wallets[i]);
            percentages.push(_percentages[i]);
        }

        require(totalPercentage == 100, "Total percentage must equal 100");
    }

    function splitETHValue(uint256 _amount) internal {
        if (wallets.length == 0) {
            require(paymentWallet != address(0), "Payment wallet not set");
            sendValue(payable(paymentWallet), _amount);
        } else {
            uint256 tempCalc;
            for (uint256 i = 0; i < wallets.length; i++) {
                uint256 amountToTransfer = (_amount * percentages[i]) / 100;
                sendValue(payable(wallets[i]), amountToTransfer);
                tempCalc += amountToTransfer;
            }
            if ((_amount - tempCalc) > 0) {
                sendValue(
                    payable(wallets[wallets.length - 1]),
                    _amount - tempCalc
                );
            }
        }
    }

    function buyWithUSDT(uint256 amount) external whenNotPaused returns (bool) {
        require(dynamicSaleState, "Dynamic sale not active");
        require(
            amount <= maxTokensToSell - directTotalTokensSold,
            "Amount exceeds max tokens to be sold"
        );
        directTotalTokensSold += amount;
        uint256 ethAmount = fetchPrice(amount * baseDecimals);
        uint256 usdPrice = (ethAmount * getLatestPrice()) / baseDecimals;
        uint256 price = usdPrice / (10 ** 12);
        splitUSDTValue(price);
        stakingManagerInterface.depositByPresale(
            _msgSender(),
            amount * baseDecimals
        );
        emit TokensBought(
            _msgSender(),
            amount,
            address(USDTInterface),
            price,
            usdPrice,
            block.timestamp
        );
        return true;
    }

    function splitUSDTValue(uint256 _amount) internal {
        if (wallets.length == 0) {
            require(paymentWallet != address(0), "Payment wallet not set");
            (bool success, ) = address(USDTInterface).call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    _msgSender(),
                    paymentWallet,
                    _amount
                )
            );
            require(success, "Token payment failed");
        } else {
            uint256 tempCalc;
            for (uint256 i = 0; i < wallets.length; i++) {
                uint256 amountToTransfer = (_amount * percentages[i]) / 100;
                (bool success, ) = address(USDTInterface).call(
                    abi.encodeWithSignature(
                        "transferFrom(address,address,uint256)",
                        _msgSender(),
                        wallets[i],
                        amountToTransfer
                    )
                );
                require(success, "Token payment failed");
                tempCalc += amountToTransfer;
            }
            if ((_amount - tempCalc) > 0) {
                (bool success, ) = address(USDTInterface).call(
                    abi.encodeWithSignature(
                        "transferFrom(address,address,uint256)",
                        _msgSender(),
                        wallets[wallets.length - 1],
                        _amount - tempCalc
                    )
                );
                require(success, "Token payment failed");
            }
        }
    }

    /**
     * @dev To add wert contract addresses to whitelist
     * @param _addressesToWhitelist addresses of the contract
     */
    function whitelistUsersForWERT(
        address[] calldata _addressesToWhitelist
    ) external onlyOwner {
        for (uint256 i = 0; i < _addressesToWhitelist.length; i++) {
            wertWhitelisted[_addressesToWhitelist[i]] = true;
        }
    }
}
