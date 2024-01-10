// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./IKeyClaimable.sol";

contract HumanFrens is Ownable, Pausable, ERC721Enumerable, IKeyClaimable {

    IERC721 public keyToTheCity;

    string private baseURI;

    event HumanMinted(address owner, uint256 tokenId);

    constructor(address _keyToTheCity) ERC721("Human Frens", "ZFHUMAN") {
        keyToTheCity = IERC721(_keyToTheCity);
    }

    function mintTo(address to, uint8 amount) external onlyOwner {
        uint256 tokenId = totalSupply();
        for(uint8 i=0;i<amount;++i) {
            _safeMint(to, tokenId + i);
        }
    }

    function claimKeyFor(address owner) external override onlyKey whenNotPaused {
        uint256 tokenId = totalSupply();
        _safeMint(owner, tokenId);
        emit HumanMinted(owner, tokenId);
    }

    function claimKeysFor(address owner, uint8 amount) external override onlyKey whenNotPaused {
        uint256 tokenId = totalSupply();
        for(uint8 i=0;i<amount;++i) {
            _safeMint(owner, tokenId + i);
            emit HumanMinted(owner, tokenId);
        }
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        require(_owner != address(0), "owner_zero_address");
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount <= 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    modifier onlyKey() {
        require(msg.sender == address(keyToTheCity), "caller_not_key");
        _;
    }
}