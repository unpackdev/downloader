// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";

import "./AggregatorV3Interface.sol";

import "./BustadToken.sol";
import "./GovernanceDistributor.sol";

abstract contract IERC20Extended is IERC20 {
    function decimals() public view virtual returns (uint8);
}

contract Crowdsale is Context, ReentrancyGuard, AccessControl, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Extended;

    BustadToken public bustadToken;
    AggregatorV3Interface internal priceFeed;
    GovernanceDistributor public governanceDistributor;

    address payable public bustadWallet;

    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    mapping(address => bool) public acceptedStableCoins;

    uint256 public rate;    

    event TokensMinted(address indexed purchaser, uint256 amount, address indexed tokenAddress);

    constructor(
        address payable _bustadWallet,
        BustadToken _bustadToken,
        GovernanceDistributor _governanceDistributor,
        uint256 _initialRate,
        address[] memory _acceptedStableCoins,
        address _priceFeedAddress
    ) {
        require(_bustadWallet != address(0), "Wallet is the zero address");
        require(
            address(_bustadToken) != address(0),
            "bustadToken is the zero address"
        );
        require(_initialRate > 0, "Rate cannot be 0");

        bustadWallet = _bustadWallet;
        bustadToken = _bustadToken;
        governanceDistributor = _governanceDistributor;
        rate = _initialRate;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _initializeAcceptableStableCoin(_acceptedStableCoins);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    receive() external payable {}

    function buyWithETH() external payable nonReentrant whenNotPaused {
        address buyer = msg.sender;

        _preValidatePurchase(buyer, msg.value);

        int256 ethUSDPrice = getLatestETHPrice();

        uint256 ethAmountInUSD = (uint256(ethUSDPrice) * msg.value) / 1e18;

        (bool success, ) = bustadWallet.call{value: msg.value}("");

        if (success) {
            uint256 amountToMint = _getTokenAmount(ethAmountInUSD);
            _mint(buyer, amountToMint);
            governanceDistributor.addBuyer(buyer, amountToMint);

            emit TokensMinted(_msgSender(), amountToMint, address(0));
        } else {
            revert("Could not send to bustadWallet");
        }
    }

    function buyWithStableCoin(uint256 amount18based, address stableCoinAddress)
        external
        nonReentrant
        whenNotPaused
    {
        require(
            acceptedStableCoins[stableCoinAddress] == true,
            "Token not accepted"
        );

        IERC20Extended coin = IERC20Extended(stableCoinAddress);

        address buyer = msg.sender;

        _preValidatePurchase(buyer, amount18based);

        uint256 coinAmount = _toCoinAmount(amount18based, coin);

        coin.safeTransferFrom(buyer, address(this), coinAmount);

        coin.transfer(address(bustadWallet), coinAmount);

        uint256 amountToMint = _getTokenAmount(amount18based);

        _mint(buyer, amountToMint);
        governanceDistributor.addBuyer(buyer, amountToMint);

        emit TokensMinted(_msgSender(), amountToMint, stableCoinAddress);
    }

    function getLatestETHPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price * 1e10;
    }

    function setRate(uint256 newRate) external onlyRole(MAINTAINER_ROLE) {
        rate = newRate;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function addAcceptedStableCoin(address _stableCoin)
        external
        onlyRole(MAINTAINER_ROLE)
    {
        acceptedStableCoins[_stableCoin] = true;        
    }

    function removeAcceptedStableCoin(address _stableCoin)
        external
        onlyRole(MAINTAINER_ROLE)
    {
        acceptedStableCoins[_stableCoin] = false;        
    }

    function isAcceptableStableCoin(address coin) external view returns (bool) {
        return acceptedStableCoins[coin];
    }

    function setBustadWallet(address payable walletAddress)
        external
        onlyRole(MAINTAINER_ROLE)
    {
        bustadWallet = walletAddress;
    }

    function setGovernanceDistributor(GovernanceDistributor _governanceDistributor)
        external
        onlyRole(MAINTAINER_ROLE)
    {
        governanceDistributor = _governanceDistributor;
    }

    function setPriceFeed(AggregatorV3Interface _priceFeed)
        external
        onlyRole(MAINTAINER_ROLE)
    {
        priceFeed = _priceFeed;
    }

    function setBustadToken(BustadToken _token)
        external
        onlyRole(MAINTAINER_ROLE)
    {
        bustadToken = _token;
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount)
        internal
        view
        virtual
    {
        require(
            beneficiary != address(0),
            "Beneficiary is the zero address"
        );
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        this;
    }

    /**
     * @param weiAmount Value in wei to be converted into amountToMint
     * @return Number of amountToMint that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) private view returns (uint256) {
        return weiAmount.mul(rate) / 1 ether;
    }

    function _mint(address to, uint256 tokenAmount) private {
        bustadToken.mint(to, tokenAmount);
    }

    function _initializeAcceptableStableCoin(address[] memory addresses)
        private
    {
        for (uint8 i = 0; i < addresses.length; i++) {
            acceptedStableCoins[addresses[i]] = true;            
        }
    }

    /**
     * @dev Converts from 18 based decimal system to another coins decimal value.
     * Ex. USDC has decimal = 6, and needs to be treated as such.
     * @param amount original amount in wei
     * @param coin coin with decimal value
     */
    function _toCoinAmount(uint256 amount, IERC20Extended coin)
        private
        view
        returns (uint256)
    {
        return (amount / 1e18) * (10**coin.decimals());
    }

    /**
     * @dev Converts back to 18 based decimal system.
     * Ex. USDC has decimal = 6, and needs to be treated as such.
     * @param coinAmount amount based on the coin's decimal
     * @param coin coin with decimal value
     */
    function _fromCoinAmount(uint256 coinAmount, IERC20Extended coin)
        private
        view
        returns (uint256)
    {
        return (coinAmount / (10**coin.decimals())) * 1e18;
    }
}
