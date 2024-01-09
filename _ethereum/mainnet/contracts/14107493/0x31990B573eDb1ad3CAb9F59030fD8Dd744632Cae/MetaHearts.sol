pragma solidity ^0.8.0;

import "IERC20.sol";
import "ERC721.sol";
import "ERC721Enumerable.sol";
import "ERC721Burnable.sol";
import "ERC721Holder.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "Counters.sol";


contract MetaHearts is ERC721, ERC721Enumerable, ERC721Burnable, ERC721Holder, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _allowIdTracker;

    // allow list for pre-sale
    mapping(address => uint8) private _allowList;

    // token greetings data
    mapping(uint256 => string) private _tokenData;

    uint256 public constant MAX_ELEMENTS = 10000;
    uint256 public constant MAX_ALLOW_LIST = 500;

    uint8 public constant MAX_PRESALE_MINT = 4;
    uint8 public constant MAX_MINT = 20;

    uint256 public step_limit = 4000;
    uint256 public allowPrice = 1 * 10**16;
    uint256 public heartPrice = 35 * 10**15;
    uint256 public dataPrice = 1 * 10**16;

    bool public preSaleIsActive = false;
    bool public saleIsActive = false;

    string public baseTokenURI = "https://metahearts.club/api/tokens/";

    event CreateHeart(address indexed to, uint256 indexed id);

    constructor() ERC721("MetaHearts", "MHRT") {
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function _totalAllow() internal view returns (uint) {
        return _allowIdTracker.current();
    }

    function totalAllow() public view returns (uint256) {
        return _totalAllow();
    }

    //
    // payable interfaces
    //

    function selfAddToPresaleAllow() public payable {
        require(msg.value >= allowPrice, "Value below price for add to allow list");
        require(_allowIdTracker.current() <= MAX_ALLOW_LIST, "Allow list is full");
        require(_allowList[msg.sender] == 0, "Already in allow list");

        _allowIdTracker.increment();
        _allowList[msg.sender] = MAX_PRESALE_MINT;
    }

    function mint(uint8 _count) external payable {
        uint256 total = _totalSupply();
        require(saleIsActive || preSaleIsActive, "Sale must be active");
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(_count <= MAX_MINT, "Exceeds number");
        require(total + _count <= step_limit, "Current stage limit");
        require(msg.value >= price(_count), "Value below price at current stage");
        if (preSaleIsActive) {
            require(_count <= _allowList[msg.sender], "Exceeded allowed tokens to purchase");
            _allowList[msg.sender] -= _count;
        }

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }
    }

    function mintPresent(address _to, uint8 _count, string memory _data) external payable {
        uint256 total = _totalSupply();
        require(saleIsActive || preSaleIsActive, "Sale must be active");
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(_count <= MAX_MINT, "Exceeds number");
        require(total + _count <= step_limit, "Current stage limit");
        require(msg.value >= price(_count), "Value below price at current stage");
        if (preSaleIsActive) {
            require(_count <= _allowList[msg.sender], "Exceeded allowed tokens to purchase");
            _allowList[msg.sender] -= _count;
        }

        for (uint256 i = 0; i < _count; i++) {
            uint256 token_id = _totalSupply();
            _mintAnElement(_to);
            _tokenData[token_id] = _data;
        }
    }

    function setTokenData(uint256 _token_id, string memory _data) external payable {
        if (msg.sender != owner()) {
            require(ownerOf(_token_id) == msg.sender, "Only owner can change data");
            require(msg.value >= dataPrice, "Value below price for set data");
        }

        _tokenData[_token_id] = _data;
    }

    //
    // owner interfaces
    //

    function reserve(uint256 _count) external onlyOwner {
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }
    }

    function addToPresaleAllow(address[] calldata addresses, uint8 numAllowed) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");
            _allowList[addresses[i]] = numAllowed;
        }
    }

    function setPriceAllow(uint256 _price) external onlyOwner {
        require(_price >= 0, "Negative price");

        allowPrice = _price;
    }

    function setPriceData(uint256 _price) external onlyOwner {
        require(_price >= 0, "Negative price");

        dataPrice = _price;
    }

    function setPriceHeart(uint256 _price) external onlyOwner {
        require(_price >= 0, "Negative price");

        heartPrice = _price;
    }

    function setCurrentLimit(uint256 _limit) external onlyOwner {
        require(_limit > 0, "Zero limit");
        require(_limit <= MAX_ELEMENTS, "Big limit");

        step_limit = _limit;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function withdraw(address _address, uint256 _amount) public payable onlyOwner {
        require(_amount > 0, "Invalid amount");
        uint256 balance = address(this).balance;
        require(balance > 0, "Zero balance");
        require(balance >= _amount, "Big amount to withdraw");

        payable(_address).transfer(_amount);
    }

    function transferERC20(IERC20 _token, address _to, uint256 _amount) public onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        require(balance >= _amount, "Big amount to transfer");

        _token.transfer(_to, _amount);
    }

    function transferERC721(ERC721 _token, address _to, uint256 _token_id) public onlyOwner {
        require(address(this) == _token.ownerOf(_token_id), "Invalid owner of token");
        _token.transferFrom(address(this), _to, _token_id);
    }

    //
    // public
    //

    function numAllowedToMint(address _address) external view returns (uint8) {
        return _allowList[_address];
    }

    function tokenData(uint256 _token_id) external view returns (string memory) {
        return _tokenData[_token_id];
    }

    function price(uint256 _count) public view returns (uint256) {
        return heartPrice.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //
    // private
    //

    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateHeart(_to, id);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 _token_id) internal virtual override {
        super._burn(_token_id);

        if (bytes(_tokenData[_token_id]).length != 0) {
            delete _tokenData[_token_id];
        }
    }

    // contract can recieve Ether
    fallback() external payable { }
    receive() external payable { }
}
