// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./ERC721EnumerableUpgradeable.sol";
import "./CouponExtension.sol";

abstract contract ERC721CouponExtension is CouponExtension, ERC721EnumerableUpgradeable {

    function __ERC721CouponExtension_init(address signer) internal onlyInitializing {
        __CouponExtension_init(signer);
    }

    function __ERC721CouponExtension_init_unchained() internal onlyInitializing {
    }

    function mint(uint256 price, uint256 amount, uint256 deadline, bytes calldata signature) public payable {
        _checkCoupon(0, price, amount, deadline, signature);
        saleEthRecipient.transfer(msg.value);
        for (uint256 i=0; i<amount; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControlEnumerableUpgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[10] private __gap;

}
