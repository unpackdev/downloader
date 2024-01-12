// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./WAYCFactory.sol";
import "./WarpedApeYachtClub.sol";

contract WAYCFactoryExtendable is WAYCFactory {

    /**
    * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event CollectionExtended(uint256 optionNumber, address indexed NFTAddress);

    struct optionDetail {
        address nftAddress;
        string optionMetadata;
    }

    uint256 public mintPrice = 0.075 ether;
    uint256 public whitelistPrice = 0.05 ether;
    uint256 public limitPerWhitelist = 5;
    uint256 public limitPerAirdrop = 1;
    uint256 public whitelistEndTime;
    uint256 public privateMintTime = 2 hours;
    uint256 private currentOffer = 0;
    uint256 public generalMintCap = 5;

    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public hasAirdrop;
    mapping(address => uint256) public whitelistRemaining;
    mapping(address => uint256) public airdropRemaining;

    mapping(uint256 => optionDetail) private _optionsMap;

    mapping(address => uint256) public generalMintCount;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory _name, string memory _symbol, address _proxyRegistryAddress, string memory _optionMetadata,
            string memory _initialNFTName, string memory _initialNFTSymbol,
            string memory _initialNFTBaseTokenURI, uint256 _initialNFTMaxSupply) WAYCFactory(_name, _symbol, _proxyRegistryAddress){
        addOption(_optionMetadata, _initialNFTName, _initialNFTSymbol, _initialNFTBaseTokenURI, _initialNFTMaxSupply);
    }

    function canMint(uint256 _optionId) public view override returns (bool) {

        return maxSupply > 0 ? WarpedApeYachtClub(_optionsMap[_optionId].nftAddress).canMint() : false;
    }

    function tokenURI(uint256 _optionId) external view override returns (string memory) {
        return _optionsMap[_optionId].optionMetadata;
    }

    function addOption(string memory optionMetadata, string memory _name, string memory _symbol, string memory _baseTokenURI, uint256 _maxSupply) public onlyOwner {
        uint256 currentOptionCount = _numOptions;
        _numOptions += 1;
        optionDetail memory newNFT;

        newNFT.optionMetadata = optionMetadata;
        newNFT.nftAddress = address(new WarpedApeYachtClub(_name, _symbol, proxyRegistryAddress, _baseTokenURI, _maxSupply));
        maxSupply = maxSupply + _maxSupply;
        _optionsMap[currentOptionCount] = newNFT;

        WarpedApeYachtClub(newNFT.nftAddress).transferOwnership(_msgSender());

        emit CollectionExtended(currentOptionCount, newNFT.nftAddress);

        emit Transfer(address(0), owner(), currentOptionCount);
    }

    /**
    * @dev Mints asset(s) in accordance to a specific address with a particular "option". This should be
     * callable only by the contract owner or the owner's Wyvern Proxy (later universal login will solve this).
     * Options should also be delineated 0 - (numOptions() - 1) for convenient indexing.
     * @param _optionId the option id
     * @param _toAddress address of the future owner of the asset(s)
     */
    function mint(uint256 _optionId, address _toAddress) public override {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        require(address(proxyRegistry.proxies(owner())) == _msgSender() || owner() == _msgSender());
        require(canMint(_optionId), "This option cannot be minted anymore");
        WarpedApeYachtClub(_optionsMap[_optionId].nftAddress).mintTo(_toAddress);
        maxSupply = maxSupply - 1;
    }

    function _mint(uint256 _optionId, address _toAddress) private {
        require(canMint(_optionId), "This option cannot be minted anymore");
        WarpedApeYachtClub(_optionsMap[_optionId].nftAddress).mintTo(_toAddress);
        maxSupply = maxSupply - 1;
    }

    function transferFrom(
        address,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator)
    public
    view
    returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }

        return _operatorApprovals[_owner][_operator];
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256) public view returns (address _owner) {
        return owner();
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < _numOptions; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function approve(address to, uint256 tokenId) public virtual {
        address owner = owner();
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner(), to, tokenId);
    }

    function updateWhitelist(address[] memory whitelistAddresses, bool enableWhitelist) public onlyMinter {
        uint256 arraySize = whitelistAddresses.length;

        for(uint256 i = 0; i < arraySize; i++){
            isWhitelisted[whitelistAddresses[i]] = enableWhitelist;
            whitelistRemaining[whitelistAddresses[i]] = limitPerWhitelist;
        }
    }

    function updateAirdropList(address[] memory airdropAddresses, bool enableWhitelist) public onlyMinter {
        uint256 arraySize = airdropAddresses.length;

        for(uint256 i = 0; i < arraySize; i++){
            hasAirdrop[airdropAddresses[i]] = enableWhitelist;
            airdropRemaining[airdropAddresses[i]] = limitPerAirdrop;
        }
    }

    function claimAirdrop() external {
        require(whitelistEndTime > 0);
        require(airdropRemaining[_msgSender()] > 0, "You have no remaining airdrops to collect");
        airdropRemaining[_msgSender()] = airdropRemaining[_msgSender()] - 1;
        _mint(currentOffer, _msgSender());
    }

    function claimWhitelist() external payable {
        require(whitelistRemaining[_msgSender()] > 0, "You have no remaining NFTs on your whitelist");
        require(block.timestamp < whitelistEndTime, "Whitelist has ended");
        require(uint256(msg.value) == whitelistPrice, "Incorrect Price For Whitelist");

        whitelistRemaining[_msgSender()] = whitelistRemaining[_msgSender()] - 1;
        _mint(currentOffer, _msgSender());
    }

    function airdropsRemaining() external view returns(uint256 value) {
        value = airdropRemaining[_msgSender()];
    }

    function whitelistMintsRemaining() external view returns(uint256 value) {
        value = whitelistRemaining[_msgSender()];
    }

    function ownerClaim() external onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }

    function startTrading() external onlyOwner {
        whitelistEndTime = block.timestamp + privateMintTime;
    }

    function generalMint() external payable {
        require(whitelistEndTime != 0 && block.timestamp > whitelistEndTime);
        require(uint256(msg.value) == mintPrice, "Incorrect Price For Whitelist");
        require(maxSupply > 0, "All NFTs have been minted");
        require(generalMintCount[_msgSender()] < generalMintCap, "All general mints have been claimed");
        generalMintCount[_msgSender()] = generalMintCount[_msgSender()] +1;
        _mint(currentOffer, _msgSender());
    }

    function updatePreMintParams(uint256 _mintPrice, uint256 _whitelistPrice, uint256 _limitPerWhitelist, uint256 _limitPerAirdrop, uint256 _privateMintTimeHours, uint256 _option, bool _resetPrivateMintTimer) external onlyMinter {
        mintPrice = _mintPrice;
        whitelistPrice = _whitelistPrice;
        limitPerWhitelist = _limitPerWhitelist;
        limitPerAirdrop = _limitPerAirdrop;

        privateMintTime = _privateMintTimeHours * 1 hours;
        currentOffer = _option;

        if(_resetPrivateMintTimer){
            whitelistEndTime = 0;
        }
    }
}
