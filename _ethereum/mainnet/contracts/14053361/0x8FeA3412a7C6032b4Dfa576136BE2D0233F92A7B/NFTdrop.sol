// SPDX-License-Identifier: MIT
/*
                wW  Ww  \\\    ///                                
                (O)(O)__((O)  (O))       /)         Drops:
                 (..)(  )| \  / |      (o)(O)       Jan. 24, 2022
                  ||  )/ ||\\//||       //\\        7:00 p.m. CST
                 _||_ /  || \/ ||      |(__)| 
                (_/\_)   ||    ||      /,-. |  
                        (_/    \_)    -'   '' 
         _ wW  Ww(o)__(o)(o)__(o)wWw  wWw       c  c     (o)__(o) 
  (OO) .' )(O)(O)(__  __)(__  __)(O)  (O)       (OO)   /)(__  __) 
   ||_/ .'  (..)   (  )    (  )  ( \  / )     ,'.--.)(o)(O)(  )   
   |   /     ||     )(      )(    \ \/ /     / //_|_\ //\\  )(    
   ||\ \    _||_   (  )    (  )    \o /      | \___  |(__)|(  ) 
  (/\)\ `. (_/\_)   )/      )/    _/ /       '.    ) /,-. | )/ 
       `._)        (       (     (_.'          `-.' -'   ''(  

  "I'm a Kitty Cat NFT" --> Mint @ https://imakittycat.com/ <--
   10,000 generative 3D-rendered Kitty Cats running around crazy 
   on the ETH blockchain and coming to life in their own AR app. 
   Adopt up to 10 cats and level them up on the coming app! 
   Enjoy freely: Copyright transfers to NFT holder. (^_^)

*/

pragma solidity 0.8.2;
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";

contract NFTcontract is Ownable, ERC721Enumerable, PaymentSplitter {

    uint public MAXSUPPLY = 10000; 
    // We reserve the right to *reduce* the supply shown, if needed.
    // But we hard-coded it below to *never* raise it above this figure.

    uint public PUBLICMINTPRICE = 0.07 ether;
    uint public PRESALEPRICE = 0.07 ether;
    uint public WALLETLIMIT = 10; 
    uint public publicSale = 1643072400; // 1-24-22, 7pm CST

    string public PROVENANCE_HASH;
    // Once we sellout and are sure of no errors requiring any image changes,
    // we will set and lock the provenance hash. This hash is a proof that the
    // images have not been tampered with in terms of order or content.
    // Barring any image corrections or other changes that could affect this,
    // the provenance hash for the set is and will be:
    // 50d5e342bd2fafeff1252559a8c71fad0fafa8ca436a1d4a3d7c972af8125692

    string private _baseURIExtended;
    string private _contractURI;
    bool public _isSaleLive = false;
    bool public _isPreSaleLive = false;
    bool private locked;
    bool private PROVENANCE_LOCK = false;
    uint public _reserved;
    uint id = totalSupply();

    struct Account {
        uint nftsReserved;
        uint mintedNFTs;
        bool isAdmin ;
    }

    mapping(address => Account) public accounts;

    event Mint(address indexed sender, uint totalSupply);
    event PermanentURI(string _value, uint256 indexed _id);
    event Burn(address indexed sender, uint indexed _id);

    address[] private _distro;
    uint[] private _distro_shares;

    constructor(address[] memory distro, uint[] memory distro_shares, address[] memory teamclaim)
        ERC721("Im a Kitty Cat NFT", "KCNFT")
        PaymentSplitter(distro, distro_shares)
    {
        _baseURIExtended = "ipfs://QmQj9VXzpwEKEC59qTPhiQkxpPBuNtRPSeUtpsk1aMQpMq/";

        accounts[msg.sender] = Account( 0, 0, true);

        // teamclaim (5 ttl)
        accounts[teamclaim[0]] = Account( 25, 0, true); // Team_jd
        accounts[teamclaim[1]] = Account( 25, 0, true); // Team_wd
        accounts[teamclaim[2]] = Account( 25, 0, true); // Team_gn
        accounts[teamclaim[3]] = Account( 25, 0, true); // Team_gn
        accounts[teamclaim[4]] = Account( 65, 0, true); // KCat_ownr
        accounts[teamclaim[5]] = Account(  5, 0, true); // CB_ownr

        _reserved = 170;

        _distro = distro;
        _distro_shares = distro_shares;

    }

    // (^_^) Modifiers (^_^) 

    modifier onlyAdmin() {
        require(accounts[msg.sender].isAdmin == true, "Error: You must be an admin.");
        _;
    }

    modifier noReentrant() {
        require(!locked, "Error: No re-entrancy.");
        locked = true;
        _;
        locked = false;
    }

    // (^_^) Setters (^_^) 

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

    function activatePreSale() external onlyOwner {
        _isPreSaleLive = true;
    }

    function deactivatePreSale() external onlyOwner {
        _isPreSaleLive = false;
    }

    function activateSale() external onlyOwner {
        _isSaleLive = true;
        _isPreSaleLive = false;
    }

    function deactivateSale() external onlyOwner {
        _isSaleLive = false;
    }

    function setNewSaleTime(uint _newTime) external onlyOwner {
        publicSale = _newTime;
    }
    
    function setNewPublicPrice(uint _newPrice) external onlyOwner {
        PUBLICMINTPRICE = _newPrice;
    }

    function setNewPreSalePrice(uint _newPrice) external onlyOwner {
        PRESALEPRICE = _newPrice;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        require(_maxSupply <= MAXSUPPLY, 'Error: New max supply cannot exceed original max.');        
        MAXSUPPLY = _maxSupply;
    }

    function setWalletLimit(uint _newLimit) external onlyOwner {
        WALLETLIMIT = _newLimit;
    }

    function increaseReserved(uint _increaseReservedBy, address _addr) external onlyOwner {
        require(_reserved + totalSupply() + _increaseReservedBy <= MAXSUPPLY, "Error: This would exceed the max supply.");
        _reserved += _increaseReservedBy;
        accounts[_addr].nftsReserved += _increaseReservedBy;
        accounts[_addr].isAdmin = true;
    }

    function decreaseReserved(uint _decreaseReservedBy, address _addr) external onlyOwner {
        require(_reserved - _decreaseReservedBy >= 0, "Error: This would make reserved less than 0.");
        require(accounts[_addr].nftsReserved - _decreaseReservedBy >= 0, "Error: User does not have this many reserved NFTs.");
        _reserved -= _decreaseReservedBy;
        accounts[_addr].nftsReserved -= _decreaseReservedBy;
        accounts[_addr].isAdmin = true;
    }
    
    // (^_^) Getters (^_^)

    // -- For OpenSea
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // -- For Metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    // -- For Convenience
    function getMintPrice() public view returns (uint){
        return PUBLICMINTPRICE;
    }

    // (^_^) Business Logic (^_^) 

    function claimReserved(uint _amount) external onlyAdmin {

        require(_amount > 0, "Error: Need to have reserved supply.");
        require(accounts[msg.sender].isAdmin == true,"Error: Only an admin can claim.");
        require(accounts[msg.sender].nftsReserved >= _amount, "Error: You are trying to claim more NFTs than you have reserved.");
        require(totalSupply() + _amount <= MAXSUPPLY, "Error: You would exceed the max supply limit.");

        accounts[msg.sender].nftsReserved -= _amount;
        _reserved = _reserved - _amount;

       for (uint i = 0; i < _amount; i++) {
           id++;
           _safeMint(msg.sender, id);
           emit Mint(msg.sender, totalSupply());
        }

    }

    function airDropNFT(address[] memory _addr) external onlyOwner {

        require(totalSupply() + _addr.length <= (MAXSUPPLY - _reserved), "Error: You would exceed the airdrop limit.");

        for (uint i = 0; i < _addr.length; i++) {
            id++;
            _safeMint(_addr[i], id);
            emit Mint(msg.sender, totalSupply());
        }

    }

    function mint(uint _amount) external payable noReentrant {

        require(_isSaleLive || _isPreSaleLive, "Error: Sale is not active.");
        require(totalSupply() + _amount <= (MAXSUPPLY - _reserved), "Error: Purchase would exceed max supply.");
        require((_amount + accounts[msg.sender].mintedNFTs) <= WALLETLIMIT, "Error: You would exceed the wallet limit.");
        require(!isContract(msg.sender), "Error: Contracts cannot mint.");

        if(_isPreSaleLive) {

            require(msg.value >= (PRESALEPRICE * _amount), "Error: Not enough ether sent.");

        } else if (_isSaleLive) {

            require(msg.value >= (PUBLICMINTPRICE * _amount), "Error: Not enough ether sent.");
            require(block.timestamp >= publicSale, "Error: Public sale has not started.");

        }

        for (uint i = 0; i < _amount; i++) {
            id++;
            accounts[msg.sender].mintedNFTs++;
            _safeMint(msg.sender, id);
            emit Mint(msg.sender, totalSupply());
        }

    }

    function burn(uint _id) external returns (bool, uint) {

        require(msg.sender == ownerOf(_id) || msg.sender == getApproved(_id) || isApprovedForAll(ownerOf(_id), msg.sender), "Error: You must own this token to burn it.");
        _burn(_id);
        emit Burn(msg.sender, _id);
        return (true, _id);

    }

    function distributeShares() external onlyAdmin {
        for (uint i = 0; i < _distro.length; i++) {
            release(payable(_distro[i]));
        }
    }

    function isContract(address account) internal view returns (bool) {  
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }    

    // (^_^) THE END. (^_^)
    // .--- .. -- .--.-. --. . -. . .-. .- - .. ...- . -. ..-. - ... .-.-.- .. ---

}
