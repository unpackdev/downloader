pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Ownable.sol";


/**
 * @title Mario contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract Mario is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    string public baseURI = "";
    string public defaultURI = "";

    uint256 public constant marioPrice = 130000000000000000; //0.13 ETH

    uint public constant MAX_PER_USER = 30;

    uint256 public MAX_SUPPLY;

    bool public saleIsActive = false;

    // mapping of address to amount
    mapping (address => uint256) public whitelistPrePay;

    uint256 public whitelistReserved = 0;

    struct Whitelist {
        address account;
        uint256 amount;
    }

    // mapping of address to amount
    mapping (address => uint256) public purchases;

    constructor(string memory name, string memory symbol, uint256 maxNftSupply, string memory _defaultURI) ERC721(name, symbol) {
        MAX_SUPPLY = maxNftSupply;
        defaultURI = _defaultURI;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * team tokens
     */
    function reserveTeam(uint256 amount) public onlyOwner {
        uint supply = totalSupply();
        require(supply.add(amount) <= MAX_SUPPLY, "Not enough to reserve");
        uint i;
        for (i = 0; i < amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function addWhitelistPrePay(Whitelist[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            // remove amount from total if already added
            require(whitelistPrePay[accounts[i].account] == 0, "cannot add the same user again");
            whitelistPrePay[accounts[i].account] = accounts[i].amount;
            whitelistReserved = whitelistReserved.add(accounts[i].amount);
        }
    }

    function whitelistPrePayAmount(address account) external view returns(uint256) {
        return whitelistPrePay[account];
    }

    function purchased(address account) external view returns(uint256) {
        return purchases[account];
    }
    
    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setMaxSupply(uint256 amount) public onlyOwner {
        MAX_SUPPLY = amount;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory uri = super.tokenURI(tokenId);
        return bytes(uri).length > 0 ? uri : defaultURI;
    }

    /**
    * Mints Mario
    */
    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint");
        require(numberOfTokens <= MAX_PER_USER, "Can only mint 20 tokens at once");
        require(totalSupply().add(numberOfTokens) <= MAX_SUPPLY, "Purchase would exceed max supply");
        if (whitelistPrePay[msg.sender] > 0) {
            require(whitelistPrePay[msg.sender] - purchases[msg.sender] >= numberOfTokens, "no tokens left for you here");
            whitelistReserved = whitelistReserved.sub(numberOfTokens);
        } else {
            require(totalSupply().add(numberOfTokens) <= MAX_SUPPLY.sub(whitelistReserved), "Purchase would exceed max supply");
            require(marioPrice.mul(numberOfTokens) == msg.value, "Ether value sent is not correct");
        }
        purchases[msg.sender] = purchases[msg.sender] + numberOfTokens;
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
}