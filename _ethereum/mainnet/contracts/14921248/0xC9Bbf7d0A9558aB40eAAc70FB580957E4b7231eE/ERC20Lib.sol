// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Metadata.sol";

contract ERC20Lib is ERC20Upgradeable, OwnableUpgradeable, Metadata {
    event URLUpdated(string _tokenUrl);

    function init(bytes calldata _implementationData) external initializer {
        string memory name_;
        string memory symbol_;
        address mintTo;
        uint256 totalSupply_;
        string memory tokenURL;
        // add mint_to
        (name_, symbol_, mintTo, totalSupply_, tokenURL) = abi.decode(
            _implementationData,
            (string, string, address, uint256, string)
        );

        __ERC20_init(name_, symbol_);
        _mint(mintTo, totalSupply_);
        __Ownable_init();
        updateMeta(address(this), address(0), tokenURL);
    }

    function updateTokenURL(string memory _tokenURL) external onlyOwner {
        updateMetaURL(address(this), _tokenURL);
        emit URLUpdated(_tokenURL);
    }
}
