// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./console.sol";

contract DRIPBOND is ERC721Upgradeable, OwnableUpgradeable {
  using SafeERC20 for IERC20;
  using SafeMath for *;
  struct DripBond {
    bool spent;
    uint64 maturesAt;
    uint128 initValue;
    uint256 rate;
  }
  event DripBondMinted(address indexed holder, uint256 indexed bond, uint256 initValue, uint256 maturesAt);
  event DripBondBurned(address indexed holder, uint256 indexed bond, uint256 maturedValue);
  uint256 count;
  address public constant drip = 0x0d44CfA6a50E4C16eE311af6EDAD36E89f90b0a6;
  address public constant treasury = 0x592E10267af60894086d40DcC55Fe7684F8420D5;
  address public constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  mapping (uint256 => DripBond) public bonds;
  uint256 public rate;
  uint256 public target;
  uint256 public maturesAfter;
  function initialize() public initializer {
    __ERC721_init("DRIPBOND", "DRIPBOND");
    rate = 2e16;
    count = 0;
    target = 4e15;
    maturesAfter = 60*60*24*30;
    IERC20(drip).approve(router, uint256(int256(~0)));
  }
  function setTarget(uint256 _target) public onlyOwner {
    target = _target;
  }
  function setRate(uint256 _rate) public onlyOwner {
    rate = _rate;
  }
  function setMaturity(uint256 _maturesAfter) public onlyOwner {
    maturesAfter = _maturesAfter;
  }
  function computeTargetDRIP(uint256 ethAmount) public view returns (uint256) {
    return ethAmount.mul(uint256(1 ether)).div(target);
  }
  function mint() public payable returns (uint256) {
    uint256 _count = count;
    require(msg.value != 0, "!enough-eth");
    uint256 dripAmount = computeTargetDRIP(msg.value);
    require(dripAmount != 0, "!enough-drip");
    IERC20(drip).safeTransferFrom(treasury, address(this), dripAmount);
    (uint256 amountToken,,) = IUniswapV2Router02(router).addLiquidityETH{ value: msg.value }(
      drip,
      dripAmount,
      uint256(1),
      msg.value,
      treasury,
      block.timestamp + 1
    );
    uint256 maturesAt = block.timestamp + maturesAfter;
    bonds[_count] = DripBond({
      spent: false,
      initValue: uint128(amountToken),
      maturesAt: uint64(maturesAt),
      rate: rate
    });
    emit DripBondMinted(msg.sender, _count, amountToken, maturesAt);
    _mint(msg.sender, count);
    count++;
    return bonds[count - 1].initValue;
  }
  function computeMatureValue(uint256 input, uint256 _rate) internal pure returns (uint256) {
    return input.mul(uint256(1 ether).add(_rate)).div(uint256(1 ether));
  }
  function burn(uint256 idx) public {
    require(ownerOf(idx) == msg.sender, "!owner");
    require(bonds[idx].maturesAt <= block.timestamp, "!matured");
    require(!bonds[idx].spent, "spent");
    bonds[idx].spent = true;
    _burn(idx);
    uint256 maturedValue = computeMatureValue(bonds[idx].initValue, bonds[idx].rate);
    IERC20(drip).safeTransferFrom(treasury, msg.sender, maturedValue);
    emit DripBondBurned(msg.sender, idx, maturedValue); 
  }
}
