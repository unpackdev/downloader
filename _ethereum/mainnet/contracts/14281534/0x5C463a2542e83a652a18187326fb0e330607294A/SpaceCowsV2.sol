// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./UpgradeNFT.sol";

import "./ISpaceMilk.sol";
import "./ISale.sol";

contract SpaceCowsV2 is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable, UpgradeNFT {
    using StringsUpgradeable for uint256;

    modifier isAllowAddress(address _addr) {
        require(_addr == address(SaleContract), "Can't call this");
        _;
    }

    struct MintingInfo {
        uint256 tier;
        uint256 rate;
    }
    mapping(uint256 => MintingInfo) public mintingInfo;
    mapping(address => uint256) public mintingRate;

    uint256 public collectionIndex;

    string public baseExtension;
    string public baseURI;
    string public notRevealedUri;
    bool public revealed;

    ISpaceMilk public YieldToken;
    ISale public SaleContract;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        string memory _notRevealedUri,
        address _tokenAddress,
        uint256 _namePrice,
        uint256 _bioPrice
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ChangeAttr_init(_namePrice, _bioPrice);

        revealed = false;
        notRevealedUri = _notRevealedUri;
        baseURI = _baseUri;
        baseExtension = ".json";
        YieldToken = ISpaceMilk(_tokenAddress);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function _baseURI() internal view virtual override(ERC721Upgradeable) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setRevealed(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /** Custom Code */
    function changeCustomName(uint256 _tokenId, string memory _newName) public override {
		YieldToken.burn(msg.sender, collectionIndex, nameChangePrice);
		super.changeCustomName(_tokenId, _newName);
	}

    function changeBio(uint256 _tokenId, string memory _newBio) public override {
		YieldToken.burn(msg.sender, collectionIndex, bioChangePrice);
		super.changeBio(_tokenId, _newBio);
	}

    function getMintingRate(address _address) public view returns (uint256) {
        return mintingRate[_address];
    }

    function setTokenAddress(address _newTokenAddress) public onlyOwner {
        YieldToken = ISpaceMilk(_newTokenAddress);
    }

    function setSalesAddress(address _newSalesAddress) public onlyOwner {
        SaleContract = ISale(_newSalesAddress);
    }

    function setCollectionIndex(uint256 _newCollectionIndex) public onlyOwner {
        collectionIndex = _newCollectionIndex;
    }

    function getReward() external {
        address user = msg.sender;

		YieldToken.updateReward(user, address(0), collectionIndex);
		YieldToken.getReward(user, collectionIndex);
	}

    function mint(address _user, uint256 _tokenId, uint256 _tier, uint256 _rate)
    external
    isAllowAddress(msg.sender) {
        _mint(_user, _tokenId, _tier, _rate);
    }

    /** Custom Overrides */
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable) {
        super.transferFrom(from, to, tokenId); 
        uint256 _mintingRate = mintingInfo[tokenId].rate;
        mintingRate[from] -= _mintingRate;
        mintingRate[to] += _mintingRate;
        YieldToken.updateReward(from, to, collectionIndex);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable) {
        super.safeTransferFrom(from, to, tokenId, "");
        uint256 _mintingRate = mintingInfo[tokenId].rate;
        mintingRate[from] -= _mintingRate;
        mintingRate[to] += _mintingRate;
        YieldToken.updateReward(from, to, collectionIndex);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721Upgradeable)
    returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory currentBaseURI;

        if(revealed == false) {
            currentBaseURI = notRevealedUri;
        } else {
            currentBaseURI = _baseURI();
        }

        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function _mint(address _to, uint256 _tokenId, uint256 _tier, uint256 _rate)
    internal
    virtual {
        mintingInfo[_tokenId] = MintingInfo(_tier, _rate);
        super._mint(_to, _tokenId);
        mintingRate[_to] += mintingInfo[_tokenId].rate;
        YieldToken.updateUserTimeOnMint(_to, collectionIndex);
    }

    function updateMintingRate(uint256 _tokenId, uint256 _rate) external onlyOwner {
        _updateMintingRate(_tokenId, _rate);
    }

    function _updateMintingRate(uint256 _tokenId, uint256 _rate) internal {
        uint256 oldRate = mintingInfo[_tokenId].rate;
        uint256 tier = mintingInfo[_tokenId].tier;
        address owner = ownerOf(_tokenId);
        mintingInfo[_tokenId] = MintingInfo(tier, _rate);
        mintingRate[owner] += _rate - oldRate;
    }
}