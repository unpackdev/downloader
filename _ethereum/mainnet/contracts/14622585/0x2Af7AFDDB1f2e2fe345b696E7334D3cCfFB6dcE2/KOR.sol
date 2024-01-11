// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721EnumerableUpgradeable.sol";
import "./IERC20.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./AggregatorV3Interface.sol";

contract KOR is ERC721EnumerableUpgradeable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter internal tokenIds;
    address public owner;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    struct Miner {
        string minerType;
        uint256 hashRate;
        uint256 numOfMiner;
        uint256 price;
        uint256 mintedCount;
    }

    struct Token {
        uint256 index;
        uint256 amount;
        uint256 mintTime;
        uint256 totalEarning;
    }

    uint256 constant public EXPIRE_LIMIT = 4 * 365 * 24 * 60 * 60; // 4 years
    uint256 constant public REWARD_DISTRIBUTE_PERIOD = 14 * 24 * 60 * 60; // two weeks
    uint256 internal lastDistributionTime;

    address public priceFeedAddress;
    AggregatorV3Interface internal priceFeed;

    address public usdcAddress;
    IERC20 internal usdcToken;
    string public baseTokenUri;
    
    mapping(uint256 => Miner) public miners; // miner index to miner
    mapping(uint256 => Token) public tokenIdToToken; // nft token Id to Token

    uint256 public totalMiner;

    function initialize() initializer external {
        __ERC721_init("KOR", "KOR");

        owner = msg.sender;

        // Ethereum mainnet: 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4
        // Rinkeby testnet: 0xdCA36F27cbC4E38aE16C4E9f99D39b42337F6dcf
        priceFeedAddress = 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        
        // Ethereum mainnet: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        // Rinkeby testnet: 0xD92E713d051C37EbB2561803a3b5FBAbc4962431
        usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }

    // constructor() ERC721("KOR", "KOR") {
    //     owner = msg.sender;

    //     // Ethereum mainnet: 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4
    //     // Rinkeby testnet: 0xdCA36F27cbC4E38aE16C4E9f99D39b42337F6dcf
    //     priceFeedAddress = 0xdCA36F27cbC4E38aE16C4E9f99D39b42337F6dcf;
        
    //     // Ethereum mainnet: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    //     // Rinkeby testnet: 0xD92E713d051C37EbB2561803a3b5FBAbc4962431
    //     usdcAddress = 0xD92E713d051C37EbB2561803a3b5FBAbc4962431;
    // }

    function getLatestPrice() public view returns (uint256) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function isExpired (uint256 tokenId) public view returns(bool) {
        Token memory token = tokenIdToToken[tokenId];
        return (block.timestamp - token.mintTime > EXPIRE_LIMIT);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
        require(!isExpired(tokenId), "Expired item cannot be traded");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(!isExpired(tokenId), "Expired item cannot be traded");
        super.safeTransferFrom(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(!isExpired(tokenId), "Expired item cannot be traded");
        super.transferFrom(from, to, tokenId);
    }

    function setUSDCAddress(address usdcAddress_) external onlyOwner {
        usdcAddress = usdcAddress_;
    }

    function setPriceFeedAddress(address priceFeedAddress_) external onlyOwner {
        priceFeedAddress = priceFeedAddress_;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function setLastDistributionTime() external onlyOwner {
        lastDistributionTime = block.timestamp;
    }

    function forceExpire(uint256 tokenId) external onlyOwner {
        require(isExpired(tokenId), "This token is not expired yet");
        Token memory token = tokenIdToToken[tokenId];
        uint256 minerIndex = token.index;
        miners[minerIndex].mintedCount -= token.amount;
    }

    // numOfMiners should be multiplied by 4
    function addMiner(string memory minerType_, uint256 hashRate_, uint256 numOfMiner_, uint256 price_) external onlyOwner {
        Miner memory miner = Miner({minerType: minerType_, hashRate: hashRate_, numOfMiner: numOfMiner_ * 4, price: price_, mintedCount: 0});
        miners[totalMiner] = miner;
        totalMiner++;
    }

    // numOfMiners should be multiplied by 4
    function updateMiner(uint256 index, string memory minerType, uint256 hashRate, uint256 numOfMiner, uint256 price) external onlyOwner {
        require(index < totalMiner, "index out of bounds");
        miners[index].minerType = minerType;
        miners[index].hashRate = hashRate;
        miners[index].numOfMiner = numOfMiner * 4;
        miners[index].price = price;
    }

    // num 1 is equal to 1 / 4, and 2 is equal to 2 / 4
    function buyMiner(uint256 index, uint256 num) external payable nonReentrant {
        require(index < totalMiner, "index out of bounds");
        require(num > 0, "invalid amount");
        Miner memory miner = miners[index];
        uint256 currentPrice = getLatestPrice();
        require(msg.value >= (miner.price * currentPrice * num / 4), "Not enough money");

        uint256 minted = miners[index].mintedCount;
        require(minted + num <= miner.numOfMiner, "Exceed available number of miners");

        tokenIds.increment();
        _safeMint(msg.sender, tokenIds.current());

        Token memory token = Token({index: index, amount: num, mintTime: block.timestamp, totalEarning: 0});

        tokenIdToToken[tokenIds.current()] = token;
        miners[index].mintedCount += num;
    }

    function distributeReward(uint256 totalReward) external onlyOwner {
        require(lastDistributionTime > 0, "reward start time not set");
        require(block.timestamp - lastDistributionTime >= REWARD_DISTRIBUTE_PERIOD, "not reached distribution period yet");
        usdcToken = IERC20(usdcAddress);
        uint256 totalPower;

        for (uint256 i = 0; i < totalMiner; i++) {
            totalPower += miners[i].hashRate * miners[i].numOfMiner / 4;
        }

        Token memory token;
        for (uint256 i = 0; i < totalSupply(); i++) {
            if (isExpired(i + 1))
                continue;
            token = tokenIdToToken[i + 1];
            uint256 minerIndex = token.index;
            
            uint256 rewardOfToken = (totalReward * miners[minerIndex].hashRate * token.amount * 2) / (3 * 4 * totalPower);
            if (token.mintTime > lastDistributionTime + REWARD_DISTRIBUTE_PERIOD)
                continue;
            if (token.mintTime > lastDistributionTime) {
                rewardOfToken = rewardOfToken * (REWARD_DISTRIBUTE_PERIOD - (token.mintTime - lastDistributionTime)) / REWARD_DISTRIBUTE_PERIOD;
            }
            bool result = usdcToken.transfer(ownerOf(i + 1), rewardOfToken);
            require(result, "failed to transfer reward");

            tokenIdToToken[i + 1].totalEarning += rewardOfToken;
        }
        lastDistributionTime += REWARD_DISTRIBUTE_PERIOD;
    }

    // Function to withdraw all Ether from this contract.
    function withdraw() external onlyOwner{
        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function setBaseUri(string memory baseUri) external onlyOwner {
        baseTokenUri = baseUri;
    }
}
