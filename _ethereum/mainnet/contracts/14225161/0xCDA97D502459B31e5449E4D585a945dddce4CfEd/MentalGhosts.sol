

import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./ERC721A.sol";
import "./IMerkle.sol";

contract MentalGhosts is ERC721A, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;
    uint256 public price = 0.06 ether;
    string public baseUri = "https://ipfs.io/ipfs/QmThpUyzTb59ycjzV2ZaRzw3nwinVpr4C25QAv1GeXcLTQ/";
    uint256 public supply = 6666;
    string public extension = ".json"; 

    bool public whitelistLive;
    address payable public paymentSplitter;
    uint256 public maxPerTx = 3;
    uint256 public maxPerWallet = 100;
    uint256 public maxPerWLWallet = 3;

    mapping(address => uint256) whitelistLimitPerWallet;
    mapping(address => uint256) limitPerWallet;
    mapping(address => bool) admins;

    IMerkle public whitelist;

    event WhitelistLive(bool live);

    constructor(
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) { _pause(); }

    function mint(uint256 count) external payable nonReentrant whenNotPaused {
        require(msg.value >= price * count, "invalid price");
        require(limitPerWallet[msg.sender] + count <= maxPerWallet, "Exceeds max");
        require(count <= maxPerTx, "Exceeds max");
        _callMint(count, msg.sender);
        limitPerWallet[msg.sender] += count;
    }

    function whitelistMint(uint256 count, bytes32[] memory proof) external payable nonReentrant {
        require(whitelistLive, "Not live");
        require(msg.value >= price * count, "invalid price");
        require(whitelist.isPermitted(msg.sender, proof), "not whitelisted");
        require(whitelistLimitPerWallet[msg.sender] + count <= maxPerWLWallet, "Exceeds max");
        require(count <= maxPerTx, "Exceeds max");
        _callMint(count, msg.sender);
        whitelistLimitPerWallet[msg.sender] += count;
    }

    function adminMint(uint256 count, address to) external adminOrOwner {
        _callMint(count, to);
    }

    function _callMint(uint256 count, address to) internal {        
        uint256 total = totalSupply();
        require(count > 0, "Count is 0");
        require(total + count <= supply, "Sold out");
        _safeMint(to, count);
    }

    function burn(uint256 tokenId) external {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        require(isApprovedOrOwner, "Not approved");
        _burn(tokenId);
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

    function toggleWhitelistLive() external adminOrOwner {
        bool isLive = !whitelistLive;
        whitelistLive = isLive;
        emit WhitelistLive(isLive);
    }

    function setMerkle(IMerkle _whitelist) external adminOrOwner {
        whitelist = _whitelist;
    }

    function setPrice(uint256 _price) external adminOrOwner {
        price = _price;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external adminOrOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setMaxWLPerWallet(uint256 _maxPerWLWallet) external adminOrOwner {
        maxPerWLWallet = _maxPerWLWallet;
    }

    function setMaxPerTx(uint256 _maxPerTx) external adminOrOwner {
        maxPerTx = _maxPerTx;
    }

    function setPaymentSplitter(address payable _paymentSplitter) external adminOrOwner {
        paymentSplitter = _paymentSplitter;
    }
     
    function withdraw() external adminOrOwner {
        (bool success, ) = paymentSplitter.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
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
}
