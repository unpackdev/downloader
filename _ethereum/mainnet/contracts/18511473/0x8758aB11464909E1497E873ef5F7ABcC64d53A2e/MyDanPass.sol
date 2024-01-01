// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Errors.sol";

contract MyDanPass is ERC721Enumerable, Ownable {
    using Strings for uint256;
    address public minter;
    uint256 public nextTokenId;
    string private _baseURIExtended;
    event Minted(address to, uint256 tokenId);

    constructor() ERC721("MyDanPass", "MDP") {
        minter = msg.sender;
        mint(msg.sender);
    }

    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert NotMinter();
        }
        _;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function mint(address to) public onlyMinter returns (uint256) {
        uint256 currentTokenId = nextTokenId;
        _mint(to, currentTokenId);
        nextTokenId += 1;
        emit Minted(to, currentTokenId);
        return currentTokenId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory base = _baseURI();
        return string(abi.encodePacked(base, tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }
}
