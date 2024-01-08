//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./SafeMath.sol";

import "./SafeMathUint.sol";
import "./SafeMathInt.sol";
import "./IWETH.sol";

// Based on Roger Wu's Dividend-Paying Token implementation
// Source: https://github.com/Roger-Wu/erc1726-dividend-paying-token
contract TheDudesStaking is IERC721Receiver, Ownable {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  IERC721 public target;
  IWETH public weth;

  bool public isStakingActive = false;
  uint256 public timelockPeriod = 0;
  address public emergencyWithdrawAddress;

  uint256 public totalSupply;
  mapping(uint256 => address) public tokenOwners;
  mapping(uint256 => uint256) public timelocks;
  mapping(address => uint256) public balances;

  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
  mapping(uint256 => uint256) private _ownedTokensIndex;

  uint256 constant internal magnitude = 2**128;
  uint256 internal magnifiedDividendPerShare;
  mapping(uint256 => int256) internal magnifiedDividendCorrections;
  mapping(uint256 => uint256) internal withdrawnDividends;

  constructor(address targetAddress_, address wethAddress_) {
    target = IERC721(targetAddress_);
    weth = IWETH(wethAddress_);
  }

  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) override pure public returns (bytes4) {
    return this.onERC721Received.selector;
  }

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  function setWETHAddress(address wethAddress_) public onlyOwner {
    weth = IWETH(wethAddress_);
  }

  function setIsStakingActive(bool isStakingActive_) public onlyOwner {
    isStakingActive = isStakingActive_;
  }

  function setTimelockPeriod(uint256 timelockPeriod_) public onlyOwner {
    timelockPeriod = timelockPeriod_;
  }

  function setEmergencyWithdrawAddress(address emergencyWithdrawAddress_) public onlyOwner {
    emergencyWithdrawAddress = emergencyWithdrawAddress_;
  }

  function emergencyWithdrawWETH() public onlyOwner {
    uint256 balance = weth.balanceOf(address(this));
    weth.transfer(emergencyWithdrawAddress, balance);
  }

  function emergencyWithdrawETH() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(emergencyWithdrawAddress).transfer(balance);
  }

  function stakeMultiple(uint256[] calldata tokenIds) public {
    for(uint256 i=0; i<tokenIds.length; i++) {
      stake(tokenIds[i]);
    }
  }

  function unsstakeMultiple(uint256[] calldata tokenIds) public {
    for(uint256 i=0; i<tokenIds.length; i++) {
      unstake(tokenIds[i]);
    }
  }

  function stake(uint256 tokenId) public {
    require(isStakingActive, "Staking is not active.");
    require(!tokenStaked(tokenId), "Token is already staked.");

    _addTokenToOwner(msg.sender, tokenId);
    totalSupply++;
    tokenOwners[tokenId] = msg.sender;
    timelocks[tokenId] = block.timestamp;
    balances[msg.sender] += 1;

    magnifiedDividendCorrections[tokenId] = magnifiedDividendCorrections[tokenId]
      .sub( (magnifiedDividendPerShare.mul(1)).toInt256Safe() );

    target.safeTransferFrom(msg.sender, address(this), tokenId);

    emit Staked(msg.sender, tokenId);
  }

  function unstake(uint256 tokenId) public {
    require(tokenStaked(tokenId), "Token is not staked.");
    require(tokenOwners[tokenId] == msg.sender, "Owner of the token should unstake.");

    _removeTokenFromOwner(msg.sender, tokenId);
    totalSupply--;
    tokenOwners[tokenId] = address(0);
    timelocks[tokenId] = 0;
    balances[msg.sender] -= 1;

    magnifiedDividendCorrections[tokenId] = magnifiedDividendCorrections[tokenId]
      .add( (magnifiedDividendPerShare.mul(1)).toInt256Safe() );

    target.safeTransferFrom(address(this), msg.sender, tokenId);

    emit Unstaked(msg.sender, tokenId);
  }

  function distributeDividends() public {
    require(isStakingActive, "Staking is not active.");
    uint amount = address(this).balance;
    require(totalSupply > 0, "There should be atleast one staked token.");
    require(amount > 0, "Insufficient balance to distrubute.");

    magnifiedDividendPerShare = magnifiedDividendPerShare.add(
      (amount).mul(magnitude) / totalSupply
    );

    weth.deposit{ value: amount }();

    emit DividendsDistributed(msg.sender, amount);
  }

  function withdrawMultipleDividends(uint256[] calldata tokenIds) public {
    for (uint256 i=0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      if (enoughTimeSpentFor(tokenId)) {
        withdrawDividend(tokenId);
      }
    }
  }

  function withdrawDividend(uint256 tokenId) public {
    require(isStakingActive, "Staking is not active.");
    require(enoughTimeSpentFor(tokenId), "This token is not staked for timelock period.");

    uint256 _withdrawableDividend = withdrawableDividendOf(tokenId);
    address _user = tokenOwners[tokenId];

    if (_withdrawableDividend > 0) {
      withdrawnDividends[tokenId] = withdrawnDividends[tokenId].add(_withdrawableDividend);
      emit DividendWithdrawn(_user, _withdrawableDividend);
      weth.transfer(_user, _withdrawableDividend);
    }
  }

  function multipleEligibleClaims(uint256[] calldata tokenIds) public view returns(uint256) {
    uint256 total;
    for (uint256 i=0 ; i<tokenIds.length; i++) {
      if (enoughTimeSpentFor(tokenIds[i])) {
        total += withdrawableDividendOf(tokenIds[i]);
      }
    }
    return total;
  }

  function eligibleClaims(uint256 tokenId) public view returns(uint256) {
    if (enoughTimeSpentFor(tokenId)) {
      return withdrawableDividendOf(tokenId);
    }
    return 0;
  }

  function dividendOf(uint256 tokenId) public view returns(uint256) {
    return withdrawableDividendOf(tokenId);
  }

  function withdrawableDividendOf(uint256 tokenId) internal view returns(uint256) {
    return accumulativeDividendOf(tokenId).sub(withdrawnDividends[tokenId]);
  }

  function withdrawnDividendOf(uint256 tokenId) public view returns(uint256) {
    return withdrawnDividends[tokenId];
  }

  function accumulativeDividendOf(uint256 tokenId) public view returns(uint256) {
    return magnifiedDividendPerShare.mul(_balanceOf(tokenId)).toInt256Safe()
      .add(magnifiedDividendCorrections[tokenId]).toUint256Safe() / magnitude;
  }

  function enoughTimeSpentFor(uint256 tokenId) public view returns(bool) {
    if (!tokenStaked(tokenId)) {
      return false;
    }
    uint256 startDate = timelocks[tokenId];
    uint256 endDate = block.timestamp;
    return (endDate - startDate) >= timelockPeriod;
  }

  function tokenStaked(uint256 tokenId) public view returns(bool) {
    return tokenOwners[tokenId] != address(0);
  }

  function stakedTokensOf(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balances[_owner];
    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = _ownedTokens[_owner][index];
      }
      return result;
    }
  }

  function _balanceOf(uint256 tokenId) internal view returns(uint256) {
    if (tokenStaked(tokenId)) {
      return 1;
    }
    return 0;
  }

  function _addTokenToOwner(address to, uint256 tokenId) private {
    uint256 length = balances[to];
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  function _removeTokenFromOwner(address from, uint256 tokenId) private {
    uint256 lastTokenIndex = balances[from] - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }

  event Staked(
    address indexed from,
    uint256 tokenId
  );

  event Unstaked(
    address indexed from,
    uint256 tokenId
  );

  event Received(
    address indexed from,
    uint256 weiAmount
  );

  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}
