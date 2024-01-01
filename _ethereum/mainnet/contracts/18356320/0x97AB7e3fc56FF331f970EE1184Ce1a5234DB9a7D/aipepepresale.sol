///SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import  "@openzeppelin/contracts/access/Ownable2Step.sol";

/// chainlink aggregator interface
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
/// @title TpepePresale: A Presale smart contract for Tpepe presale
/// @dev users can participate via eth and usdt
contract TpepePresale is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice struct user information, how much usdt worth
    /// contribution a user has. tokens alloted and claimed till date.
    struct User {
        uint256 USDTContributed;
        uint256 tokensBought;
        uint256 tokensClaimed;
    }
    /// @notice token to be sold in presale
    IERC20 public Tpepe;
    /// @notice token to be accepted other than eth
    IERC20  constant private USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    /// @notice chainlink price feed address
    Aggregator public aggregatorInterface;
    /// @notice token decimals
    uint256 constant private BASE_DECIMALS = 1e18;
    uint256 constant private MIN_THRESHOLD = 1e6; // 1 usdt 
    /// @notice tokens per USDT 
    uint256 public tokensPerUSDT;
    /// @notice mapping address to user info
    mapping (address => User) public users;
    /// @notice bool value to showcase if presale is live or not
    bool public presaleEnabled = true;
    /// @notice bool value to showcase if claims are live or not
    bool public claimAvaialble;
    /// @notice tokens sold in presale
    uint256 public totalTokenSold;
    /// @notice total USDT worth assets raised
    uint256 public totalUSDTRaised; 
    /// @notice max usdt equivalent that a user can buy per wallet
    uint256 public maxThresholdPerWallet;
    /// @notice min usdt equivalent that a user need to buy in order to participate
    uint256 public minThresholdPerWallet;
    /// @notice wallet or multisig where all the presale funds go
    address public paymentWallet;
    /// @notice variable for front end to calculate total usd to be raised
    uint256 public totalTokensForSale;
    /// @notice variable for front end to display remaining sale time
    uint256 public saleEndTime;


      /// errors
    error IsZeroAddress();
    error SaleIsNotLiveYet();
    error AmountTooLow();
    error AlreadyClaimed();
    error AmountExceedsPresaleSupply();
    error ValueMustBeGreatorThanMinThreshold();
    error claimsAlreadyEnabled();
    error UpdateBoolValue();
    error ClaimsNotAvailableYet();
    error MaxLimitPerWalletExceeds();
    error CannotRescueNativeTokens();
    error SaleIsAlreadyEnded();
    

    event tokensBoughtUser (uint256 indexed USDT, uint256 indexed Tokens);
    event tokensClaimedByUser(uint256 indexed claimAmount);
    

    /// @dev create presale contract, using IERC20, SafeERC20, Ownable,
    /// ReentrancyGaurd from openezeppelin. and uses aggregator interface
    /// to use chainlink price feed
    constructor (address newOwner) Ownable (newOwner){
        
        Tpepe = IERC20(0xE90696B7dFF6F796d756ca92fE57075E0467c379); //aipepe ddress
        aggregatorInterface = Aggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); //chainlink ETH_USD price feed
        paymentWallet = address(0xaffF6581D00c4E07690693DeCb38cB360A211785); // replace with actual wallet to receive funds
        tokensPerUSDT = 1000; /// 0.001 usd
        minThresholdPerWallet = 10e6; // 10 usd min buy per wallet
        maxThresholdPerWallet = 5000e6; // 5000 usd max buy per wallet

    }

    /// @dev check if sale is live or not
    modifier saleLiveStatus(){
        if(!presaleEnabled){
            revert SaleIsNotLiveYet();
        }
        _;
    }

    /// @dev check for address if it's zero or not
    modifier NonZeroAddressCheck(address user){
        if(user == address(0)){
            revert IsZeroAddress();
        }
        _;
    }

    

    /// @notice user can buy tokens with usdt
    /// @param _usdtAmount: no. of tokens that a user want to buy
    function buyWithUSDT (uint256 _usdtAmount) external saleLiveStatus nonReentrant {
      
     if(_usdtAmount < minThresholdPerWallet){
         revert AmountTooLow();
     }
     User storage user = users[msg.sender];
     if(user.USDTContributed + _usdtAmount > maxThresholdPerWallet){
         revert MaxLimitPerWalletExceeds();
     }
     uint256 tokensAmount = calculateTokens(_usdtAmount);
     uint256 availableTokensForSale = Tpepe.balanceOf(address(this));
     if(tokensAmount + totalTokenSold > availableTokensForSale){
         revert AmountExceedsPresaleSupply();
     }
     USDT.safeTransferFrom(msg.sender, paymentWallet, _usdtAmount);
     totalTokenSold = totalTokenSold + tokensAmount;
     totalUSDTRaised = totalUSDTRaised + _usdtAmount;
     user.tokensBought = user.tokensBought + tokensAmount;
     user.USDTContributed = user.USDTContributed + _usdtAmount;
     emit tokensBoughtUser ( _usdtAmount, tokensAmount); 

    }
    

    /// @notice user can buy tokens with native eth
    function buyWithETH()  saleLiveStatus external payable nonReentrant {


        uint256 ethAmount = msg.value;
        uint256 usdtAmount = ethBuyHelper(ethAmount);
        if(usdtAmount < minThresholdPerWallet){
         revert AmountTooLow();
     }

     uint256 tokensAmount = calculateTokens(usdtAmount);
     User storage user = users[msg.sender];
     if(user.USDTContributed + usdtAmount > maxThresholdPerWallet){
         revert MaxLimitPerWalletExceeds();
     }
     uint256 availableTokensForSale = Tpepe.balanceOf(address(this));
     if(tokensAmount + totalTokenSold > availableTokensForSale){
         revert AmountExceedsPresaleSupply();
     }
     (bool sent,) = payable(paymentWallet).call{value: ethAmount}("");
     require(sent, "eth transfer failed");
     totalTokenSold = totalTokenSold + tokensAmount;
     totalUSDTRaised = totalUSDTRaised + usdtAmount;
     user.tokensBought = user.tokensBought + tokensAmount;
     user.USDTContributed = user.USDTContributed + usdtAmount;
     emit tokensBoughtUser ( usdtAmount, tokensAmount); 

    }

    
    /// @dev To get latest ETH price in wei format
    /// chainlink price feed returns price with 8 decimals,
    /// multiplying that with 1e10 to have right calculations.
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterface.latestRoundData();
        return uint256(price);
    }

  
    /// @dev Helper funtion to get USDT price for given amount of eth
    /// @param amount No of tokens to buy
    function ethBuyHelper(
        uint256 amount
    ) public view returns (uint256 usdAmount) {
        uint256 perEthPrice = getLatestPrice();
        ///chainlink ETH_USD oracle returns price upto 8 decimals only 
        /// so multiplying it 1e10 first and then divide it with 1e18 to
        /// get usdt per wei price
        uint256 pricePerWei = (perEthPrice * 1e10) / 1e18;
        /// multiply the eth amount with pricePerWei and divide that with 1e12
        /// so that we can get answer upto 6 decimals only (as usdt has 6 decimals only.
         usdAmount = (amount * pricePerWei) / 1e12;

    }


    /**
     * @dev To calculate the tokens output for given amount of usdt.
     * @param _amount No of tokens
     */
    function calculateTokens(uint256 _amount) public view returns (uint256) {
        uint256 TpepeAmount;
        TpepeAmount = (_amount * BASE_DECIMALS) / tokensPerUSDT;
        return TpepeAmount;
    }

    
    /// @dev update max and min treshold for user
    function setMinAndMaxThresholdValue (uint256 _newMinThreshold, uint256 _newMaxThreshold) external onlyOwner {
        if(_newMinThreshold < MIN_THRESHOLD && _newMaxThreshold < MIN_THRESHOLD){
            revert ValueMustBeGreatorThanMinThreshold();
        }
        minThresholdPerWallet = _newMinThreshold;
        maxThresholdPerWallet = _newMaxThreshold;
    }
    

    /// @dev update payment wallet to receive funds
    function setPaymentWallet (address _newWallet) external NonZeroAddressCheck(_newWallet) onlyOwner {
        paymentWallet = _newWallet;
    }
    
    /// @dev set tokens per usdt
    /// @param _tknPerusdt: tokens per usdt
    function setTokenPrice (uint256 _tknPerusdt) external onlyOwner {
        if(_tknPerusdt < 1){
            revert AmountTooLow();
        }
        tokensPerUSDT = _tknPerusdt;
    }


    /// @dev enable claims once presale has been finished
    function enableClaims() external onlyOwner {
        if(!presaleEnabled){
            revert claimsAlreadyEnabled();
        }
     saleEndTime = block.timestamp;   
     presaleEnabled = false;   
     claimAvaialble = true;
    }

    ///@notice user can call this function to claim tokens,
    /// when presale has been ended and claims are opened by the owner.
    function claim () external nonReentrant {
        if(!claimAvaialble){
            revert ClaimsNotAvailableYet();
        }

        User storage user = users[msg.sender];
        uint256 unlockedAmount = user.tokensBought;
        uint256 claimedAmount = user.tokensClaimed;
        if (claimedAmount > 0){
            revert AlreadyClaimed();
        }
        if(claimedAmount == 0){
        user.tokensClaimed = claimedAmount + unlockedAmount;
        Tpepe.safeTransfer(msg.sender, unlockedAmount);
        emit tokensClaimedByUser (unlockedAmount);
        }
        
    }


    /// @notice send unsold tokens to payment wallet, wehn presale is over
    /// and claims are opened
    function claimUnsoldTokens () external onlyOwner {
        require(claimAvaialble, "presale is not over yet");
        uint256 balance = Tpepe.balanceOf(address(this));
        if(balance > totalTokenSold){
            uint256 remainingTokens = balance - totalTokenSold;
            if(remainingTokens > 0){
              Tpepe.safeTransfer(paymentWallet, remainingTokens);
            }
        }
    }
    

    /// @notice claim stucked tokens (other than Tpepe) if accidently sent by someone)
    /// @param token: token address to rescue
    function RescueOtherTokens (address token) external onlyOwner {
        if(token == address(Tpepe)){
            revert CannotRescueNativeTokens();
        }
        IERC20 tkn = IERC20(token);
        uint256 balance = tkn.balanceOf(address(this));
        tkn.safeTransfer(paymentWallet, balance);
    }
     
    /// @notice update sale end time
    /// @param time in unixtimestamp 
    function updateSaleEndTime (uint256 time) external onlyOwner {
        if(claimAvaialble){
            revert SaleIsAlreadyEnded();
        }
        saleEndTime = time;
    }

    /// @notice update total tokens for sale
    /// @param totalTokens: total tokens for sale
    function updateTotalTokensForSale (uint256 totalTokens) external onlyOwner {
        totalTokensForSale = totalTokens;
    }


}