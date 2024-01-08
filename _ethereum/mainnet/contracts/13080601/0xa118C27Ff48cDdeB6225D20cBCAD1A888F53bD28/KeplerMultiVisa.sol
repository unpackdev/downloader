import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IERC20.sol";

pragma solidity ^0.8.6;

contract KeplerMultiVisa is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;  // Counters track total # of elements in mapping
    
    Counters.Counter public _tokenIds;    
    mapping(uint256 => bool) private whitelisted;  // Mapping tracks which ID's were minted by owner thru giveaway, used for differentiating tokenURI return
    bool public isActive = false;  // Controls access to mint() function, true for mint accessible / false for mint inaccessible
    uint256 public itemPrice;
    uint256 public mintCount;  // Tracks total public mints
    uint256 public numGiveAwaysMinted;  // Tracks total minted from giveaway
    uint256 public maxMintNumAllowed = 100;  // Max mint allowed until increased by owner through setNewSaleAmount()
    uint256 public immutable hardcap = 330;  // 330 Total Multivisas can be minted from mint function
    uint256 public immutable maxGiveAway = 70;  // 70 Total Multivisas can be minted from mintGiveAway function
    string private baseURI;
    string private baseURIWhitelist;

    constructor () ERC721("Kepler Multivisa", "KMV") {
        baseURI = "https://gateway.pinata.cloud/ipfs/QmTiY9NvUmAQ4ezn4E3sXR5MEREi1GBDq3mLmbzBwyM4YT/";
        baseURIWhitelist = "https://gateway.pinata.cloud/ipfs/Qme5nSo98uAZP1Aq3bzQfQofVwZhrQtyhYaGk8AjPsqEJq/";
        itemPrice = 80000000000000000;  // 0.08 ETH
        transferOwnership(address(0x5c8FC210f2ccEC69e0a78A0Ce675fcDd39BF6ba8));
    }
    
    // Public Mint
    function mint(uint _amount) public payable {
        require(isActive, "Keplers Civil Society Multivisa Sale Is Not Active");
        require(mintCount + _amount <= maxMintNumAllowed, "Minting Maxed Out");
        require(msg.value >= itemPrice * _amount, "Insufficient ETH sent for Payment");
        require(_amount <= 10, "Maximum 10 Mints Per Transaction");
        require(_amount > 0, "Youre Welcome");
        mintCount += _amount;
        for(uint i = 0; i < _amount; i++) {
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
            _tokenIds.increment();
        }
    }
    
    // Owner can mint _amount of passes up to total of 70, tag minted passes as whitelisted in mapping
    function mintGiveAway(uint256 _amount) public onlyOwner {
        require(numGiveAwaysMinted+_amount <= maxGiveAway, "Requested amount over maximum allowed giveaway count");
        numGiveAwaysMinted += _amount;
        for(uint256 i; i < _amount; i++){
            uint256 newItemId = _tokenIds.current();
            _safeMint(owner(), newItemId);
            whitelisted[newItemId] = true;
            _tokenIds.increment();
        }
    }

    // Setters - onlyOwner access

    function setNewSaleAmount(uint256 _maxMintNumAllowed) external onlyOwner {
        require(maxMintNumAllowed < _maxMintNumAllowed, "Specified input not greater than current max mint amount");
        require(_maxMintNumAllowed <= hardcap, "Specified input over maximum of 330 for public mint");  // 330 hard cap total for public mints
        require(!isActive, "Cannot increase number of passes for sale while active");
        maxMintNumAllowed = _maxMintNumAllowed;
    }
    
    function setActive(bool _val) public onlyOwner {
        isActive = _val;
    }
     
    function setURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setURIWhitelist(string memory _uri) public onlyOwner {
        baseURIWhitelist = _uri;
    }

    function setItemPrice(uint256 _price) public onlyOwner {
        require(!isActive, "Cannot change price during active sale");
		itemPrice = _price;
	}

    // Getters - view functions

    // Returns baseURIWhitelist if specified ID was whitelisted(minted by owner),
    // Returns baseURI otherwise (minted through mint() function)
    function tokenURI(uint256 _id) public view virtual override returns (string memory) {
        require(_id < _tokenIds.current(), "tokenId exceeds upper bound");
        string memory URI;
        URI = whitelisted[_id] ? baseURIWhitelist : baseURI;
        return bytes(URI).length > 0 ? string(abi.encodePacked(URI, _id.toString(), ".json")) : "";
    }

    function getItemPrice() public view returns (uint256) {
		return itemPrice;
	}
	
    // Returns array of tokenID's that input address _owner owns
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
    // Utility/Withdraw Functions - onlyOwner Access

    function withdrawEth() public onlyOwner {
        uint256 _balance = address(this).balance;
        require(payable(owner()).send(_balance));
    }

    // Rescue any ERC-20 tokens that are sent to contract mistakenly
    function withdrawToken(IERC20 _token, uint256 _amount) public onlyOwner {
        _token.transferFrom(address(this), owner(), _amount);
    }
}