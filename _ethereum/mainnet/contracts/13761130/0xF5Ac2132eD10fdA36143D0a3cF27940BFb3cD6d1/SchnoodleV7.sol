// contracts/SchnoodleV7.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./SchnoodleV7Base.sol";

/// @author Jason Payne (https://twitter.com/Neo42)
contract SchnoodleV7 is SchnoodleV7Base, AccessControlUpgradeable {
    address private _schnoodleFarming;
    address private _farmingFund;
    uint256 private _sowRate;

    bytes32 public constant LIQUIDITY = keccak256("LIQUIDITY");
    bytes32 public constant FARMING_CONTRACT = keccak256("FARMING_CONTRACT");
    bytes32 public constant LOCKED = keccak256("LOCKED");

    function configure(bool testnet, address liquidityToken, address schnoodleFarming) external onlyOwner {
        require(_farmingFund == address(0), "Schnoodle: already configured");

        _setupRole(DEFAULT_ADMIN_ROLE, owner());
        _setupRole(LIQUIDITY, liquidityToken);
        _setupRole(FARMING_CONTRACT, schnoodleFarming);
        _schnoodleFarming = schnoodleFarming;
        _farmingFund = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1))))));

        _sowRate = 40;
        configure(testnet);
    }

    // Transfer overrides

    function _beforeTokenTransfer(address operator, address from, address to, uint256 amount) internal virtual override {
        // Ensure the sender has enough unlocked balance to perform the transfer
        if (from != address(0)) {
            uint256 standardAmount = _getStandardAmount(amount);
            uint256 balance = balanceOf(from);
            require(standardAmount > balance || standardAmount <= balance - lockedBalanceOf(from), "Schnoodle: transfer amount exceeds unlocked balance");
            require(!hasRole(LOCKED, from));
        }

        super._beforeTokenTransfer(operator, from, to, amount);
    }

    function payFees(address to, uint256 amount, uint256 reflectedAmount, function(address, address, uint256) internal transferCallback) internal virtual override {
        super.payFees(to, amount, reflectedAmount, transferCallback);
        payFund(to, _farmingFund, amount, _sowRate, transferCallback);
    }

    function isLiquidityToken(address account) internal view virtual override returns(bool)
    {
        return hasRole(LIQUIDITY, account);
    }

    // Farming functions

    function getFarmingFund() external view returns (address) {
        return _farmingFund;
    }

    function changeSowRate(uint256 rate) external onlyOwner {
        _sowRate = rate;
        emit SowRateChanged(rate);
    }

    function getSowRate() external view returns (uint256) {
        return _sowRate;
    }

    function farmingReward(address account, uint256 netReward, uint256 grossReward) external {
        require(hasRole(FARMING_CONTRACT, _msgSender()));
        _transferFromReflected(_farmingFund, account, _getReflectedAmount(netReward));

        // Burn the unused part of the gross reward
        _burn(_farmingFund, grossReward - netReward, "", "");
    }

    // Calls to the SchnoodleFarming proxy contract

    function lockedBalanceOf(address account) private returns(uint256) {
        if (_schnoodleFarming == address(0)) return 0;
        (bool success, bytes memory result) = _schnoodleFarming.call(abi.encodeWithSignature("lockedBalanceOf(address)", account));
        assert(success);
        return abi.decode(result, (uint256));
    }

    event SowRateChanged(uint256 rate);
}
