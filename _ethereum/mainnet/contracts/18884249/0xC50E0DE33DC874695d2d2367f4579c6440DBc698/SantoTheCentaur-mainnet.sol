// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";
import "./AggregatorV3Interface.sol";

contract SantoTheCentaur is ERC721, ERC2981, ERC721Enumerable, Pausable, ERC721Burnable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    AggregatorV3Interface internal dataFeed;

    enum Status {
        WhiteListSale,
        PublicSale
    }
    
    string private baseURI;
    string private baseExtension;
    string private mysteryURI;
    uint256 public mysteryStartId;
    bytes32 public merkleRoot;
    
    address private signer;
    uint8 public groupCurrent;
    uint256 public openSupply;

    mapping(bytes32 => bool) public executed;
    mapping(Status => uint256) public saleStartTime;
    mapping(Status => uint256) public keepTime;
    mapping(Status => uint256) public salePrice;
    mapping(Status => uint256) public mintMax;
    mapping(Status => uint256) public mintPerMax;
    mapping(Status => uint256) public mintCount;

    mapping(address => mapping(uint8 => uint256)) public amountMintedPerWhiteList;
    mapping(address => mapping(uint8 => uint256)) public amountMintedPerPublic;

    mapping(uint8 => uint256) public whiteListGroupCount;
    mapping(address => mapping(uint8 => bool)) private whiteList;

    Counters.Counter private _tokenIdCounter;

    constructor(
        string memory _name,
        string memory _symbol,
        address _signer,
        uint256 _saleStartTime,
        string memory _mysteryURI
    ) ERC721(_name, _symbol) {
        dataFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );

        openSupply = 7777;
        mintMax[Status.WhiteListSale] = 1200;
        mintMax[Status.PublicSale] = 626;

        mintPerMax[Status.WhiteListSale] = 2;
        mintPerMax[Status.PublicSale] = 2;

        salePrice[Status.WhiteListSale] = 60000000 gwei;
        salePrice[Status.PublicSale] = 80000000 gwei;
 
        keepTime[Status.WhiteListSale] = 8 days;
        keepTime[Status.PublicSale] = 8 days;

        saleStartTime[Status.WhiteListSale] = _saleStartTime;
        saleStartTime[Status.PublicSale] = _saleStartTime;

        signer = _signer;
        setMysteryStartId(3851);
        _tokenIdCounter._value = 3851;

        mysteryURI = _mysteryURI;
        setGroupCurrent(1);
        _setDefaultRoyalty(_msgSender(), 500);
    }

    modifier _notContract() {
        uint256 size;
        address addr = _msgSender();
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0, "Contract is not allowed");
        require(_msgSender() == tx.origin, "Proxy contract is not allowed");
        _;
    }

    modifier _saleBetweenPeriod(uint256 _startTime, uint256 _endTime) {
        require(currentTime() >= _startTime, "Sale has not started yet");
        require(currentTime() < _endTime, "Sale is finished");
        _;
    }

    function whitelistMint(uint256 amount, bytes32[] calldata _merkleProof)
        external
        payable
        whenNotPaused
        _notContract
        _saleBetweenPeriod(saleStartTime[Status.WhiteListSale], saleStartTime[Status.WhiteListSale] + keepTime[Status.WhiteListSale])
        nonReentrant
    {
        uint8 _group = groupCurrent;
        address _sender = _msgSender();
        Status _current = Status.WhiteListSale;

        bytes32 leaf = keccak256(abi.encodePacked(_sender));
        if(!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
            require(whiteList[_sender][_group], "Not in whitelist");
        }

        require(amountMintedPerWhiteList[_sender][_group] + amount <= mintPerMax[_current], "Minted reached the limit");
        require(mintCount[_current] + amount <= mintMax[_current], "Exceeded max mint");
        require(msg.value >= salePrice[_current] * amount, "Not enough funds");

        mintCount[_current] += amount;
        amountMintedPerWhiteList[_sender][_group] += amount;
        _batchMint(_sender, amount);
    }

    function publicSaleMint(uint256 amount)
        external
        payable
        whenNotPaused
        _notContract
        _saleBetweenPeriod(saleStartTime[Status.PublicSale], saleStartTime[Status.PublicSale] + keepTime[Status.PublicSale])
        nonReentrant
    {
        uint8 _group = groupCurrent;
        address _sender = _msgSender();
        Status _current = Status.PublicSale;

        require(amountMintedPerPublic[_sender][_group] + amountMintedPerWhiteList[_sender][_group] + amount <= mintPerMax[_current], "Minted reached the limit");
        require(mintCount[_current] + amount <= mintMax[_current], "Exceeded max mint");

        uint256 totalValue = salePrice[_current] * amount;
        require(msg.value >= totalValue, "Not enough funds");

        mintCount[_current] += amount;
        amountMintedPerPublic[_sender][_group] += amount;
        _batchMint(_sender, amount);
    }

    function duplicate(
        bytes memory signature,
        address _account,
        uint256[] memory _ids,
        uint deadline
    ) public whenNotPaused _notContract nonReentrant {
        require(deadline >= block.timestamp, "Deadline Passed");

        bytes32 txHash = keccak256(abi.encode(_account, _ids, deadline, _msgSender()));
        require(!executed[txHash], "Tx Executed");
        require(verify(txHash, signature), "Unauthorised");
        executed[txHash] = true;

        for (uint256 i = 0; i < _ids.length; i++) {
            if (_ids[i] >= mysteryStartId) {
                revert("Exceeded the id limit");
            }
        }

        _mintById(_account, _ids);
    }

    function _batchMint(address _account, uint256 _quantity) internal {
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            require(tokenId < openSupply, "Exceeded the open supply limit");
            _safeMint(_account, tokenId);
        }
    }

    function _mintById(address _account, uint256[] memory _ids) internal {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 tokenId = _ids[i];
            _safeMint(_account, tokenId);
        }
    }

    function foundationClaim(address to, uint256 amount) public onlyOwner {
        _batchMint(to, amount);
    }

    function rewardClaim(address[] memory addrs, uint256[] memory amounts) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            _batchMint(addrs[i], amounts[i]);
        }
    }

    function duplicateClaim(address _account, uint256[] memory ids) public onlyOwner {
        _mintById(_account, ids);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        if (tokenId >= mysteryStartId) {
            return string(abi.encodePacked(mysteryURI, tokenId.toString(), ".json"));
        }
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString(), baseExtension)) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Whitelist
    function isWhiteList(address addr, uint8 group) public view returns (bool) {
        return whiteList[addr][group];
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function addWhiteList(address addr, uint8 group) public onlyOwner {
        whiteListGroupCount[group]++;
        whiteList[addr][group] = true;
    }

    function addWhiteListBatch(address[] memory addrs, uint8 group) public onlyOwner {
        for (uint i = 0; i < addrs.length; i++) {
            addWhiteList(addrs[i], group);
        }
    }

    // Royalty
    function setDefaultRoyalty(address _receiver, uint96 _freeNumerator) public onlyOwner {
        _setDefaultRoyalty(_receiver, _freeNumerator);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _freeNumerator
    ) public onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _freeNumerator);
    }

    function resetTokenRoyalty(uint256 _tokenId) public onlyOwner {
        _resetTokenRoyalty(_tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    // Setting
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setOpenSupply(uint256 _openSupply) public onlyOwner {
        openSupply = _openSupply;
    }

    function setGroupCurrent(uint8 _group) public onlyOwner {
        groupCurrent = _group;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setSaleStartTime(Status _saleStartTimeStatus, uint256 _saleStartTime) public onlyOwner {
        saleStartTime[_saleStartTimeStatus] = _saleStartTime;
    }

    function setKeepTime(Status _keepTimeStatus, uint256 _keepTime) public onlyOwner {
        keepTime[_keepTimeStatus] = _keepTime;
    }

    function setSalePrice(Status _salePriceStatus, uint256 _salePrice) public onlyOwner {
        salePrice[_salePriceStatus] = _salePrice;
    }

    function setMintPerMax(Status _mintPerMaxStatus, uint256 _max) public onlyOwner {
        mintPerMax[_mintPerMaxStatus] = _max;
    }

    function setMintMax(Status _mintMaxStatus, uint256 _max) public onlyOwner {
        mintMax[_mintMaxStatus] = _max;
    }

    function setMysteryURI(string memory _mysteryURI) public onlyOwner {
        mysteryURI = _mysteryURI;
    }

    function setMysteryStartId(uint256 _mysteryStartId) public onlyOwner {
        mysteryStartId = _mysteryStartId;
    }

    function transferSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    // Tools
    function currentTime() private view returns (uint256) {
        return block.timestamp;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function latestTokenId() public view returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }

    function getBalanceIds(address _address) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(_address);
        uint256[] memory ids = new uint256[](balance);

        for (uint256 i = 0; i < balance; i++) {
            uint256 _tokenId = tokenOfOwnerByIndex(_address, i);
            ids[i] = _tokenId;
        }
        return ids;
    }

    function verify(bytes32 hash, bytes memory signature) private view returns (bool) {
        bytes32 ethSignedHash = hash.toEthSignedMessageHash();
        return ethSignedHash.recover(signature) == signer;
    }

    function getChainlinkEthDataFeed() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}