// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./Pausable.sol";
import "./ChainlinkClient.sol";

/// @notice Contract for facilitating a whitelisted airdrop and token sale
contract MembershipContract is Pausable, ChainlinkClient {
  using Chainlink for Chainlink.Request;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /*///////////////////////////////////////////////////////////////
                          IMMUTABLE STORAGE
  //////////////////////////////////////////////////////////////*/

  bytes32 public immutable merkleRoot;

  /*///////////////////////////////////////////////////////////////
                          MUTABLE STORAGE
  //////////////////////////////////////////////////////////////*/

  address public owner;
  address public usdcTokenContract;
  address public gcrTokenContract;
  address public linkTokenContract;

  IERC20 public usdcToken;
  IERC20 public gcrToken;
  IERC20 public linkToken;

  uint256 public rate; // rate of exchange between GCR and USDC
  uint256 public airdropAmount; // airdrop amount that qualified members can claim

  // various tiers
  uint256 public proTier;
  uint256 public midTier;
  uint256 public baseTier;

  // chainlink oracle params
  address private oracle;
  bytes32 private jobId;
  uint256 private oracleFee;
  string public priceFeedURI;
  string public priceFeedPath;

  // need parameters around validity window of sale (start + end times). also should be able to be adjusted by owner

  // mapping for eligible airdrop recipients
  mapping (address => bool) private _hasClaimedAirdrop;

  // mapping for those who are entitled to purchasing tokens at a discount
  mapping (address => uint256) private _purchasedAmount;

  /*///////////////////////////////////////////////////////////////
                                ERRORS
  //////////////////////////////////////////////////////////////*/

  /// @notice Thrown if address has already claimed
  error AlreadyClaimed();
  /// @notice Thrown if address/amount are not part of Merkle tree
  error NotInMerkle();

  /*///////////////////////////////////////////////////////////////
                                EVENTS
  //////////////////////////////////////////////////////////////*/

  event ClaimAirdrop(address indexed claimant, uint256 amount);
  event Purchase(address indexed claimaint, uint256 amount);
  event SetOwner(address indexed prevOwner, address indexed newOwner);
  event SetRate(address indexed owner, uint256 oldRate, uint256 newRate);
  event WithdrawAll(address indexed owner);
  event WithdrawToken(address indexed owner, address indexed token);

  /*///////////////////////////////////////////////////////////////
                              MODIFIERS
  //////////////////////////////////////////////////////////////*/

  modifier onlyOwner() {
    require(owner == msg.sender, "Function is only callable by the owner");
    _;
  }

  /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  // @dev assume we initialize this contract with arrays with addresses <> balances matched up at the same index,
  // though this may be costly
  constructor(
    bytes32 _merkleRoot,
    address _usdcTokenContract,
    address _gcrTokenContract,
    address _linkTokenContract,
    address _oracle,
    string memory _jobId,
    uint256 _oracleFee,
    string memory _priceFeedURI,
    string memory _priceFeedPath
  ) {
    owner = msg.sender;
    merkleRoot = _merkleRoot;

    usdcTokenContract = _usdcTokenContract;
    usdcToken = IERC20(_usdcTokenContract);
    gcrTokenContract = _gcrTokenContract;
    gcrToken = IERC20(_gcrTokenContract);
    linkTokenContract = _linkTokenContract;
    linkToken = IERC20(_linkTokenContract);

    rate = 350; // # USDC required for 1 GCR in base units
    airdropAmount = 1600000; // 160 GCR
    proTier = 20000000; // 2000 GCR
    midTier = 7000000; // 700 GCR
    baseTier = 1000000; // 100 GCR

    // Oracle setup
    oracle = _oracle;
    jobId = stringToBytes32(_jobId);
    oracleFee = _oracleFee;
    priceFeedURI = _priceFeedURI;
    priceFeedPath = _priceFeedPath;
    setChainlinkToken(_linkTokenContract);
  }

  /*///////////////////////////////////////////////////////////////
                    AIRDROP + PURCHASE FUNCTIONALITY
  //////////////////////////////////////////////////////////////*/

  // @dev Claim airdrop, only for those with > 2000 balance. 
  // Note: only claimable to msg.sender so that people can't claim airdrops on behalf of others
  // examples of how to do such crowdsales: https://docs.openzeppelin.com/contracts/2.x/crowdsales
  // @return success (bool)
  function claimAirdrop(uint256 snapshotAmount, bytes32[] memory proof) public whenNotPaused returns (bool success){
    require(!checkAirdropClaimed(msg.sender), "Airdrop already claimed");
    require(_purchasedAmount[msg.sender] == 0, "You've begun purchasing tokens"); // this should not be possible, per logic
    require(verifyMerkleProof(msg.sender, snapshotAmount, proof), "Ineligible");

    _hasClaimedAirdrop[msg.sender] = true;
    gcrToken.safeTransfer(msg.sender, airdropAmount); // this should guard against the case where balance is insufficient

    emit ClaimAirdrop(msg.sender, airdropAmount);
    
    success = true;
  }

  // @dev Purchase GCR tokens in exchange for USDC
  // purchasing tokens will require the user to approve the token (USDC) for spending with this dapp
  // @param amount (uint256): desired amount of GCR, in base units
  // example: you want to buy 1600 GCR at 3.50 USDC each. you transfer 1600 * 3.50 USDC, get back 1600 GCR.
  function purchaseTokens(uint256 purchaseAmount, uint256 snapshotAmount, bytes32[] memory proof) public whenNotPaused returns (bool success) {
    require(!checkAirdropClaimed(msg.sender), "Airdrop claimed. Ineligible for purchase");
    require(verifyMerkleProof(msg.sender, snapshotAmount, proof), "Ineligible");
    require(snapshotAmount >= baseTier, "Insufficient tokens to participate in purchase"); // 100 whole unit requirement
    require(snapshotAmount <= proTier, "Ineligible to participate in purchase. See airdrop instead"); // 2000 whole unit maximum

    uint256 allocation;
    uint256 usdcCost;

    if (snapshotAmount >= 3500000) { // < 2000 due to the above require case, >= 350 tokens
      // entitled to 2000 - amount
      allocation = remainingAllocation(msg.sender, snapshotAmount, proof);
      require(purchaseAmount <= allocation, "Attempting to buy more than allocation");

      usdcCost = purchaseAmount * rate;
      conductTrade(msg.sender, usdcCost, purchaseAmount);

    } else if (snapshotAmount >= baseTier) { // < 300, >= 100 tokens
      // entitled to 700 - amount
      allocation = remainingAllocation(msg.sender, snapshotAmount, proof);
      require(purchaseAmount <= allocation, "Attempting to buy more than allocation");

      usdcCost = purchaseAmount * rate;
      conductTrade(msg.sender, usdcCost, purchaseAmount);

    } else { // < 100 tokens
      // we shouldn't reach this case given we have that require statement above; ineligible to participate
    }

    emit Purchase(msg.sender, purchaseAmount);

    success = true;
  }

  // @dev Helper function that facilitates purchases + movement of funds
  // Note: purchasing tokens will require the user to approve the token (USDC) for spending with this dapp
  // @param buyer (address): address that will be spending USDC in exchange for GCR
  // @param GCRAmount (uint256): desired amount of GCR, in base units
  // @param USDCAmount (uint256): USDC being spent, in base units
  // @return success (bool)
  function conductTrade(address buyer, uint256 USDCAmount, uint256 GCRAmount) internal returns (bool success) {
    checkUSDCAllowance(buyer, USDCAmount);

    // send USDC tokens from buyer to contract  
    usdcToken.safeTransferFrom(buyer, address(this), USDCAmount);

    // send tokens from contract to buyer; maybe we can specify a separate recipient
    gcrToken.safeTransfer(buyer, GCRAmount);

    // update state
    _purchasedAmount[buyer] += GCRAmount;

    success = true;
  }

  /*///////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
                       (note owner == admin)
  //////////////////////////////////////////////////////////////*/


  // @dev Update the owner of the contract (admin only)
  // @param newOwner (address)
  function setOwner(address newOwner) onlyOwner external {
    // prevent accidentally making this contract inaccessible
    require(newOwner != address(0));
    // prevent unnecessary change
    require(newOwner != owner);

    emit SetOwner(owner, newOwner);

    owner = newOwner;
  }

  // @dev Update the exchange rate between USDC <> GCR (admin only).
  // Note that this is in the form of USDC per GCR in base units
  function setRate(uint256 usdcPerToken) onlyOwner external {
    require(usdcPerToken > 0, "Rejecting a 0 rate");

    emit SetRate(owner, rate, usdcPerToken);
  
    rate = usdcPerToken;
  }

  // @dev Withdraw allows admin to return all funds (USDC, GCR, ETH) to admin address
  // @return success (bool)
  function withdrawAllTokens() onlyOwner public returns (bool success) {
    if (usdcToken.balanceOf(address(this)) > 0) {
      usdcToken.safeTransfer(owner, usdcToken.balanceOf(address(this)));
    }
    
    if (gcrToken.balanceOf(address(this)) > 0) {
      gcrToken.safeTransfer(owner, gcrToken.balanceOf(address(this)));
    }

    if (linkToken.balanceOf(address(this)) > 0) {
      linkToken.safeTransfer(owner, linkToken.balanceOf(address(this)));
    }
    
    if (address(this).balance > 0) {
      payable(owner).transfer(address(this).balance);
    }

    emit WithdrawAll(owner);

    success = true;
  }

  // @dev Withdraw specific token contract to admin address
  // @return success (bool)
  function withdrawToken(address tokenAddress) onlyOwner public returns (bool success) {
    IERC20 token = IERC20(tokenAddress);
    if (token.balanceOf(address(this)) > 0) {
      token.safeTransfer(owner, token.balanceOf(address(this)));
    }

    emit WithdrawToken(owner, tokenAddress);

    success = true;
  } 

  function pause() onlyOwner public {
    _pause();
  }

  function unpause() onlyOwner public {
    _unpause();
  }

  /*///////////////////////////////////////////////////////////////
                        EXTERNAL GETTERS
  //////////////////////////////////////////////////////////////*/

  // @dev Check if participant has claimed airdrop
  // @param participant (address)
  // @return bool
  function checkAirdropClaimed(address participant) public view returns (bool) {
    return _hasClaimedAirdrop[participant];
  }

  // 
  // @dev Check if participant is eligible to claim airdrop
  // @param participant (address)
  // @return bool
  function checkAirdropEligibility(address participant, uint256 amount, bytes32[] memory proof) public view returns (bool) {
    require(verifyMerkleProof(participant, amount, proof), "Ineligible");

    return amount >= proTier;
  }
  
  // @dev Check if participant is eligible for discounted token sale
  // @param participant (address)
  // @return bool
  function checkPurchaseEligibility(address participant, uint256 amount, bytes32[] memory proof) public view returns (bool) {
    return initialAllocation(participant, amount, proof) > 0;
  }

  // @dev Public function that returns the total initial purchase allocation for participant.
  // Allocation is dependent upon initial snapshot values, which are determined at deployment time.
  // @param participant (address) 
  // @return allocation (uint256)
  function initialAllocation(address participant, uint256 amount, bytes32[] memory proof) public view returns (uint256 allocation) {
    require(verifyMerkleProof(participant, amount, proof), "Ineligible");

    if (amount > proTier) { // > 2000
      // no allocation; eligible for airdrop instead
      allocation = 0;

    } else if (amount >= 3500000) { // <= 2000, >= 350 tokens
      // entitled to 2000 - amount
      allocation = proTier - amount;

    } else if (amount >= baseTier) { // < 300, >= 100 tokens
      // entitled to 700 - amount
      allocation = midTier - amount;

    } else { // < 100 tokens
      allocation = 0; // we can also return -1 if that better indicates that the address wasn't eligible in the first place (insufficienrt funds)
    }
  }

  // @dev Public function that returns the purchased allocation for participant.
  // @param participant (address) 
  // @return allocation (uint256)
  function purchasedAllocation(address participant) public view returns (uint256 purchasedAmount) {
    purchasedAmount = _purchasedAmount[participant];
  }

  // @dev Public function that returns the remaining allocation for participant.
  // Remaining allocation is dependent upon initial snapshot values, user tier, and amount already claimed.
  // @param participant (address) 
  // @return allocation (uint256)
  function remainingAllocation(address participant, uint256 amount, bytes32[] memory proof) public view returns (uint256 allocation) {
    require(verifyMerkleProof(participant, amount, proof), "Ineligible");

    uint256 purchasedAmount = _purchasedAmount[participant];

    uint256 initial = initialAllocation(participant, amount, proof);

    allocation = initial - purchasedAmount; // should never be negative
  }

  /*///////////////////////////////////////////////////////////////
                              HELPERS
  //////////////////////////////////////////////////////////////*/

  // @dev Helper function that ensures USDC spend allowance by this contract is sufficient
  // @param _participant (address): spender
  // @param _amount (uint256): amount to be spent
  // @return allowed (bool)
  function checkUSDCAllowance(address _participant, uint256 _amount) internal view returns (bool allowed) {
    uint256 allowance = usdcToken.allowance(_participant, address(this));
    require(allowance >= _amount, "Insufficient token allowance");

    allowed = true;
  }

  function verifyMerkleProof(address _address, uint256 _amount, bytes32[] memory _proof) internal view returns (bool valid) {
    // Verify merkle proof, or revert if not in tree
    bytes32 leaf = keccak256(abi.encodePacked(_address, _amount));
    bool isValidLeaf = MerkleProof.verify(_proof, merkleRoot, leaf);
    if (!isValidLeaf) revert NotInMerkle();

    valid = true;
  }

  function stringToBytes32(string memory source) public pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
  }

  function stringEquals(string memory a, string memory b) internal pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }

  /*///////////////////////////////////////////////////////////////
                              ORACLE
  //////////////////////////////////////////////////////////////*/

  function updateChainlinkTokenContract(address _newChainlinkTokenContract) onlyOwner public {
    require(linkTokenContract != _newChainlinkTokenContract, "Using the same token");

    linkTokenContract = _newChainlinkTokenContract;
  }

  function updateChainlinkOracle(address _newOracle) onlyOwner public {
    require(oracle != _newOracle, "Using the same oracle");
    oracle = _newOracle;
  }

  function updateOracleFee(uint256 _newOracleFee) onlyOwner public {
    require(oracleFee != _newOracleFee, "Using the same oracleFee");
    oracleFee = _newOracleFee;
  }

  function updateChainlinkJobId(bytes32 _newJobId) onlyOwner public {
    require(jobId != _newJobId, "Using the same jobId");
    jobId = _newJobId;
  }

  function updatePriceFeedURI(string memory _newPriceFeedURI) onlyOwner public {
    require(!stringEquals(priceFeedURI, _newPriceFeedURI), "Using the same priceFeedURI");
    priceFeedURI = _newPriceFeedURI;
  }

  function updatePriceFeedPath(string memory _newPriceFeedPath) onlyOwner public {
    require(!stringEquals(priceFeedPath, _newPriceFeedPath), "Using the same priceFeedPath");
    priceFeedPath = _newPriceFeedPath;
  }

  // @dev Helper function that allows the USDC / SAMP rate to be updated
  // Must be able to handle errors/faulty API responses
  // @return requestId (bytes32)
  function requestPriceData() public returns (bytes32 requestId) {
      Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
      
      // GET request for token price on Ethereum
      request.add("get", priceFeedURI);
      
      // Set the path to find the desired data in the API response, where the response format is:
      //    {
      //      "0x6307b25a665efc992ec1c1bc403c38f3ddd7c661": {
      //        "usd": x.xx
      //      }
      //    }
      request.add("path", priceFeedPath);
      
      // Multiply the result by 100 to get to an amount in cents
      // Note that this also aligns with the units for general USDC / GCR token exchange
      int timesAmount = 100;
      request.addInt("times", timesAmount);
      
      // Sends the request
      return sendChainlinkRequestTo(oracle, request, oracleFee);
  }

  /**
  * Receive the response in the form of uint256
  */ 
  function fulfill(bytes32 _requestId, uint256 _rate) public recordChainlinkFulfillment(_requestId) {
    if (_rate >= 400) {
      rate = _rate * 9 / 10;
    } else {
      rate = 350;
    }
  }

  /*///////////////////////////////////////////////////////////////
                            FALLBACK
  //////////////////////////////////////////////////////////////*/

  fallback() external payable {}
  receive() external payable {}
}
