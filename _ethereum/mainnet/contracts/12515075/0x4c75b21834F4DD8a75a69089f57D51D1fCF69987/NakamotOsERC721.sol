// SPDX-License-Identifier: MIT

pragma solidity 0.6.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./NakamotOsERC20.sol";

contract NakamotOsERC721 is ERC721, Ownable {
    using SafeMath for uint256;

    NakamotOsERC20 public nakamotOsErc20;

    string public _tokenURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory tokenURI_
    ) public ERC721(name, symbol) {
        _tokenURI = tokenURI_;
    }

    modifier onlyNakamotOs() {
        require(_msgSender() == address(nakamotOsErc20), "Caller must the NakamotOsERC20");
        _;
    }

    function setERC20Address(address erc20Address) external onlyOwner {
        nakamotOsErc20 = NakamotOsERC20(erc20Address);
    }

    function tokenURI(uint256 /* tokenId */) public view override returns (string memory) {
        return _tokenURI;
    }

    function mint(address recipient, uint256 amount) external onlyNakamotOs returns (bool) {
        for (uint i = 0; i < amount; i = i.add(1)) {
            _safeMint(recipient, totalSupply());
        }

        return true;
    }
}
