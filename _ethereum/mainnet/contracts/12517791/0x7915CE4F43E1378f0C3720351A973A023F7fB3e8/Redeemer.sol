// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./ReentrancyGuard.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./IVUSD.sol";
import "./ITreasury.sol";

/// @title VUSD Redeemer, User can redeem their VUSD with any supported tokens
contract Redeemer is Context, ReentrancyGuard {
    string public constant NAME = "VUSD-Redeemer";
    string public constant VERSION = "1.1.0";

    IVUSD public immutable vusd;

    uint256 public redeemFee; // Default no fee
    uint256 public constant MAX_REDEEM_FEE = 10_000; // 10_000 = 100%

    event UpdatedRedeemFee(uint256 previousRedeemFee, uint256 newRedeemFee);

    constructor(address _vusd) {
        require(_vusd != address(0), "vusd-address-is-zero");
        vusd = IVUSD(_vusd);
    }

    modifier onlyGovernor() {
        require(_msgSender() == governor(), "caller-is-not-the-governor");
        _;
    }

    ////////////////////////////// Only Governor //////////////////////////////

    /// @notice Update redeem fee
    function updateRedeemFee(uint256 _newRedeemFee) external onlyGovernor {
        require(_newRedeemFee <= MAX_REDEEM_FEE, "redeem-fee-limit-reached");
        require(redeemFee != _newRedeemFee, "same-redeem-fee");
        emit UpdatedRedeemFee(redeemFee, _newRedeemFee);
        redeemFee = _newRedeemFee;
    }

    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Redeem token and burn VUSD amount less redeem fee, if any.
     * @param _token Token to redeem, it should be 1 of the supported tokens from treasury.
     * @param _vusdAmount VUSD amount to burn
     */
    function redeem(address _token, uint256 _vusdAmount) external nonReentrant {
        _redeem(_token, _vusdAmount, _msgSender());
    }

    /**
     * @notice Redeem token and burn VUSD amount less redeem fee, if any.
     * @param _token Token to redeem, it should be 1 of the supported tokens from treasury.
     * @param _vusdAmount VUSD amount to burn. VUSD will be burnt from caller
     * @param _tokenReceiver Address of token receiver
     */
    function redeem(
        address _token,
        uint256 _vusdAmount,
        address _tokenReceiver
    ) external nonReentrant {
        _redeem(_token, _vusdAmount, _tokenReceiver);
    }

    /**
     * @notice Current redeemable amount for given token and vusdAmount.
     * If token is not supported by treasury it will return 0.
     * If vusdAmount is higher than current total redeemable of token it will return 0.
     * @param _token Token to redeem
     * @param _vusdAmount VUSD amount to burn
     */
    function redeemable(address _token, uint256 _vusdAmount) external view returns (uint256) {
        ITreasury _treasury = ITreasury(treasury());
        if (_treasury.whitelistedTokens().contains(_token)) {
            uint256 _redeemable = _calculateRedeemable(_token, _vusdAmount);
            return _redeemable > redeemable(_token) ? 0 : _redeemable;
        }
        return 0;
    }

    /// @dev Current redeemable amount for given token
    function redeemable(address _token) public view returns (uint256) {
        return ITreasury(treasury()).withdrawable(_token);
    }

    /// @dev Governor is defined in VUSD token contract only
    function governor() public view returns (address) {
        return vusd.governor();
    }

    /// @dev Treasury is defined in VUSD token contract only
    function treasury() public view returns (address) {
        return vusd.treasury();
    }

    function _redeem(
        address _token,
        uint256 _vusdAmount,
        address _tokenReceiver
    ) internal {
        // In case of redeemFee, We will burn vusdAmount from user and withdraw (vusdAmount - fee) from treasury.
        uint256 _redeemable = _calculateRedeemable(_token, _vusdAmount);
        // Burn vusdAmount
        vusd.burnFrom(_msgSender(), _vusdAmount);
        // Withdraw _redeemable
        ITreasury(treasury()).withdraw(_token, _redeemable, _tokenReceiver);
    }

    /**
     * @notice Calculate redeemable amount based on redeemFee, if any.
     * Also covert 18 decimal VUSD amount to _token defined decimal amount.
     * @return Token amount that user will get after burning vusdAmount
     */
    function _calculateRedeemable(address _token, uint256 _vusdAmount) internal view returns (uint256) {
        uint256 _decimals = IERC20Metadata(_token).decimals();
        uint256 _redeemable = redeemFee != 0 ? _vusdAmount - ((_vusdAmount * redeemFee) / MAX_REDEEM_FEE) : _vusdAmount;
        return _redeemable / 10**(18 - _decimals);
    }
}
