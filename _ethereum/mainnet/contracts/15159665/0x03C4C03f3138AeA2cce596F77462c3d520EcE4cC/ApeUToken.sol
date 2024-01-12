// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract ApeUToken is ERC721A, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;

    // whiteList
    bytes32 public merkleRoot;

    // metadata
    string public hiddenMetadataUri;
    string public baseURI;
    address public foundAddress;

    // mint conf
    uint256 public immutable maxSupply = 10000;

    // reveal conf
    uint256 public canRevealedTokenId = 0;

    // event conf
    event Reveal(
        uint256 indexed _oldRevealedTokenId,
        uint256 _newRevealedTokenId
    );

    // sale conf
    struct SaleConfig {
        uint32 whitelistSaleStartTime;
        uint256 whitelistPrice;
        uint32 publicSaleStartTime;
        uint256 publicPrice;
    }
    SaleConfig public saleConfig;

    // common conf
    struct CommonConfig {
        uint32 maxMintAmountPerTx;
        uint32 maxMintNumPerAddress;
    }
    CommonConfig public commonConfig;

    // auction conf
    struct AuctionConfig {
        uint32 startTime;
        uint32 amountForAuction;
        uint32 durationSecond;
        uint32 dropIntervalSecond;
        uint256 startPriceWei;
        uint256 endPriceWei;
    }
    AuctionConfig public auctionConfig;
    uint256 private auction_drop_per_step;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _hiddenMetadataUri,
        address _foundAddress
    ) ERC721A(_tokenName, _tokenSymbol) {
        pause();
        setHiddenMetadataUri(_hiddenMetadataUri);
        commonConfig.maxMintAmountPerTx = 5;
        commonConfig.maxMintNumPerAddress = 5;
        foundAddress = _foundAddress;
    }

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "The caller is another contract");
        _;
    }

    modifier mintCompliance(
        address owner,
        uint256 _mintAmount,
        uint256 _total
    ) {
        require(
            _mintAmount > 0 && _mintAmount <= commonConfig.maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(totalSupply() + _mintAmount <= _total, "Max supply exceeded!");
        require(
            _numberMinted(owner) + _mintAmount <=
                commonConfig.maxMintNumPerAddress,
            "Slot not engouth!"
        );
        _;
    }

    function getCurrentId() public view returns (uint256) {
        return _nextTokenId();
    }

    function getAuctionPrice() public view returns (uint256) {
        uint256 _saleStartTime = auctionConfig.startTime;
        uint256 _startPrice = auctionConfig.startPriceWei;
        uint256 tm = block.timestamp;
        if (tm < _saleStartTime) {
            return _startPrice;
        }
        uint256 tmDiff = tm - _saleStartTime;
        if (tmDiff >= auctionConfig.durationSecond) {
            return auctionConfig.endPriceWei;
        } else {
            return
                _startPrice -
                ((tmDiff / auctionConfig.dropIntervalSecond) *
                    auction_drop_per_step);
        }
    }

    function auctionMint(uint256 _mintAmount)
        external
        payable
        whenNotPaused
        callerIsUser
        mintCompliance(
            _msgSender(),
            _mintAmount,
            auctionConfig.amountForAuction
        )
    {
        uint256 _saleStartTime = auctionConfig.startTime;
        require(
            _saleStartTime != 0 && block.timestamp >= _saleStartTime,
            "sale has not started yet"
        );
        uint256 totalCost = getAuctionPrice() * _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
        refundIfOver(totalCost);
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        callerIsUser
        whenNotPaused
        mintCompliance(_msgSender(), _mintAmount, maxSupply)
    {
        uint256 _saleStartTime = uint256(saleConfig.whitelistSaleStartTime);
        require(
            _saleStartTime != 0 && block.timestamp >= _saleStartTime,
            "sale has not started yet"
        );
        uint256 price = saleConfig.whitelistPrice;
        //require(price >= 0, "allowlist sale has not begin yet");
        // Verify whitelist requirements
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );
        _safeMint(_msgSender(), _mintAmount);
        refundIfOver(price * _mintAmount);
    }

    function publicSaleMint(uint256 _mintAmount)
        public
        payable
        callerIsUser
        whenNotPaused
        mintCompliance(_msgSender(), _mintAmount, maxSupply)
    {
        require(isPublicSaleOn(), "public sale has not begin yet");
        uint256 publicPrice = saleConfig.publicPrice;
        refundIfOver(publicPrice * _mintAmount);
        _safeMint(_msgSender(), _mintAmount);
    }

    function devMint(uint256 _mintAmount, address _receiver)
        public
        onlyOwner
        mintCompliance(_receiver, _mintAmount, maxSupply)
    {
        _safeMint(_receiver, _mintAmount);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (price > 0) {
            payable(address(foundAddress)).transfer(price);
        }
        if (msg.value > price) {
            payable(_msgSender()).transfer(msg.value - price);
        }
    }

    function isPublicSaleOn() public view returns (bool) {
        return
            saleConfig.publicPrice != 0 &&
            saleConfig.publicSaleStartTime > 0 &&
            block.timestamp >= saleConfig.publicSaleStartTime;
    }

    function mintSlotBanlance(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    //query owner address all tokenIds
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            TokenOwnership memory ownership = _ownershipAt(currentTokenId);
            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }
            if (latestOwnerAddress == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (_tokenId > canRevealedTokenId) {
            return hiddenMetadataUri;
        }
        return
            string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json"));
    }

    function setSaleConf(SaleConfig calldata _conf) external onlyOwner {
        saleConfig = _conf;
    }

    function setAuctionConf(AuctionConfig calldata _conf) external onlyOwner {
        require(
            _conf.dropIntervalSecond > 0 && _conf.durationSecond > 0,
            "conf invalid"
        );
        auctionConfig = _conf;
        auction_drop_per_step =
            (_conf.startPriceWei - _conf.endPriceWei) /
            (_conf.durationSecond / _conf.dropIntervalSecond);
    }

    function setCommonConf(
        uint32 _maxMintAmountPerTx,
        uint32 _maxMintNumPerAddress
    ) external onlyOwner {
        commonConfig.maxMintAmountPerTx = _maxMintAmountPerTx;
        commonConfig.maxMintNumPerAddress = _maxMintNumPerAddress;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setBaseURI(string calldata baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setRevealTokenId(uint256 _tokenId) public onlyOwner {
        uint256 _oldRevealedTokenId = canRevealedTokenId;
        canRevealedTokenId = _tokenId;
        emit Reveal(_oldRevealedTokenId, canRevealedTokenId);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
