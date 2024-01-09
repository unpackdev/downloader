// SPDX-License-Identifier: Unlicense

pragma solidity >=0.6.0 <0.8.0;

import "./ISatelliteWSCC.sol";
import "./MultiBridge.sol";

/**
 * wSCC Satellite MultiBridge
 *
 * Attributes:
 * - Mints satellite wSCC tokens to a user from an authorized member after a cross-chain migration
 * - Burns satellite wSCC tokens from a user by an authorized member to initiate a cross-chain migration
 * - Burns satellite wSCC tokens from the bridge and emits a cross-chain fee migration event
 */
contract SatelliteMultiBridge is MultiBridge {
    using SafeERC20 for ISatelliteWSCC;

    // Mintable / Burnable Token
    ISatelliteWSCC private immutable SATELLITE_wSCC;

    event CrossChainFees(uint256 amount);
    event CrossChainBurn(address indexed from, uint256 amount);

    // Gas Units Required for an `unlock`
    uint256 private constant SATELLITE_UNLOCK_COST = 152982;

    constructor(ISatelliteWSCC SatelliteWSCC, uint256[] memory chainList)
        public
        MultiBridge(SATELLITE_UNLOCK_COST, chainList)
    {
        SATELLITE_wSCC = SatelliteWSCC;
    }

    function lock(
        address to,
        uint256 amount,
        uint256 chain
    ) external payable override validFunding() validChain(chain) {
        // Zero Security Assumptions
        uint256 lockAmount = SATELLITE_wSCC.balanceOf(address(this));
        SATELLITE_wSCC.safeTransferFrom(msg.sender, address(this), amount);
        lockAmount = SATELLITE_wSCC.balanceOf(address(this)).sub(lockAmount);

        SATELLITE_wSCC.burn(msg.sender, lockAmount);

        uint256 id = crossChainTransfer++;

        outwardTransfers[id] = CrossChainTransfer(
            to,
            false,
            safe88(
                tx.gasprice,
                "SatelliteMultiBridge::lock: tx gas price exceeds 32 bits"
            ),
            amount,
            chain
        );

        // Optionally captured by off-chain migrator
        emit CrossChainTransferLocked(msg.sender, id);
    }

    function unlock(
        uint256 satelliteChain,
        uint256 i,
        address to,
        uint256 amount
    ) external override onlyOperator() {
        bytes32 h = keccak256(abi.encode(satelliteChain, i, to, amount));

        uint256 refundGasPrice = inwardTransferFunding[h];
        if (refundGasPrice == PROCESSED) return;
        inwardTransferFunding[h] = PROCESSED;

        SATELLITE_wSCC.mint(to, amount);
        if (refundGasPrice != 0)
            msg.sender.sendValue(refundGasPrice * SATELLITE_UNLOCK_COST);

        emit CrossChainTransferUnlocked(to, amount, satelliteChain);
    }

    function burn(address from, uint256 amount) external onlyOwner() {
        SATELLITE_wSCC.burn(from, amount);
        emit CrossChainBurn(from, amount);
    }

}
