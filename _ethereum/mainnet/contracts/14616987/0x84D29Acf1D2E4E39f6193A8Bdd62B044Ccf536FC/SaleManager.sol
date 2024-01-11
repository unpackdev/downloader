pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./AggregatorV3Interface.sol";


contract SaleManager is ReentrancyGuard {
  using SafeERC20 for IERC20;

  AggregatorV3Interface priceOracle;
  IERC20 public immutable paymentToken;
  uint8 public immutable paymentTokenDecimals;

  struct Sale {
    address payable seller; // the address that will receive sale proceeds
    bytes32 merkleRoot; // the merkle root used for proving access
    address claimManager; // address where purchased tokens can be claimed (optional)
    uint256 saleBuyLimit;  // max tokens that can be spent in total
    uint256 userBuyLimit;  // max tokens that can be spent per user
    uint startTime; // the time at which the sale starts
    uint endTime; // the time at which the sale will end, regardless of tokens raised
    string name; // the name of the asset being sold, e.g. "New Crypto Token"
    string symbol; // the symbol of the asset being sold, e.g. "NCT"
    uint256 price; // the price of the asset (eg if 1.0 NCT == $1.23 of USDC: 1230000)
    uint8 decimals; // the number of decimals in the asset being sold, e.g. 18
    uint256 totalSpent; // total purchases denominated in payment token
    mapping(address => uint256) spent;
  }

  mapping (bytes32 => Sale) public sales;

  // global metrics
  uint256 public saleCount = 0;
  uint256 public totalSpent = 0;

  event NewSale(
    bytes32 indexed saleId,
    bytes32 indexed merkleRoot,
    address indexed seller,
    uint256 saleBuyLimit,
    uint256 userBuyLimit,
    uint startTime,
    uint endTime,
    string name,
    string symbol,
    uint256 price,
    uint8 decimals
  );

  event UpdateStart(bytes32 indexed saleId, uint startTime);
  event UpdateEnd(bytes32 indexed saleId, uint endTime);
  event UpdateMerkleRoot(bytes32 indexed saleId, bytes32 merkleRoot);
  event Buy(bytes32 indexed saleId, address indexed buyer, uint256 value, bool native, bytes32[] proof);
  event RegisterClaimManager(bytes32 indexed saleId, address indexed claimManager);

  constructor(
    address _paymentToken,
    uint8 _paymentTokenDecimals,
    address _priceOracle
  ) {
    paymentToken = IERC20(_paymentToken);
    paymentTokenDecimals = _paymentTokenDecimals;
    priceOracle = AggregatorV3Interface(_priceOracle);
  }

  modifier validSale (bytes32 saleId) {
    require(
      sales[saleId].seller != address(0),
      "invalid sale id"
    );
    _;
  }

  modifier isSeller(bytes32 saleId) {
    require(
      sales[saleId].seller == msg.sender,
      "must be seller"
    );
    _;
  }

  modifier canAccessSale(bytes32 saleId, bytes32[] calldata proof) {
    // make sure the buyer is an EOA
    require((msg.sender == tx.origin), "Must buy with an EOA");

    // If the merkle root is non-zero this is a private sale and requires a valid proof
    if (sales[saleId].merkleRoot != bytes32(0)) {
      require(
        this._isAllowed(
          sales[saleId].merkleRoot,
          msg.sender,
          proof
        ) == true,
        "invalid access proof for this private sale"
      );
    }
    _;
  }

  modifier requireOpen(bytes32 saleId) {
    require(block.timestamp > sales[saleId].startTime, "sale not started yet");
    require(block.timestamp < sales[saleId].endTime, "sale ended");
    require(sales[saleId].totalSpent < sales[saleId].saleBuyLimit, "sale over");
    _;
  }

  // Get current price from chainlink oracle
  function getLatestPrice() public view returns (uint) {
    (
        uint80 roundID,
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
    ) = priceOracle.latestRoundData();

    require(price > 0, "negative price");
    return uint(price);
  }

  // Accessor functions
  function getSeller(bytes32 saleId) public validSale(saleId) view returns(address) {
    return(sales[saleId].seller);
  }

  function getMerkleRoot(bytes32 saleId) public validSale(saleId) view returns(bytes32) {
    return(sales[saleId].merkleRoot);
  }

  function getPriceOracle() public view returns (address) {
    return address(priceOracle);
  }

  function getClaimManager(bytes32 saleId) public validSale(saleId) view returns(address) {
    return (sales[saleId].claimManager);
  }


  function getSaleBuyLimit(bytes32 saleId) public validSale(saleId) view returns(uint256) {
    return(sales[saleId].saleBuyLimit);
  }

  function getUserBuyLimit(bytes32 saleId) public validSale(saleId) view returns(uint256) {
    return(sales[saleId].userBuyLimit);
  }

  function getStartTime(bytes32 saleId) public validSale(saleId) view returns(uint) {
    return(sales[saleId].startTime);
  }

  function getEndTime(bytes32 saleId) public validSale(saleId) view returns(uint) {
    return(sales[saleId].endTime);
  }

  function getName(bytes32 saleId) public validSale(saleId) view returns(string memory) {
    return(sales[saleId].name);
  }

  function getSymbol(bytes32 saleId) public validSale(saleId) view returns(string memory) {
    return(sales[saleId].symbol);
  }

  function getPrice(bytes32 saleId) public validSale(saleId) view returns(uint) {
    return(sales[saleId].price);
  }

  function getDecimals(bytes32 saleId) public validSale(saleId) view returns(uint256) {
    return (sales[saleId].decimals);
  }

  function getTotalSpent(bytes32 saleId) public validSale(saleId) view returns(uint256) {
    return (sales[saleId].totalSpent);
  }

  function spentToBought(bytes32 saleId, uint256 spent) public view returns (uint256) {
    // Convert tokens spent (e.g. 10,000,000 USDC = $10) to tokens bought (e.g. 8.13e18) at a price of $1.23/NCT
    // convert an integer value of tokens spent to an integer value of tokens bought
    return (spent * 10 ** sales[saleId].decimals ) / (sales[saleId].price);
  }

  function nativeToPaymentToken(uint256 nativeValue) public view returns (uint256) {
    // convert a payment in the native token (eg ETH) to an integer value of the payment token
    return (nativeValue * getLatestPrice() * 10 ** paymentTokenDecimals) / (10 ** (priceOracle.decimals() + 18));
  }

  function getSpent(
      bytes32 saleId,
      address userAddress
    ) public validSale(saleId) view returns(uint256) {
    // returns the amount spent by this user in paymentToken
    return(sales[saleId].spent[userAddress]);
  }

  function getBought(
      bytes32 saleId,
      address userAddress
    ) public validSale(saleId) view returns(uint256) {
    // returns the amount bought by this user in the new token being sold
    return(spentToBought(saleId, sales[saleId].spent[userAddress]));
  }

  function isOpen(bytes32 saleId) public validSale(saleId) view returns(bool) {
    // is the sale currently open?
    return(
      block.timestamp > sales[saleId].startTime
      && block.timestamp < sales[saleId].endTime
      && sales[saleId].totalSpent < sales[saleId].saleBuyLimit
    );
  }

  function isOver(bytes32 saleId) public validSale(saleId) view returns(bool) {
    // is the sale permanently over?
    return(
      block.timestamp >= sales[saleId].endTime || sales[saleId].totalSpent >= sales[saleId].saleBuyLimit
    );
  }

  /**
  sale setup and config
  - the address calling this method is the seller: all payments are sent to this address
  - only the seller can change the sale start and end time
  */
  function newSale(
    bytes32 merkleRoot,
    uint256 saleBuyLimit,
    uint256 userBuyLimit,
    uint startTime,
    uint endTime,
    string calldata name,
    string calldata symbol,
    uint256 price,
    uint8 decimals
  ) public returns(bytes32) {
    require(startTime <= 4102444800, "max: 4102444800 (Jan 1 2100)");
    require(endTime <= 4102444800, "max: 4102444800 (Jan 1 2100)");
    require(startTime < endTime, "sale must start before it ends");
    require(endTime > block.timestamp, "sale must end in future");
    require(userBuyLimit <= saleBuyLimit, "userBuyLimit cannot exceed saleBuyLimit");
    require(userBuyLimit > 0, "userBuyLimit must be > 0");
    require(saleBuyLimit > 0, "saleBuyLimit must be > 0");

    // Generate a reorg-resistant sale ID
    bytes32 saleId = keccak256(abi.encodePacked(
      merkleRoot,
      msg.sender,
      saleBuyLimit,
      userBuyLimit,
      startTime,
      endTime,
      name,
      symbol,
      price,
      decimals
    ));

    // This ensures the Sale struct wasn't already created (msg.sender will never be the zero address)
    require(sales[saleId].seller == address(0), "a sale with these parameters already exists");

    Sale storage s = sales[saleId];

    s.merkleRoot = merkleRoot;
    s.seller = payable(msg.sender);
    s.saleBuyLimit = saleBuyLimit;
    s.userBuyLimit = userBuyLimit;
    s.startTime = startTime;
    s.endTime = endTime;
    s.name = name;
    s.symbol = symbol;
    s.price = price;
    s.decimals = decimals;

    saleCount++;

    emit NewSale(saleId,
      s.merkleRoot,
      s.seller,
      s.saleBuyLimit,
      s.userBuyLimit,
      s.startTime,
      s.endTime,
      s.name,
      s.symbol,
      s.price,
      s.decimals
    );

    return saleId;
  }

  function setStart(bytes32 saleId, uint startTime) public validSale(saleId) isSeller(saleId) {
    // seller can update start time until the sale starts
    require(block.timestamp < sales[saleId].endTime, "disabled after sale closes");
    require(startTime < sales[saleId].endTime, "sale start must precede end");
    require(startTime <= 4102444800, "max: 4102444800 (Jan 1 2100)");

    sales[saleId].startTime = startTime;
    emit UpdateStart(saleId, startTime);
  }

  function setEnd(bytes32 saleId, uint endTime) public validSale(saleId) isSeller(saleId){
    // seller can update end time until the sale ends
    require(block.timestamp < sales[saleId].endTime, "disabled after sale closes");
    require(endTime > block.timestamp, "sale must end in future");
    require(endTime <= 4102444800, "max: 4102444800 (Jan 1 2100)");
    require(sales[saleId].startTime < endTime, "sale must start before it ends");

    sales[saleId].endTime = endTime;
    emit UpdateEnd(saleId, endTime);
  }

  function setMerkleRoot(bytes32 saleId, bytes32 merkleRoot) public validSale(saleId) isSeller(saleId){
    require(!isOpen(saleId) && !isOver(saleId), "cannot set merkle root once sale opens");
    sales[saleId].merkleRoot = merkleRoot;
    emit UpdateMerkleRoot(saleId, merkleRoot);
  }

  function _isAllowed(
      bytes32 root,
      address account,
      bytes32[] calldata proof
  ) external pure returns (bool) {
    // check if the account is in the merkle tree
    bytes32 leaf = keccak256(abi.encodePacked(account));
    if (MerkleProof.verify(proof, root, leaf)) {
      return true;
    }

    return false;
  }

  // pay with the payment token (eg USDC)
  function buy(
    bytes32 saleId,
    uint256 tokenQuantity,
    bytes32[] calldata proof
  ) public validSale(saleId) requireOpen(saleId) canAccessSale(saleId, proof) nonReentrant {
    // make sure the purchase would not break any sale limits
    require(
      tokenQuantity + sales[saleId].spent[msg.sender] <= sales[saleId].userBuyLimit,
      "purchase exceeds your limit"
    );

    require(
      tokenQuantity + sales[saleId].totalSpent <= sales[saleId].saleBuyLimit,
      "purchase exceeds sale limit"
    );

    require(paymentToken.allowance(msg.sender, address(this)) >= tokenQuantity, "allowance too low");

    // move the funds
    paymentToken.safeTransferFrom(msg.sender, sales[saleId].seller, tokenQuantity);

    // effects after interaction: we need a reentrancy guard
    sales[saleId].spent[msg.sender] += tokenQuantity;
    sales[saleId].totalSpent += tokenQuantity;
    totalSpent += tokenQuantity;

    emit Buy(saleId, msg.sender, tokenQuantity, false, proof);
  }

  // pay with the native token
  function buy(
    bytes32 saleId,
    bytes32[] calldata proof
  ) public payable validSale(saleId) requireOpen(saleId) canAccessSale(saleId, proof) nonReentrant {
    // convert to the equivalent payment token value from wei
    uint256 tokenQuantity = nativeToPaymentToken(msg.value);

    // make sure the purchase would not break any sale limits
    require(
      tokenQuantity + sales[saleId].spent[msg.sender] <= sales[saleId].userBuyLimit,
      "purchase exceeds your limit"
    );

    require(
      tokenQuantity + sales[saleId].totalSpent <= sales[saleId].saleBuyLimit,
      "purchase exceeds sale limit"
    );

    // forward the eth to the seller
    sales[saleId].seller.transfer(msg.value);

    // account for the purchase in equivalent payment token value
    sales[saleId].spent[msg.sender] += tokenQuantity;
    sales[saleId].totalSpent += tokenQuantity;
    totalSpent += tokenQuantity;

    // flag this payment as using the native token
    emit Buy(saleId, msg.sender, tokenQuantity, true, proof);
  }

  // Tell users where they can claim tokens
  function registerClaimManager(bytes32 saleId, address claimManager) public validSale(saleId) isSeller(saleId) {
    require(claimManager != address(0), "Claim manager must be a non-zero address");
    sales[saleId].claimManager = claimManager;
    emit RegisterClaimManager(saleId, claimManager);
  }

  function recoverERC20(bytes32 saleId, address tokenAddress, uint256 tokenAmount) public isSeller(saleId) {
    IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
  }
}
