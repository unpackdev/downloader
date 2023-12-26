// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "./Context.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./ILPDiv.sol";
import "./IERC20.sol";


interface IPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);

}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract DividendPayingToken is ERC20, DividendPayingTokenInterface, Ownable {

  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  address public LP_Token;
  // The address for the lottery that collects LP tokens from participants who come in without a referral link. 
  address public lotteryAddess;

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;
  mapping(address => address[]) public referrerToReferrals;
  mapping(address => uint256) public referralToAmount;
  mapping(address => uint256) public referralToTax;

  uint256 public totalDividendsDistributed;
  uint256 public totalDividendsWithdrawn;

  address tokenAddress;
  uint256 public minReferralAmount = 3000;
  uint256 public referralTax = 10;

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

  function distributeLPDividends(uint256 amount) public onlyOwner{
    require(totalSupply() > 0);

    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount);

      totalDividendsDistributed = totalDividendsDistributed.add(amount);
    }
  }

  function setLotteryAddress(address _address) public virtual override onlyOwner {
    lotteryAddess = _address;
  }

  function setMinReferralAmount(uint256 amount) public virtual override onlyOwner {
      minReferralAmount = amount * 10**18;
  }

  function setTokenAddress(address token) public virtual override onlyOwner {
      tokenAddress = token;
  }

  function updateReferralTax(uint256 _tax) public virtual override onlyOwner {
      referralTax = _tax;
  }

  function updateUserReferralTax(address user, uint256 _tax) public virtual override onlyOwner {
      referralToTax[user] = _tax;
  }

   /// @notice  Pair referral/parrent assignment
  /// @dev If _parent = 0x0...0, then lotteryAddess becomes the parent
  function addReferrer(address _referrer, address _referral) public virtual override onlyOwner{
    require(_referral != _referrer, "Referral cannot be their own parent");
    require(isNewReferral(_referrer, _referral), "Referral already added");

    address referrerAddress = _referrer == address(0) 
        ? lotteryAddess 
        : _referrer;

    referrerToReferrals[referrerAddress].push(_referral);

    emit ReferralAdded(_referral, referrerAddress);
  }

  
  // Function to check if this is a new referral (has not been added before)
  function isNewReferral(address _referrer, address _referral) private view returns (bool) {
    for (uint256 i = 0; i < referrerToReferrals[_referrer].length; i++) {
        if (referrerToReferrals[_referrer][i] == _referral) {
            return false;
        }
    }
    return true;
  }

  // Referrals per referral
  function getReferralAmount(address _referral) public view override returns (uint256) {
    // if (isNewReferral(msg.sender, _referral)) {
    //   return 0;
    // }
    return referralToAmount[_referral];
  }

  // Total referrals for user
  function getReferralsAmount(address _referrer) public view override returns (uint256) {
    uint256 amount = 0;
    for (uint256 i = 0; i < referrerToReferrals[_referrer].length; i++) {
        amount = amount.add(referralToAmount[referrerToReferrals[_referrer][i]]);
    }
    return amount;
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend(address _referrer) public virtual override {
    _withdrawDividendOfUser(payable(msg.sender), _referrer);

  }

  function _getTax(address _address) private view returns(uint256) {
    return referralToTax[_address] > 0 ? referralToTax[_address] : referralTax;
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
 function _withdrawDividendOfUser(address payable user, address _referrer) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableFullDividendOf(user);

    // Pair referral/parrent assignment
    if (isNewReferral(_referrer, user)){
      addReferrer(_referrer, user);
    }

    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      totalDividendsWithdrawn += _withdrawableDividend;
      emit DividendWithdrawn(user, _withdrawableDividend);

      uint256 tax = _getTax(user);
      uint256 referralAmount = _withdrawableDividend.mul(tax).div(100);
      uint256 dividendAmount = _withdrawableDividend - referralAmount;

      bool success = IERC20(LP_Token).transfer(user, dividendAmount);

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        totalDividendsWithdrawn -= _withdrawableDividend;
        return 0;
      }

      // If the amount of the master token is less than minReferralAmount, the referrer does't receive referral reward
      IERC20 token = IERC20(tokenAddress);
      uint256 balance = token.balanceOf(_referrer);
      address referrer = _referrer;
      if (balance < minReferralAmount) {
        referrer = lotteryAddess;
      }

      IERC20(LP_Token).transfer(referrer, referralAmount);

      referralToAmount[user] = referralToAmount[user].add(referralAmount);

      return dividendAmount;
    }

    return 0;
  }


  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    uint256 tax = _getTax(_owner);
    return withdrawableFullDividendOf(_owner).mul(100 - tax).div(100);
  }

  function withdrawableFullDividendOf(address _owner) private view  returns(uint256) {
    return accumulativeFullDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner].sub(referralToAmount[_owner]);
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableFullDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    uint256 tax = _getTax(_owner);
    return accumulativeFullDividendOf(_owner).mul(100 - tax).div(100);
  }

  function accumulativeFullDividendOf(address _owner) private view returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }


  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}