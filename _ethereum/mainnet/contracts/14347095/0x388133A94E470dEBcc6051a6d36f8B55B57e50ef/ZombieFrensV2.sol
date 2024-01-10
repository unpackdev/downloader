// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./IKeyClaimable.sol";

contract ZombieFrensV2 is Ownable, Pausable, ERC721Enumerable, IKeyClaimable {

    IERC721 public keyToTheCity;

    string private baseURI;

    event HumanMinted(address owner, uint256 tokenId);

    constructor(address _keyToTheCity) ERC721("Zombie Frens", "ZFREN") {
        keyToTheCity = IERC721(_keyToTheCity);
    }

    function claimKeyFor(address owner) external override onlyKey whenNotPaused {
        uint256 tokenId = totalSupply();
        _safeMint(owner, tokenId);
        emit HumanMinted(owner, tokenId);
    }

    function claimKeysFor(address owner, uint8 amount) external override onlyKey whenNotPaused {
        for(uint8 i=0;i<amount;++i) {
            uint256 tokenId = totalSupply() + i;
            _safeMint(owner, tokenId);
            emit HumanMinted(owner, tokenId);
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