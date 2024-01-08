// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import "./IUZV1ProMembershipNFT.sol";
import "./IERC20Extended.sol";
import "./IERC20Extended.sol";
import "./DexAMM.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
contract UZV1ProSale is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, DexAMM {
    using SafeERC20 for IERC20Extended;
    using SafeMath for uint256;

    IUZV1ProMembershipNFT public membershipToken; // nft membership
    uint256 public membershipPrice; // price in stable coin
    address public defaultStableCoin; // usdc as default
    address public utilityToken; // zcx
    mapping(address => bool) public paymentMethod;

    // if enabled, no memberships can be purchased
    bool internal _locked;
    // if enabled, all paid tokens will be burned
    bool internal _burn;

    function initialize(
        address _membershipToken,
        address _defaultStableCoin,
        address _utilityToken
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        // set default values
        membershipToken = IUZV1ProMembershipNFT(_membershipToken);
        membershipPrice = 5 * 10**IERC20Extended(_defaultStableCoin).decimals(); // 5 USD
        paymentMethod[address(0)] = true;
        paymentMethod[_defaultStableCoin] = true;
        paymentMethod[_utilityToken] = true;
        utilityToken = _utilityToken;
        defaultStableCoin = _defaultStableCoin;
        IERC20Extended(_defaultStableCoin).approve(uniswapRouter, type(uint256).max);
        IERC20Extended(utilityToken).approve(uniswapRouter, type(uint256).max);
        // states
        _locked = false;
        _burn = true;
    }

    function whiteListPaymentMethod(address _paymentMethod, bool _whiteList) external onlyOwner {
        paymentMethod[_paymentMethod] = _whiteList;
        if(_paymentMethod != address(0) && _whiteList) { 
            IERC20Extended(_paymentMethod).approve(uniswapRouter, type(uint256).max);
        }
    }

    /**
     * @dev pause smart contract    
     */
    function pause() public onlyOwner() { 
        _pause();
    }

     /**
     * @dev unpause smart contract    
     */
    function unPause() public onlyOwner() { 
        _unpause();
    }
    /**
     * @dev Checks if the sale contract is currently open for use
     * @return locked bool
     **/
    function isLocked() public view returns (bool locked) {
        locked = _locked;
    }

    /**
     * @dev This function allows the purchase of a membership NFT using
     * a supported stablecoin. It will internally swap using a route and
     * use those for the purchase. Refunds unused stable.
     * @param _paymentMethod address of token user want to pay
     **/
    function purchase(address _paymentMethod) external payable whenNotPaused() nonReentrant() {
        require(paymentMethod[_paymentMethod], "ONLY_WHITELISTED_PAYMENT_METHOD");
        require(membershipToken.balanceOf(msg.sender) == 0, "CAN_NOT_MINT_MORE");
        uint256 _burnAmount;
        if(_paymentMethod == defaultStableCoin) {
            IERC20Extended(_paymentMethod).safeTransferFrom(msg.sender, address(this), membershipPrice);
            _burnAmount = _swapTokenForToken(_paymentMethod, utilityToken, membershipPrice, 0); // swap stable coin to xzc for burning
        } 
        else if(_paymentMethod == address(0))  {// payWithEther
            uint256 swapAmout =  estimateSwapAmount(WETH, defaultStableCoin, membershipPrice);
            require(msg.value >= swapAmout, "INVALID_PAYMENT_AMOUNT");
            _burnAmount = _swapETHForToken(utilityToken, swapAmout, 0); 
            if(msg.value > swapAmout) { // return diff
                uint256 refund = msg.value.sub(swapAmout);
                (bool success,) = payable(msg.sender).call{value: refund}("");
                require(success);
            }
        }
        else if(_paymentMethod == utilityToken){ 
            _burnAmount = estimateSwapAmount(_paymentMethod, defaultStableCoin, membershipPrice);
			IERC20Extended(_paymentMethod).safeTransferFrom(msg.sender, address(this), _burnAmount);
        }
        // finalize purchase
        _mintMembership(_burnAmount);
    }

    /**
     * @dev Returns all current pricing and amount informations for a purchase
     * @return priceInStable uint256 current price of nft membership in stable coin
     * @return priceInETH uint256 current price of nft membership in ETH
     * @return priceInZCX uint256 current price of nft membership in ZCX
     **/
    function purchaseInfo()
        public
        view
        returns (
            uint256 priceInStable,
            uint256 priceInETH,
            uint256 priceInZCX
        )
    {
        priceInStable = membershipPrice;
        // get required utility tokens for price
        priceInETH = estimateSwapAmount(WETH, defaultStableCoin, membershipPrice);
        priceInZCX = estimateSwapAmount(utilityToken, defaultStableCoin, membershipPrice);
    }

    /**
     * @dev The final step of all purchase options. Will burn utility tokens, if enabled,
     * mint the membership NFT and emit the purchase event
     * @param _burnAmount uint256 amount of ZCX token will be burn
     **/
    function _mintMembership(uint256 _burnAmount) internal {
        if (_burn == true) {
            // burn ZCX token
            IERC20Extended(utilityToken).burn(_burnAmount);
        }

        // mint membership token
        membershipToken.mint(_msgSender());

        emit MembershipPurchased(_msgSender(), membershipPrice, _burnAmount);
    }

    function adminChangePrice(uint256 _newPrice) external onlyOwner { 
        require(membershipPrice != _newPrice, "SAME_PRICE");
        membershipPrice = _newPrice;
    }

    function switchLock() external onlyOwner {
        _locked = !_locked;
    }

    function switchBurn() external onlyOwner {
        _burn = !_burn;
    }

    /**
     * @dev Withdrawal function to remove payments or tokens sent by accident, to the owner
     *
     * @param tokenAddress address of token to withdraw
     * @param amount amount of tokens to withdraw, 0 for all
     */
    function withdrawTokens(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0), "ZERO_ADDRESS");

        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "NO_TOKEN_BALANCE");

        uint256 amountToWithdraw = (amount > 0 && amount <= balance) ? amount : balance;

        SafeERC20.safeTransfer(token, owner(), amountToWithdraw);
    }

    /* === EVENTS === */
    event MembershipPurchased(address indexed user, uint256 price, uint256 burned);
}
