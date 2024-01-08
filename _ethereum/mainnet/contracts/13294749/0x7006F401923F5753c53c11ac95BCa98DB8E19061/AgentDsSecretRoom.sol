// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721TradableRandomMint.sol";

contract AgentDsSecretRoom is ERC721TradableRandomMint {
    string public contractURI;

    bool public isMetadataLocked = false;

    address public originalOwner;

    /**
     * @dev Throws if called by any account other than the original owner.
     */
    modifier onlyOriginalOwner() {
        require(originalOwner == _msgSender(), "Caller is not the original owner");
        _;
    }

    // They are watching you!

    constructor(address _proxyRegistryAddress)
        ERC721TradableRandomMint("Agent D's Secret Room", "ASR", _proxyRegistryAddress)
        
    {
        originalOwner = owner();
    }

    function lockContractMetadata() public onlyOriginalOwner {
        require(!isMetadataLocked, "The Contract has already been locked!");
        isMetadataLocked = true;
    }

    // One does not simply enter the basement!

    function setBaseUri(string memory uri) public onlyOriginalOwner {
        require(!isMetadataLocked, "The Contract has been locked, toughluck!");
        baseURI = uri;
    }

    // Don't eat those donuts!

    function setContractUri(string memory uri) public onlyOriginalOwner {
        require(!isMetadataLocked, "The Contract has been locked, toughluck!");
        contractURI = uri;
    }
}
