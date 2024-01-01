// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";

contract AXYSNFT is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    IERC2981Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    struct RoyaltyInfo {
        address receiver;
        uint rate;
    }

    bool public isPreMintingAllowed;
    bool public isNftTransferedAllowed;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bytes32 private randomString;

    uint256 public maxRoyaltyPercentage;
    uint256 public royaltyPercentage;

    address public AXYSPAYMASTER;
    address public MARKETPLACE_CONTRACT;
    address public royaltyReceiverAddress;

    mapping(bytes4 => bool) private _supportedInterfaces;
    mapping(address => uint256[]) tokenIdsCreatorAddress;
    mapping(uint256 => RoyaltyInfo) private royalties;

    event NftCreated(
        uint256 tokenId,
        uint256 price,
        uint256 royaltyPercentage,
        address to,
        address ownerAddress,
        string uri
    );

    modifier onlyOwnerOrMarketplace() {
        require(
            _msgSender() == MARKETPLACE_CONTRACT || _msgSender() == owner(),
            "Only owner or marketplace contract can call"
        );
        _;
    }

    modifier onlyAXYSPaymaster() {
        require(
            _msgSender() == AXYSPAYMASTER,
            "Only AXYSPAYMASTER Contract can call"
        );
        _;
    }

    modifier isUnlocked() {
        require(isNftTransferedAllowed, "NFT is still locked");
        _;
    }

    function initialize(
        bytes32 _randomString,
        address _axys_paymaster,
        address _royaltyReceiverAddress
    ) public initializer {
        __ERC721_init("AXYS-NFT", "AXYS");
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        _registerInterface(_INTERFACE_ID_ERC2981);
        maxRoyaltyPercentage = 200; // 20% maximum royalty percentage
        royaltyPercentage = 50; // 5% royalty Percentage
        randomString = _randomString;
        AXYSPAYMASTER = _axys_paymaster;
        royaltyReceiverAddress = _royaltyReceiverAddress;
    }

    function setMaxRoyaltyPercentage(
        uint256 _maxRoyaltyPercentage
    ) public onlyOwnerOrMarketplace {
        maxRoyaltyPercentage = _maxRoyaltyPercentage;
    }

    function setRoyaltyPercentage(uint256 _royaltyPercentage) public onlyOwner {
        require(
            _royaltyPercentage <= maxRoyaltyPercentage,
            "Exceeds the royalty limit"
        );
        royaltyPercentage = _royaltyPercentage;
    }

    function setMarketplaceContract(
        address _marketplaceContract
    ) public onlyOwner {
        MARKETPLACE_CONTRACT = _marketplaceContract;
    }

    function setRoyaltyReceiverAddress(
        address _royaltyReceiverAddress
    ) public onlyOwner {
        royaltyReceiverAddress = _royaltyReceiverAddress;
    }

    function setAXYSPaymasterContract(
        address _axysPaymasterContract
    ) public onlyOwner {
        AXYSPAYMASTER = _axysPaymasterContract;
    }

    function setisNftTransferedAllowed(
        bool _isNftTransferedAllowed
    ) public onlyOwner {
        isNftTransferedAllowed = _isNftTransferedAllowed;
    }

    function setIsMintingAllowed(bool _isPreMintingAllowed) public onlyOwner {
        isPreMintingAllowed = _isPreMintingAllowed;
    }

    function lazyMint(
        address _to,
        bytes32 _randomString,
        string memory _uri,
        uint256 _price
    ) external payable whenNotPaused onlyAXYSPaymaster {
        safeMint(_to, _randomString, _uri, _price);
    }

    function preMintNft(
        address _to,
        bytes32 _randomString,
        string memory _uri
    ) external whenNotPaused onlyAXYSPaymaster {
        require(isPreMintingAllowed, "Minting not allowed");
        safeMint(_to, _randomString, _uri, 0);
    }

    function mintNftByAdmins(
        address _to,
        bytes32 _randomString,
        string memory _uri
    ) external whenNotPaused onlyAXYSPaymaster {
        safeMint(_to, _randomString, _uri, 0);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(
        address to,
        bytes32 _randomString,
        string memory uri,
        uint256 _price
    ) internal whenNotPaused {
        require(_randomString == randomString, "Mismatched random string");
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        randomString = keccak256(
            abi.encodePacked(msg.sender, tokenId, _randomString)
        );
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        royalties[tokenId].receiver = royaltyReceiverAddress;
        royalties[tokenId].rate = royaltyPercentage;
        tokenIdsCreatorAddress[to].push(tokenId);

        setApprovalForAll(MARKETPLACE_CONTRACT, true);

        emit NftCreated(tokenId, _price, royaltyPercentage, to, owner(), uri);
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        receiver = royalties[_tokenId].receiver;
        if (
            royalties[_tokenId].rate > 0 &&
            royalties[_tokenId].receiver != address(0)
        ) {
            royaltyAmount = (_salePrice * royalties[_tokenId].rate) / 1000;
        }
    }

    function getRoyaltyPercentage(uint256 _tokenId) public view returns (uint) {
        return royalties[_tokenId].rate;
    }

    function getCreator(uint256 _tokenId) public view returns (address) {
        return royalties[_tokenId].receiver;
    }

    function getMintedTokenIdsOfAddress(
        address _ownerAddress
    ) external view returns (uint256[] memory) {
        uint256 numberOfExistingTokens = getTotalMintedTokens();
        uint256 numberOfTokensOwned = balanceOf(_ownerAddress);
        uint256[] memory ownedTokenIds = new uint256[](numberOfTokensOwned);

        uint256 currentIndex = 0;
        for (uint256 i = 0; i < numberOfExistingTokens; i++) {
            uint256 _tokenId = i + 1;
            if (ownerOf(_tokenId) == _ownerAddress) {
                ownedTokenIds[currentIndex] = _tokenId;
                currentIndex++;
            }
        }
        return ownedTokenIds;
    }

    function getCreatorTokenIds(
        address _creatorAddress
    ) public view returns (uint256[] memory) {
        return tokenIdsCreatorAddress[_creatorAddress];
    }

    // get randomString
    function getRandomString() public view onlyOwner returns (bytes32) {
        return randomString;
    }

    function getTotalMintedTokens() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        virtual
        override(IERC721Upgradeable, ERC721Upgradeable)
        isUnlocked
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        virtual
        override(IERC721Upgradeable, ERC721Upgradeable)
        isUnlocked
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        virtual
        override(IERC721Upgradeable, ERC721Upgradeable)
        isUnlocked
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function approve(
        address to,
        uint256 tokenId
    )
        public
        virtual
        override(IERC721Upgradeable, ERC721Upgradeable)
        isUnlocked
    {
        super.approve(to, tokenId);
    }

    function _burn(
        uint256 tokenId
    )
        internal
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
        whenNotPaused
    {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(
            ERC721URIStorageUpgradeable,
            ERC721Upgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            _supportedInterfaces[interfaceId];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}
