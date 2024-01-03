// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

import "./ITDAO.sol";
import "./IFeeSplitter.sol";
import "./INFTRewardsVault.sol";
import "./IVault.sol";
import "./TRIG.sol";

contract LockedLiquidityEvent is ERC1155Holder {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event LiquidityAddition(address indexed account, uint256 value);
  event TransferredNFT(address indexed account, uint32[7] amount);
  event DivinityClaimed(address indexed account);
  event TrigClaimed(address indexed account, uint256 value);

  struct HighestDeposit {
    address account;
    uint256 amount;
  }

  /// @notice Time required to pass before TDAO transfers can succeed
  uint256 public constant GRACE_PERIOD = 1 hours;

  /// @notice Minimum amount of TDAO which needs to be deposited
  /// for the Divinity NFT to be claimed
  uint256 public constant MIN_PRICE_DIVINITY_NFT = 50000 ether;

  IUniswapV2Router02 public uniswapRouterV2;
  IUniswapV2Factory public uniswapFactory;
  HighestDeposit public highestDeposit;

  /// @notice Time when LLE starts
  uint256 public startTime;

  /// @notice Time when LLE ends
  uint256 public endTime;

  /// @notice Exact time when trading with Uniswap is allowed
  uint256 public startTradingTime;

  /// @notice Total TRIB contributed in LLE event
  uint256 public totalContributed;

  /// @notice Trig tokens per TRIB unit sold
  uint256 public trigTokensPerUnit;

  address public tdao;
  address public tokenB;
  address public nft;
  address public trig;
  address public tokenUniswapPair;
  address public burnAddress = 0x000000000000000000000000000000000000dEaD;

  /// @notice LLE completion flag
  bool public eventCompleted;

  /// @notice Unique NFT index that was not allocated during the LLE
  uint32[] public nftTreasuryIndex;

  /// @notice Initial allocation for each NFT with Divnity exception
  uint32[] public nftAllocation = [10, 8, 6, 5, 4, 2, 1];

  /// @notice Supply tracker for each NFT with Divnity exception
  uint32[] public nftSupply = [10, 8, 6, 5, 4, 2, 1];

  /// @notice Minimum TRIB required to distribute each NFT
  uint32[] public nftMin = [500, 2000, 5000, 10000, 20000, 50000, 100000];

  /// @notice TRIB contributed by address
  mapping(address => uint256) public contributed;

  modifier onlyGovernance() {
    address governance = ITDAO(tdao).governance();
    require(
      governance != address(0),
      'LockedLiquidityEvent: Governance is not set.'
    );
    require(
      msg.sender == governance,
      'LockedLiquidityEvent: Only governance can call this function.'
    );
    _;
  }

  constructor(
    address _router,
    address _factory,
    address _tdao,
    address _tokenB,
    address _nft,
    uint256 _startTime,
    uint256 _endTime
  ) public {
    require(
      _startTime < _endTime,
      'LockedLiquidityEvent: Must start before the end.'
    );
    tdao = _tdao;
    tokenB = _tokenB;
    nft = _nft;
    startTime = _startTime;
    endTime = _endTime;
    startTradingTime = _endTime.add(GRACE_PERIOD);
    uniswapRouterV2 = IUniswapV2Router02(_router);
    uniswapFactory = IUniswapV2Factory(_factory);
    tokenUniswapPair = _createUniswapPair(tdao, tokenB);
    trig = address(new TRIG('Contribute Rig', 'TRIG'));
  }

  /// @notice Time in seconds left for the Liquidity Pool Event.
  function timeRemaining() external view returns (uint256 remaining) {
    if (ongoing()) {
      remaining = endTime.sub(block.timestamp);
    }
  }

  /// @notice Is Locked Liquidity Event ongoing.
  function ongoing() public view virtual returns (bool) {
    return (endTime > block.timestamp && block.timestamp >= startTime);
  }

  /// @notice Deposits tokenB to the contract, allocates and distributes NFT
  /// to the account.
  function addLiquidity(uint256 amount) external {
    require(
      _addLiquidity(msg.sender, amount),
      'LockedLiquidityEvent: Failed to add liquidity.'
    );
    _allocateHighestDeposit(msg.sender, amount);
    _processNFT(msg.sender, amount);
  }

  /// @notice Deposits tokenB to the contract in behalf of someone else,
  /// allocates and distributes NFT to the account.
  function addLiquidityFor(address account, uint256 amount) external {
    require(
      _addLiquidityFor(msg.sender, account, amount),
      'LockedLiquidityEvent: Failed to add liquidity.'
    );
    _allocateHighestDeposit(account, amount);
    _processNFT(account, amount);
  }

  /// @notice Locks liquidity in the Uniswap Pool,
  /// mints UNI-LP and TRIG tokens.
  function lockLiquidity() external {
    require(ongoing() == false, 'LockedLiquidityEvent: LLE ongoing.');
    require(
      eventCompleted == false,
      'LockedLiquidityEvent: LLE already finished.'
    );
    require(
      totalContributed != 0,
      'LockedLiquidityEvent: Contribution must be greater than zero.'
    );

    IUniswapV2Pair pair = IUniswapV2Pair(tokenUniswapPair);

    IERC20(tdao).safeTransfer(
      address(pair),
      IERC20(tdao).balanceOf(address(this))
    );
    IERC20(tokenB).safeTransfer(address(pair), totalContributed);

    pair.mint(address(this));
    require(
      pair.balanceOf(address(this)) != 0,
      'LockedLiquidityEvent: Failed to mint LP tokens.'
    );

    trigTokensPerUnit = IERC20(trig).totalSupply().mul(1e18).div(
      totalContributed
    );

    _depositUnclaimedTier();
    _burnRemainingNFTs();

    eventCompleted = true;
  }

  /// @notice Allows contributors to claim TRIG tokens.
  function claimTrig() external {
    require(eventCompleted, 'LockedLiquidityEvent: Event not over yet.');
    require(
      contributed[msg.sender] != 0,
      'LockedLiquidityEvent: Nothing to claim.'
    );

    uint256 amountTrigToTransfer =
      contributed[msg.sender].mul(trigTokensPerUnit).div(1e18);

    contributed[msg.sender] = 0;

    _processHighestDeposit(msg.sender);

    IERC20(trig).safeTransfer(msg.sender, amountTrigToTransfer);

    emit TrigClaimed(msg.sender, amountTrigToTransfer);
  }

  function claimERC20(address erc20, address recipient)
    external
    onlyGovernance
  {
    if (erc20 == tokenUniswapPair) {
      require(
        block.timestamp > startTradingTime.add(365 days),
        'LockedLiquidityEvent: Can only claim LP tokens after one year.'
      );
    }
    IERC20(erc20).safeTransfer(
      recipient,
      IERC20(erc20).balanceOf(address(this))
    );
  }

  function claimTreasuryNFTRewards() external {
    require(eventCompleted, 'LockedLiquidityEvent: Event not over yet.');
    require(
      nftTreasuryIndex.length != 0,
      'LockedLiquidityEvent: Treasury has not NFTs staking.'
    );

    address nftRewardsVault =
      IFeeSplitter(ITDAO(tdao).feeSplitter()).nftRewardsVault();
    address treasuryVault =
      IFeeSplitter(ITDAO(tdao).feeSplitter()).treasuryVault();

    for (uint8 i = 0; i < nftTreasuryIndex.length; i++) {
      INFTRewardsVault(nftRewardsVault).withdraw(nftTreasuryIndex[i], 0);
    }

    uint256 amount = IERC20(tdao).balanceOf(address(this));

    IERC20(tdao).safeTransfer(treasuryVault, amount);

    IVault(treasuryVault).update(amount);
  }

  function _addLiquidity(address _account, uint256 _amount)
    internal
    returns (bool)
  {
    require(ongoing(), 'LockedLiquidityEvent: Locked Liquidity Event over.');
    require(
      _amount > 0,
      'LockedLiquidityEvent: Must add value greater than 0.'
    );

    IERC20(tokenB).safeTransferFrom(_account, address(this), _amount);
    contributed[_account] = contributed[_account].add(_amount);
    totalContributed = totalContributed.add(_amount);

    emit LiquidityAddition(_account, _amount);

    return true;
  }

  function _addLiquidityFor(
    address _from,
    address _to,
    uint256 _amount
  ) internal returns (bool) {
    require(ongoing(), 'LockedLiquidityEvent: Liquidity Pool Event over.');
    require(
      _amount > 0,
      'LockedLiquidityEvent: Must add value greater than 0.'
    );

    IERC20(tokenB).safeTransferFrom(_from, address(this), _amount);
    contributed[_to] = contributed[_to].add(_amount);
    totalContributed = totalContributed.add(_amount);

    emit LiquidityAddition(_to, _amount);

    return true;
  }

  /// @notice Uniswap Pair Contract creation.
  function _createUniswapPair(address _tokenA, address _tokenB)
    internal
    returns (address)
  {
    require(
      tokenUniswapPair == address(0),
      'LiquidityPool: pool already created'
    );
    address uniPair = uniswapFactory.createPair(_tokenA, _tokenB);
    return uniPair;
  }

  function _allocateHighestDeposit(address _account, uint256 _amount) internal {
    if (_amount > highestDeposit.amount && _amount >= MIN_PRICE_DIVINITY_NFT) {
      highestDeposit.account = _account;
      highestDeposit.amount = _amount;
    }
  }

  function _depositUnclaimedTier() internal {
    address nftRewardsVault =
      IFeeSplitter(ITDAO(tdao).feeSplitter()).nftRewardsVault();
    IERC1155(nft).setApprovalForAll(nftRewardsVault, true);

    for (uint8 i = 0; i < nftAllocation.length; i++) {
      if (nftSupply[i] == nftAllocation[i]) {
        nftTreasuryIndex.push(i);
        nftSupply[i] -= 1;
      }
    }

    if (highestDeposit.account == address(0)) {
      nftTreasuryIndex.push(7);
    }

    for (uint8 i = 0; i < nftTreasuryIndex.length; i++) {
      INFTRewardsVault(nftRewardsVault).deposit(nftTreasuryIndex[i], 1);
    }
  }

  function _burnRemainingNFTs() internal {
    for (uint8 i = 0; i < nftSupply.length; i++) {
      if (nftSupply[i] != 0) {
        uint256 _amount = nftSupply[i];
        nftSupply[i] = 0;
        IERC1155(nft).safeTransferFrom(
          address(this),
          burnAddress,
          i,
          _amount,
          bytes('0x0')
        );
      }
    }
  }

  function _processHighestDeposit(address _account) internal {
    if (_account != highestDeposit.account) {
      return;
    }

    _transferHighestDepositNFT(_account);
  }

  function _transferHighestDepositNFT(address _account) internal {
    IERC1155(nft).safeTransferFrom(address(this), _account, 7, 1, bytes('0x0'));

    emit DivinityClaimed(_account);
  }

  function _shouldTransferNFT(uint32[7] memory _allocatedAmounts)
    internal
    pure
    returns (bool _result)
  {
    for (uint8 i = 0; i < _allocatedAmounts.length; i++) {
      if (_allocatedAmounts[i] != 0) {
        _result = true;
        break;
      }
    }
  }

  function _processNFT(address _account, uint256 _amount) internal {
    uint32[7] memory _allocatedAmounts = _allocateNFT(_amount);

    if (!_shouldTransferNFT(_allocatedAmounts)) {
      return;
    }

    _transferNFT(_account, _allocatedAmounts);
  }

  function _transferNFT(address _account, uint32[7] memory _allocatedAmounts)
    internal
  {
    uint256[] memory _amounts = new uint256[](7);
    uint256[] memory _indexes = new uint256[](7);

    for (uint8 i = 0; i < _allocatedAmounts.length; i++) {
      _amounts[i] = (_allocatedAmounts[i]);
      _indexes[i] = i;
    }

    IERC1155(nft).safeBatchTransferFrom(
      address(this),
      _account,
      _indexes,
      _amounts,
      bytes('0x0')
    );

    emit TransferredNFT(_account, _allocatedAmounts);
  }

  function _allocateNFT(uint256 _amount) internal returns (uint32[7] memory) {
    uint32 _remaining = uint32(_amount.div(1e18));
    uint32[7] memory _rewards;

    for (uint256 i = nftSupply.length; i > 0; i--) {
      uint256 _index = i - 1;

      if (nftSupply[_index] == 0) {
        break;
      }

      while (_remaining >= nftMin[_index]) {
        if (nftSupply[_index] != 0) {
          uint32 _attainable = _remaining / nftMin[_index];
          if (_attainable <= nftSupply[_index]) {
            nftSupply[_index] = nftSupply[_index] - _attainable;
            _remaining = _remaining - _attainable * nftMin[_index];
            _rewards[_index] = _attainable;
          } else {
            _attainable = nftSupply[_index];
            nftSupply[_index] = 0;
            _remaining = _remaining - _attainable * nftMin[_index];
            _rewards[_index] = _attainable;
          }
        } else {
          break;
        }
      }
    }
    return _rewards;
  }
}
