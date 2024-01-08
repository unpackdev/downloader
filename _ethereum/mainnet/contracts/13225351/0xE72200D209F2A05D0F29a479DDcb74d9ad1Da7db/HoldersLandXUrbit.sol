/// SPDX-License-Identifier: GNU Affero General Public License v3.0

pragma solidity 0.8.4;

import "./ERC721Enumerable.sol";

contract HoldersLandXUrbit is ERC721Enumerable {

    address public minter;
    uint256 private _tokenId;

    /// @dev base uri to point to IPFS-hosted metadata
    string private constant baseURI = "ipfs://";

    mapping (uint256 => string) private _mediaHash;

    event NewMinterSet(address indexed oldMinter, address indexed newMinter);

    modifier onlyMinter() {
        require(msg.sender == minter, "This function can only be called by the minter");
        _;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        minter = msg.sender;
        _tokenId = 0;
    }

    function setMinter(address newMinter) external onlyMinter {
        require(newMinter != address(0), "New minter cannot be zero address");
        
        emit NewMinterSet(minter, newMinter);
        
        minter = newMinter;
    }

    function mint(address to, string memory _hash) external onlyMinter {
        _mediaHash[_tokenId] = _hash;
        _safeMint(to, _tokenId);
        _tokenId++;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _mediaHash[tokenId]));
    }

}