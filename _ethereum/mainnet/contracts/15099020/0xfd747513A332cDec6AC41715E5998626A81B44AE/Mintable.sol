// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./MerkleProof.sol";

error AddressNotAllowed();
error CannotMintMoreThan(uint256 amount);
error InvalidMintState();
error MaxMintPerWalletWouldBeReached(uint256 max);
error NeedToSendMoreETH();
error QuantityWouldExceedMaxSupply();
error MintHasNotStarted();
error MintHasEnded();
error MintClosed();

abstract contract Mintable {

    uint32 public constant STATE_MINT_CLOSED = 0;

    uint32 public constant STATE_MINT_ALL = 1;
    uint32 public constant STATE_MINT_ALLOWLIST = 2;
    uint32 public constant STATE_MINT_PUBLIC = 3;


    uint32 private _mintState;


    function _merkleProofGate(address buyer, bytes32[] calldata proof, bytes32 root) internal pure {
        if (proof.length == 0 || !MerkleProof.verify(proof, root, keccak256(abi.encodePacked(buyer)))) {
            revert AddressNotAllowed();
        }
    }

    function _mintGate(bool open) internal pure {
        if (!open) {
            revert MintClosed();
        }
    }

    function _mintGate(uint256 end, uint256 start) internal view {
        if (block.timestamp < start) {
            revert MintHasNotStarted();
        }

        if (end != 0 && block.timestamp > end) {
            revert MintHasEnded();
        }
    }

    function _priceGate(address buyer, uint256 cost, uint256 quantity, uint256 received) internal {
        unchecked {
            uint256 total = cost * quantity;

            if (total < received) {
                revert NeedToSendMoreETH();
            }

            // Refund remaining value
            if (received > total) {
                payable(buyer).transfer(received - total);
            }
        }
    }

    function _setMintState(uint32 state) internal {
        if (state > 3) {
            revert InvalidMintState();
        }

        _mintState = state;
    }

    function _supplyGate(uint256 available, uint256 quantity) internal pure {
        if (quantity > available) {
            revert QuantityWouldExceedMaxSupply();
        }
    }

    function _supplyGate(uint256 available, uint256 max, uint256 minted, uint256 quantity) internal pure {
        _supplyGate(available, quantity);

        if (max > 0) {
            if (quantity > max) {
                revert CannotMintMoreThan({ amount: max });
            }

            if ((minted + quantity) > max) {
                revert MaxMintPerWalletWouldBeReached({ max: max });
            }
        }
    }

    function isMintAllowlist() public view returns(bool) {
        return _mintState == STATE_MINT_ALL || _mintState == STATE_MINT_ALLOWLIST;
    }

    function isMintClosed() public view returns(bool) {
        return _mintState == STATE_MINT_CLOSED;
    }

    function isMintOpen() public view returns(bool) {
        return _mintState != 0;
    }

    function isMintPublic() public view returns(bool) {
        return _mintState == STATE_MINT_ALL || _mintState == STATE_MINT_PUBLIC;
    }
}
