// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";

contract BenFTCollection is Ownable, ERC721Enumerable, PaymentSplitter {

    uint public MAX_BNFT = 10000;
    uint public BNFT_PRICE = 0.1 ether;
    uint public walletLimit = 100;
    string public PROVENANCE_HASH;
    string private _baseURIExtended;
    string private _contractURI;
    bool public _isSaleLive = false;
    bool private locked;
    bool private PROVENANCE_LOCK = false;
    uint public _reserved;
    uint id = totalSupply();


    //BenFT Collection Release Time -
    uint public presaleStart = 1636214400; // November 6th 9AM PST 
    uint public presaleEnd = 1636225200;   // November 6th 12PM PST  
    uint public publicSale = 1636225201;   // November 6th 12PM PST 

    struct Account {
        uint nftsReserved;
        uint walletLimit;
        uint mintedNFTs;
        bool isWhitelist;
        bool isAdmin;
    }

    mapping(address => Account) public accounts;

    event Mint(address indexed sender, uint totalSupply);
    event PermanentURI(string _value, uint256 indexed _id);

    address[] private _team;
    uint[] private _team_shares;

    constructor(address[] memory team, uint[] memory team_shares, address[] memory admins)
        ERC721("BenFT Collection", "BNFT")
        PaymentSplitter(team, team_shares)
    {
        _baseURIExtended = "ipfs://QmUdERdpxsgRAiGVw9V15yUQ2LvNM1Hb8d1XQhvuF3dTEi/";

        accounts[msg.sender] = Account( 0, 0, 0, true, true);
        // teamClaimNFTs
        accounts[admins[0]] = Account( 100, 0, 0, false, true); // 10% shares and 100 NFT
        accounts[admins[1]] = Account( 0, 0, 0, false, true); // 14% shares NO NFT
        accounts[admins[2]] = Account( 0, 0, 0, false, true); // 6% shares NO NFT
        accounts[admins[3]] = Account( 25, 0, 0, false, true); // team NFTs
        accounts[admins[4]] = Account( 25, 0, 0, false, true); // team NFTs
        accounts[admins[5]] = Account( 13, 0, 0, false, true); // team NFTs 
        accounts[admins[6]] = Account( 12, 0, 0, false, true); // team NFTs

        // distroAddresses:
        // [0] 0x750EF1D7a0b4Ab1c97B7A623D7917CcEb5ea779C - 70% of proceeds from the primary sale are hard-coded here to the following ETH address: 0x750EF1D7a0b4Ab1c97B7A623D7917CcEb5ea779C
        // This goes straight to the GiveDirectly organization to help those living in poverty and can be verified on their web site at https://www.givedirectly.org/crypto/ A 2.5% royalty on each resale will also benefit GiveDirectly!
        // [1] 0x3D05c62857DD644225f125e863a25724C40B4a31 - 14%
        // [2] 0xB7bee3e6b4124d48b726d782E5F1413806e66E79 - 10%
        // [3] 0x7905c1685096738b228a5383eF531778602Af642 - 6%

        _reserved = 175;

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

    function setBaseURI(string memory _newURI) external onlyAdmin {
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

    function setWhitelist(address[] memory _addr) external onlyOwner {
        for(uint i = 0; i < _addr.length; i++) {
            accounts[_addr[i]].walletLimit = 100;
            accounts[_addr[i]].isWhitelist = true;
        }
    }

    function setSaleTimes(uint[] memory _newTimes) external onlyAdmin {
        require(_newTimes.length == 3, "You need to update all times at once");
        presaleStart = _newTimes[0];
        presaleEnd = _newTimes[1];
        publicSale = _newTimes[2];
    }
    
    function setNewPrice(uint _newPrice) external onlyOwner {
        BNFT_PRICE = _newPrice;
    }

    function setMaxBNFT(uint _maxbnft) external onlyOwner {
        MAX_BNFT = _maxbnft;
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
        require(totalSupply() + _amount <= MAX_BNFT, "You would exceed the mint limit");

        accounts[msg.sender].nftsReserved -= _amount;
        _reserved = _reserved - _amount;


        for (uint i = 0; i < _amount; i++) {
            id++;
            _safeMint(msg.sender, id);
            emit Mint(msg.sender, totalSupply());
        }
    }

    // ANY Admin set on deployment can call this function.
    function airDropMany(address[] memory _addr) external onlyAdmin {
        require(totalSupply() + _addr.length <= (MAX_BNFT - _reserved), "You would exceed the airdrop limit");

        // DO MINT

        for (uint i = 0; i < _addr.length; i++) {
            id++;
            _safeMint(_addr[i], id);
            emit Mint(msg.sender, totalSupply());
        }

    }

    function mintBen(uint _amount) external payable noReentrant {
        // CHECK BASIC SALE CONDITIONS
        require(_isSaleLive, "Sale must be active to mint");
        require(block.timestamp >= presaleStart, "You must wait till presale begins to mint");
        require(totalSupply() + _amount <= (MAX_BNFT - _reserved), "Purchase would exceed max supply of BenFTs");
        require(msg.value >= (BNFT_PRICE * _amount), "Ether value sent is not correct");
        require(!isContract(msg.sender), "Contracts can't mint");

        if(block.timestamp >= publicSale) {
            require((_amount + accounts[msg.sender].mintedNFTs) <= walletLimit, "Sorry you can only mint 100 per wallet");
        } else if(block.timestamp >= presaleEnd) {
            require(false, "Presale has ended, please wait until Public Sale");
        } else if(block.timestamp >= presaleStart) {
            require(accounts[msg.sender].isWhitelist, "Sorry, you need to be on Whitelist to mint during Presale");
            require((_amount + accounts[msg.sender].mintedNFTs) <= accounts[msg.sender].walletLimit, "Wallet Limit Reached");
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