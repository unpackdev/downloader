// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./ERC721Royalty.sol";

contract NousPsycheNFT is ERC721, ERC721Enumerable, ERC721Royalty, Pausable, AccessControl {
    uint256 public immutable maxTokens;
    uint256 public immutable mintPrice;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant WHITELISTED = keccak256("WHITELISTED");
    
    mapping(address => bool) private whitelistedClaimed;
    uint256 private _nextTokenId = 0;
    // metadata URI
    string private _baseTokenURI;

    address public royaltyAddress;
    uint96 public royaltyBps;

    event CommunityBuy(address from, uint tokenId);

    constructor(uint256 _mintPrice, uint256 _maxTokens)
        ERC721("NousPsyche", "NPSY")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        mintPrice = _mintPrice;
        maxTokens = _maxTokens;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setBaseURI(string calldata baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return hasRole(WHITELISTED, _address);
    }

    function isWhitelistedClaimed(address _address) public view returns (bool) {
        return whitelistedClaimed[_address];
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        royaltyAddress = _receiver;
        royaltyBps = _feeNumerator;
        
        _setDefaultRoyalty(royaltyAddress, royaltyBps);
    }

    function buy() external payable {
        require(msg.value >= mintPrice, "Insufficient fee");
        require(totalSupply() < maxTokens, "Exceeded max token limit");

        // Token id will start from 0
        if (totalSupply() > 0) {
            _nextTokenId++;
        }
        uint256 tokenId = _nextTokenId;

        _safeMint(msg.sender, tokenId);
    }

    function communityBuy() external payable {
        require(totalSupply() < maxTokens, "Exceeded max token limit");
        require(hasRole(WHITELISTED, msg.sender), "Not whitelisted");
        require(!whitelistedClaimed[msg.sender], "Already claimed");

        // Token id will start from 0
        if (totalSupply() > 0) {
            _nextTokenId++;
        }
        uint256 tokenId = _nextTokenId;

        _safeMint(msg.sender, tokenId);
        emit CommunityBuy(msg.sender, tokenId);

        whitelistedClaimed[msg.sender] = true;
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }
}
