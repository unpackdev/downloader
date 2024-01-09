pragma solidity ^0.8.10;

import "./Context.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./UniswapV2Library.sol";
import "./Provider.sol";
import "./IProviderMigration.sol";

import "./console.sol";

contract ProviderMigration is Context, Ownable, IProviderMigration {
  IUniswapV2Router public UniswapRouter =
    IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  IUniswapV2Pair public immutable LPToken_V1;
  IERC20 public immutable UrusToken_V1;
  IERC20 public immutable WETH;

  IERC20 public UrusToken_V2;
  IUniswapV2Pair public LPToken_V2;
  Provider public ProviderContract;

  uint256 public createdLPTokenTotal;
  uint256 public tokenBalanceTotal;
  bool public positionsClosed;

  address[] public users;
  mapping(address => uint256) public balances;

  constructor(
    address wethAddress,
    address lpTokenV1Address,
    address urusTokenV1Address,
    address ownerAddress
  ) {
    LPToken_V1 = IUniswapV2Pair(lpTokenV1Address);
    UrusToken_V1 = IERC20(urusTokenV1Address);

    WETH = IERC20(wethAddress);

    transferOwnership(ownerAddress);
  }

  function setUrusV2Token(IERC20 _UrusToken_V2) external override onlyOwner {
    UrusToken_V2 = _UrusToken_V2;

    emit SetUrusV2Address(address(_UrusToken_V2));
  }

  function setProviderV2(Provider _ProviderContract)
    external
    override
    onlyOwner
  {
    ProviderContract = _ProviderContract;

    emit SetProviderV2Address(address(_ProviderContract));
  }

  function getUsers() external view override returns (address[] memory) {
    return users;
  }

  receive() external payable {}

  function addTokens(uint256 _amount) external override returns (bool) {
    require(_amount > 0, "User must be depositing more than 0 tokens");
    require(positionsClosed == false, "LP Position has already been closed");

    // If this is the first time they are adding tokens, add the user to the users array
    if (balances[_msgSender()] == 0) {
      users.push(_msgSender());
    }

    balances[_msgSender()] += _amount;
    tokenBalanceTotal += _amount;

    LPToken_V1.transferFrom(_msgSender(), address(this), _amount);

    emit TokensAdded(_msgSender(), _amount);

    return true;
  }

  function withdrawETH() external override onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function withdraw(IERC20 Token) external override onlyOwner {
    require(
      Token.transfer(owner(), Token.balanceOf(address(this))),
      "Transferring ERC20 Token failed"
    );
  }

  function _applySlippage(uint256 _value) private pure returns (uint256) {
    return (_value * 9) / 10;
  }

  function returnUsersLPShare(address user)
    public
    view
    override
    returns (uint256 share)
  {
    require(
      address(LPToken_V2) != address(0x0),
      "New position hasn't been created yet"
    );

    uint256 balance = balances[user];

    // (balance / total) * NewTotal
    share = ((balance * 1 ether) / tokenBalanceTotal);
  }

  function returnUsersLPTokenAmount(address user)
    public
    view
    override
    returns (uint256 amount)
  {
    uint256 share = returnUsersLPShare(user);

    amount = (share * createdLPTokenTotal) / 1 ether;
  }

  function removeUserFromArray(address _user) private {
    uint8 index;

    // Interate over each user to find the matching one
    for (uint256 i = 0; i < users.length; i++) {
      if (users[i] == _user) {
        index = uint8(i);
        break;
      }
    }
    // If the user is found update the array
    if (users.length > 1) {
      users[index] = users[users.length - 1];
    }
    // Remove last item
    users.pop();
  }

  function distributeTokens(Provider.MigrateArgs[] memory migrateArgs)
    external
    override
    onlyOwner
  {
    require(
      address(LPToken_V2) != address(0x0),
      "New position hasn't been created yet"
    );
    require(users.length > 0, "No users left to migrate");

    uint256 totalTransferAmount;

    // Distribute new position to all users
    for (uint256 i = 0; i < migrateArgs.length; i++) {
      address user = migrateArgs[i]._user;

      require(
        balances[user] > 0,
        "Can't distribute tokens for 0 balance users"
      );

      // Pass in the migrateArgs and replace the _amount for each item. This is cheaper than reassigning the array with the _amount field added in.
      uint256 claimableAmount = returnUsersLPTokenAmount(user);

      migrateArgs[i]._amount = claimableAmount;

      totalTransferAmount += claimableAmount;

      balances[user] = 0;

      removeUserFromArray(user);
    }

    LPToken_V2.approve(address(ProviderContract), totalTransferAmount);

    ProviderContract.migrateUsersLPPositions(migrateArgs);

    emit TokensDistributed(migrateArgs);
  }

  function closePositions() external override onlyOwner returns (bool status) {
    require(positionsClosed == false, "LP Position has already been closed");
    uint256 totalLiquidity = LPToken_V1.balanceOf(address(this));

    require(totalLiquidity > 0, "No liquidity to close positions with");

    positionsClosed = true;

    // Get the total supply
    uint256 totalSupply = LPToken_V1.totalSupply();

    (uint112 reserve0, uint112 reserve1, ) = LPToken_V1.getReserves();

    // userLiquidity * reserves / totalSupply
    uint256 liquidityValue0 = (totalLiquidity * reserve0) / totalSupply;
    uint256 liquidityValue1 = (totalLiquidity * reserve1) / totalSupply;

    LPToken_V1.approve(address(UniswapRouter), totalLiquidity);

    UniswapRouter.removeLiquidityETH(
      address(UrusToken_V1),
      totalLiquidity,
      // Apply 10% slippage
      // Minimum amount of URUS
      _applySlippage(liquidityValue0),
      // Minimum amount of ETH
      _applySlippage(liquidityValue1),
      address(this),
      // Deadline is now + 300 seconds
      block.timestamp + 300
    );

    emit ClosePositions();

    return true;
  }

  function createNewPosition() external override onlyOwner {
    uint256 urusBalance = UrusToken_V2.balanceOf(address(this));

    UrusToken_V2.approve(address(UniswapRouter), urusBalance);

    UniswapRouter.addLiquidityETH{ value: address(this).balance }(
      address(UrusToken_V2),
      urusBalance,
      _applySlippage(urusBalance),
      _applySlippage(address(this).balance),
      address(this),
      block.timestamp + 300
    );

    address LPToken_V2Address = UniswapV2Library.pairFor(
      UniswapRouter.factory(),
      address(UrusToken_V2),
      address(WETH)
    );

    LPToken_V2 = IUniswapV2Pair(LPToken_V2Address);

    createdLPTokenTotal = LPToken_V2.balanceOf(address(this));

    emit NewPositionCreated(LPToken_V2Address, createdLPTokenTotal);
  }
}
