// contracts/SchnoodleV7.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./SchnoodleV7Base.sol";

/// @author Jason Payne (https://twitter.com/Neo42)
contract SchnoodleV7 is SchnoodleV7Base, AccessControlUpgradeable {
    address private _schnoodleStaking;
    address private _stakingFund;
    uint256 private _stakingRate;
    mapping(address => TokenMeter) private _sellsTrackers;

    bytes32 public constant LIQUIDITY = keccak256("LIQUIDITY");
    bytes32 public constant STAKING_CONTRACT = keccak256("STAKING_CONTRACT");

    function configure(bool testnet, address liquidityToken, address schnoodleStaking) external onlyOwner {
        require(_stakingFund == address(0), "Schnoodle: already configured");

        _setupRole(DEFAULT_ADMIN_ROLE, owner());
        _setupRole(LIQUIDITY, liquidityToken);
        _setupRole(STAKING_CONTRACT, schnoodleStaking);
        _schnoodleStaking = schnoodleStaking;
        _stakingFund = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1))))));

        _stakingRate = 40;
        configure(testnet);
    }

    // Transfer overrides

    function _beforeTokenTransfer(address operator, address from, address to, uint256 amount) internal virtual override {
        // Ensure the sender has enough unstaked balance to perform the transfer
        if (from != address(0)) {
            uint256 standardAmount = _getStandardAmount(amount);
            uint256 balance = balanceOf(from);
            require(standardAmount > balance || standardAmount <= balance - lockedBalanceOf(from), "Schnoodle: transfer amount exceeds unstaked balance");
        }

        super._beforeTokenTransfer(operator, from, to, amount);
    }

    function payFees(address to, uint256 amount, uint256 reflectedAmount, function(address, address, uint256) internal transferCallback) internal virtual override {
        super.payFees(to, amount, reflectedAmount, transferCallback);
        payFund(to, _stakingFund, amount, _stakingRate, transferCallback);
    }

    function isLiquidityToken(address account) internal view virtual override returns(bool)
    {
        return hasRole(LIQUIDITY, account);
    }

    // Staking functions

    function stakingFund() external view returns (address) {
        return _stakingFund;
    }

    function changeStakingRate(uint256 rate) external onlyOwner {
        _stakingRate = rate;
        emit StakingRateChanged(rate);
    }

    function stakingRate() external view returns (uint256) {
        return _stakingRate;
    }

    function stakingReward(address account, uint256 netReward, uint256 grossReward) external {
        require(hasRole(STAKING_CONTRACT, _msgSender()));
        _transferFromReflected(_stakingFund, account, _getReflectedAmount(netReward));

        // Burn the unused part of the gross reward
        _burn(_stakingFund, grossReward - netReward, "", "");
    }

    // Calls to the SchnoodleStaking proxy contract

    function lockedBalanceOf(address account) private returns(uint256) {
        if (_schnoodleStaking == address(0)) return 0;
        (bool success, bytes memory result) = _schnoodleStaking.call(abi.encodeWithSignature("lockedBalanceOf(address)", account));
        assert(success);
        return abi.decode(result, (uint256));
    }

    event StakingRateChanged(uint256 rate);
}
