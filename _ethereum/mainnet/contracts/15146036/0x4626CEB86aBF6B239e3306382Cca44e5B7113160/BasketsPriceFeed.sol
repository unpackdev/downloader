pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IBasketFacet.sol";
import "./ILendingRegistry.sol";
import "./IChainLinkOracle.sol";
import "./IERC20.sol";
import "./ILendingLogic.sol";
import "./IERC20Metadata.sol";

contract BasketsPriceFeed is Ownable {
    IBasketFacet immutable basket;
    ILendingRegistry immutable lendingRegistry;
    uint8 public constant decimals = 18;
    mapping(address => IChainLinkOracle) public linkFeeds;

    constructor (address _basket, address _lendingRegistry) {
        basket = IBasketFacet(_basket);
        lendingRegistry = ILendingRegistry(_lendingRegistry);
    }

    /**
     * Function to retrieve the price of 1 basket token in USD, scaled by 1e18
     *
     * @return usdPrice Price of 1 basket token in USD
     */
    function latestAnswer() external view returns (uint256 usdPrice) {
        address[] memory components = basket.getTokens();

        uint256 marketCapUSD = 0;

        // Gather link prices, component balances, and basket market cap
        for (uint8 i = 0; i < components.length; i++) {
            address component = components[i];
            address underlying = lendingRegistry.wrappedToUnderlying(component);
            IERC20 componentToken = IERC20(component);
            IChainLinkOracle linkFeed;
            if (underlying != address(0)) { // Wrapped tokens
                ILendingLogic lendingLogic = ILendingLogic(lendingRegistry.protocolToLogic(lendingRegistry.wrappedToProtocol(component)));
                linkFeed = linkFeeds[underlying];
                marketCapUSD += (
                    fmul(fmul(componentToken.balanceOf(address(basket)), lendingLogic.exchangeRateView(component), 1 ether),
                    10 ** (36 - IERC20Metadata(address(componentToken)).decimals() - linkFeed.decimals()) * uint256(linkFeed.latestAnswer()),1 ether)
                );
            } else { // Non-wrapped tokens
                linkFeed = linkFeeds[component];
                marketCapUSD += (
                    fmul(componentToken.balanceOf(address(basket)),10 ** (36 - IERC20Metadata(address(componentToken)).decimals() - linkFeed.decimals())  * uint256(linkFeed.latestAnswer()),1 ether)
                );
            }
        }
        usdPrice = fdiv(marketCapUSD, IERC20(address(basket)).totalSupply(), 1 ether);	
	return usdPrice;
    }

    function setTokenFeed(address _token, address _oracle) external onlyOwner {
        linkFeeds[_token] = IChainLinkOracle(_oracle);
    }

    function removeTokenFeed(address _token) external onlyOwner {
        delete linkFeeds[_token];
    }

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            if iszero(eq(div(mul(x,y),x),y)) {revert(0,0)}
            z := div(mul(x,y),baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            if iszero(eq(div(mul(x,baseUnit),x),baseUnit)) {revert(0,0)}
            z := div(mul(x,baseUnit),y)
        }
    }
}

