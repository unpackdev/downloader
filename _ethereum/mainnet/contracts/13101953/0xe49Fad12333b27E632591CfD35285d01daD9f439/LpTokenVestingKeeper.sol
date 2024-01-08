//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/*
This contract claims amm lp shares from multiple `LpTokenVesting` contracts,
removes liquidity, sells the non-XRUNE token, and distributes it's resulting
XRUNE balance to an `VotersInvestmentDispenser` contract, a `Voters` contract,
the grants multisig and the DAO.
*/

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Factory.sol";
import "./IDAO.sol";
import "./IVoters.sol";
import "./ILpTokenVesting.sol";
import "./IVotersInvestmentDispenser.sol";

contract LpTokenVestingKeeper {
  using SafeERC20 for IERC20;

  IVotersInvestmentDispenser public votersInvestmentDispenser;
  IUniswapV2Router public sushiRouter;
  IERC20 public xruneToken;
  IDAO public dao;
  address public grants;
  address public owner;
  uint public lpVestersCount;
  mapping(uint => address) public lpVesters;
  mapping(uint => uint) public lpVestersSnapshotIds;
  uint lastRun;

  event AddLpVester(address vester, uint snapshotId);
  event Claim(address vester, uint snapshotId, uint amount);

  constructor(address _votersInvestmentDispenser, address _sushiRouter, address _xruneToken, address _dao, address _grants, address _owner) {
    votersInvestmentDispenser = IVotersInvestmentDispenser(_votersInvestmentDispenser);
    sushiRouter = IUniswapV2Router(_sushiRouter);
    xruneToken = IERC20(_xruneToken);
    dao = IDAO(_dao);
    grants = _grants;
    owner = _owner;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "!owner");
    _;
  }

  function addLpVester(address vester, uint snapshotId) public onlyOwner {
    lpVesters[lpVestersCount] = vester;
    lpVestersSnapshotIds[lpVestersCount] = snapshotId;
    lpVestersCount++;
    emit AddLpVester(vester, snapshotId);
  }

  function setVotersInvestmentDispenser(address value) public onlyOwner {
    votersInvestmentDispenser = IVotersInvestmentDispenser(value);
  }

  function setDao(address value) public onlyOwner {
    dao = IDAO(value);
  }

  function setGrants(address value) public onlyOwner {
    grants = value;
  }

  function setOwner(address value) public onlyOwner {
    owner = value;
  }
  
  function shouldRun() public view returns (bool) {
    return block.timestamp > lastRun + 82800; // 23 hours
  }

  function run() external {
    require(shouldRun(), "should not run");
    lastRun = block.timestamp;
    for (uint i = 0; i < lpVestersCount; i++) {
      ILpTokenVesting vester = ILpTokenVesting(lpVesters[i]);
      uint claimable = vester.claimable(0);
      if (claimable > 0) {
        vester.claim(0);
        address token0 = address(vester.token0());
        address token1 = address(vester.token1());
        IERC20 lpToken = IERC20(pair(token0, token1));
        uint lpTokenAmount = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(sushiRouter), lpTokenAmount);
        (uint amount0, uint amount1) = sushiRouter.removeLiquidity(
          token0, token1,
          lpTokenAmount, 0, 0,
          address(this), type(uint).max
        );
        {
          address[] memory path = new address[](2);
          path[0] = address(xruneToken) == token0 ? token1 : token0;
          path[1] = address(xruneToken);
          uint amountToSwap = address(xruneToken) == token0 ? amount1 : amount0;
          IERC20(path[0]).safeApprove(address(sushiRouter), amountToSwap);
          sushiRouter.swapExactTokensForTokens(
            amountToSwap, 0,
            path, address(this), type(uint).max
          );
        }
        uint amount = xruneToken.balanceOf(address(this));

        xruneToken.safeApprove(address(votersInvestmentDispenser), (amount * 35) / 100);
        votersInvestmentDispenser.deposit(lpVestersSnapshotIds[i], (amount * 35) / 100);

        xruneToken.safeApprove(dao.voters(), (amount * 35) / 100);
        IVoters(dao.voters()).donate((amount * 35) / 100);

        xruneToken.safeTransfer(grants, (amount * 5) / 100);

        // Send the leftover 25% to the DAO
        xruneToken.transfer(address(dao), xruneToken.balanceOf(address(this)));
        emit Claim(lpVesters[i], lpVestersSnapshotIds[i], amount);
      }
    }
  }

  function pair(address token0, address token1) public view returns (address) {
    return IUniswapV2Factory(sushiRouter.factory()).getPair(token0, token1);
  }
}
