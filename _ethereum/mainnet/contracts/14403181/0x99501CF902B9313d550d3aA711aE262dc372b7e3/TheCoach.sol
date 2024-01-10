// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC2981.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./LinkTokenInterface.sol";
import "./VRFConsumerBaseV2.sol";

contract TheCoach is ERC721, Ownable, Pausable, IERC2981, VRFConsumerBaseV2 {
    using Strings for uint256;
    using Address for address payable;

    enum TokenType {
        WarmUp,
        Match,
        Celebration
    }

    // The royalties taken on each sale. Can range from 0 to 10000
    // 500 => 5%
    uint16 internal constant ROYALTIES = 500;

    //NFT price in USD
    uint256 private constant PRICE_IN_USD = 450;

    address public fundsRecipient = 0x1D2720071D79B8D472de0fBe06c7EC8B1278fCFB;

    //team address
    address private constant TEAM_ADDRESS =
        0x5F5D71bf86b805Ae3f3df27B43EBa3A8F3Caf18A;

    // How many premints are left
    uint256 public supplyLeftToPremint = 2000;

    //current minted supply
    uint256 public totalSupply;

    string public baseURI = "";

    uint256 public currentIndex;

    uint256 public randomStart;

    uint256 public randomIncrementor;

    AggregatorV3Interface private ethToUsdFeed;

    // Address => how many tokens this address will receive on the next batch mint
    mapping(address => uint256) public preMintAllowance;

    // Addresses that have paid to get a token in the next batch mint
    address[] public preMintAddresses;

    VRFCoordinatorV2Interface private vrfCoordinator;
    LinkTokenInterface private linkToken;

    // Your subscription ID.
    uint64 private s_subscriptionId;

    event RandomNumbersReceived(uint256 start, uint256 incrementor);

    bytes32 private keyHash;

    constructor(
        address _ethToUsdPriceFeed,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint64 subscriptionId
    ) ERC721("The Coach", "COACH") VRFConsumerBaseV2(_vrfCoordinator) {
        ethToUsdFeed = AggregatorV3Interface(_ethToUsdPriceFeed);
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        linkToken = LinkTokenInterface(_linkToken);
        keyHash = _keyHash;
        s_subscriptionId = subscriptionId;
    }

    function preMint(uint256 amount) external payable {
        preMintFor(msg.sender, amount);
    }

    function preMintFor(address addr, uint256 amount)
        public
        payable
        whenNotPaused
    {
        require(amount > 0 && amount <= 50, "Wrong amount");
        // We check there is enough supply left
        require(supplyLeftToPremint > 0, "No supply left");
        amount = amount > supplyLeftToPremint ? supplyLeftToPremint : amount;
        require(preMintAllowance[addr] + amount <= 50, "More than 50NFTs");

        uint256 weiPrice = getWeiPrice();
        uint256 minTotalPrice = (weiPrice * amount * 995) / 1000;
        require(msg.value >= minTotalPrice, "Not enough ETH");

        // Add the address to the list if it's not in there yet
        if (preMintAllowance[addr] == 0) {
            preMintAddresses.push(addr);
        }

        // Assign the number of token to the sender
        preMintAllowance[addr] += amount;
        // Remove the newly acquired tokens from the supply left before next batch mint
        supplyLeftToPremint -= amount;
        uint256 actualPrice = amount * weiPrice;
        if (msg.value > actualPrice) {
            uint256 change = msg.value - actualPrice;
            if (change > weiPrice / 40) {
                payable(msg.sender).sendValue(change);
            }
        }
    }

    /**
     * @param count - number of premint addresses to drop
     */
    function batchMint(uint256 count) external onlyOwner {
        require(supplyLeftToPremint == 0, "ongoing premint");
        require(randomIncrementor != 0, "Random not initialized");
        for (uint256 i = 0; i < count; i++) {
            uint256 length = preMintAddresses.length;
            if (length == 0) {
                return;
            }
            address to = preMintAddresses[length - 1];
            uint256 allowance = preMintAllowance[to];
            for (uint256 j = 0; j < allowance; j++) {
                uint256 tokenId = getCurrentTokenId();
                _owners[tokenId] = to;
                emit Transfer(address(0), to, tokenId);
            }
            _balances[to] += allowance;
            totalSupply += allowance;
            preMintAddresses.pop();
            delete preMintAllowance[to];
        }
    }

    function requestRandomNumber() external onlyOwner {
        vrfCoordinator.requestRandomWords(
            keyHash,
            s_subscriptionId,
            // 10 confirmations
            10,
            // up to 1 million gas
            1000000,
            // 2 random numbers
            2
        );
    }

    function fulfillRandomWords(uint256, uint256[] memory _randomWords)
        internal
        override
    {
        // Limit the size of the starting point
        randomStart = _randomWords[0] % 1000000;
        // Limit the size of the incrementor
        randomIncrementor = _randomWords[1] % 100000;
        if (randomIncrementor % 2011 <= 1) {
            randomIncrementor += 10;
        }
        emit RandomNumbersReceived(randomStart, randomIncrementor);
    }

    /**
     * @dev Set the base URI of every token URI
     */
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    /**
     * @dev Set the recipient of most of the funds of this contract
     * and all of the royalties
     */
    function setFundsRecipient(address addr) external onlyOwner {
        require(addr != address(0), "Invalid address");
        fundsRecipient = addr;
    }

    /**
     * @dev Retrieve the funds of the sale
     */
    function retrieveFunds() external {
        require(
            msg.sender == fundsRecipient ||
                msg.sender == TEAM_ADDRESS ||
                msg.sender == owner(),
            "Not allowed"
        );
        uint256 teamBalance = (address(this).balance * 125) / 1000;
        // Sends 12.5% to the team...
        payable(TEAM_ADDRESS).sendValue(teamBalance);
        // ...and sends all the rest to the recipient address
        payable(fundsRecipient).sendValue(address(this).balance);
    }

    /**
     * @dev Get the URI for a given token
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        // Concatenate the baseURI and the tokenId as the tokenId should
        // just be appended at the end to access the token metadata
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = fundsRecipient;
        // We divide it by 10000 as the royalties can change from
        // 0 to 10000 representing percents with 2 decimals
        royaltyAmount = (salePrice * ROYALTIES) / 10000;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Gets the current price of the token in wei according
     * to a fixed price in USD
     */
    function getWeiPrice() public view returns (uint256) {
        uint256 dollarByEth = getDollarByEth();
        uint256 power = 18 + ethToUsdFeed.decimals();
        uint256 weiPrice = (PRICE_IN_USD * 10**power) / dollarByEth;
        return weiPrice;
    }

    function getCurrentTokenId() private returns (uint256) {
        uint256 tokenId;
        do {
            tokenId =
                ((randomIncrementor * currentIndex++) + randomStart) %
                2011;
        } while (tokenId >= 2000);
        return tokenId;
    }

    /**
    @dev Gets current dollar price for a single ETH (10^18 wei)
    */
    function getDollarByEth() private view returns (uint256) {
        (, int256 dollarByEth, , , ) = ethToUsdFeed.latestRoundData();
        return uint256(dollarByEth);
    }

    /**
     * @dev Get the type of NFT (either Warm up, Match or Celebration) according to the id
     * of the token
     */
    function getTokenType(uint256 tokenId) external view returns (TokenType) {
        require(tokenId < 2000, "Wrong id");
        if (tokenId < 5) {
            return TokenType.Celebration;
        } else if (tokenId < 275) {
            return TokenType.Match;
        } else {
            return TokenType.WarmUp;
        }
    }
}
