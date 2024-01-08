// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import "./IAxelarGasService.sol";
import "./IAxelarGateway.sol";
import "./AddressString.sol";
import "./AggregatorV3Interface.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IERC20.sol";

/**
 * @title SellSlqqEthereum
 * @notice This contract is for the selling Slqq token in ethereum.
 */

contract SellSlqqEthereum is Ownable, ReentrancyGuard {
    /// ------------------------------------- LIBRARYS ------------------------------------- \\\

    /**
     * @notice Utility library to convert an address into its string representation.
     */
    using AddressToString for address;

    using SafeERC20 for IERC20;

    /// --------------------------------- VARIABLES ---------------------------------- \\\

    AggregatorV3Interface public priceFeed;
    IAxelarGateway public gateway;
    IAxelarGasService public gasService;
    IERC20 public USDT;

    address public msgReceiverContract;
    string public baseChainName;
    bool public isClosed;

    mapping(address => bool) public hasBought;

    /// ---------------------------------- EVENTS ------------------------------------ \\\

    event SlqqBought(
        address user,
        uint256 tokenCost,
        uint256 tokenCostDollarValue,
        uint256 nativeTokenPriceInUSD,
        uint256 decimals,
        address referrer,
        bool withUSDT,
        uint256 timestamp
    );

    event Withdrawn(address admin, uint256 usdtAmount, uint256 ethAmount);

    /// --------------------------------- MODIFIERS ---------------------------------- \\\

    modifier isNotClosed() {
        require(!isClosed, "SellSlqqEthereum: Presale is closed.");
        _;
    }

    /// ----------------------------- EXTERANL FUNCTIONS ----------------------------- \\\

    /**
     * @notice Initializes the contract with the given parameters.
     * @dev Constructor sets up the essential parameters for the contract, including the admin, price feed, USDT token, base chain name, and Axelar gateway.
     * @param _priceFeed The address of the Chainlink priceFeed contract.
     * @param _baseChainName The name for the base chain used in cross-chain transactions.
     * @param _usdt The address of the USDT token.
     * @param _axelarGateway The address of the Axelar router contract.
     * @param _gasService The address of the Axelar gas service contract.
     */
    constructor(
        address _priceFeed,
        string memory _baseChainName,
        IERC20 _usdt,
        IAxelarGateway _axelarGateway,
        IAxelarGasService _gasService
    ) {
        priceFeed = AggregatorV3Interface(_priceFeed);
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
     * @dev This function allows the owner to withdraw both USDT and ETH from the contract. It can only be called by the owner.
     */
    function withdraw() external onlyOwner {
        uint256 usdtBalance = USDT.balanceOf(address(this));
        USDT.safeTransfer(msg.sender, usdtBalance);
        uint256 ethBalance = address(this).balance;
        payable(msg.sender).transfer(ethBalance);
        emit Withdrawn(msg.sender, usdtBalance, ethBalance);
    }

    /**
     * @notice Buys SLQQ tokens with USDT.
     * @dev This function enables users to purchase SLQQ tokens using USDT. It also handles referral rewards .
     * @param _amount Amount of USDT tokens to buy with.
     * @param _referrer Referrer's address for potential referral rewards.
     * @param _axelarFee Fee to be paid to axelar for delivering message to the base chain.
     */
    function buySlqqWithUSDT(
        uint256 _amount,
        address _referrer,
        uint256 _axelarFee
    ) external payable {
        USDT.safeTransferFrom(msg.sender, address(this), _amount);
        _buySlqq(_amount, _referrer, true, _axelarFee);
    }

    /**
     * @notice Buys SLQQ tokens with ETH.
     * @dev This function allows users to buy SLQQ tokens using ETH. It also handles referral rewards.
     * @param _referrer Referrer's address for potential referral rewards.
     * @param _axelarFee Fee to be paid to axelar for delivering message to the base chain.
     */
    function buySlqqWithETH(
        address _referrer,
        uint256 _axelarFee
    ) external payable {
        _buySlqq(0, _referrer, false, _axelarFee);
    }

    /**
     * @notice Sets the receiver contract address for cross-chain messages.
     * @dev This function allows the owner to set the contract address that will receive cross-chain messages.
     * @param _msgReceiver The address of the message receiver contract.
     */
    function setMsgReceiver(address _msgReceiver) external onlyOwner {
        msgReceiverContract = _msgReceiver;
    }

    /**
     * @notice Launches the presale by starting the first stage.
     * @dev This function closes the presale.
     * It can only be called by the owner.
     */
    function closePresale() external onlyOwner {
        isClosed = true;
    }
    /// ----------------------------- PUBLIC FUNCTIONS ------------------------------- \\\

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
     * @notice Handles the purchase of SLQQ tokens.
     * @dev This internal function executes the necessary steps for a user to buy SLQQ tokens, including updating the stage, calculating fees,
     * and emitting the appropriate events.
     * @param _amount The amount of USDT tokens to be purchased with.
     * @param _referrer The address of the referrer.
     * @param _withUSDT A boolean indicating whether the purchase is made with USDT.
     * @param _axelarFee Fee to be paid to axelar for delivering message to the base chain.
     */
    function _buySlqq(
        uint256 _amount,
        address _referrer,
        bool _withUSDT,
        uint256 _axelarFee
    ) internal nonReentrant isNotClosed {
        uint256 nativeTokenPriceInUSD = uint256(getLatestData());
        uint256 decimals = (10 ** priceFeed.decimals());
        require(
            _referrer != msg.sender,
            "SellSlqqEthereum: Can't refer yourself."
        );
        if (_referrer != address(0)) {
            if (hasBought[msg.sender]) {
                _referrer = address(0);
            } else {
                hasBought[msg.sender] = true;
            }
        }
        uint256 tokenCost;
        uint256 tokenCostDollarValue;
        if (_withUSDT) {
            require(
                msg.value >= _axelarFee,
                "SellSlqqEthereum: Insufficiant fee."
            );
            tokenCost = _amount;
            tokenCostDollarValue = tokenCost * 1e12;
        } else {
            require(
                msg.value > _axelarFee,
                "SellSlqqEthereum: Insufficiant native token."
            );
            tokenCost = msg.value - _axelarFee;
            tokenCostDollarValue = (tokenCost * nativeTokenPriceInUSD) /
                decimals;
        }
        bytes memory payload = abi.encode(
            msg.sender,
            tokenCost,
            tokenCostDollarValue,
            nativeTokenPriceInUSD,
            decimals,
            _referrer,
            _withUSDT,
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
            msg.sender,
            tokenCost,
            tokenCostDollarValue,
            nativeTokenPriceInUSD,
            decimals,
            _referrer,
            _withUSDT,
            block.timestamp
        );
    }
}
