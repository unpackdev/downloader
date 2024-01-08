// SPDX-License-Identifier: MIT
/*
    $$$$$$\  $$\   $$\ $$$$$$$$\ $$$$$$$$\ $$$$$$$\   $$$$$$\   $$$$$$\   $$$$$$\  
    $$  __$$\ $$ |  $$ |$$  _____|$$  _____|$$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ 
    $$ /  \__|$$ |  $$ |$$ |      $$ |      $$ |  $$ |$$ /  $$ |$$ /  \__|$$ /  \__|
    $$ |      $$$$$$$$ |$$$$$\    $$$$$\    $$ |  $$ |$$ |  $$ |$$ |$$$$\ \$$$$$$\  
    $$ |      $$  __$$ |$$  __|   $$  __|   $$ |  $$ |$$ |  $$ |$$ |\_$$ | \____$$\ 
    $$ |  $$\ $$ |  $$ |$$ |      $$ |      $$ |  $$ |$$ |  $$ |$$ |  $$ |$$\   $$ |
    \$$$$$$  |$$ |  $$ |$$$$$$$$\ $$ |      $$$$$$$  | $$$$$$  |\$$$$$$  |\$$$$$$  |
    \______/ \__|  \__|\________|\__|      \_______/  \______/  \______/  \______/                                                                        
*/
pragma solidity 0.8.2;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";

contract ChefBoiRDoge is Ownable, ERC721Enumerable, PaymentSplitter {

    uint public MAX_MUTTS = 10000;
    uint public MUTTS_PRICE = 0.05 ether;
    uint public constant walletLimit = 10;
    string public PROVENANCE_HASH;
    string private _baseURIExtended;
    string private _contractURI;
    bool public _isSaleLive = false;
    bool private locked;
    bool private PROVENANCE_LOCK = false;
    uint public _reserved;
    uint id = totalSupply();

    //Chef Boi R Doge: MUTTS Release Time -
    uint public publicSale = 1636389000; // November 8th 9AM PST

    struct Account {
        uint nftsReserved;
        uint walletLimit;
        uint mintedNFTs;
        bool isAdmin;
    }

    mapping(address => Account) public accounts;

    event Mint(address indexed sender, uint totalSupply);
    event PermanentURI(string _value, uint256 indexed _id);

    address[] private _team;
    uint[] private _team_shares;

    constructor(address[] memory team, uint[] memory team_shares, address[] memory admins)
        ERC721("Chef Boi R Doge: Mutts", "CBRD")
        PaymentSplitter(team, team_shares)
    {
        _baseURIExtended = "ipfs://";

        accounts[msg.sender] = Account( 0, 0, 0, true);
        // teamClaimNFTs
        accounts[admins[0]] = Account( 15, 0, 0, true); 
        accounts[admins[1]] = Account( 8, 0, 0, true);
        accounts[admins[2]] = Account( 2, 0, 0, true);
        accounts[admins[3]] = Account( 125, 0, 0, true); 
        accounts[admins[4]] = Account( 25, 0, 0, true);
        accounts[admins[5]] = Account( 25, 0, 0, true);
        accounts[admins[6]] = Account( 25, 0, 0, true); 
        accounts[admins[7]] = Account( 25, 0, 0, true);


        _reserved = 250;

        _team = team;
        _team_shares = team_shares;
    }

    // Modifiers

    modifier onlyAdmin() {
        require(accounts[msg.sender].isAdmin == true, "Sorry, You need to be an admin");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    // End Modifier

    // Setters

    function setAdmin(address _addr) external onlyOwner {
        accounts[_addr].isAdmin = !accounts[_addr].isAdmin;
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        require(PROVENANCE_LOCK == false);
        PROVENANCE_HASH = _provenanceHash;
    }

    function lockProvenance() external onlyOwner {
        PROVENANCE_LOCK = true;
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        _baseURIExtended = _newURI;
    }

    function setContractURI(string memory _newURI) external onlyOwner {
        _contractURI = _newURI;
    }

    function deactivateSale() external onlyOwner {
        _isSaleLive = false;
    }

    function activateSale() external onlyOwner {
        _isSaleLive = true;
    }


    function setNewSaleTime(uint[] memory _newTime) external onlyOwner {
        require(_newTime.length == 1);
        publicSale = _newTime[0];
    }
    
    function setNewPrice(uint _newPrice) external onlyOwner {
        MUTTS_PRICE = _newPrice;
    }

    function setMaxMUTTS(uint _maxmutts) external onlyOwner {
        MAX_MUTTS = _maxmutts;
    }

    // End Setters

    // Getters

    // For OpenSea
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // For Metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    // End Getter

    // Business Logic

    function adminMint() external onlyAdmin {
        uint _amount = accounts[msg.sender].nftsReserved;
        require(accounts[msg.sender].isAdmin == true,"Sorry, Only an admin can mint");
        require(_amount > 0, 'Need to have reserved supply');
        require(totalSupply() + _amount <= MAX_MUTTS, "You would exceed the mint limit");

        accounts[msg.sender].nftsReserved -= _amount;
        _reserved = _reserved - _amount;


        for (uint i = 0; i < _amount; i++) {
            id++;
            _safeMint(msg.sender, id);
            emit Mint(msg.sender, totalSupply());
        }
    }

    function airDropMany(address[] memory _addr) external onlyOwner {
        require(totalSupply() + _addr.length <= (MAX_MUTTS - _reserved), "You would exceed the airdrop limit");

        // DO MINT

        for (uint i = 0; i < _addr.length; i++) {
            id++;
            _safeMint(_addr[i], id);
            emit Mint(msg.sender, totalSupply());
        }

    }

    function mintMutt(uint _amount) external payable noReentrant {
        // CHECK BASIC SALE CONDITIONS
        require(_isSaleLive, "Sale must be active to mint");
        require(totalSupply() + _amount <= (MAX_MUTTS - _reserved), "Purchase would exceed max supply of MUTTS");
        require(msg.value >= (MUTTS_PRICE * _amount), "Ether value sent is not correct");
        require(!isContract(msg.sender), "Contracts can't mint");
        
        if(block.timestamp >= publicSale) {
            require((_amount + accounts[msg.sender].mintedNFTs) <= walletLimit, "Sorry you can only mint 10 per wallet");
        } 

        // DO MINT

        for (uint i = 0; i < _amount; i++) {
            id++;
            accounts[msg.sender].mintedNFTs++;
            _safeMint(msg.sender, id);
            emit Mint(msg.sender, totalSupply());
        }

    }
    // ANY of the Admins set on deployment can call this funciton. 
    function releaseFunds() external onlyAdmin {
        for (uint i = 0; i < _team.length; i++) {
            release(payable(_team[i]));
        }
    }
    // helper

    function isContract(address account) internal view returns (bool) {
  
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }    

}