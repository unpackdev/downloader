// SPDX-License-Identifier: WTFPL

pragma solidity 0.8.13;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeCast.sol";
import "./ECDSA.sol";

/// @dev A mintable ERC20 token that allows anyone to pay and distribute ZERO
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: https://github.com/Roger-Wu/erc1726-dividend-paying-token/blob/master/contracts/DividendPayingToken.sol
contract ZeroMoney is ERC20, Ownable {
    using SafeCast for uint256;
    using SafeCast for int256;

    // For more discussion about choosing the value of `magnitude`,
    //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 public constant MAGNITUDE = 2**128;
    uint256 public constant HALVING_PERIOD = 21 days;
    uint256 public constant FINAL_ERA = 60;

    address public signer;
    uint256 public startedAt;
    mapping(address => bool) public blacklisted;
    mapping(address => bool) public claimed;

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

    event ChangeSigner(address indexed signer);
    event SetBlacklisted(address indexed account, bool blacklisted);
    event Start();
    /// @dev This event MUST emit when ZERO is distributed to token holders.
    /// @param weiAmount The amount of distributed ZERO in wei.
    event DividendsDistributed(uint256 weiAmount);
    /// @dev This event MUST emit when an address withdraws their dividend.
    /// @param to The address which withdraws ZERO from this contract.
    /// @param weiAmount The amount of withdrawn ZERO in wei.
    event Withdraw(address indexed to, uint256 weiAmount);

    constructor(address _signer) ERC20("thezero.money", "ZERO") {
        signer = _signer;
        blacklisted[address(this)] = true;

        emit ChangeSigner(_signer);
        emit SetBlacklisted(address(this), true);
    }

    function currentHalvingEra() public view returns (uint256) {
        if (startedAt == 0) return type(uint256).max;
        uint256 era = (block.timestamp - startedAt) / HALVING_PERIOD;
        return FINAL_ERA < era ? FINAL_ERA : era;
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param account The address of a token holder.
    /// @return The amount of dividend in wei that `account` can withdraw.
    function withdrawableDividendOf(address account) public view returns (uint256) {
        return accumulativeDividendOf(account) - withdrawnDividends[account];
    }

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param account The address of a token holder.
    /// @return The amount of dividend in wei that `account` has withdrawn.
    function withdrawnDividendOf(address account) public view returns (uint256) {
        return withdrawnDividends[account];
    }

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(account) = withdrawableDividendOf(account) + withdrawnDividendOf(account)
    /// = (magnifiedDividendPerShare * balanceOf(account) + magnifiedDividendCorrections[account]) / magnitude
    /// @param account The address of a token holder.
    /// @return The amount of dividend in wei that `account` has earned in total.
    function accumulativeDividendOf(address account) public view returns (uint256) {
        return
            ((magnifiedDividendPerShare * balanceOf(account)).toInt256() + magnifiedDividendCorrections[account])
            .toUint256() / MAGNITUDE;
    }

    function changeSigner(address _signer) external onlyOwner {
        signer = _signer;

        emit ChangeSigner(_signer);
    }

    function setBlacklisted(address account, bool _blacklisted) external onlyOwner {
        blacklisted[account] = _blacklisted;

        emit SetBlacklisted(account, _blacklisted);
    }

    function start() external onlyOwner {
        _mint(msg.sender, totalSupply());
        startedAt = block.timestamp;

        emit Start();
    }

    function claim(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(!claimed[msg.sender], "ZERO: CLAIMED");

        bytes32 message = keccak256(abi.encodePacked(msg.sender));
        require(ECDSA.recover(ECDSA.toEthSignedMessageHash(message), v, r, s) == signer, "ZERO: UNAUTHORIZED");

        claimed[msg.sender] = true;

        _mint(msg.sender, 1 ether);
    }

    /// @dev Internal function that mints tokens to an account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] -= (magnifiedDividendPerShare * value).toInt256();
    }

    /// @dev Internal function that transfer tokens from one address to another.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param amount The amount to be transferred.
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._transfer(from, to, amount);

        int256 _magCorrection = (magnifiedDividendPerShare * amount).toInt256();
        magnifiedDividendCorrections[from] += _magCorrection;
        magnifiedDividendCorrections[to] -= _magCorrection;

        if (startedAt > 0 && !blacklisted[from]) {
            _distributeDividends(amount);
        }
    }

    /// @notice Distributes ZERO to token holders as dividends.
    /// @dev It emits the `DividendsDistributed` event if the amount of received ZERO is greater than 0.
    /// About undistributed ZERO:
    ///   In each distribution, there is a small amount of ZERO not distributed,
    ///     the magnified amount of which is
    ///     `(msg.value * magnitude) % totalSupply()`.
    ///   With a well-chosen `magnitude`, the amount of undistributed ZERO
    ///     (de-magnified) in a distribution can be less than 1 wei.
    ///   We can actually keep track of the undistributed ZERO in a distribution
    ///     and try to distribute it in the next distribution,
    ///     but keeping track of such data on-chain costs much more than
    ///     the saved ZERO, so we don't do that.
    function _distributeDividends(uint256 amount) private {
        uint256 era = (block.timestamp - startedAt) / HALVING_PERIOD;
        if (FINAL_ERA <= era) {
            return;
        }

        amount = amount / (2**era);
        magnifiedDividendPerShare += ((amount * MAGNITUDE) / totalSupply());
        _mint(address(this), amount);
        emit DividendsDistributed(amount);
    }

    /// @notice Withdraws dividends distributed to the sender.
    /// @dev It emits a `Withdraw` event if the amount of withdrawn ZERO is greater than 0.
    function withdrawDividend() public {
        uint256 _withdrawableDividend = withdrawableDividendOf(msg.sender);
        require(_withdrawableDividend > 0, "ZERO: ZERO_DIVIDEND");

        withdrawnDividends[msg.sender] += _withdrawableDividend;
        _transfer(address(this), msg.sender, _withdrawableDividend);
        emit Withdraw(msg.sender, _withdrawableDividend);
    }

    /// @dev External function that burns an amount of the token of a given account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param value The amount that will be burnt.
    function burn(uint256 value) public {
        _burn(msg.sender, value);

        magnifiedDividendCorrections[msg.sender] += (magnifiedDividendPerShare * value).toInt256();
    }
}
