// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IERC721Receiver.sol";

import "./IBeramonium.sol";

contract ProxyMinter is IERC721Receiver {
    function mintAndTransfer(
        IBeramonium beramonium,
        uint256 quantity,
        address recipient
    ) external payable {
        unchecked {
            beramonium.publicSaleMint{value: msg.value}(quantity);

            for (uint256 i = 0; i < quantity; i++) {
                beramonium.transferFrom(
                    address(this),
                    recipient,
                    // BCG tokens are 0-based, hence -1
                    beramonium.totalSupply() - i - 1
                );
            }
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

contract ProxyMinterFactory {
    uint256 private constant MAX_PER_ADDRESS = 4;
    uint256 private constant UNIT_PRICE = 0.045 ether;

    function proxyMint(IBeramonium beramonium, uint256 quantity) external payable {
        require(quantity * UNIT_PRICE == msg.value, "Invalid payment amount");

        unchecked {
            uint256 fullCycles = quantity / MAX_PER_ADDRESS;
            uint256 remainder = quantity % MAX_PER_ADDRESS;

            for (uint256 i = 0; i < fullCycles; i++) {
                new ProxyMinter().mintAndTransfer{value: MAX_PER_ADDRESS * UNIT_PRICE}(
                    beramonium,
                    MAX_PER_ADDRESS,
                    msg.sender
                );
            }

            if (remainder > 0) {
                new ProxyMinter().mintAndTransfer{value: remainder * UNIT_PRICE}(
                    beramonium,
                    remainder,
                    msg.sender
                );
            }
        }
    }
}
