// cryptomonserclub.com
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Pausable.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract MonsterPortalBadge is ERC721Enumerable, ERC721Pausable, Ownable {
    using SafeMath for uint256;
    
    string _baseTokenURI = "ipfs://QmeacGfGj5AVUd7fd1xvMDwCPscfMkmWMmxe6Zet3iS8Q4/";
    
    uint public MAX_BADGE = 500;
    uint public mintLimitPerUser = 1;
    
    bool public canDestroyPortal = false;
    
    mapping(address => uint) public badgeOwnersMintLimit;
    
    event DestroyPortal(
        address from,
        uint256 portalTokenId
    );
    
    constructor() ERC721("Monster Portal Badge", "MPB") {}
    
    function mintBadge() external {
        require(canDestroyPortal == false, "MonsterPortalBadge: Minting badge is over.");
        require(badgeOwnersMintLimit[_msgSender()] < mintLimitPerUser, "MonsterPortalBadge: Badge limit exceeded.");
        require(totalSupply().add(1) <= MAX_BADGE, "MonsterPortalBadge: All badge portals are minted.");
        badgeOwnersMintLimit[_msgSender()] = badgeOwnersMintLimit[_msgSender()].add(1);
        _safeMint(_msgSender(), totalSupply().add(1));
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function destroyPortal(uint256 tokenPortalId) public {
        require(canDestroyPortal, "MonsterPortalBadge: Destroying portal is not enable yet.");
        require(
            _isApprovedOrOwner(_msgSender(), tokenPortalId),
            "MonsterPortalBadge: caller is not the owner nor approved address."
        );
        _burn(tokenPortalId);
        emit DestroyPortal(_msgSender(), tokenPortalId);
    }
    
    
    //  ====== Admin only functions ======
    function pause() external onlyOwner() {
        _pause();
    }
    
    function unpause() external onlyOwner() {
        _unpause();
    }
    
    function updateCanDestroyPortal(bool isDestroy) external onlyOwner() {
        canDestroyPortal = isDestroy;
    }
    
    function updateMintLimitPerUser(uint256 limitPerUser) external onlyOwner() {
        mintLimitPerUser = limitPerUser;
    }
    
    function updateBadgeSupply(uint256 _badgeSupply) external onlyOwner() {
        MAX_BADGE = _badgeSupply;
    }
    
    function updateBaseURI(string memory newURI) external onlyOwner() {
        _baseTokenURI = newURI;
    }

}