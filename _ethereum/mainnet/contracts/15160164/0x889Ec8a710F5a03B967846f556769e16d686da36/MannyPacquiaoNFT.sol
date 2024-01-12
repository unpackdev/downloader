// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract MannyPacquiaoNFT is Ownable, ERC721A, ReentrancyGuard {
    // // metadata URI
    string private _baseTokenURI;

    // Base URI for not revealed.
    bool public revealed = false;
    string private notRevealedUri;

    bool public enableMint;

    uint256 public MAX_TOKENS = 10000;
    uint256 public MAX_SUB_TOKENS = 1000;
    uint256 public RESERVED_TOKENS = 1000;
    uint256 public MAX_BATCH_SIZE = 100;
    uint256 public TOTAL_LIMIT_PER_ACCOUNT = 10;

    mapping(address => uint256) public userTotalMinted;

    // dev mint
    uint256 public devMinted;

    // team mint
    uint256 public teamMintPrice = 0 ether;
    mapping(address => uint256) public teams;
    mapping(address => uint256) public teamMinted;

    // whitelist mint
    uint256 public whitelistMintPrice = 0 ether;
    mapping(address => uint256) public whitelists;
    mapping(address => uint256) public whitelistMinted;

    // public mint
    uint256 public pubSaleStartTime;
    uint256[] public pubSalePrices;
    uint8 public pubSaleStage;
    uint256 public pubSaleMintedCount;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier isMintable(uint _quantity) {
        require(enableMint, "Mint not enabled now");
        require(_quantity <= MAX_BATCH_SIZE, 
            "Too many batch mint");
        require(totalSupply() + _quantity <= MAX_TOKENS - RESERVED_TOKENS, 
            "Would exceed max supply");
        _;
    }

    event NewBaseURI(string newURI, address updatedBy);
    event UpdatedTotalLimitPerAcc(uint256 size, address updatedBy);
    event UpdatedTeamPrice(uint256 price, address updatedBy);
    event UpdatedWhitelistPrice(uint256 price, address updatedBy);
    event UpdatedPubSalePrice(uint256[] prices, address updatedBy);
    event UpdatedPubSaleStartTime(uint256 period, address updatedBy);

    event NewNFTMintedOnDevSale(uint256 quantity, address mintedBy);
    event NewNFTMintedOnTeamSale(uint256 quantity, address mintedBy);
    event NewNFTMintedOnWhitelistSale(uint256 quantity, address mintedBy);
    event NewNFTMintedOnPubSale(uint256 quantity, address mintedBy);

    event NewPubSaleStatus(uint256 pubSaleStage);

    constructor() ERC721A("Manny Pacquiao NFT", "MPNFT", MAX_BATCH_SIZE, MAX_TOKENS) {
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        emit NewBaseURI(baseURI, msg.sender);
    }

    /**
     * @dev Set the not revealed URI of the NFT collection by the owner.
     */
    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setEnableMint(bool enable) external onlyOwner {
        enableMint = enable;
    }

    /**
     * @dev Reveal/Hide the real URI of NFT token by the owner.
     */
    function reveal() external onlyOwner() {
        revealed = !revealed;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint tokenId) public view 
        virtual 
        override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(revealed == false && msg.sender != owner()) {
            return notRevealedUri;
        }

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")) : "";
    }

    /**
     * @dev Returns token IDs of _owner
     */
    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 i; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

    function setTotalLimitPerAcc(uint256 _size) external onlyOwner {
        TOTAL_LIMIT_PER_ACCOUNT = _size;
        emit UpdatedTotalLimitPerAcc(_size, msg.sender);
    }

    function setTeamMintPrice(uint256 _price) external onlyOwner {
        teamMintPrice = _price;
        emit UpdatedTeamPrice(_price, msg.sender);
    }

    function setWhitelistPrice(uint256 _price) external onlyOwner {
        whitelistMintPrice = _price;
        emit UpdatedWhitelistPrice(_price, msg.sender);
    }

    function setPubSalePrice(uint256[] memory _prices) external onlyOwner {
        pubSalePrices = _prices;
        emit UpdatedPubSalePrice(_prices, msg.sender);
    }

    function setPubSaleStartTime(uint256 _startTime) external onlyOwner {
        pubSaleStartTime = _startTime;
        emit UpdatedPubSaleStartTime(_startTime, msg.sender);
    }

    function addTeamMembers(address[] memory _recipients, uint[] memory _limit) 
        external onlyOwner {
        require(_recipients.length == _limit.length, "Wrong value");
        for(uint i = 0; i < _recipients.length; i++) {
          teams[_recipients[i]] = _limit[i];
        }
    }

    function addWhitelist(address[] memory _recipients, uint[] memory _limit) 
        external onlyOwner {
        require(_recipients.length == _limit.length, "Wrong value");
        for(uint i = 0; i < _recipients.length; i++) {
          whitelists[_recipients[i]] = _limit[i];
        }
    }

    function removeTeamMembers(address[] memory _recipients) external onlyOwner {
        for(uint i = 0; i < _recipients.length; i++) {
          teams[_recipients[i]] = 0;
        }
    }

    function removeWhitelist(address[] memory _recipients) external onlyOwner {
        for(uint i = 0; i < _recipients.length; i++) {
          whitelists[_recipients[i]] = 0;
        }
    }

    // For dev members.
    function devMint(uint256 _quantity) external onlyOwner {
        require(enableMint, "Mint not enabled now");
        require(_quantity <= MAX_BATCH_SIZE, 
            "Too many batch mint");
        require(devMinted + _quantity <= RESERVED_TOKENS, "Cannot buy that many NFTs");
        _safeMint(msg.sender, _quantity);
        devMinted += _quantity;

        emit NewNFTMintedOnDevSale(_quantity, msg.sender);
    }

    // For team members.
    function teamMint(uint256 _quantity) external payable 
        callerIsUser isMintable(_quantity) {
        require(teams[msg.sender] > 0, "Caller is not team member");
        require(
          userTotalMinted[msg.sender] + _quantity <= TOTAL_LIMIT_PER_ACCOUNT,
          "Can not mint more than the total limit per account"
        );
        require(
          teamMinted[msg.sender] + _quantity <= teams[msg.sender],
          "Can not mint more than the limit for team member"
        );
        require(msg.value >= _quantity * teamMintPrice, "Not enough ETH for transaction");

        _safeMint(msg.sender, _quantity);
        teamMinted[msg.sender] += _quantity;
        userTotalMinted[msg.sender] += _quantity;

        emit NewNFTMintedOnTeamSale(_quantity, msg.sender);
    }

    // For whitelist.
    function whitelistMint(uint _quantity) 
        external payable callerIsUser isMintable(_quantity) {
        require(whitelists[msg.sender] > 0, "Caller is not in the whitelist");
        require(
          userTotalMinted[msg.sender] + _quantity <= TOTAL_LIMIT_PER_ACCOUNT,
          "Can not mint more than the total limit per account"
        );
        require(
          whitelistMinted[msg.sender] + _quantity <= whitelists[msg.sender],
          "Can not mint more than the limit for whitelist user"
        );

        require(msg.value >= _quantity * whitelistMintPrice, "Not enough ETH for transaction");

        _safeMint(msg.sender, _quantity);
        whitelistMinted[msg.sender] += _quantity;
        userTotalMinted[msg.sender] += _quantity;

        emit NewNFTMintedOnWhitelistSale(_quantity, msg.sender);
    }

    function isPublicSaleOn(uint256 _publicPrice, uint256 _pubSaleStartTime) 
        public view returns (bool) {
        return
          _publicPrice > 0 &&
          block.timestamp >= _pubSaleStartTime;
    }

    function publicSaleMint(uint256 _quantity)
        external payable callerIsUser isMintable(_quantity) {
        require(
          isPublicSaleOn(pubSalePrices[pubSaleStage], pubSaleStartTime),
          "public sale stage has not begun yet"
        );
        require(
          userTotalMinted[msg.sender] + _quantity <= TOTAL_LIMIT_PER_ACCOUNT,
          "Can not mint more than the total limit per account"
        );
        require(
          pubSaleMintedCount + _quantity <= MAX_SUB_TOKENS,
          "Exceed the limit of current public sale phase"
        );
        require(msg.value >= _quantity * pubSalePrices[pubSaleStage], "Not enough ETH for transaction");

        _safeMint(msg.sender, _quantity);
        userTotalMinted[msg.sender] += _quantity;
        pubSaleMintedCount += _quantity;

        emit NewNFTMintedOnPubSale(_quantity, msg.sender);

        if (pubSaleMintedCount == MAX_SUB_TOKENS) {
            pubSaleStage ++;
            pubSaleMintedCount = 0;

            emit NewPubSaleStatus(pubSaleStage);
        }
    }

    function getCurrentPrice(address _account) public view returns (uint256) {
        if (teams[_account] > 0 && 
            teamMinted[_account] < teams[_account])
            return teamMintPrice;

        if (whitelists[_account] > 0 && 
            whitelistMinted[_account] < whitelists[_account])
            return whitelistMintPrice;

        return pubSalePrices[pubSaleStage];
    }

    function withdrawAll() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}