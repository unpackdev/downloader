// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./ERC1967Proxy.sol";

import "./ERC721Burnable.sol";

contract ERC721BurnableFactory {
    event Deployed(address indexed creator, address indexed newContract);

    address public implementation;

    constructor() {
        implementation = address(new ERC721Burnable());
    }

    function createERC721Burnable(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        address royaltyReceiver_,
        uint256 royaltyBps_,
        uint256 initialSupply_,
        address initialSupplyReceiver_,
        address contractOwner_,
        address gaslessListingManager_
    ) external returns (address) {
        ERC1967Proxy proxy = new ERC1967Proxy(
            implementation,
            abi.encodeWithSelector(
                ERC721Burnable(address(0)).initialize.selector,
                name_,
                symbol_,
                baseTokenURI_,
                royaltyReceiver_,
                royaltyBps_,
                initialSupply_,
                initialSupplyReceiver_,
                gaslessListingManager_
            )
        );

        ERC721Burnable(address(proxy)).transferOwnership(contractOwner_);

        emit Deployed(msg.sender, address(proxy));
        return address(proxy);
    }
}
