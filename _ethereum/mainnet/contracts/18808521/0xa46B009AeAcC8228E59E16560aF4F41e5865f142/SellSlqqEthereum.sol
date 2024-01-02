// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.7;

import "./ReentrancyGuardUpgradeable.sol";
import "./AddressString.sol";
import "./IAxelarGasService.sol";
import "./AccessControlUpgradeable.sol";
import "./IAxelarGateway.sol";
import "./AggregatorV3Interface.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

/**
 * @title SellSlqqEthereum
 * @notice This contract is for the selling Slqq token in ethereum.
 */

contract SellSlqqEthereum is
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// ------------------------------------- LIBRARYS ------------------------------------- \\\

    /**
     * @notice Utility library to convert an address into its string representation.
     */
    using AddressToString for address;

    /// --------------------------------- VARIABLES ---------------------------------- \\\

    using SafeERC20 for IERC20;

    AggregatorV3Interface public priceFeed;
    IAxelarGateway public gateway;
    IAxelarGasService public gasService;
    IERC20 public USDT;

    address public msgReceiverContract;
    uint8 public currentStage;
    string public baseChainName;

    struct Stage {
        uint256 soldAmount;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 maxDuration;
        uint256 maxAmount;
        uint256 price; // in USD * 1e18
    }

    mapping(uint8 => Stage) public stagesInfo;
    mapping(address => uint256) public boughtAmount;
    mapping(address => uint256) public referralRewards;

    /// ---------------------------------- EVENTS ------------------------------------ \\\

    event StageSet(
        uint8 stage,
        uint256 maxDuration,
        uint256 maxAmount,
        uint256 price
    );

    event StageStarted(
        uint8 stage,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    event SlqqBought(
        uint8 stage,
        address user,
        uint256 amount,
        uint256 tokenCost,
        uint256 tokenCostDollarValue,
        address referrer,
        bool withUSDT,
        uint256 timestamp
    );

    event Withdrawn(address admin, uint256 usdtAmount, uint256 ethAmount);

    /// --------------------------------- MODIFIERS ---------------------------------- \\\

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SellSlqqEthereum: Caller access denied."
        );
        _;
    }

    /// ----------------------------- EXTERANL FUNCTIONS ----------------------------- \\\

    /**
     * @notice Initializes the contract with the given parameters.
     * @dev This function sets up the essential parameters for the contract, including the admin, price feed, USDT token, base chain name, and Axelar gateway.
     * @param _priceFeed The address of the Chainlink priceFeed contract.
     * @param _baseChainName The name for the base chain used in cross-chain transactions.
     * @param _usdt The address of the USDT token.
     * @param _axelarGateway The address of the Axelar router contract.
     * @param _gasService The address of the Axelar gas service contract.
     */
    function initialize(
        address _priceFeed,
        string memory _baseChainName,
        IERC20 _usdt,
        IAxelarGateway _axelarGateway,
        IAxelarGasService _gasService
    ) external initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        priceFeed = AggregatorV3Interface(_priceFeed);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        USDT = _usdt;
        baseChainName = _baseChainName;
        gateway = _axelarGateway;
        gasService = _gasService;
    }

    /**
     * @notice Fallback function.
     * @dev This function is a fallback function that allows the contract to receive Ether without triggering any specific logic.
     *      It is commonly used to receive Ether sent directly to the contract address.
     */
    fallback() external {}

    /**
     * @notice Withdraws USDT and ETH from the contract.
     * @dev This function allows the admin to withdraw both USDT and ETH from the contract. It can only be called by the admin.
     */
    function withdraw() external onlyAdmin {
        uint256 usdtBalance = USDT.balanceOf(address(this));
        USDT.safeTransfer(msg.sender, usdtBalance);
        uint256 ethBalance = address(this).balance;
        payable(msg.sender).transfer(ethBalance);
        emit Withdrawn(msg.sender, usdtBalance, ethBalance);
    }

    /**
     * @notice Buys SLQQ tokens with USDT.
     * @dev This function enables users to purchase SLQQ tokens using USDT. It also handles referral rewards and updates the presale stage.
     * @param _amount Amount of SLQQ tokens to buy.
     * @param _referrer Referrer's address for potential referral rewards.
     */
    function buySlqqWithUSDT(
        uint256 _amount,
        address _referrer,
        uint256 _axelarFee
    ) external payable {
        USDT.safeTransferFrom(
            msg.sender,
            address(this),
            calcPriceInUSDT(_amount)
        );
        _buySlqq(_amount, _referrer, true, _axelarFee);
    }

    /**
     * @notice Buys SLQQ tokens with ETH.
     * @dev This function allows users to buy SLQQ tokens using ETH. It manages referral rewards, calculates fees, and updates the presale stage.
     * @param _amount Amount of SLQQ tokens to buy.
     * @param _referrer Referrer's address for potential referral rewards.
     */
    function buySlqqWithETH(
        uint256 _amount,
        address _referrer,
        uint256 _axelarFee
    ) external payable {
        _buySlqq(_amount, _referrer, false, _axelarFee);
    }

    /**
     * @notice Sets the stage information.
     * @dev This function allows the admin to set information for each presale stage, such as maximum duration, maximum amount, and price.
     * @param _maxDurations Maximum duration for each stage.
     * @param _maxAmounts Maximum amount of SLQQ tokens available for sale in each stage.
     * @param _prices Price of SLQQ tokens in USD for each stage.
     */
    function setStagesInfo(
        uint256[15] memory _maxDurations,
        uint256[15] memory _maxAmounts,
        uint256[15] memory _prices
    ) external onlyAdmin {
        for (uint8 i; i < 15; i++) {
            setStageInfo(i, _maxDurations[i], _maxAmounts[i], _prices[i]);
        }
    }

    /**
     * @notice Sets the receiver contract address for cross-chain messages.
     * @dev This function allows the admin to set the contract address that will receive cross-chain messages.
     * @param _msgReceiver The address of the message receiver contract.
     */
    function setMsgReceiver(address _msgReceiver) external onlyAdmin {
        msgReceiverContract = _msgReceiver;
    }

    /**
     * @notice Launches the presale by starting the first stage.
     * @dev This function initiates the presale by starting the first stage, ensuring that the required stage information is set.
     * It can only be called by the admin.
     */
    function launchPresale() external onlyAdmin {
        Stage storage stage = stagesInfo[0];
        require(
            stage.maxDuration > 0,
            "SellSlqqEthereum: Stage info is not set"
        );
        require(
            stage.startTimestamp == 0,
            "SellSlqqBSC: Presale already started."
        );
        stage.startTimestamp = block.timestamp;
        stage.endTimestamp = block.timestamp + stage.maxDuration;
    }

    /**
     * @notice Calculates the equivalent total ETH amount for a given SLQQ amount.
     * @param _amount The amount in SLQQ for which to calculate the corresponding ETH amount.
     * @param _axelarFee The axelar fee to be paid in eth.
     * @return totalNative The calculated ETH amount.
     */
    function calcNativeToBePaid(
        uint256 _amount,
        uint256 _axelarFee
    ) external view returns (uint256) {
        return (calcPriceInNativeToken(_amount) + _axelarFee);
    }

    /**
     * @notice Calculates the equivalent SLQQ token amount for a given USDT amount.
     * @param _amount The amount in USDT for which to calculate the corresponding SLQQ tokens.
     * @return slqqAmount The calculated SLQQ token amount.
     */
    function calcTokenAmountForUSDT(
        uint256 _amount
    ) external view returns (uint256 slqqAmount) {
        (uint8 stageNumber, ) = calcStage();
        if (stageNumber > 14) {
            stageNumber = 14;
        }
        uint256 availableInUSDT = calcPriceInUSDT(availableTokens());
        if (_amount > availableInUSDT) {
            uint256 amountLeft = _amount - availableInUSDT;
            slqqAmount = availableTokens();
            for (uint8 i = stageNumber + 1; i < 15; i++) {
                availableInUSDT =
                    (stagesInfo[i].maxAmount * stagesInfo[i].price) /
                    1e30;
                if (amountLeft < availableInUSDT) {
                    slqqAmount += (amountLeft * 1e30) / stagesInfo[i].price;
                    break;
                } else {
                    slqqAmount += stagesInfo[i].maxAmount;
                    amountLeft -= availableInUSDT;
                }
            }
        } else {
            slqqAmount = (_amount * 1e30) / stagesInfo[stageNumber].price;
        }
    }

    /// ----------------------------- PUBLIC FUNCTIONS ------------------------------- \\\

    /**
     * @notice Sets the stage information.
     * @dev This public function allows the admin to set information for a specific presale stage.
     * @param _stage Stage number.
     * @param _maxDuration Maximum duration for the stage.
     * @param _maxAmount Maximum amount of SLQQ tokens available for sale in the stage.
     * @param _price Price of SLQQ tokens in USD.
     */
    function setStageInfo(
        uint8 _stage,
        uint256 _maxDuration,
        uint256 _maxAmount,
        uint256 _price
    ) public onlyAdmin {
        require(_stage < 15, "SellSlqqEthereum: Invalid stage number.");
        require(
            _maxAmount < 1000000000 ether,
            "SellSlqqEthereum: Invalid max amount."
        );
        Stage storage stage = stagesInfo[_stage];
        stage.maxDuration = _maxDuration;
        stage.maxAmount = _maxAmount;
        stage.price = _price;
        emit StageSet(_stage, _maxDuration, _maxAmount, _price);
    }

    /**
     * @notice Calculates the price of SLQQ tokens in the native token.
     * @dev This function calculates the price of SLQQ tokens in the native token based on the specified amount and the current presale stage.
     * @param _amount The amount of SLQQ tokens.
     * @return price The calculated price in the native token.
     */
    function calcPriceInNativeToken(
        uint256 _amount
    ) public view returns (uint256 price) {
        (uint8 stageNumber, ) = calcStage();
        if (stageNumber > 14) {
            stageNumber = 14;
        }
        uint256 nativeTokenPriceInUSD = uint256(getLatestData());
        uint256 decimals = (10 ** priceFeed.decimals());
        Stage memory stage = stagesInfo[stageNumber];
        if (_amount > availableTokens()) {
            uint256 available = availableTokens();
            price =
                (available * stage.price * decimals) /
                (nativeTokenPriceInUSD * 1e18);
            uint256 amountLeft = _amount - available;
            for (uint8 i = stageNumber + 1; i < 15; i++) {
                if (amountLeft < stagesInfo[i].maxAmount) {
                    price += ((amountLeft * stagesInfo[i].price * decimals) /
                        (nativeTokenPriceInUSD * 1e18));
                    break;
                } else {
                    price +=
                        (stagesInfo[i].maxAmount *
                            stagesInfo[i].price *
                            decimals) /
                        (nativeTokenPriceInUSD * 1e18);
                    amountLeft -= stagesInfo[i].maxAmount;
                }
            }
        } else {
            price =
                (_amount * stage.price * decimals) /
                (nativeTokenPriceInUSD * 1e18);
        }
    }

    /**
     * @notice Calculates the price of SLQQ tokens in USDT.
     * @dev This function calculates the price of SLQQ tokens in USDT based on the specified amount and the current presale stage.
     * @param _amount The amount of SLQQ tokens.
     * @return price The calculated price in USDT.
     */
    function calcPriceInUSDT(
        uint256 _amount
    ) public view returns (uint256 price) {
        (uint8 stageNumber, ) = calcStage();
        if (stageNumber > 14) {
            stageNumber = 14;
        }
        if (_amount > availableTokens()) {
            uint256 amountLeft = _amount - availableTokens();
            price = (availableTokens() * stagesInfo[stageNumber].price) / 1e30;
            for (uint8 i = stageNumber + 1; i < 15; i++) {
                if (amountLeft < stagesInfo[i].maxAmount) {
                    price += (amountLeft * stagesInfo[i].price) / 1e30;
                    break;
                } else {
                    price +=
                        (stagesInfo[i].maxAmount * stagesInfo[i].price) /
                        1e30;
                    amountLeft -= stagesInfo[i].maxAmount;
                }
            }
        } else {
            price = (_amount * stagesInfo[stageNumber].price) / 1e30;
        }
    }

    /**
     * @notice Retrieves the available SLQQ tokens for the current stage.
     * @dev This function returns the remaining SLQQ tokens available for sale in the current presale stage.
     * @return The number of SLQQ tokens available.
     */
    function availableTokens() public view returns (uint256) {
        (uint8 stageNumber, ) = calcStage();
        if (stageNumber > 14) {
            stageNumber = 14;
        }
        Stage memory stage = stagesInfo[stageNumber];
        return (stage.maxAmount - stage.soldAmount);
    }

    /**
     * @notice Calculates the current presale stage and its start timestamp.
     * @dev This function determines the current presale stage and its corresponding start timestamp.
     * @return stageNumber The current presale stage number.
     * @return startTimestamp The start timestamp of the current presale stage.
     */
    function calcStage() public view returns (uint8, uint256) {
        Stage memory stage = stagesInfo[currentStage];
        if (currentStage == 0 && stage.startTimestamp == 0) {
            return (0, 0);
        }
        if (stage.endTimestamp < block.timestamp) {
            uint8 stagesPassed = 1;
            uint256 startTimestamp = stage.endTimestamp;
            for (uint8 i = currentStage + 1; i < 15; i++) {
                if (
                    block.timestamp >
                    (startTimestamp + stagesInfo[i].maxDuration)
                ) {
                    stagesPassed++;
                    startTimestamp += stagesInfo[i].maxDuration;
                } else {
                    break;
                }
            }
            return (currentStage + stagesPassed, startTimestamp);
        }
        return (currentStage, stage.startTimestamp);
    }

    /**
     * @notice Retrieves the latest price data from the Chainlink price feed.
     * @dev This function queries the latest price data from the Chainlink price feed.
     * @return The latest price data in the form of an int256 value.
     */
    function getLatestData() public view returns (int256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return answer;
    }

    /// ----------------------------- INTERNAL FUNCTIONS ----------------------------- \\\

    /**
     * @notice Updates the current presale stage based on the block timestamp.
     * @dev This internal function updates the current presale stage if a new stage has started.
     */
    function _updateStage() internal {
        (uint8 newStage, uint256 startTimestamp) = calcStage();
        if (newStage > currentStage) {
            require(newStage < 15, "SellSlqqEthereum: Presale ended.");
            currentStage = newStage;
            Stage storage stage = stagesInfo[currentStage];
            stage.startTimestamp = startTimestamp;
            stage.endTimestamp = startTimestamp + stage.maxDuration;
        }
    }

    /**
     * @notice Handles the purchase of SLQQ tokens.
     * @dev This internal function executes the necessary steps for a user to buy SLQQ tokens, including updating the stage, calculating fees,
     * and emitting the appropriate events.
     * @param _amount The amount of SLQQ tokens to be purchased.
     * @param _referrer The address of the referrer.
     * @param _withUSDT A boolean indicating whether the purchase is made with USDT.
     */
    function _buySlqq(
        uint256 _amount,
        address _referrer,
        bool _withUSDT,
        uint256 _axelarFee
    ) internal nonReentrant {
        _updateStage();
        require(
            stagesInfo[0].startTimestamp > 0,
            "SellSlqqEthereum: Presale has not started."
        );
        require(
            _referrer != msg.sender,
            "SellSlqqEthereum: Can't refer yourself."
        );
        require(
            _amount >= 100 ether,
            "SellSlqqEthereum: less then min amount that can be sold."
        );
        if (_referrer != address(0)) {
            if (boughtAmount[msg.sender] > 0) {
                _referrer = address(0);
            } else {
                referralRewards[_referrer] += (_amount / 10);
            }
        }
        uint256 tokenCost;
        uint256 tokenCostDollarValue;
        if (_withUSDT) {
            require(
                msg.value >= _axelarFee,
                "SellSlqqEthereum: Insufficiant fee."
            );
            tokenCost = calcPriceInUSDT(_amount);
            tokenCostDollarValue = tokenCost * 1e12;
        } else {
            tokenCost = calcPriceInNativeToken(_amount);
            require(
                msg.value >=
                    tokenCost + _axelarFee,
                "SellSlqqEthereum: Insufficiant native token."
            );
            tokenCostDollarValue = calcPriceInUSDT(_amount) * 1e12;
        }
        if (_amount > availableTokens()) {
            uint256 amountLeft = _amount - availableTokens();
            stagesInfo[currentStage].soldAmount += availableTokens();
            for (uint8 i = currentStage + 1; i < 15; i++) {
                currentStage++;
                Stage storage stage = stagesInfo[currentStage];
                stage.startTimestamp = block.timestamp;
                stage.endTimestamp = block.timestamp + stage.maxDuration;
                if (amountLeft < stagesInfo[i].maxAmount) {
                    stagesInfo[currentStage].soldAmount += amountLeft;
                    amountLeft = 0;
                    break;
                } else {
                    amountLeft -= stagesInfo[i].maxAmount;
                    stagesInfo[currentStage].soldAmount = stagesInfo[i]
                        .maxAmount;
                }
            }
            require(
                amountLeft == 0,
                "SellSlqqEthereum: Requested amount exceeds available tokens across stages."
            );
        } else {
            stagesInfo[currentStage].soldAmount += _amount;
        }
        boughtAmount[msg.sender] += _amount;

        bytes memory payload = abi.encode(
            msg.sender,
            _amount,
            _referrer,
            block.timestamp
        );
        string memory msgReceiverAddress = msgReceiverContract.toString();

        gasService.payNativeGasForContractCall{value: _axelarFee}(
            address(this),
            baseChainName,
            msgReceiverAddress,
            payload,
            address(this)
        );

        gateway.callContract(baseChainName, msgReceiverAddress, payload);

        emit SlqqBought(
            currentStage,
            msg.sender,
            _amount,
            tokenCost,
            tokenCostDollarValue,
            _referrer,
            _withUSDT,
            block.timestamp
        );
        if (availableTokens() < 100 ether) {
            currentStage++;
            Stage storage stage = stagesInfo[currentStage];
            stage.startTimestamp = block.timestamp;
            stage.endTimestamp = block.timestamp + stage.maxDuration;
        }
    }
}
