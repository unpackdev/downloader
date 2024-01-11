//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";

import "./ECDSA.sol";
import "./Ownable.sol";

contract TVHeadX is Ownable, ERC721A {
    uint256 constant public maxSupply = 100;
    address public minter;

    event SetMinter(address minter);

    constructor() ERC721A("SNW TV Head X", "SNW-X", 100, 100) {
    }

    function mint(address user, uint256 quantity) external onlyMinter {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(totalSupply() + quantity <= maxSupply, "Over Max Supply");
        _safeMint(user, quantity);
    }

        // ====== Minter ======
    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "Invalid minter");
        minter = _minter;
        emit SetMinter(_minter);
    }

    modifier onlyMinter() {
        require(minter == msg.sender, "Only minter");
        _;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _baseURI = uri;
    }
    

}