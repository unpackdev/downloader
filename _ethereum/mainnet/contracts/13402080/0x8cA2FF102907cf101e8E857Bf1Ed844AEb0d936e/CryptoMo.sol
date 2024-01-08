// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/*

 ██████╗██████╗ ██╗   ██╗██████╗ ████████╗ ██████╗     ███╗   ███╗ ██████╗
██╔════╝██╔══██╗╚██╗ ██╔╝██╔══██╗╚══██╔══╝██╔═══██╗    ████╗ ████║██╔═══██╗
██║     ██████╔╝ ╚████╔╝ ██████╔╝   ██║   ██║   ██║    ██╔████╔██║██║   ██║
██║     ██╔══██╗  ╚██╔╝  ██╔═══╝    ██║   ██║   ██║    ██║╚██╔╝██║██║   ██║
╚██████╗██║  ██║   ██║   ██║        ██║   ╚██████╔╝    ██║ ╚═╝ ██║╚██████╔╝
 ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝        ╚═╝    ╚═════╝     ╚═╝     ╚═╝ ╚═════╝

*/

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";

contract CryptoMo is Ownable, ERC721Enumerable, PaymentSplitter {

    uint public constant MAX_MOES = 10000;
    uint public constant MOE_PRICE = 0.08 ether;
    string public PROVENANCE_HASH; // this will be the original CID from IPFS to validate Provenance of collection
    string private _baseURIExtended;
    string private _contractURI;
    bool public _isSaleLive = false;
    bool private PROVENANCE_LOCK = false;
    uint public _reserved;
    bool internal locked;

    //Date: Oct 12, 2021
    uint public presale; //PreSale  : 1PM West Coast Time
    uint public publicSale; //Open Sale: 1PM West Coast Time

    struct Account {
        uint32 nftsReserved;
        uint32 walletLimit;
        uint32 mintedNFTs;
        bool isWhitelist;
        bool isAdmin;
    }

    mapping(address => Account) public accounts;

    address[] private _team;
    uint[] private _team_shares;
    address[] private _moeById;

    constructor(address[] memory team, uint[] memory team_shares, address[] memory admins)
    ERC721("Crypto Mo", "MO")
    PaymentSplitter(team, team_shares)
    {
        _baseURIExtended = "ipfs://QmbHjsvFJT8uP64xRRSKoXuoq4VYXeRaao1VKzK3JFyEvE/";
        accounts[msg.sender] = Account( 0, 0, 0, true, true );
        accounts[admins[0]] = Account( 200, 0, 0, true, true );
        accounts[admins[1]] = Account( 34, 0, 0, true, true );
        accounts[admins[2]] = Account( 33, 0, 0, true, true );
        accounts[admins[3]] = Account( 33, 0, 0, true, true );

        _reserved = 300;

        _team = team;
        _team_shares = team_shares;

        presale = 1634068800; // Oct 12 1pm PST
        publicSale = presale + 24 hours; // Public Sale Begins at Oct 13 1pm PST

    }

    // Modifiers

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyAdmin() {
        require(accounts[msg.sender].isAdmin == true, "Nice try! You need to be an admin");
        _;
    }

    // End Modifier

    // Setters

    function setAdmin(address _addr) external onlyOwner {
        accounts[_addr].isAdmin = !accounts[_addr].isAdmin;
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyAdmin {
        require(PROVENANCE_LOCK == false);
        PROVENANCE_HASH = _provenanceHash;
    }

    function lockProvenance() external onlyOwner {
        PROVENANCE_LOCK = true;
    }

    function setBaseURI(string memory _newURI) external onlyAdmin {
        _baseURIExtended = _newURI;
    }

    function setContractURI(string memory _newURI) external onlyAdmin {
        _contractURI = _newURI;
    }

    function deactivateSale() external onlyAdmin {
        _isSaleLive = false;
    }

    function activateSale() external onlyAdmin {
        _isSaleLive = true;
    }

    function setWhitelist(address[] memory _addr) external onlyAdmin {
        for(uint i = 0; i < _addr.length; i++) {
            accounts[_addr[i]].isWhitelist = true;
        }
    }

    function setSaleTimes(uint[] memory _newTimes) external onlyAdmin {
        require(_newTimes.length == 2, "You need to update all times at once");
        presale = _newTimes[0];
        publicSale = _newTimes[1];
    }

    // End Setter

    // Getters

    function getSaleTimes() public view returns (uint, uint) { // for the frontend
        return (presale, publicSale);
    }

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

    function adminMint(uint32 _amount) external onlyAdmin {
        require(accounts[msg.sender].isAdmin == true,"Nice Try! Only an admin can mint");
        require(_amount > 0, 'Need to have reserved supply');
        require(_amount <= accounts[msg.sender].nftsReserved, "Amount requested more then you have reserved");

        accounts[msg.sender].nftsReserved -= _amount;
        _reserved = _reserved - _amount;

        uint id = totalSupply();

        for (uint i = 0; i < _amount; i++) {
            id++;
            _safeMint(msg.sender, id);
        }

    }

    function airDropMany(address[] memory _addr) external onlyAdmin {

        require(_addr.length <= accounts[msg.sender].nftsReserved, "You can't mint more then your reserved amount");
        accounts[msg.sender].nftsReserved -= uint32(_addr.length); // subtract from the admins reserved amount
        require(_addr.length <= _reserved, "You requested to mint more than your reserved amount");
        _reserved -= uint32(_addr.length); // subtract from the contracts reserved amount for airdrops

        // DO MINT
        uint id = totalSupply();

        for (uint i = 0; i < _addr.length; i++) {
            id++;
            _safeMint(_addr[i], id);
        }

    }

    function mintMoe(uint _amount) external payable noReentrant {
        // CHECK BASIC SALE CONDITIONS
        require(_isSaleLive, "Sale must be active");
        require(block.timestamp >= presale, "Presale has not started");
        require(_amount > 0, "Must mint at least one token");
        require(totalSupply() + _amount <= (MAX_MOES - _reserved), "Purchase would exceed max supply of Moes");
        require(msg.value >= MOE_PRICE * _amount, "Ether value sent is not correct");
        require(!isContract(msg.sender), "Nice try contracts can't mint");
        require((_amount + accounts[msg.sender].mintedNFTs) <= 25, "Can only mint 25 tokens at a time");

       if(block.timestamp >= presale && block.timestamp <= publicSale) {
           require(accounts[msg.sender].isWhitelist, "Sorry you need to be on a whitelist" );
           require((_amount + accounts[msg.sender].mintedNFTs) <= 10, "Can only mint 10 Mo's during presale");
        }

        // DO MINT
        uint id = totalSupply();

        for (uint i = 0; i < _amount; i++) {
            id++;
            accounts[msg.sender].mintedNFTs++;
            _safeMint(msg.sender, id);
        }

    }

    function releaseFunds() external onlyAdmin {
        for (uint i = 0; i < _team.length; i++) {
            release(payable(_team[i]));
        }
    }

    function releaseExtraFunds() external onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    // helper

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

}
