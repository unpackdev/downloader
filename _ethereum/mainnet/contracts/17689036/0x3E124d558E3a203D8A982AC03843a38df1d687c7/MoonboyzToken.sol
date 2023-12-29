// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

import "./ERC20.sol";
import "./AccessControl.sol";
import "./MerkleProof.sol";

contract MoonboyzToken is ERC20, AccessControl {
  address public immutable burnAddress = 0x000000000000000000000000000000000000dEaD;

  IERC721 public Moonboyz;
  IERC20 public darkToken;

  address public taxReceiver;
  address public router;
  mapping(address => bool) public isTradeableContract;

  uint256 public immutable classicDailyEarnRate;
  uint256 public immutable divineDailyEarnRate;
  uint256 public immutable earnPeriod;
  uint256 public deployedAt;

  mapping(uint256 => bool) public isDivine;
  struct TokenClaim {
    uint128 lastClaimedAt;
    uint128 totalClaimTime;
  }
  mapping(uint256 => TokenClaim) public tokenClaims;
 
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant EXEMPT_ROLE = keccak256("EXEMPT_ROLE");

  uint256 public darkConversionRate;
  bytes32 public burnedMbzMerkleRoot;
  mapping(address => bool) public burnedMbzClaimed;
  uint256 public burnedMbzConversionRate;

  uint256 public taxPercentage;
  uint256 public taxCollected;
  uint256 taxSwapCooldown;
  uint256 taxSwapLastTime;

  event DARKClaimed(address indexed account, uint256 darkAmount, uint256 mbzAmount);
  event MBZClaimed(address indexed account, uint256 indexed tokenId, uint256 amount);

  constructor(
    address _mbz,
    address _dark,
    uint256[] memory divineTokenIds,
    bytes32 _burnedMbzMerkleroot,
    address _taxReceiver,
    address _router
  ) ERC20("Moon Boyz Token", "$MBZ") {
    Moonboyz = IERC721(_mbz);
    darkToken = IERC20(_dark);

    for (uint i = 0; i < divineTokenIds.length; i++) {
      isDivine[divineTokenIds[i]] = true;
    }

    burnedMbzMerkleRoot = _burnedMbzMerkleroot;

    classicDailyEarnRate = 10 ether;
    divineDailyEarnRate = 500 ether;
    earnPeriod = 5 * 365 days;

    darkConversionRate = 20_000;
    burnedMbzConversionRate = 3650 ether;

    taxSwapCooldown = 10 minutes;
    taxSwapLastTime = block.timestamp;

    taxReceiver = _taxReceiver;
    router = _router;
    taxPercentage = 50;

    _approve(address(this), _router, ~uint256(0));
    IUniswapV2Router02 swapRouter = IUniswapV2Router02(_router);
    address pair = IUniswapV2Factory(swapRouter.factory()).createPair(
        address(this),
        swapRouter.WETH()
    );
    isTradeableContract[pair] = true;

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(EXEMPT_ROLE, address(this));

    _mint(_taxReceiver, 134996073 ether);
  }

  function claimMBZ(
    uint256[] memory tokenIds, 
    bool claimDark,
    uint256 burnedMbzCount,
    bytes32[] memory burnedMbzProof
  ) external {
    require(deployedAt > 0, "Claim not started");

    uint256 darkClaimableMbz;
    uint256 burnedMbzClaimable;
    uint256 totalEarned;

    if (claimDark && darkToken.balanceOf(msg.sender) > 0) {
      uint256 darkBalance = darkToken.balanceOf(msg.sender);
      uint256 mbzDark = _getMbzFromDark(darkBalance);
      uint256 darkSpend = mbzDark * darkConversionRate;
      require(darkToken.transferFrom(msg.sender, burnAddress, darkSpend), "DARK transfer failed");
      darkClaimableMbz += mbzDark;
    }

    if (
      burnedMbzCount > 0 &&
      !burnedMbzClaimed[msg.sender]
    ) {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender, burnedMbzCount));
      require(MerkleProof.verify(burnedMbzProof, burnedMbzMerkleRoot, leaf), "INVALID PROOF");
      burnedMbzClaimable += burnedMbzConversionRate * burnedMbzCount;
      burnedMbzClaimed[msg.sender] = true;
    }

    if (tokenIds.length > 0) {
      for (uint i = 0; i < tokenIds.length; i++) {
        uint256 tokenId = tokenIds[i];
        TokenClaim storage tokenClaim = tokenClaims[tokenId];

        require(Moonboyz.ownerOf(tokenId) == msg.sender, "Must own token");
        if (tokenClaim.totalClaimTime >= earnPeriod) {
          continue;
        }

        uint256 lastClaimedAt = tokenClaim.lastClaimedAt == 0 ? deployedAt : tokenClaim.lastClaimedAt;
        uint256 timeDelta = block.timestamp - lastClaimedAt;
        uint256 claimTime = tokenClaim.totalClaimTime + timeDelta > earnPeriod ? 
          earnPeriod - tokenClaim.totalClaimTime : 
          timeDelta;

        bool isTokenDivine = isDivine[tokenId];
        totalEarned += claimTime * (isTokenDivine ? divineDailyEarnRate : classicDailyEarnRate);

        tokenClaim.lastClaimedAt = uint128(block.timestamp);
        tokenClaim.totalClaimTime += uint128(claimTime);
        emit MBZClaimed(msg.sender, tokenId, claimTime);
      }
    }

    uint256 total = darkClaimableMbz + burnedMbzClaimable + totalEarned / 1 days;
    if (total > 0)
      _mint(msg.sender, total);
  }

  function mint(address account, uint256 amount) external onlyRole(MINTER_ROLE) {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external onlyRole(BURNER_ROLE) {
    _burn(account, amount);
  }

  function setDarkConversionRate(uint256 rate) external onlyRole(DEFAULT_ADMIN_ROLE) {
    darkConversionRate = rate;
  }

  function setTaxPercentage(uint256 percentage) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(percentage <= 50, "Tax percentage must be <= 50");
    taxPercentage = percentage;
  }

  function setTradeablePair(address pair, bool isTradeable) external onlyRole(DEFAULT_ADMIN_ROLE) {
    isTradeableContract[pair] = isTradeable;
  }
  
  function setBurnedMbzMerkleRoot(bytes32 root) external onlyRole(DEFAULT_ADMIN_ROLE) {
    burnedMbzMerkleRoot = root;
  }

  function startClaimPeriod() external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(deployedAt == 0, "Claim period already started");
    deployedAt = block.timestamp;
  }

  function setTaxSwapCooldown(uint256 cooldown) external onlyRole(DEFAULT_ADMIN_ROLE) {
    taxSwapCooldown = cooldown;
  }

  function _getMbzFromDark(uint256 darkAmount) internal view returns (uint256) {
    return (darkAmount / (darkConversionRate * 1e18)) * 1e18;
  }

  function _spendAllowance(
    address owner,
    address spender,
    uint256 amount
  ) internal override {
    if (allowance(owner, spender) == ~uint256(0)) {
      return;
    }
    return super._spendAllowance(owner, spender, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    uint256 toRecip = amount;
    if (
      (isTradeableContract[from] || 
      isTradeableContract[to]) 
      &&
      !(hasRole(EXEMPT_ROLE, from) ||
      hasRole(EXEMPT_ROLE, to))
    ) {
      uint256 toTax = (amount * taxPercentage) / 1000;
      toRecip = amount - toTax;
      if (toTax > 0) {
        super._transfer(from, address(this), toTax);
        taxCollected += toTax;
      }
    }
    if (
      !isTradeableContract[from] && 
      taxCollected > 0 &&
      block.timestamp - taxSwapLastTime >= taxSwapCooldown 
    ) {
      uint256 toSwap = taxCollected;
      taxCollected = 0;
      taxSwapLastTime = block.timestamp;
      if (balanceOf(address(this)) < toSwap)
        toSwap = balanceOf(address(this));
      _swapTokensToEth(toSwap, taxReceiver);
    }
    super._transfer(from, to, toRecip);
  }

   function _swapTokensToEth(
        uint256 tokenAmount,
        address recip
    ) private {
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(router);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();
        swapRouter.swapExactTokensForETH(
            tokenAmount,
            0,
            path,
            recip,
            block.timestamp + 15 minutes
        );
    }

    receive() external payable {}
}