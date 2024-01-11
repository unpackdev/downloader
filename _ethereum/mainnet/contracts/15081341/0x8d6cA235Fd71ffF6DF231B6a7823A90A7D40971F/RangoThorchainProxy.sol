// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./BaseProxyContract.sol";
import "./IRangoThorchain.sol";

/// @title thorchain proxy logic
/// @author Thinking Particle
/// @dev This contract stores the address of the RangoThorchain contract and implements the logic for interacting with it. This contract can swap the given input token to another token and then pass the output to the RangoThorchain contract.
/// @notice This contract can swap the token to another token before passing it to thorchain for another swap.
contract RangoThorchainProxy is BaseProxyContract {

    // @dev keccak256("exchange.rango.thorchain.proxy")
    bytes32 internal constant RANGO_THORCHAIN_PROXY_NAMESPACE = hex"2d408556142e9c30601bb067c0631f1a23ffac1d1598afa3da595c26103e4966";

    /// @notice stores the address of RangoThorchain contract
    struct ThorchainProxyStorage {
        address rangoThorchainAddress;
    }

    /// @notice Notifies that the RangoThorchain.sol contract address is updated
    /// @param _oldAddress The previous deployed address
    /// @param _newAddress The new deployed address
    event RangoThorchainAddressUpdated(address _oldAddress, address _newAddress);

    /// @notice updates RangoThorchain contract address, only callable by the owner.
    function updateRangoThorchainAddress(address _address) external onlyOwner {
        ThorchainProxyStorage storage thorchainProxyStorage = getThorchainProxyStorage();

        address oldAddress = thorchainProxyStorage.rangoThorchainAddress;
        thorchainProxyStorage.rangoThorchainAddress = _address;

        emit RangoThorchainAddressUpdated(oldAddress, _address);
    }

    /// @notice Swap tokens if necessary, then pass it to RangoThorchain
    /// @dev Swap tokens if necessary, then pass it to RangoThorchain. If no swap is required (calls.length==0) the provided token is passed to RangoThorchain without change.
    /// @param request The swap information used to check input and output token addresses and balances, as well as the fees if any. Together with calls param, determines the swap logic before passing to Thorchain.
    /// @param calls The contract call data that is used to swap (can be empty if no swap is needed). Together with request param, determines the swap logic before passing to Thorchain.
    /// @param tcRouter The router contract address of Thorchain. This cannot be hardcoded because Thorchain can upgrade its router and the address might change.
    /// @param tcVault The vault address of Thorchain. This cannot be hardcoded because Thorchain rotates vaults.
    /// @param thorchainMemo The transaction memo used by Thorchain which contains the thorchain swap data. More info: https://dev.thorchain.org/thorchain-dev/memos
    /// @param expiration The expiration block number. If the tx is included after this block, it will be reverted.
    function swapInToThorchain(
        SwapRequest memory request,
        Call[] calldata calls,

        address tcRouter,
        address tcVault,
        string calldata thorchainMemo,
        uint expiration
    ) external payable whenNotPaused nonReentrant {
        ThorchainProxyStorage storage thorchainProxyStorage = getThorchainProxyStorage();
        require(thorchainProxyStorage.rangoThorchainAddress != NULL_ADDRESS, 'Thorchain wrapper address in Rango contract not set');

        (, uint out) = onChainSwapsInternal(request, calls);
        uint value = 0;
        if (request.toToken != NULL_ADDRESS) {
            approve(request.toToken, thorchainProxyStorage.rangoThorchainAddress, out);
        } else {
            value = out;
        }

        IRangoThorchain(thorchainProxyStorage.rangoThorchainAddress).swapInToThorchain{value : value}(
            request.toToken,
            out,
            tcRouter,
            tcVault,
            thorchainMemo,
            expiration
        );
    }

    /// @notice reads the storage using namespace
    /// @return s the stored value for ThorchainProxyStorage using the namespace
    function getThorchainProxyStorage() internal pure returns (ThorchainProxyStorage storage s) {
        bytes32 namespace = RANGO_THORCHAIN_PROXY_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}