// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.2;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}

contract TokenPresale {

    // Settings
    address public admin;
    address public treasury;
    IERC20 public token;
    uint256 public tokenPrice;
    uint256 minETHAmount;
    uint256 maxETHAmount;
    uint256 maxTokenAmount;

    // Presale
    bool public presaleEnded;
    bool public presaleStarted;
    uint256 public presaleStartTime;
    uint256 public presaleEndTime;
    mapping(address => uint8) public buyers; // 0 unset | 1 seed | 2 public
    mapping(address => uint256) public purchasedTokens; 

    // Claim
    bool public claimStarted;
    uint256 public claimStartTime;
    mapping(address => uint256) public claimedTokens;

    // Stats
    uint256 totalTokenSold;
    uint256 totalClaimed;

    // Whitelist
    mapping(address => bool) public whitelist;
    bool whitelistActive;
    uint256 whitelistDuration;

    // State
    bool private locked;
    bool private released;

    event StartPresale();
    event EndPresale();
    event ClaimStart();
    event Claim(address user, uint256 amount);

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor(
        uint256 _oneEthInTokens,
        uint256 _maxTokenAmount,
        address _treasury
    ) {
        admin = msg.sender;
        tokenPrice = 1 ether / _oneEthInTokens;
        maxTokenAmount = _maxTokenAmount;
        treasury = _treasury;
        minETHAmount = 0.01 ether;
        maxETHAmount = 1.5 ether;
        whitelistActive = true;
        totalTokenSold = 0;
        totalClaimed = 0;
        claimStarted = false;
        presaleStarted = false;
        whitelistDuration = 4 hours;
    }

    // Admin Only
    function openPresale() public {
        require(msg.sender == admin, 'Only admin can open the presale');
        presaleStarted = true;
        presaleStartTime = block.timestamp;
        presaleEndTime = block.timestamp + 4 hours;
        emit StartPresale();
    }
    function setTreasury(address _treasury) public {
        require(msg.sender == admin, 'Only admin can set the treasury');
        require(_treasury != address(0), 'ZERO_ADDRESS');
        treasury = _treasury;
    }
    function whitelistUsers(address[] memory users) public {
        require(msg.sender == admin, 'Only admin can whitelist a user');
        for(uint256 i=0; i<users.length; i++){
            whitelist[users[i]] = true;
        }
    }
    function setWhitelistActive(bool state) public {
        require(msg.sender == admin, 'Only admin can turn the whitelist on or off');
        whitelistActive = state;
    }
    function setTokenAddress(address _tokenAddress) public {
        require(msg.sender == admin, 'Only admin can set the token address');
        token = IERC20(_tokenAddress);
    }
    function setMinAmount(uint256 ethamount) public {
        require(msg.sender == admin, 'Only admin can set the minimum amount');
        minETHAmount = ethamount;
    }
    function setMaxAmount(uint256 ethamount) public {
        require(msg.sender == admin, 'Only admin can set the maximum amount');
        maxETHAmount = ethamount;
    }
    function registerSeedBuyers(address[] memory _buyers, uint256[] memory _amounts) public {
        require(msg.sender == admin, 'Only admin can set the maximum amount');
        require(_buyers.length == _amounts.length, 'SIZE_MISMATCH');
        for(uint256 i=0; i<_buyers.length; i++){
            buyers[_buyers[i]] = 1;
            purchasedTokens[_buyers[i]] = _amounts[i];
        }
    }
    function endPresale() public {
        require(msg.sender == admin, "Only admin can end the presale");
        presaleEnded = true;
        emit EndPresale();
    }
    function startClaimPeriod() public {
        require(presaleEnded, 'Presale still running');
        require(address(token) != address(0), 'EMPTY_TOKEN');
        claimStarted = true;
        claimStartTime = block.timestamp;
        emit ClaimStart();
    }
    function depositTokens(uint256 amount) public {
        require(msg.sender == admin, "Only admin can deposit tokens");
        token.transferFrom(msg.sender, address(this), amount);
    }
    function emergencyRelease() public {
        require(msg.sender == admin, "Only admin can release for emergency");
        released = true;
    }
    function airdrop(address[] memory _recipients) public {
        require(msg.sender == admin, "Only admin can call airdrop");
        for (uint i = 0; i < _recipients.length; i++) {
            uint256 amount = getAirdropAmount(_recipients[i]);
            token.transfer(_recipients[i], amount);
            purchasedTokens[_recipients[i]] - amount;
        }
    }

    // Public accessible
    function buyTokens(address referrer) public payable noReentrant {
        require(presaleStarted, "Presale is not open yet");
        require(!presaleEnded, "Presale has ended");
        require(buyers[msg.sender] != 1, 'Seed investors cannot buy in public');
        require(msg.value >= minETHAmount, 'Insufficient ETH sent');
        require(msg.value <= maxETHAmount, 'ETH amount exceeds limit');

        if(isWhitelistActive()){
            require(whitelist[msg.sender], 'User is not whitelisted');
        }

        uint256 tokenAmount = getAmount(msg.value);
        require(purchasedTokens[msg.sender] + tokenAmount <= maxTokenAmount, 'Max ticket reached');

        purchasedTokens[msg.sender] += tokenAmount;
        totalTokenSold += tokenAmount;
        buyers[msg.sender] = 2;
        address ref = referrer == address(0) ? treasury : referrer;
        uint256 referrerReward = msg.value / 10;
        if(ref != treasury && ref != msg.sender){
            // Transfer referrer reward
            (bool refSent, ) = ref.call{value: referrerReward}("");
            require(refSent, "Referrer reward transfer failed");
        }else{
            referrerReward = 0;
        }

        // Transfer remaining ETH to treasury
        (bool treasSent, ) = treasury.call{value: msg.value - referrerReward}("");
        require(treasSent, "Failed to send ETH to treasury");
    }
    function claimTokens() public noReentrant {
        require(claimStarted, "Claim not available yet");
        require(buyers[msg.sender] > 0, 'Not a buyer');

        uint256 totalTokens = purchasedTokens[msg.sender];
        require(totalTokens > 0, "No tokens to claim");

        uint256 tokensAvailable = getAvailableTokens(msg.sender);
        require(tokensAvailable > 0, "No tokens available for claim");

        claimedTokens[msg.sender] += tokensAvailable;
        totalClaimed += tokensAvailable;
        token.transfer(msg.sender, tokensAvailable);
        emit Claim(msg.sender, tokensAvailable);
    }
    function getAmount(uint256 ethamount) public view returns (uint256) {
        return (ethamount * 1 ether) / tokenPrice;
    }
    function getAvailableTokens(address user) public view returns (uint256) {
        uint256 totalTokens = purchasedTokens[user];
        if (totalTokens == 0) return 0;

        if(released){
            return totalTokens - claimedTokens[user];
        }

        uint256 immediateRelease = 0;
        // IF PUBLIC
        if(buyers[user] == 2){
            immediateRelease = totalTokens * 20 / 100;
        }
        uint256 vestedRelease = totalTokens - immediateRelease;
        uint256 daysSinceEnd = (block.timestamp - claimStartTime) / 60 / 60 / 24;
        uint256 vestedAvailable = (vestedRelease * daysSinceEnd) / 30;
        vestedAvailable = vestedAvailable > vestedRelease ? vestedRelease : vestedAvailable;

        uint256 totalAvailable = immediateRelease + vestedAvailable;
        return totalAvailable - claimedTokens[user];
    }
    function getTokenPrice() view public returns(uint256) {
        return tokenPrice;
    }
    function secondsToNextRelease() public view returns(uint256) {

        if(!claimStarted){
            return 0;
        }

        uint256 secondsInADay = 60 * 60 * 24;
        uint256 daysSinceEnd = (block.timestamp - claimStartTime) / secondsInADay;
        uint256 nextReleaseTime = claimStartTime + ((daysSinceEnd + 1) * secondsInADay);

        return nextReleaseTime - block.timestamp;
    }
    function isWhitelistActive() public view returns(bool) {
        return whitelistActive && block.timestamp < presaleStartTime + whitelistDuration;
    }

    // Internal
    function getAirdropAmount(address seeder) internal view returns(uint256) {
        if(purchasedTokens[seeder] > 0){
            return purchasedTokens[seeder] * 40 / 100;
        }
        return 0;
    }

}
