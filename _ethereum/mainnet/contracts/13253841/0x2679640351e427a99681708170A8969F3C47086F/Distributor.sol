pragma solidity ^0.5.0;

import "./Roles.sol";
import "./Crowdsale.sol";

// $$$$$$$$\ $$$$$$$$\ $$\   $$\
// \____$$  |$$  _____|$$$\  $$ |
//     $$  / $$ |      $$$$\ $$ |
//    $$  /  $$$$$\    $$ $$\$$ |
//   $$  /   $$  __|   $$ \$$$$ |
//  $$  /    $$ |      $$ |\$$$ |
// $$$$$$$$\ $$$$$$$$\ $$ | \$$ |
// \________|\________|\__|  \__|

contract Distributor is Crowdsale {
    using SafeMath for uint256;
    using Roles for Roles.Role;

    Roles.Role private _owners;
    IERC20 private _token;
    address private _wallet;

    bool private _active;
    uint256 private _round;
    uint256 private _cap; // total cap in wei
    uint256 private _changeableRate; // token / wei price

    constructor(
        uint256 initialRate,
        address payable wallet,
        IERC20 tokenAddr,
        uint256 cap
    ) public Crowdsale(initialRate, wallet, tokenAddr) {
        require(initialRate > 0, "Initial rate is less than 0");
        require(cap > 0, "Wei Cap is less than 0");
        _owners.add(msg.sender);
        _round = 1;
        _cap = cap;
        _changeableRate = initialRate;
        _token = tokenAddr;
        _wallet = wallet;
    }

    modifier onlyAdmin() {
        require(_owners.has(msg.sender), "DOES_NOT_HAVE_ADMIN_ROLE");
        _;
    }

    function increaseRound(uint256 newRate, uint256 newCap) external onlyAdmin {
        _round = _round.add(1);
        _setRate(newRate);
        _addCap(newCap);
    }

    function setActivity(bool isActive) external onlyAdmin {
        _active = isActive;
    }

    function _setRate(uint256 newRate) private {
        _changeableRate = newRate;
    }

    function _addCap(uint256 additionalCap) private {
        _cap = _cap.add(additionalCap);
    }

    function active() public view returns (bool) {
        return _active;
    }

    function round() public view returns (uint256) {
        return _round;
    }

    function rate() public view returns (uint256) {
        return _changeableRate;
    }

    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev Checks whether the cap has been reached.
     * @return Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        return weiRaised() >= _cap;
    }

    function capLeft() public view returns (uint256) {
        return _cap.sub(weiRaised());
    }

    /**
     * @dev Overrides the original function
     * @return How much token you can purchase
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_changeableRate);
    }

    /**
     * @dev Overrides the original function to use safeTransferFrom
     * @return How much token you can purchase
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransferFrom(_wallet, beneficiary, tokenAmount);
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the funding cap.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(active(), "Crowdsale is Paused");
        require(weiRaised().add(weiAmount) <= _cap, "Exceeds total cap");
    }
}
