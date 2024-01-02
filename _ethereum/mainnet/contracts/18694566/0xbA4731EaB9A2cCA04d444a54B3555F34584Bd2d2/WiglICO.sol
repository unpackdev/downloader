// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;


import "./AggregatorV3Interface.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

interface myIERC20 is IERC20 {
    function decimals() external view returns (uint8);
}

contract WiglICO is Ownable {
    using SafeERC20 for myIERC20;

    struct AllowedToken {
        bool enabled;
        AggregatorV3Interface oracleAddress;
    }

    struct PhaseConfig {
        uint256 supply;
        uint256 value; // in cents
    }

    struct Sale {
        address user;
        myIERC20 currency;
        uint256 value;
        uint256 quantity;
        Phase phase;
        string orderId;
    }

    enum Phase {
        Close,
        Private,
        Presale,
        Public
    }

    Phase public currentPhase = Phase.Private;
    Sale[] public sales;
    uint8 public slippage = 10; // 10 === 0.10%
    address public fundsRecipient;
    AggregatorV3Interface public ethToUsdFeed; //ChainLink Feed
    AggregatorV3Interface public eurToUsdFeed; //ChainLink Feed

    mapping(myIERC20 => AllowedToken) public allowedTokens;
    mapping(Phase => PhaseConfig) public phaseConfig;

    event NewSale(address indexed user, myIERC20 currency, uint256 value, uint256 quantity, Phase phase, string orderId);

    constructor(
        address _initialOwner,
        myIERC20[] memory _allowedTokens,
        AggregatorV3Interface[] memory _oracles,
        address _fundsRecipient,
        address _ethToUsdFeed,
        address _eurToUsdFeed
    )Ownable(_initialOwner) {
        require(_allowedTokens.length == _oracles.length, "bad array size");
        for (uint256 i = 0; i < _allowedTokens.length; i++) {
            allowedTokens[_allowedTokens[i]] = AllowedToken(true, _oracles[i]);
        }
        fundsRecipient = _fundsRecipient;
        phaseConfig[Phase.Private] = PhaseConfig(37_500_000, 25);
        phaseConfig[Phase.Presale] = PhaseConfig(37_500_000, 50);
        phaseConfig[Phase.Public] = PhaseConfig(25_000_000, 70);
        ethToUsdFeed = AggregatorV3Interface(_ethToUsdFeed);
        eurToUsdFeed = AggregatorV3Interface(_eurToUsdFeed);
    }

    /**
     * @dev Buy NFT with ETH with a 0.1% slippage
     * @param _amount quantity to mint
     */
    function buyInETH(uint256 _amount, string memory _orderId) public payable {
        require(currentPhase != Phase.Close, "Wigl-ICO: sale phase is closed");

        uint256 ethPrice = getPriceInETH();
        require(
            msg.value > (((10000 - slippage) * ethPrice)) * _amount / 10000 &&
            msg.value < (((10000 + slippage) * ethPrice)) * _amount / 10000,
            "Wigl-ICO:bad ETH amount"
        );

        // The value is immediately transferred to the funds recipient
        (bool sent,) = payable(fundsRecipient).call{value: msg.value}("");
        require(sent, "Wigl-ICO:Failed to send Ether");

        _addSale(_orderId, msg.sender, myIERC20(address(0)), msg.value, _amount);
    }

    /**
    * @dev Buy NFT with custom Token
     * @param _amount quantity to mint
     * @param _tokenAddress custom token
     */
    function buyInToken(uint256 _amount, myIERC20 _tokenAddress, string memory _orderId) public payable {
        require(currentPhase != Phase.Close, "Wigl-ICO: sale phase is closed");
        require(allowedTokens[_tokenAddress].enabled, "WGL-ICO: token not allowed");

        uint256 tokenPrice = getPriceInToken(_tokenAddress);

        // The value is immediately transferred to the funds recipient
        _tokenAddress.safeTransferFrom(
            msg.sender,
            fundsRecipient,
            _amount * tokenPrice
        );

        _addSale(_orderId, msg.sender, _tokenAddress, _amount * tokenPrice, _amount);
    }

    function updateCurrentPhase(Phase _phase) public onlyOwner {
        require(currentPhase != _phase, "Wigl-ICO: already in that phase");
        currentPhase = _phase;
    }

    function setTokenAllowanceState(myIERC20 _tokenAddress, bool _state, AggregatorV3Interface _aggregator) public onlyOwner {
        require(allowedTokens[_tokenAddress].enabled != _state, "WIGL-ICO: already at this state");
        require(address(_aggregator) != address(0), "WIGL-ICO: _aggregator can't be 0 address");
        allowedTokens[_tokenAddress] = AllowedToken(_state, _aggregator);
    }

    function updatePhaseConfig(Phase _phase, uint256 _supply, uint256 _value) public onlyOwner {
        phaseConfig[_phase] = PhaseConfig(_supply, _value);
    }

    function updateSlippage(uint8 _slippage) public onlyOwner {
        slippage = _slippage;
    }

    function getSales() public view returns (Sale[] memory) {
        return sales;
    }

    /**
   * @dev Return the price in ETH of the specified Pack
     * decimals of Chainlink feeds are NOT with 18 decimals.
     */
    function getPriceInETH() public view returns (uint256 priceInETH) {
        uint256 priceInEur = phaseConfig[currentPhase].value;
        uint256 eurToUsd = _getEURtoUSDPrice();
        uint256 ethToUsd = _getETHtoUSDPrice();
        uint256 priceInUsd = priceInEur * eurToUsd;
        priceInETH = (priceInUsd * 10 ** 15) / ethToUsd;
    }

    /**
   * @dev Return the price in USD of the specified Pack
     * decimals of Chainlink feeds are NOT with 18 decimals.
     */
    function getPriceInToken(myIERC20 _tokenAddress) public view returns (uint256 priceInToken) {
        uint256 priceInEur = phaseConfig[currentPhase].value;
        uint256 eurToUsd = _getEURtoUSDPrice();
        uint256 tokenToUsd = _getTokenToUSDPrice(_tokenAddress);
        uint256 decimals = _tokenAddress.decimals();
        priceInToken = priceInEur * eurToUsd * 10 ** (decimals - 3) / tokenToUsd;
    }

    //////////////////////////////////////////////////////////////////////////
    //////////////////////////  INTERNAL FUNCTION ////////////////////////////////
    //////////////////////////////////////////////////////////////////////////

    /**
     * @dev Get current rate of Token to US Dollar
     */
    function _getTokenToUSDPrice(myIERC20 _tokenAddress) private view returns (uint256) {
        (, int256 price, , ,) = allowedTokens[_tokenAddress].oracleAddress.latestRoundData();
        return uint256(price);
    }

    /**
     * @dev Get current rate of ETH to US Dollar
     */
    function _getETHtoUSDPrice() private view returns (uint256) {
        (, int256 price, , ,) = ethToUsdFeed.latestRoundData();
        return uint256(price);
    }

    /**
     * @dev Get current rate of EUR to US Dollar
     */
    function _getEURtoUSDPrice() private view returns (uint256) {
        (, int256 price, , ,) = eurToUsdFeed.latestRoundData();
        return uint256(price);
    }

    function _addSale(string memory _orderId, address _user, myIERC20 _token, uint256 _paidAmount, uint256 _amount) private {
        sales.push(Sale(_user, _token, _paidAmount, _amount, currentPhase, _orderId));
        emit NewSale(_user, _token, _paidAmount, _amount, currentPhase, _orderId);
    }


}

