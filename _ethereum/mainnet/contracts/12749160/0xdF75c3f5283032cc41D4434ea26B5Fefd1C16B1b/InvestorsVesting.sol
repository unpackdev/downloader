//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IOneUp.sol";
import "./IVesting.sol";


contract InvestorsVesting is IVesting, Ownable {
    using SafeMath for uint256;

    uint256 public start;
    uint256 public finish;

    uint256 public constant RATE_BASE = 10000; // 100%
    uint256 public constant VESTING_DELAY = 90 days;

    IOneUp public immutable oneUpToken;

    struct Investor {
        // If user keep his tokens during the all vesting delay
        // He becomes privileged user and will be allowed to do some extra stuff
        bool isPrivileged;

        // Tge tokens will be available for claiming immediately after UNI liquidity creation
        // Users will receive all available TGE tokens with 1 transaction
        uint256 tgeTokens;

        // Released locked tokens shows amount of tokens, which user already received
        uint256 releasedLockedTokens;

        // Total locked tokens shows total amount, which user should receive in general
        uint256 totalLockedTokens;
    }

    mapping(address => Investor) internal _investors;

    event NewPrivilegedUser(address investor);
    event TokensReceived(address investor, uint256 amount, bool isLockedTokens);

    // ------------------------
    // CONSTRUCTOR
    // ------------------------

    constructor(address token_) {
        oneUpToken = IOneUp(token_);
    }

    // ------------------------
    // SETTERS (ONLY PRE-SALE)
    // ------------------------

    /// @notice Add investor and receivable amount for future claiming
    /// @dev This method can be called only by Public sale contract, during the public sale
    /// @param investor Address of investor
    /// @param amount Tokens amount which investor should receive in general
    /// @param lockPercent Which percent of tokens should be available immediately (after start), and which should be locked
    function submit(
        address investor,
        uint256 amount,
        uint256 lockPercent
    ) public override onlyOwner {
        require(start == 0, 'submit: Can not be added after liquidity pool creation!');

        uint256 tgeTokens = amount.mul(lockPercent).div(RATE_BASE);
        uint256 lockedAmount = amount.sub(tgeTokens);

        _investors[investor].tgeTokens = _investors[investor].tgeTokens.add(tgeTokens);
        _investors[investor].totalLockedTokens = _investors[investor].totalLockedTokens.add(lockedAmount);
    }

    /// @notice Remove investor data
    /// @dev Owner will remove investors data if they called emergency exit method
    /// @param investor Address of investor
    function reset(address investor) public override onlyOwner {
      delete _investors[investor];
    }

    /// @notice The same as submit, but for multiply investors
    /// @dev Provided arrays should have the same length
    /// @param investors Array of investors
    /// @param amounts Array of receivable amounts
    /// @param lockPercent Which percent of tokens should be available immediately (after start), and which should be locked
    function submitMulti(
        address[] memory investors,
        uint256[] memory amounts,
        uint256 lockPercent
    ) external override onlyOwner {
        uint256 investorsLength = investors.length;

        for (uint i = 0; i < investorsLength; i++) {
            submit(investors[i], amounts[i], lockPercent);
        }
    }

    /// @notice Start vesting process
    /// @dev After this method investors can claim their tokens
    function setStart() external override onlyOwner {
        start = block.timestamp;
        finish = start.add(VESTING_DELAY);
    }

    // ------------------------
    // SETTERS (ONLY CONTRIBUTOR)
    // ------------------------

    /// @notice Claim TGE tokens immediately after start
    /// @dev Can be called once for each investor
    function claimTgeTokens() external override {
        require(start > 0, 'claimTgeTokens: TGE tokens not available now!');

        // Get user available TGE tokens
        uint256 amount = _investors[msg.sender].tgeTokens;
        require(amount > 0, 'claimTgeTokens: No available tokens!');

        // Update user available TGE balance
        _investors[msg.sender].tgeTokens = 0;

        // Mint tokens to user address
        oneUpToken.mint(msg.sender, amount);

        emit TokensReceived(msg.sender, amount, false);
    }

    /// @notice Claim locked tokens
    function claimLockedTokens() external override {
        require(start > 0, 'claimLockedTokens: Locked tokens not available now!');

        // Get user releasable tokens
        uint256 availableAmount = _releasableAmount(msg.sender);
        require(availableAmount > 0, 'claimLockedTokens: No available tokens!');

        // If investors claim all tokens after vesting finish they become privileged
        // No need to validate flag every time, as users will claim all tokens with this method
        if (_investors[msg.sender].releasedLockedTokens == 0 && block.timestamp > finish) {
            _investors[msg.sender].isPrivileged = true;

            emit NewPrivilegedUser(msg.sender);
        }

        // Update user released locked tokens amount
        _investors[msg.sender].releasedLockedTokens = _investors[msg.sender].releasedLockedTokens.add(availableAmount);

        // Mint tokens to user address
        oneUpToken.mint(msg.sender, availableAmount);

        emit TokensReceived(msg.sender, availableAmount, true);
    }

    // ------------------------
    // GETTERS
    // ------------------------

    /// @notice Get current available locked tokens
    /// @param investor address
    function getReleasableLockedTokens(address investor) external override view returns (uint256) {
        return _releasableAmount(investor);
    }

    /// @notice Get investor data
    /// @param investor address
    function getUserData(address investor) external override view returns (
        uint256 tgeAmount,
        uint256 releasedLockedTokens,
        uint256 totalLockedTokens
    ) {
        return (
            _investors[investor].tgeTokens,
            _investors[investor].releasedLockedTokens,
            _investors[investor].totalLockedTokens
        );
    }

    /// @notice Is investor privileged or not, it will be used from external contracts
    /// @param account user address
    function isPrivilegedInvestor(address account) external override view returns (bool) {
        return _investors[account].isPrivileged;
    }

    // ------------------------
    // INTERNAL
    // ------------------------

    function _releasableAmount(address investor) private view returns (uint256) {
        return _vestedAmount(investor).sub(_investors[investor].releasedLockedTokens);
    }

    function _vestedAmount(address investor) private view returns (uint256) {
        uint256 userMaxTokens = _investors[investor].totalLockedTokens;

        if (start == 0 || block.timestamp < start) {
            return 0;
        } else if (block.timestamp >= finish) {
            return userMaxTokens;
        } else {
            uint256 timeSinceStart = block.timestamp.sub(start);
            return userMaxTokens.mul(timeSinceStart).div(VESTING_DELAY);
        }
    }

    function getStartTime() external view returns (uint256) {
        return start;
    }
}
