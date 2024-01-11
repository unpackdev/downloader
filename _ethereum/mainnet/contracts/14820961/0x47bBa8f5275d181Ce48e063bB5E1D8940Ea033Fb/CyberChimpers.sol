// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

/**
 * Chimpers living in cyberpunk verse
 */
contract CyberChimpers is ERC721A, Ownable, ReentrancyGuard {
    
    string private __baseURI = "ipfs://QmVSHu2nt6RqA6FLzk4RZLDQpcijhrUUiCh5iRa7DavAx5/";

    uint256 private _max_mint = 6;

    mapping(address => uint256) _account_mint;

    constructor() ERC721A("Cyber Chimpers", "CC", 22, 4444) {}

    function mint(uint256 quantity) external {
        require(totalSupply() + quantity <= collectionSize, "already mint out");
        require(quantity <= maxBatchSize, "can only mint less than the maxBatchSize");
        address to = msg.sender;
        require(_account_mint[to] + quantity <= _max_mint, "over the max minting");
        
        _safeMint(to, quantity);
        _account_mint[to] += quantity;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return __baseURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        __baseURI = baseURI;
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function queryMintAmount(address owner) external view returns(uint256) {
        return _account_mint[owner];
    }
}
