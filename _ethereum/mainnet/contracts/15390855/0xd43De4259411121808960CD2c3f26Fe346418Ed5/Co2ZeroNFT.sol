//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Address.sol";
import "./Strings.sol";
import "./MerkleProof.sol"; // OZ: MerkleProof
import "./Ownable.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";

contract Co2ZeroNFT is IERC721, IERC721Metadata, Ownable {
    using Address for address;
    using Strings for uint256;

    bytes32 public merkleRoot;

    uint256 constant public MAX_SUPPLY = 10000;

    uint256 public maxMint = 10;

    uint256 public whiteListMaxBalance = 2;

    uint256 public whiteListMintPrice = 0.26 ether;

    uint256 public mintPrice = 0.33 ether;

    uint256 public allowMintMax = 1000;

    uint256 public openingMax = 0;

    string public _baseURI;

    string public _baseMapURI;

    bool public whiteListPurchaseStatus = false;

    bool public purchaseStatus = false;

    uint256 public totalSupply;

    string override public name;
    string override public symbol;

    mapping(uint256 => address) private _owners;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(address => bool) private _whiteList;
    address[] private _whiteListA;

    event modifyOpeningMax(uint256 amount);

    event modifyPurchaseStatus(bool status);

    constructor(string memory _name, string memory _symbol, bytes32 _merkleRoot, string memory baseURI, string memory baseMapURI) {
        name = _name;
        symbol = _symbol;
        merkleRoot = _merkleRoot;
        _baseURI = baseURI;
        _baseMapURI = baseMapURI;
    }

    modifier nonCaller(address account) {
        require(account != msg.sender, "Cannot use your own address.");
        _;
    }

    modifier nonZeroAddress(address account) {
        require(account != address(0), "Cannot use zero address.");
        _;
    }

    modifier existToken(uint256 tokenId) {
        require(totalSupply > tokenId, "Token hasn't been minted yet.");
        _;
    }

    modifier onlyApprovedOrOwner(address spender, uint256 tokenId) {
        address owner = this.ownerOf(tokenId);
        require(
            msg.sender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender),
            "You don't have permission to manipulate it."
        );
        _;
    }

    modifier checkSupportERC721(address from, address to, uint256 tokenId, bytes memory _data) {
        _;
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer."
        );
    }

    modifier isExceedMaxSupply(uint256 quantity) {
        require(totalSupply + quantity <= MAX_SUPPLY, "Will exceed max supply.");
        _;
    }

    modifier isExceedMaxMint(uint256 quantity) {
        require(quantity <= maxMint, "Will exceed max mint.");
        _;
    }

    modifier isExceedAllowMaxMint(uint256 quantity) {
        require(totalSupply + quantity <= allowMintMax, "Will exceed max mint.");
        _;
    }

    modifier isExceedWhiteListMaxBalance(address owner, uint256 quantity) {
        require(_balances[owner] + quantity <= whiteListMaxBalance, "Will exceed max balance.");
        _;
    }

    modifier onWhiteListPurchase() {
        require(whiteListPurchaseStatus, "Can't mint now.");
        _;
    }

    modifier onPurchase() {
        require(purchaseStatus, "Can't mint now.");
        _;
    }

    function balanceOf(address owner) override external view nonZeroAddress(owner) returns (uint256 balance) {
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) override external view existToken(tokenId) returns (address owner) {
        return _owners[tokenId];
    }

    function _transfer(address from, address to, uint256 tokenId) private
        existToken(tokenId)
        nonZeroAddress(to)
        onlyApprovedOrOwner(msg.sender, tokenId)
    {
        this.approve(address(0), tokenId);

        _owners[tokenId] = to;
        _balances[from]--;
        _balances[to]++;

        emit Transfer(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) override external {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) override external {
        this.safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) override external checkSupportERC721(from, to, tokenId, data) {
        _transfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    function approve(address to, uint256 tokenId) override external
        existToken(tokenId) nonCaller(to) onlyApprovedOrOwner(msg.sender, tokenId)
    {
        _tokenApprovals[tokenId] = to;

        emit Approval(msg.sender, to, tokenId);
    }

    function getApproved(uint256 tokenId) override public view existToken(tokenId) returns (address operator) {
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool _approved) override external nonZeroAddress(operator) nonCaller(operator) {
        _operatorApprovals[msg.sender][operator] = _approved;

        emit ApprovalForAll(msg.sender, operator, _approved);
    }

    function isApprovedForAll(address owner, address operator) override public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function setAllowMintMax(uint256 num) external onlyOwner {
        require(num <= MAX_SUPPLY, "Will exceed max supply.");

        allowMintMax = num;
    }

    function setOpeningMax(uint256 num) external onlyOwner {
        require(num <= MAX_SUPPLY, "Will exceed max supply.");
        openingMax = num;
    }

    function setPurchaseStatus(bool status) external onlyOwner {
        require(purchaseStatus != status, "Status has been set.");

        purchaseStatus = status;

        emit modifyPurchaseStatus(status);
    }

    function setWhtieListPurchaseStatus(bool status) external onlyOwner {
        require(whiteListPurchaseStatus != status, "Status has been set.");

        whiteListPurchaseStatus = status;
    }

    function setWhiteListMintPrice(uint256 price) external onlyOwner {
        whiteListMintPrice = price;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _baseURI = uri;
    }

    function setBaseMapURI(string memory uri) external onlyOwner {
        _baseMapURI = uri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        require( _merkleRoot != bytes32(0), "merkleRoot is the zero bytes32");
        merkleRoot = _merkleRoot;
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _mint(address to, uint256 quantity) private
        nonZeroAddress(to)
        isExceedMaxSupply(quantity) {
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = uint256(totalSupply + i);
            _owners[tokenId] = to;
            emit Transfer(address(0), to, tokenId);
        }

        totalSupply += quantity;
        _balances[to] += quantity;
    }

    function _safeMint(address to, uint256 quantity, bytes memory _data) internal virtual
        checkSupportERC721(address(0), to, totalSupply, _data)
    {
        _mint(to, quantity);
    }

    function tokenURI(uint256 tokenId) override external view existToken(tokenId) returns (string memory) {
        if (tokenId < openingMax) {
            uint256 _tokenId = tokenId + 1;
            return string(abi.encodePacked(_baseURI, _tokenId.toString(), ".json"));
        }

        return _baseMapURI;
    }

    function airdrop(address to, uint256 quantity) external onlyOwner nonZeroAddress(to) {
        _safeMint(to, quantity, "");
    }

    function airdrops(address[] calldata tos, uint256[] calldata quantitys) external onlyOwner {
        require(tos.length == quantitys.length, "length not match");
        for(uint i=0; i<tos.length; i++)
            _safeMint(tos[i], quantitys[i], "");
    }

    function mint(uint256 quantity) external payable
        onPurchase
        isExceedMaxMint(quantity)
        isExceedAllowMaxMint(quantity) {
        require(
            quantity * mintPrice <= msg.value,
            "Not enough ether sent"
        );

        _safeMint(msg.sender, quantity, "");
    }

    function whiteListMint(uint256 quantity, bytes32[] calldata proof) external payable
        onWhiteListPurchase
        isExceedMaxMint(quantity)
        isExceedAllowMaxMint(quantity)
        isExceedWhiteListMaxBalance(msg.sender, quantity)  {
        require(
            quantity * whiteListMintPrice <= msg.value,
            "Not enough ether sent"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(MerkleProof.verify(proof, merkleRoot, leaf), "Address not in WhiteList");

        _safeMint(msg.sender, quantity, "");
    }

    function whiteListMint(uint256 quantity) external payable
        onWhiteListPurchase
        isExceedMaxMint(quantity)
        isExceedAllowMaxMint(quantity)
        isExceedWhiteListMaxBalance(msg.sender, quantity)  {
        require(
            quantity * whiteListMintPrice <= msg.value,
            "Not enough ether sent"
        );

        require(_whiteList[msg.sender], "Address not in WhiteList");

        _safeMint(msg.sender, quantity, "");
    }

    function setWhiteList(address[] memory whiteList) external onlyOwner {
        for(uint i=0; i<_whiteListA.length; i++)
            _whiteList[whiteList[i]] = false;
        _whiteListA = whiteList;
        for(uint i=0; i<_whiteListA.length; i++)
            _whiteList[whiteList[i]] = true;
    }

    function addWhiteList(address[] memory whiteList) external onlyOwner {
        _whiteListA = whiteList;
        for(uint i=0; i<_whiteListA.length; i++) {
            _whiteListA.push(whiteList[i]);
            _whiteList[whiteList[i]] = true;
        }
    }

    function withdraw(address to, uint256 balance) public onlyOwner nonZeroAddress(to) {
        require(
            balance <= address(this).balance,
            "Not enough ether"
        );
        payable(to).transfer(balance);
    }
}
