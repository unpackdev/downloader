// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";

contract Verb is ERC721A, Ownable {
    uint256 public constant RESERVE_SUPPLY = 400;
    uint256 public constant MAX_SUPPLY = 7500;
    uint256 public constant DUTCH_SUPPLY = 5100;

    uint256 public constant MINT_LIMIT = 5;
    uint256 public constant DUTCH_MINT_LIMIT = 3;
    uint256 public constant PRESALE_MINT_LIMIT = 1;

    bool _revealed = false;

    string private baseURI = "";

    bytes32 presaleRoot;

    uint256 public publicSaleStartTime;
    uint256 public presaleStartTime;
    mapping(address => uint256) addressBlockBought;

    address public constant ADDRESS_1 =
        0x7bAdC616Fb80D3937677F9c2a4bf837Dea2aF8EC; //Owner
    address public constant ADDRESS_2 =
        0x188A3c584F0dE9ee0eABe04316A94A41F0867C0C; //ZL

    address signer;
    mapping(bytes32 => bool) public usedDigests;

    //DA CONFIGURATION
    uint256 public dutchAuctionStartTime;
    uint256 public dutchAuctionEndTime;
    uint256 public refundEndTime;
    uint256 constant STARTING_PRICE_DA = 0.3 ether;
    uint256 constant ENDING_PRICE_DA = 0.1 ether;
    uint256 constant PRICE_DECREMENT = 0.04 ether;
    uint256 constant DECREMENT_INTERVAL = 30 minutes;
    uint256 constant DUTCH_AUCTION_DURATION = 180 minutes;
    uint256 constant MAX_STEP = 5;

    uint256 public LAST_PRICE_DA = STARTING_PRICE_DA;

    uint256 public dutchMints = 0;
    struct UserPurchaseInfo {
        uint256 dutchSpent;
        uint256 dutchMinted;
        uint256 presaleMinted;
        bool claimed;
    }

    mapping(address => UserPurchaseInfo) public userPurchase;

    constructor(
        uint256 _dutchAuctionStartTime,
        uint256 _presaleStartTime,
        uint256 _publicSaleStartTime,
        uint256 _refundEndTime
    ) ERC721A("Verb", "VERB", RESERVE_SUPPLY, MAX_SUPPLY) {
        require(
            _dutchAuctionStartTime + DUTCH_AUCTION_DURATION < _presaleStartTime,
            "DA_GREATER_THAN_PRESALE_TIME"
        );
        require(
            _presaleStartTime < _publicSaleStartTime,
            "PRESALE_GREATER_THAN_PUBLIC_SALE_TIME"
        );
        dutchAuctionStartTime = _dutchAuctionStartTime;
        dutchAuctionEndTime = _dutchAuctionStartTime + DUTCH_AUCTION_DURATION;
     require(_refundEndTime > dutchAuctionEndTime, "REFUND_GREATER_THAN_DA_END");
        presaleStartTime = _presaleStartTime;
        publicSaleStartTime = _publicSaleStartTime;
        refundEndTime = _refundEndTime;

    }

    modifier isSecured(uint8 mintType) {
        require(
            addressBlockBought[msg.sender] < block.timestamp,
            "CANNOT_MINT_ON_THE_SAME_BLOCK"
        );
        require(tx.origin == msg.sender, "CONTRACTS_NOT_ALLOWED_TO_MINT");

        if (mintType == 1) {
            require(isPublicSaleActive(), "PUBLIC_MINT_IS_NOT_YET_ACTIVE");
        }

        if (mintType == 2) {
            require(isPresaleActive(), "PRESALE_MINT_IS_NOT_YET_ACTIVE");
        }
        if (mintType == 3) {
            require(isDutchAuctionActive(), "DUTCH_AUCTION_IS_NOT_YET_ACTIVE");
        }

        _;
    }

    //Essential
    function mint(
        uint256 numberOfTokens,
        uint64 expireTime,
        bytes memory sig
    ) external payable isSecured(1) {
        bytes32 digest = keccak256(
            abi.encodePacked(msg.sender, expireTime, numberOfTokens)
        );
        require(isAuthorized(sig, digest), "CONTRACT_MINT_NOT_ALLOWED");
        require(block.timestamp <= expireTime, "EXPIRED_SIGNATURE");
        require(!usedDigests[digest], "SIGNATURE_LOOPING_NOT_ALLOWED");
        require(
            numberOfTokens + totalSupply() <= MAX_SUPPLY,
            "NOT_ENOUGH_SUPPLY"
        );
        require(
            numberMinted(msg.sender) + numberOfTokens <= MINT_LIMIT,
            "EXCEED_MINT_LIMIT"
        );
        require(msg.value == LAST_PRICE_DA * numberOfTokens, "INVALID_AMOUNT");
        addressBlockBought[msg.sender] = block.timestamp;
        usedDigests[digest] = true;
        _safeMint(msg.sender, numberOfTokens);
    }

    function presaleMint(bytes32[] memory proof) external payable isSecured(2) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, presaleRoot, leaf), "PROOF_INVALID");
        require(
            numberMinted(msg.sender) + 1 <= MINT_LIMIT,
            "EXCEED_MINT_LIMIT"
        );
        require(
            userPurchase[msg.sender].presaleMinted + 1 <= PRESALE_MINT_LIMIT,
            "EXCEED_PRESALE_MINT_LIMIT"
        );
        require(
            1 + totalSupply() <= MAX_SUPPLY,
            "NOT_ENOUGH_SUPPLY"
        );
        require(
            msg.value == (LAST_PRICE_DA / 2),
            "INVALID_AMOUNT"
        );
        addressBlockBought[msg.sender] = block.timestamp;
        userPurchase[msg.sender].presaleMinted += 1;
        _safeMint(msg.sender, 1);
    }

    function devMint(uint256 numberOfTokens) external onlyOwner {
        require(
            numberOfTokens + totalSupply() <= MAX_SUPPLY,
            "NOT_ENOUGH_SUPPLY"
        );
        require(
            numberOfTokens + numberMinted((msg.sender)) <= RESERVE_SUPPLY,
            "NOT_ENOUGH_RESERVE_SUPPLY"
        );
        _safeMint(msg.sender, numberOfTokens);
    }

    //Essential
    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    function reveal(bool revealed, string calldata _baseURI) public onlyOwner {
        _revealed = revealed;
        baseURI = _baseURI;
    }

    //Essential

    function withdraw() external onlyOwner {
        require(
            block.timestamp >= refundEndTime,
            "MUST_WAIT_FOR_REFUND_PERIOD_TO_END"
        );
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(ADDRESS_2).transfer((balance * 700) / 10000);
        payable(ADDRESS_1).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (_revealed) {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        } else {
            return string(abi.encodePacked(baseURI));
        }
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setPreSaleRoot(bytes32 _presaleRoot) external onlyOwner {
        presaleRoot = _presaleRoot;
    }


    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function isAuthorized(bytes memory sig, bytes32 digest)
        private
        view
        returns (bool)
    {
        return ECDSA.recover(digest, sig) == signer;
    }

    function setTimestamps(
        uint256 _dutchAuctionStartTime,
        uint256 _presaleStartTime,
        uint256 _publicSaleStartTime,
        uint256 _refundEndTime
    ) external onlyOwner {
        require(
            _dutchAuctionStartTime + DUTCH_AUCTION_DURATION < _presaleStartTime,
            "DA_GREATER_THAN_PRESALE_TIME"
        );
        require(
            _presaleStartTime < _publicSaleStartTime,
            "PRESALE_GREATER_THAN_PUBLIC_SALE_TIME"
        );
        dutchAuctionStartTime = _dutchAuctionStartTime;
        dutchAuctionEndTime = _dutchAuctionStartTime + DUTCH_AUCTION_DURATION;
        require(
            _refundEndTime > dutchAuctionEndTime,
            "REFUND_GREATER_THAN_DA_END"
        );
        presaleStartTime = _presaleStartTime;
        publicSaleStartTime = _publicSaleStartTime;
        refundEndTime = _refundEndTime;
    }

    function isPublicSaleActive() public view returns (bool) {
        return block.timestamp >= publicSaleStartTime;
    }

    function isPresaleActive() public view returns (bool) {
        return
            block.timestamp >= presaleStartTime &&
            block.timestamp < publicSaleStartTime;
    }

    //ALL DUTCH FUNCTIONS
    function isDutchAuctionActive() public view returns (bool) {
        return
            block.timestamp >= dutchAuctionStartTime &&
            block.timestamp < dutchAuctionEndTime;
    }

    function dutchMint(uint256 numberOfTokens) external payable isSecured(3) {
        require(
            numberOfTokens + totalSupply() <= MAX_SUPPLY,
            "NOT_ENOUGH_SUPPLY"
        );
        require(
            numberOfTokens + dutchMints <= DUTCH_SUPPLY,
            "NOT_ENOUGH_DUTCH_SUPPLY"
        );
        require(
            numberMinted(msg.sender) + numberOfTokens <= MINT_LIMIT,
            "EXCEED_MINT_LIMIT"
        );
        require(
            userPurchase[msg.sender].dutchMinted+ numberOfTokens <= DUTCH_MINT_LIMIT,
            "EXCEED_DUTCH_MINT_LIMIT"
        );
        uint256 mintPrice = currentDAPrice();
        require(msg.value >= mintPrice * numberOfTokens, "INVALID_AMOUNT");
        addressBlockBought[msg.sender] = block.timestamp;
        userPurchase[msg.sender].dutchSpent += msg.value;
        userPurchase[msg.sender].dutchMinted += numberOfTokens;
        LAST_PRICE_DA = mintPrice;
        dutchMints += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function currentDAPrice() public view returns (uint256) {
        if(dutchAuctionStartTime > block.timestamp) {
            return STARTING_PRICE_DA;
        }
        uint256 timeElapsed = block.timestamp - dutchAuctionStartTime;
        uint256 step = timeElapsed / DECREMENT_INTERVAL;

        if (step >= MAX_STEP) {
            return ENDING_PRICE_DA;
        }

        return STARTING_PRICE_DA - (PRICE_DECREMENT * step);
    }

    function dutchRefund() external {
        require(
            !userPurchase[msg.sender].claimed,
            "ALREADY_CLAIMED_REFUND"
        );
        require(
            userPurchase[msg.sender].dutchMinted > 0,
            "NO_DUTCH_PURCHASE"
        );
        require(
            block.timestamp >= dutchAuctionEndTime,
            "DUTCH_AUCTION_NOT_ENDED"
        );
        require(
            block.timestamp >= presaleStartTime,
            "REFUND_PERIOD_NOT_STARTED"
        );
        require(block.timestamp < refundEndTime, "REFUND_PERIOD_FINISHED");
        uint256 refund = userPurchase[msg.sender].dutchSpent -
            (LAST_PRICE_DA * userPurchase[msg.sender].dutchMinted);
        require(refund > 0, "NO_REFUNDABLE_AMOUNT");
        userPurchase[msg.sender].claimed = true;
        payable(msg.sender).transfer(refund);
    }

    function refundAmount() external view returns (uint256) {
        return
            userPurchase[msg.sender].dutchSpent -
            (LAST_PRICE_DA * userPurchase[msg.sender].dutchMinted);
    }
}
