import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";


contract QuickPresale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    // Maps user to the number of tokens owned
    mapping (address => uint256) public tokensOwned;
    // The block when the user claimed tokens prevously
    mapping (address => uint256) public lastTokensClaimed;
    // The number of times the user has claimed tokens;
    mapping (address => uint256) public numClaims;
    // The number of unclaimed tokens the user has
    mapping (address => uint256) public tokensUnclaimed;

    IERC20 bountyToken;

    // Sale ended
    bool isSaleActive;
    // Starting timestamp normal
    uint256 startingTimeStamp;
    uint256 totalTokensSold = 0;
    uint256 tokensPerBNB = 46_000;
    uint256 bnbReceived = 0;

    event TokenBuy(address user, uint256 tokens);
    event TokenClaim(address user, uint256 tokens);

    constructor () public {
        isSaleActive = false;
    }

    // Handles people sending BNB to address
    receive() external payable {
        buy (msg.sender);
    }

    function buy (address beneficiary) public payable nonReentrant {
        require(isSaleActive, "Sale is not active yet");

        address _buyer = beneficiary;
        uint256 _bnbSent = msg.value;
        uint256 tokens = _bnbSent.mul(tokensPerBNB);

        require (_bnbSent >= 0.1 ether, "BNB is lesser than min value");
        require (_bnbSent <= 6 ether, "BNB is greater than max value");
        require (bnbReceived <= 1000 ether, "Hardcap reached");
        require (block.timestamp >= startingTimeStamp, "Presale has not started");

        tokensOwned[_buyer] = tokensOwned[_buyer].add(tokens);

        // Already owns 46*6k tokens which is max
        // Changed to prevent botting of presale
        require(tokensOwned[_buyer] <= 46_000 * 6 ether, "Can't buy more than 6 BNB worth of tokens");

        tokensUnclaimed[_buyer] = tokensUnclaimed[_buyer].add(tokens);
        totalTokensSold = totalTokensSold.add(tokens);
        bnbReceived = bnbReceived.add(msg.value);
        emit TokenBuy(beneficiary, tokens);
    }

    function setSaleActive(bool _isSaleActive) external onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function getTokensOwned () external view returns (uint256) {
        return tokensOwned[msg.sender];
    }

    function getTokensUnclaimed () external view returns (uint256) {
        return tokensUnclaimed[msg.sender];
    }

    function getLastTokensClaimed () external view returns (uint256) {
        return lastTokensClaimed[msg.sender];
    }

    function getBountyTokensLeft() external view returns (uint256) {
        return bountyToken.balanceOf(address(this));
    }

    function getNumClaims () external view returns (uint256) {
        return numClaims[msg.sender];
    }

    function claimTokens() external nonReentrant {
        require (isSaleActive == false, "Sale is still active");
        require (tokensOwned[msg.sender] > 0, "User should own some QB tokens");
        require (tokensUnclaimed[msg.sender] > 0, "User should have unclaimed QB tokens");
        require (bountyToken.balanceOf(address(this)) >= tokensOwned[msg.sender], "There are not enough QB tokens to transfer");
        require (numClaims[msg.sender] < 1, "Only 1 claims can be made to the smart contract");

        tokensUnclaimed[msg.sender] = tokensUnclaimed[msg.sender].sub(tokensOwned[msg.sender]);
        lastTokensClaimed[msg.sender] = block.number;
        numClaims[msg.sender] = numClaims[msg.sender].add(1);

        bountyToken.transfer(msg.sender, tokensOwned[msg.sender]);
        emit TokenClaim(msg.sender, tokensOwned[msg.sender]);
    }

    function setToken(IERC20 quickBounty) public onlyOwner {
        bountyToken = quickBounty;
    }

    function withdrawFunds () external onlyOwner {
        (msg.sender).transfer(address(this).balance);
    }

    function withdrawMarketingFunds () external onlyOwner {
        (msg.sender).transfer(address(this).balance.div(10));
    }

    function withdrawUnsoldBounty() external onlyOwner {
        bountyToken.transfer(msg.sender, bountyToken.balanceOf(address(this)));
    }
}
