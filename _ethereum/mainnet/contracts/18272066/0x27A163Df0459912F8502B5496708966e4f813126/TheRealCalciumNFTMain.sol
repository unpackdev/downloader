// SPDX-License-Identifier: MIT

/**
/** 
──────────────────────────────────────────────────────────────────────────────────────────────────────────────
─██████████████─██████████████─██████─────────██████████████─██████████─██████──██████─██████──────────██████─
─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██─────────██░░░░░░░░░░██─██░░░░░░██─██░░██──██░░██─██░░██████████████░░██─
─██░░██████████─██░░██████░░██─██░░██─────────██░░██████████─████░░████─██░░██──██░░██─██░░░░░░░░░░░░░░░░░░██─
─██░░██─────────██░░██──██░░██─██░░██─────────██░░██───────────██░░██───██░░██──██░░██─██░░██████░░██████░░██─
─██░░██─────────██░░██████░░██─██░░██─────────██░░██───────────██░░██───██░░██──██░░██─██░░██──██░░██──██░░██─
─██░░██─────────██░░░░░░░░░░██─██░░██─────────██░░██───────────██░░██───██░░██──██░░██─██░░██──██░░██──██░░██─
─██░░██─────────██░░██████░░██─██░░██─────────██░░██───────────██░░██───██░░██──██░░██─██░░██──██████──██░░██─
─██░░██─────────██░░██──██░░██─██░░██─────────██░░██───────────██░░██───██░░██──██░░██─██░░██──────────██░░██─
─██░░██████████─██░░██──██░░██─██░░██████████─██░░██████████─████░░████─██░░██████░░██─██░░██──────────██░░██─
─██░░░░░░░░░░██─██░░██──██░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░██─██░░░░░░░░░░██─██░░██──────────██░░██─
─██████████████─██████──██████─██████████████─██████████████─██████████─██████████████─██████──────────██████─
──────────────────────────────────────────────────────────────────────────────────────────────────────────────
Chief Kek has deployed the other side of the $CAL, 1,000 custom drawn NFTs. 
These are currently the only $CAL NFTs in existance. We encourage you to hold on to them! 

*/ 

pragma solidity ^0.8.19;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

contract CalciumNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    struct Discount {
        IERC20 token;
        uint256 minToHold;
        uint256 calToHold;
    }

    using Strings for uint256;
    using Address for address;

    string public baseURI = "";
    string public baseExtension = ".json";

    IERC20 public constant CALCIUM = IERC20(0x0A63AFff33B1Ed0D209762578D328B90Ea1E7A78);

    uint256 public startMintPrice = 0; //0$ per mint
    uint256 public discountPerc = 0; //0% discount
    uint256 public increasePerStep = 0; //0% increase per step
    uint256 public increaseStep = 100; //Amount minted before price increase
    uint256 public maxMintPerWallet = 2; //Max mint per wallet
    uint256 public minCalToHold = 200 * 10 ** 9; //Min CAL to hold for discount
    Discount[] public holdDiscounts;

    uint256[1000] private ids;
    uint256 private index;
    uint256[] public mintedTokens;
    mapping(address => uint256) public mintedCount;
    mapping(address => bool) public whitelisted;

    function _pickRandomUniqueId(uint256 random) private returns (uint256 id) {
        uint256 len = ids.length - index++;
        require(len > 0, "no ids left");
        uint256 randomIndex = random % len;
        id = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex;
        ids[randomIndex] = ids[len - 1] == 0 ? len - 1 : ids[len - 1];
        ids[len - 1] = 0;
    }

    constructor() ERC721("Calcium NFT", "Calcium NFT") {
        baseURI = "ipfs://bafybeihfx6ukhmcqlt7jbxjdql64bkea6gjt5y6ffipywoz6k754f2vm7m/";
        CALCIUM.balanceOf(address(this));
        whitelisted[msg.sender] = true;
    }

    modifier nonContract() {
        /* solhint-disable-next-line */
        require(msg.sender == tx.origin && !msg.sender.isContract(), "Only non contracts");
        _;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setWhitelisted(address _user, bool _value) external onlyOwner {
        whitelisted[_user] = _value;
    }

    function addNewDiscount(IERC20 _token, uint256 _minToHold, uint256 _calToHold) external onlyOwner {
        holdDiscounts.push(Discount(_token, _minToHold, _calToHold));
    }

    function setDiscount(uint256 _index, IERC20 _token, uint256 _minToHold, uint256 _calToHold) external onlyOwner {
        holdDiscounts[_index] = Discount(_token, _minToHold, _calToHold);
    }

    function removeDiscount(uint256 _index) external onlyOwner {
        Discount memory discount = holdDiscounts[holdDiscounts.length - 1];
        holdDiscounts[_index] = discount;
        holdDiscounts.pop();
    }

    function setPriceInfo(
        uint256 _startMintPrice,
        uint256 _discountPerc,
        uint256 _increasePerStep,
        uint256 _increaseStep,
        uint256 _maxMintPerWallet,
        uint256 _minCalToHold
    ) external onlyOwner {
        startMintPrice = _startMintPrice;
        discountPerc = _discountPerc;
        increasePerStep = _increasePerStep;
        increaseStep = _increaseStep;
        maxMintPerWallet = _maxMintPerWallet;
        minCalToHold = _minCalToHold;
    }

    function mint(uint256 _count) external payable nonContract nonReentrant {
        uint256 supply = totalSupply();
        require(supply + _count <= ids.length, "Count exceeds max supply");
        require(checkMaxMint(msg.sender, _count), "Max mint per wallet exceeded");
        require(checkCalHold(msg.sender), "CALCIUM balance too low");

        uint256 _random;
        uint256 tokenId;

        for (uint256 i = 0; i < _count; i++) {
            _random = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, blockhash(block.number - 1), i)));
            tokenId = _pickRandomUniqueId(_random);
            _safeMint(msg.sender, tokenId);
            mintedTokens.push(tokenId);
        }
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
    }

    function getPriceInETH(uint256 _price) public pure returns (uint256 amount) {
        _price = 0;
        return 0;
    }

    function getPrice(uint256 _count, address _user) public pure returns (uint256 amount) {
        _count = 0;
        _user = address(0);
        amount = 0;
    }

    function getMintedTokens() external view returns (uint256[] memory) {
        return mintedTokens;
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        if (!whitelisted[from] && !whitelisted[to]) {
            require(balanceOf(to) <= maxMintPerWallet, "Max per wallet exceeded");
        }

        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function checkDiscount(address _user) public pure returns (bool) {
        _user = address(0);
        return false;
    }

    function checkCalHold(address _user) public view returns (bool) {
        if (whitelisted[_user]) return true;
        return (CALCIUM.balanceOf(_user) >= minCalToHold);
    }

    function checkMaxMint(address _user, uint256 _count) public view returns (bool) {
        if (whitelisted[_user]) return true;
        return (mintedCount[_user] + _count <= maxMintPerWallet);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
