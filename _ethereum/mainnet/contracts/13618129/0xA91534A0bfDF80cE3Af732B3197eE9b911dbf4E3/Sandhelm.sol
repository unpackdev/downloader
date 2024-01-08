// SPDX-License-Identifier: MIT

/*
 $$$$$$\   $$$$$$\  $$\   $$\ $$$$$$$\  $$\   $$\ $$$$$$$$\ $$\       $$\      $$\ 
$$  __$$\ $$  __$$\ $$$\  $$ |$$  __$$\ $$ |  $$ |$$  _____|$$ |      $$$\    $$$ |
$$ /  \__|$$ /  $$ |$$$$\ $$ |$$ |  $$ |$$ |  $$ |$$ |      $$ |      $$$$\  $$$$ |
\$$$$$$\  $$$$$$$$ |$$ $$\$$ |$$ |  $$ |$$$$$$$$ |$$$$$\    $$ |      $$\$$\$$ $$ |
 \____$$\ $$  __$$ |$$ \$$$$ |$$ |  $$ |$$  __$$ |$$  __|   $$ |      $$ \$$$  $$ |
$$\   $$ |$$ |  $$ |$$ |\$$$ |$$ |  $$ |$$ |  $$ |$$ |      $$ |      $$ |\$  /$$ |
\$$$$$$  |$$ |  $$ |$$ | \$$ |$$$$$$$  |$$ |  $$ |$$$$$$$$\ $$$$$$$$\ $$ | \_/ $$ |
 \______/ \__|  \__|\__|  \__|\_______/ \__|  \__|\________|\________|\__|     \__|
                                                                                  
*/

pragma solidity 0.8.2;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";

contract Sandhelm is Ownable, ERC721Enumerable, PaymentSplitter {

    uint public constant MAX_HELM = 9999;
    uint public constant HELM_PRICE = 0.07 ether;
    uint public constant walletLimit = 12;
    string public PROVENANCE_HASH;
    string private _baseURIExtended;
    string private _contractURI;
    bool public _isSaleLive = false;
    bool private locked;
    bool private PROVENANCE_LOCK = false;
    uint public _reserved;
    uint id = totalSupply();

    //Sandhelm Release Time -
    uint public publicSale = 1637002800; // November 15th, 2021

    struct Account {
        uint nftsReserved;
        uint walletLimit;
        uint mintedNFTs;
        bool isAdmin;
    }

    mapping(address => Account) public accounts;

    event Mint(address indexed sender, uint totalSupply);
    event PermanentURI(string _value, uint256 indexed _id);

    address[] private _distro;
    uint[] private _distro_shares;

    constructor(address[] memory distro, uint[] memory distro_shares, address[] memory teamclaim, address[] memory admins)
        ERC721("SANDHELM", "HELM")
        PaymentSplitter(distro, distro_shares)
    {
        _baseURIExtended = "ipfs://";

        accounts[msg.sender] = Account( 0, 0, 0, true);
        // teamclaimNFT
        accounts[teamclaim[0]] = Account( 80, 0, 0, true); //1
        accounts[teamclaim[1]] = Account( 10, 0, 0, true); //2
        accounts[teamclaim[2]] = Account( 10, 0, 0, true); //3
        accounts[teamclaim[3]] = Account( 25, 0, 0, true); //4
        accounts[teamclaim[4]] = Account( 25, 0, 0, true); //5
        accounts[teamclaim[5]] = Account( 25, 0, 0, true); //6
        accounts[teamclaim[6]] = Account( 25, 0, 0, true); //7

        //admins
        accounts[admins[0]] = Account( 0, 0, 0, true); //1
        accounts[admins[1]] = Account( 0, 0, 0, true); //2
        accounts[admins[2]] = Account( 0, 0, 0, true); //3
        accounts[admins[3]] = Account( 0, 0, 0, true); //4
        accounts[admins[4]] = Account( 0, 0, 0, true); //5

        _reserved = 200;

        _distro = distro;
        _distro_shares = distro_shares;
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
        require(totalSupply() + _amount <= MAX_HELM, "You would exceed the mint limit");

        accounts[msg.sender].nftsReserved -= _amount;
        _reserved = _reserved - _amount;


        for (uint i = 0; i < _amount; i++) {
            id++;
            _safeMint(msg.sender, id);
            emit Mint(msg.sender, totalSupply());
        }
    }

    function airDropNFT(address[] memory _addr) external onlyOwner {
        require(totalSupply() + _addr.length <= (MAX_HELM - _reserved), "You would exceed the airdrop limit");

        // DO MINT

        for (uint i = 0; i < _addr.length; i++) {
            id++;
            _safeMint(_addr[i], id);
            emit Mint(msg.sender, totalSupply());
        }

    }

    function mint(uint _amount) external payable noReentrant {
        // CHECK BASIC SALE CONDITIONS
        require(_isSaleLive, "Sale must be active to mint");
        require(totalSupply() + _amount <= (MAX_HELM - _reserved), "Purchase would exceed max supply of HELM");
        require(msg.value >= (HELM_PRICE * _amount), "Ether value sent is not correct");
        require(!isContract(msg.sender), "Contracts can't mint");
        
        if(block.timestamp >= publicSale) {
            require((_amount + accounts[msg.sender].mintedNFTs) <= walletLimit, "Sorry you can only mint 12 per wallet");
        } 

        // DO MINT

        for (uint i = 0; i < _amount; i++) {
            id++;
            accounts[msg.sender].mintedNFTs++;
            _safeMint(msg.sender, id);
            emit Mint(msg.sender, totalSupply());
        }

    }

    function distributeETH() external onlyAdmin {
        for (uint i = 0; i < _distro.length; i++) {
            release(payable(_distro[i]));
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