// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract CCCFactory is ERC721, Ownable {
    string public baseURI;
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public totalSupply;
    address public cccStore;

    event SetCCCStore(address cccStore);
    event SetBaseURI(string baseURI);

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseURI
    ) ERC721(__name, __symbol) {
        baseURI = __baseURI;
    }

    function setCCCStore(address _cccStore) external onlyOwner {
        cccStore = _cccStore;
        emit SetCCCStore(_cccStore);
    }

    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
        emit SetBaseURI(__baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(address to) external {
        require(totalSupply < MAX_SUPPLY, "Exceeds max supply");
        require(msg.sender == cccStore, "Not cccStore");
        _mint(to, totalSupply);
        totalSupply += 1;
    }
}
