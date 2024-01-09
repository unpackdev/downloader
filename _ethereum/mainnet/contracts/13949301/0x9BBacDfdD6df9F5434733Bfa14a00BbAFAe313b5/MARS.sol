pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./IERC721.sol";
import "./Counters.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract MARS is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    uint256 public constant MAX_PRESALE_TOKENS = 2000;
    uint256 public constant MAX_TOKENS = 10000;
    uint256 public constant MAX_PURCHASES = 10;
    uint256 public constant TOKEN_PRICE = 0.1 ether;

    bool public preSale = false;
    bool public publicSale = false;
    address[] public partnerProjects;

    string private baseURI = "";
    Counters.Counter private _nextTokenId;

    constructor(address[] memory _partnerProjects) ERC721("Mutant Ape Race Series", "MARS") {
        partnerProjects = _partnerProjects;
    }

    function mint(uint256 quantity) external payable nonReentrant {
        require(publicSale, "public sale is not live");
        require(totalSupply() + quantity <= MAX_TOKENS, "minting this many would exceed supply");
        _checkMintRequirements(quantity);
        _minter(msg.sender, quantity);
    }

    function presaleMint(uint256 quantity) external payable nonReentrant {
        require(preSale, "pre sale is not live");
        require(totalSupply() + quantity <= MAX_PRESALE_TOKENS, "invalid quantity: no more pre sale tokens available");
        require(holdsPartnerProject(msg.sender), "no partner project token ownership");
        _checkMintRequirements(quantity);

        _minter(msg.sender, quantity);
    }

    function _checkMintRequirements(uint256 quantity) internal {
        require(quantity > 0 && quantity <= MAX_PURCHASES, "invalid quantity: zero or greater than mint allowance");
        require(msg.value == TOKEN_PRICE * quantity, "wrong amount of ether sent");
    }

    function devMint(address[] memory recipients, uint256[] memory quantity) external onlyOwner {
        require(recipients.length == quantity.length, "Data length mismatch!");
        uint256 totalMintRequested = 0;
        for (uint256 i = 0; i < quantity.length; i++) {
            totalMintRequested = totalMintRequested + quantity[i];
        }
        require(_nextTokenId.current() + totalMintRequested <= MAX_TOKENS, "minting this many would exceed supply");

        for (uint256 i = 0; i < recipients.length; i++) {
            _minter(recipients[i], quantity[i]);
        }
    }

    function togglePublicSale() public onlyOwner {
        publicSale = !publicSale;
    }

    function togglePreSale() public onlyOwner {
        preSale = !preSale;
    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current();
    }

    function holdsPartnerProject(address _claimant) public view returns (bool) {
        for (uint256 i = 0; i < partnerProjects.length; i++) {
            if (IERC721(partnerProjects[i]).balanceOf(_claimant) > 0) {
                return true;
            }
        }
        return false;
    }

    function _minter(address addr, uint256 quantity) internal {
        for (uint i = 0; i < quantity; i++) {
            uint mintIndex = _nextTokenId.current();
            _safeMint(addr, mintIndex);
            _nextTokenId.increment();
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
}
