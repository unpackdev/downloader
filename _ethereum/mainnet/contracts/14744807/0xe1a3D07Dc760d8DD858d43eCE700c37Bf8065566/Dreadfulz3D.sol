pragma solidity 0.8.11;

import "./Strings.sol";
import "./ERC20PresetMinterPauserUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC20PresetMinterPauser.sol";
import "./IERC721Receiver.sol";
import "./OpenSeaGasFreeListing.sol";
import "./IMerkle.sol";

contract Dreadfulz3D is ERC721EnumerableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, IERC721Receiver {
    using Strings for uint256;
    string public baseUri;
    string public extension;  

    ERC721EnumerableUpgradeable public dreadfulz2D;
    ERC20PresetMinterPauserUpgradeable public dread;

    mapping(address => bool) admins;
    mapping(uint256 => bool) _paid;

    uint256 public cost;

    function initialize() virtual public initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
        __ERC721_init("Dreadfulz3D", "Dreadfulz3D");
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __Ownable_init();
        admins[address(this)] = true;
        baseUri  = "https://ipfs.io/ipfs/QmP4EBh4pXq11e9DaYhkFoRWTi4DUovSjQJMWij6bKGrjj/";
        extension = ".json";
        cost = 150 ether;
    }

    function adminMint(address to, uint256[] memory tokenIds) external adminOrOwner {
        for(uint256 i; i < tokenIds.length; i++) {
            _safeMint(to, tokenIds[i]);
        }
    }

    function hasPaid(uint256 id) public view returns (bool) {
        return _paid[id];
    }

    function setPaid(uint256 id, bool val) public adminOrOwner {
        _paid[id] = val;
    }

    function swap(uint256[] memory tokenIds) external whenNotPaused nonReentrant {
        uint256 requiredBurn;

        for(uint256 i; i < tokenIds.length; i++) {
            uint256 current = tokenIds[i];  
            ERC721EnumerableUpgradeable nft = correctToken(current);
            if(!hasPaid(current)) {
                requiredBurn += cost;
                _paid[current] = true;
            }            
            nft.safeTransferFrom(msg.sender, address(this), current);
        }
        if(requiredBurn > 0) dread.burnFrom(msg.sender, requiredBurn);
    }

    function _swap(uint256[] memory tokenIds, address from, address burnAddress) public adminOrOwner {
        uint256 requiredBurn;

        for(uint256 i; i < tokenIds.length; i++) {
            uint256 current = tokenIds[i];  
            ERC721EnumerableUpgradeable nft = correctToken(current);
            if(!hasPaid(current)) {
                requiredBurn += cost;
                _paid[current] = true;
            }            
            nft.safeTransferFrom(from, address(this), current);
        }
        if(requiredBurn > 0) dread.burnFrom(burnAddress, requiredBurn);
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 holdingAmount = balanceOf(owner);
        uint256[] memory ids = new uint256[](holdingAmount);

        for(uint256 i = 0; i < holdingAmount; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }

        return ids;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = baseUri;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        extension
                    )
                )
                : "";
    }

    function setExtension(string memory _extension) external adminOrOwner {
        extension = _extension;
    }

    function setUri(string memory _uri) external adminOrOwner {
        baseUri = _uri;
    }

    function setPaused(bool _paused) external adminOrOwner {
        if(_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external whenNotPaused returns (bytes4) {
        if(msg.sender == address(dreadfulz2D)) {
            require(hasPaid(tokenId), "Has not been paid");
            if(_exists(tokenId)) {
                _safeTransfer(
                    address(this),
                    from,
                    tokenId,
                    ""
                );   
            } else {
                _safeMint(from, tokenId);
            }
        }
        if(msg.sender == address(this)) {
            dreadfulz2D.transferFrom(
                address(this),
                from,
                tokenId
            );
        }
        return this.onERC721Received.selector;
    }

    function saveNFT(IERC721EnumerableUpgradeable nft, uint256 tokenId, address to) external adminOrOwner {
        nft.safeTransferFrom(address(this), to, tokenId);
    }

    function setDreadfulz2D(ERC721EnumerableUpgradeable _dreadfulz) external adminOrOwner {
        dreadfulz2D = _dreadfulz;
    }

    function setDreadz(ERC20PresetMinterPauserUpgradeable _dread) external adminOrOwner {
        dread = _dread;
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return super.isApprovedForAll(owner, operator) || OpenSeaGasFreeListing.isApprovedForAll(owner, operator) || admins[msg.sender];
    }

    function setCost(uint256 _cost) external adminOrOwner {
        cost = _cost;
    }
     
    function addAdmin(address _admin) external adminOrOwner {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external adminOrOwner {
        delete admins[_admin];
    }

    modifier adminOrOwner() {
        require(msg.sender == owner() || admins[msg.sender], "Unauthorized");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721EnumerableUpgradeable, ERC721Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721EnumerableUpgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function correctToken(uint256 id) public view returns (ERC721EnumerableUpgradeable ) {
        if(_exists(id) && ownerOf(id) == address(this)) return dreadfulz2D;
        if(!_exists(id)) return dreadfulz2D;
        bool _has = ownerOf(id) == address(this);
        return _has ? dreadfulz2D : this;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721EnumerableUpgradeable, ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}