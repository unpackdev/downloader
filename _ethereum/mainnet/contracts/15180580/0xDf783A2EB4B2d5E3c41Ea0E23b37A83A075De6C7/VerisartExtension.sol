// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: verisart

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorCore.sol";

import "./IERC721.sol";
import "./Strings.sol";
import "./ERC165.sol";

import "./EnumerableSet.sol";
import "./Ownable.sol";

// Version: Extension-1.0
contract VerisartExtension is AdminControl {
    address private _creator;
    address private _mintingWallet;
    bool private _tokenURIPrefixSet = false;

    constructor(address creator, address mintingWallet) {
        _creator = creator;
        _mintingWallet = mintingWallet;
    }

    // @dev: should only be called once the extension has been registered
    // Can only be set once to prevent rug pulling
    function setTokenURIPrefixExtension(string calldata prefix)
        public
        adminRequired
    {
        require(
            _tokenURIPrefixSet == false,
            "Token URI prefix can only be set once"
        );
        ICreatorCore(_creator).setTokenURIPrefixExtension(prefix);

        _tokenURIPrefixSet = true;
    }

    function setMintingWallet(address mintingWallet) public adminRequired {
        _mintingWallet = mintingWallet;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl)
        returns (bool)
    {
        return
            AdminControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function mint(address to, string memory _tokenURI) public minterOnly {
        IERC721CreatorCore(_creator).mintExtension(to, _tokenURI);
    }

    function walletForMinting() external view returns (address) {
        return _mintingWallet;
    }

    modifier minterOnly() {
        require(_mintingWallet == msg.sender, "Must be minter wallet only");
        _;
    }
}
