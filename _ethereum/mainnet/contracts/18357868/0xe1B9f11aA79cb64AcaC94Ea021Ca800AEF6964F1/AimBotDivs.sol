// 
//
//

// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./AimBot.sol";
import "./IUniswapV2Router.sol";

pragma solidity ^0.8.19;


contract DivPayingToken is ERC20 {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

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

  uint256 public totalDividendsDistributed;

  event DividendsDistributed(address user, uint256 amount);
  event DividendWithdrawn(address user, uint256 amount);

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {

  }

  /// @dev Distributes dividends whenever ether is paid to this contract.
  receive() external payable {
    distributeDividends();
  }

  /// @notice Distributes ether to token holders as dividends.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
  /// About undistributed ether:
  ///   In each distribution, there is a small amount of ether not distributed,
  ///     the magnified amount of which is
  ///     `(msg.value * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amount of undistributed ether
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed ether in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved ether, so we don't do that.
  function distributeDividends() public virtual payable {
    require(totalSupply() > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (msg.value).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, msg.value);

      totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() public virtual {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      (bool success,) = user.call{value: _withdrawableDividend, gas: 3000}("");

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }


  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view returns(uint256) {
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


contract AimBotDivs is DivPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    AimBot token = AimBot(payable(0x0c48250Eb1f29491F1eFBeEc0261eb556f0973C7));
    AimBotDivsBalanceHandler balanceHandler;

    mapping (address => bool) public excludedFromDividends;

    uint256 public closeTime;

    uint256 public constant claimGracePeriod = 30 days;

    event ExcludeFromDividends(address indexed account);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);
    event DividendReinvested(address indexed account, uint256 amount);

    constructor() DivPayingToken("AIMBOT_Divs", "AIMBOT_Divs") {
        balanceHandler = new AimBotDivsBalanceHandler();
    }

    function updateBalanceHandler(address _balanceHandler) external onlyOwner {
        balanceHandler = AimBotDivsBalanceHandler(_balanceHandler);
        balanceHandler.handleBalanceChanged(msg.sender);
        balanceHandler.balanceOf(msg.sender);
    }

    bool noWarning;

    function _transfer(address, address, uint256) internal override {
        require(false, "No transfers allowed");
        noWarning = noWarning;
    }

    function withdrawDividend() public override {
        require(false, "withdrawDividend disabled. Use the 'claim' function instead.");
        noWarning = noWarning;
    }

    function claim(address account, bool reinvest, uint256 amountOutMin) external {
        require(msg.sender == account, "Invalid claimer.");
        require(closeTime == 0 || block.timestamp < closeTime + claimGracePeriod, "closed");

        if(!reinvest) {
            _withdrawDividendOfUser(payable(account));
        }
        else {
            IUniswapV2Router02 router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = address(token);

            uint256 withdrawableDividend = withdrawableDividendOf(account);

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: withdrawableDividend}(
                amountOutMin,
                path,
                account,
                block.timestamp
            );

            withdrawnDividends[account] = withdrawnDividends[account].add(withdrawableDividend);
            emit DividendReinvested(account, withdrawableDividend);
        }
    }

    function excludeFromDividends(address account) external {
        require(msg.sender == address(token) || msg.sender == owner());

    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);

    	emit ExcludeFromDividends(account);
    }

    function getAccount(address _account)
        public view returns (
            address account,
            uint256 withdrawableDividends,
            uint256 totalDividends) {
        account = _account;
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
    }

    function accountData(address _account)
        public view returns (
            address account,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 dividendTokenBalance,
            uint256 dividendTokenBalanceLive) {
        account = _account;
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
        dividendTokenBalance = balanceOf(account);
        dividendTokenBalanceLive = balanceHandler.balanceOf(account);
    }

    function updateBalance(address payable account) external {
        if(excludedFromDividends[account]) {
            return;
        }

        balanceHandler.handleBalanceChanged(account);
        _setBalance(account, balanceHandler.balanceOf(account));
    }

    function updateBalances(address payable[] calldata accounts) external {
        for(uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            if(excludedFromDividends[account]) {
                return;
            }

            balanceHandler.handleBalanceChanged(account);
            _setBalance(account, balanceHandler.balanceOf(account));
        }
    }


    //If the dividend contract needs to be updated, we can close
    //this one, and let people claim for a month
    //After that is over, we can take the remaining funds and
    //use for the project
    function close() external onlyOwner {
        require(closeTime == 0, "already closed");
        closeTime = block.timestamp;
    }

    //Only allows funds to be taken if contract has been closed for a month
    function takeFunds() external onlyOwner {
        require(closeTime >= 0 && block.timestamp >= closeTime + claimGracePeriod, "cannot take yet");
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }
}

contract AimBotDivsBalanceHandler {
    AimBot token = AimBot(payable(0x0c48250Eb1f29491F1eFBeEc0261eb556f0973C7));

    mapping (address => uint256) tokenBalance;
    mapping (address => uint256) startTime;

    function handleBalanceChanged(address account) external {
        uint256 newBalance = token.balanceOf(account);

        if(newBalance < tokenBalance[account] || tokenBalance[account] == 0) {
            startTime[account] = block.timestamp;
        }

        tokenBalance[account] = newBalance;
    }

    function balanceOf(address account) external view returns (uint256) {
        uint256 epochs = 30 days / 12;
        uint256 multiplier = epochs + epochs * (block.timestamp - startTime[account]) / 30 days;
        if(multiplier > epochs * 2) {
            multiplier = epochs * 2;
        }
        return tokenBalance[account] * multiplier / epochs;
    }
}
