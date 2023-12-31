// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721AUpgradeable.sol";

contract ParaX is
    Initializable,
    OwnableUpgradeable,
    ERC721AUpgradeable
{
    uint256 private tokenId_;
    string private tokenURI_;

    function initialize() public initializerERC721A initializer {
        __Ownable_init();
        __ERC721A_init("ParaX Medal", "XMEDAL");
        _setTokenURI(
            "https://ipfs.io/ipfs/QmcuVLoBB6QZipC1EpPciuKodyCXRVgh3YbYh9jzVarMzY"
        );
    }

    function mint(address[] calldata users) external onlyOwner {
        uint256 userLength = users.length;
        for (uint256 index = 0; index < userLength; index++) {
            _mint(users[index], 1);
        }
    }

    function setTokenURI(string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenURI);
    }

    function _setTokenURI(string memory _tokenURI) internal {
        tokenURI_ = _tokenURI;
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return tokenURI_;
    }
}
