// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./draft-ERC20Permit.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Governed.sol";
import "./Pausable.sol";
import "./IAddressList.sol";
import "./IAddressListFactory.sol";

/// @title Holding pool share token
// solhint-disable no-empty-blocks
abstract contract PoolShareToken is ERC20Permit, Pausable, ReentrancyGuard, Governed {
    using SafeERC20 for IERC20;
    IERC20 public immutable token;
    IAddressList public immutable feeWhitelist;
    uint256 public constant MAX_BPS = 10_000;
    address public feeCollector; // fee collector address
    uint256 public withdrawFee; // withdraw fee for this pool

    event Deposit(address indexed owner, uint256 shares, uint256 amount);
    event Withdraw(address indexed owner, uint256 shares, uint256 amount);
    event UpdatedFeeCollector(address indexed previousFeeCollector, address indexed newFeeCollector);
    event UpdatedWithdrawFee(uint256 previousWithdrawFee, uint256 newWithdrawFee);

    constructor(
        string memory _name,
        string memory _symbol,
        address _token
    ) ERC20Permit(_name) ERC20(_name, _symbol) {
        token = IERC20(_token);
        IAddressListFactory factory = IAddressListFactory(0xded8217De022706A191eE7Ee0Dc9df1185Fb5dA3);
        IAddressList _feeWhitelist = IAddressList(factory.createList());
        feeWhitelist = _feeWhitelist;
    }

    /**
     * @notice Update fee collector address for this pool
     * @param _newFeeCollector new fee collector address
     */
    function updateFeeCollector(address _newFeeCollector) external onlyGovernor {
        require(_newFeeCollector != address(0), "fee-collector-address-is-zero");
        require(feeCollector != _newFeeCollector, "same-fee-collector");
        emit UpdatedFeeCollector(feeCollector, _newFeeCollector);
        feeCollector = _newFeeCollector;
    }

    /**
     * @notice Update withdraw fee for this pool
     * @dev Format: 1500 = 15% fee, 100 = 1%
     * @param _newWithdrawFee new withdraw fee
     */
    function updateWithdrawFee(uint256 _newWithdrawFee) external onlyGovernor {
        require(feeCollector != address(0), "fee-collector-not-set");
        require(_newWithdrawFee <= 10000, "withdraw-fee-limit-reached");
        require(withdrawFee != _newWithdrawFee, "same-withdraw-fee");
        emit UpdatedWithdrawFee(withdrawFee, _newWithdrawFee);
        withdrawFee = _newWithdrawFee;
    }

    /**
     * @notice Deposit ERC20 tokens and receive pool shares depending on the current share price.
     * @param _amount ERC20 token amount.
     */
    function deposit(uint256 _amount) external virtual nonReentrant whenNotPaused {
        _deposit(_amount);
    }

    /**
     * @notice Deposit ERC20 tokens with permit aka gasless approval.
     * @param _amount ERC20 token amount.
     * @param _deadline The time at which signature will expire
     * @param _v The recovery byte of the signature
     * @param _r Half of the ECDSA signature pair
     * @param _s Half of the ECDSA signature pair
     */
    function depositWithPermit(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external virtual nonReentrant whenNotPaused {
        IERC20Permit(address(token)).permit(_msgSender(), address(this), _amount, _deadline, _v, _r, _s);
        _deposit(_amount);
    }

    /**
     * @notice Withdraw collateral based on given shares and the current share price.
     * Withdraw fee, if any, will be deduced from given shares and transferred to feeCollector.
     * Burn remaining shares and return collateral.
     * @param _shares Pool shares. It will be in 18 decimals.
     */
    function withdraw(uint256 _shares) external virtual nonReentrant whenNotShutdown {
        _withdraw(_shares);
    }

    /**
     * @notice Withdraw collateral based on given shares and the current share price.
     * @dev Burn shares and return collateral. No withdraw fee will be assessed
     * when this function is called. Only some white listed address can call this function.
     * @param _shares Pool shares. It will be in 18 decimals.
     */
    function whitelistedWithdraw(uint256 _shares) external virtual nonReentrant whenNotShutdown {
        require(feeWhitelist.contains(_msgSender()), "not-a-white-listed-address");
        _withdrawWithoutFee(_shares);
    }

    /**
     * @notice Transfer tokens to multiple recipient
     * @dev Address array and amount array are 1:1 and are in order.
     * @param _recipients array of recipient addresses
     * @param _amounts array of token amounts
     * @return true/false
     */
    function multiTransfer(address[] memory _recipients, uint256[] memory _amounts) external returns (bool) {
        require(_recipients.length == _amounts.length, "input-length-mismatch");
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(transfer(_recipients[i], _amounts[i]), "multi-transfer-failed");
        }
        return true;
    }

    /**
     * @notice Get price per share
     * @dev Return value will be in token defined decimals.
     */
    function pricePerShare() public view returns (uint256) {
        if (totalSupply() == 0 || totalValue() == 0) {
            return convertFrom18(1e18);
        }
        return (totalValue() * 1e18) / totalSupply();
    }

    /// @dev Convert from 18 decimals to token defined decimals. Default no conversion.
    function convertFrom18(uint256 _amount) public view virtual returns (uint256) {
        return _amount;
    }

    /// @dev Returns the token stored in the pool. It will be in token defined decimals.
    function tokensHere() public view virtual returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Returns sum of token locked in other contracts and token stored in the pool.
     * Default tokensHere. It will be in token defined decimals.
     */
    function totalValue() public view virtual returns (uint256);

    /**
     * @dev Hook that is called just before burning tokens. This withdraw collateral from withdraw queue
     * @param _share Pool share in 18 decimals
     */
    function _beforeBurning(uint256 _share) internal virtual returns (uint256) {}

    /**
     * @dev Hook that is called just after burning tokens.
     * @param _amount Collateral amount in collateral token defined decimals.
     */
    function _afterBurning(uint256 _amount) internal virtual returns (uint256) {
        token.safeTransfer(_msgSender(), _amount);
        return _amount;
    }

    /**
     * @dev Hook that is called just before minting new tokens. To be used i.e.
     * if the deposited amount is to be transferred from user to this contract.
     * @param _amount Collateral amount in collateral token defined decimals.
     */
    function _beforeMinting(uint256 _amount) internal virtual {
        token.safeTransferFrom(_msgSender(), address(this), _amount);
    }

    /**
     * @dev Hook that is called just after minting new tokens. To be used i.e.
     * if the deposited amount is to be transferred to a different contract.
     * @param _amount Collateral amount in collateral token defined decimals.
     */
    function _afterMinting(uint256 _amount) internal virtual {}

    /**
     * @dev Calculate shares to mint based on the current share price and given amount.
     * @param _amount Collateral amount in collateral token defined decimals.
     * @return share amount in 18 decimal
     */
    // TODO: handle rounding effect
    function _calculateShares(uint256 _amount) internal view returns (uint256) {
        require(_amount != 0, "amount-is-0");
        return (_amount * 1e18) / pricePerShare();
    }

    /// @dev Deposit incoming token and mint pool token i.e. shares.
    function _deposit(uint256 _amount) internal {
        uint256 _shares = _calculateShares(_amount);
        _beforeMinting(_amount);
        _mint(_msgSender(), _shares);
        _afterMinting(_amount);
        emit Deposit(_msgSender(), _shares, _amount);
    }

    /// @dev Burns shares and returns the collateral value, after fee, of those.
    function _withdraw(uint256 _shares) internal {
        if (withdrawFee == 0) {
            _withdrawWithoutFee(_shares);
        } else {
            require(_shares != 0, "share-is-0");
            uint256 _fee = (_shares * withdrawFee) / MAX_BPS;
            uint256 _sharesAfterFee = _shares - _fee;
            uint256 _amountWithdrawn = _beforeBurning(_sharesAfterFee);
            // Recalculate proportional share on actual amount withdrawn
            uint256 _proportionalShares = _calculateShares(_amountWithdrawn);
            if (_proportionalShares < _sharesAfterFee) {
                // Recalculate shares to withdraw, fee and shareAfterFee
                _shares = (_proportionalShares * MAX_BPS) / (MAX_BPS - withdrawFee);
                _fee = _shares - _proportionalShares;
                _sharesAfterFee = _proportionalShares;
            }
            _burn(_msgSender(), _sharesAfterFee);
            _transfer(_msgSender(), feeCollector, _fee);
            _afterBurning(_amountWithdrawn);
            emit Withdraw(_msgSender(), _shares, _amountWithdrawn);
        }
    }

    /// @dev Burns shares and returns the collateral value of those.
    function _withdrawWithoutFee(uint256 _shares) internal {
        require(_shares != 0, "share-is-0");
        uint256 _amountWithdrawn = _beforeBurning(_shares);
        uint256 _proportionalShares = _calculateShares(_amountWithdrawn);
        if (_proportionalShares < _shares) {
            _shares = _proportionalShares;
        }
        _burn(_msgSender(), _shares);
        _afterBurning(_amountWithdrawn);
        emit Withdraw(_msgSender(), _shares, _amountWithdrawn);
    }
}
