// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./ERC721AUpgradeable.sol";
import "./Initializable.sol";

/*
* @title D8a Dao
* @author lileddie.eth / Enefte Studio
*/
contract D8aDao is Initializable, ERC721AUpgradeable {

    uint64 public MAX_SUPPLY;
    uint64 public TOKEN_PRICE;
    uint64 public MAX_TOKENS_PER_WALLET;

    uint64 public saleOpens;
    uint64 public saleCloses;   

    string public BASE_URI;
      
    mapping(address => bool) private _dev;  
    address private _owner;
    address private wallet1;
    address private wallet2;
    address private wallet3;
    address private wallet4;
    address private wallet5;
    address private wallet6;
    address private wallet7;
    
    /**
    * @notice minting process for the main sale
    *
    * @param _numberOfTokens number of tokens to be minted
    */
    function mint(uint64 _numberOfTokens) external payable  {
        require(block.timestamp >= saleOpens && block.timestamp <= saleCloses, "Public sale closed");
        require(totalSupply() + _numberOfTokens <= MAX_SUPPLY, "Not enough left");

        uint64 mintsForThisWallet = mintsForWallet(msg.sender);
        mintsForThisWallet += _numberOfTokens;
        require(mintsForThisWallet <= MAX_TOKENS_PER_WALLET, "Max tokens reached per wallet");

        require(TOKEN_PRICE * _numberOfTokens <= msg.value, 'Missing eth');

        _safeMint(msg.sender, _numberOfTokens);
        _setAux(msg.sender,mintsForThisWallet);
    }

    /**
    * @notice read the mints made by a specified wallet address.
    *
    * @param _wallet the wallet address
    */
    function mintsForWallet(address _wallet) public view returns (uint64) {
        return _getAux(_wallet);
    }

    /**
    * @notice set the timestamp of when the main sale should begin
    *
    * @param _openTime the unix timestamp the sale opens
    * @param _closeTime the unix timestamp the sale closes
    */
    function setSaleTimes(uint64 _openTime, uint64 _closeTime) external onlyDevOrOwner {
        saleOpens = _openTime;
        saleCloses = _closeTime;
    }
    
    /**
    * @notice set the maximum number of tokens that can be bought by a single wallet
    *
    * @param _quantity the amount that can be bought
    */
    function setMaxPerWallet(uint64 _quantity) external onlyDevOrOwner {
        MAX_TOKENS_PER_WALLET = _quantity;
    }

    /**
    * @notice sets the URI of where metadata will be hosted, gets appended with the token id
    *
    * @param _uri the amount URI address
    */
    function setBaseURI(string memory _uri) external onlyDevOrOwner {
        BASE_URI = _uri;
    }

    function setFounderWallet(address _address) external onlyDevOrOwner {
        wallet1 = _address;
    }
    function setMarketingWallet(address _address) external onlyDevOrOwner {
        wallet2 = _address;
    }
    function setDaoCommunityWallet(address _address) external onlyDevOrOwner {
        wallet3 = _address;
    }
    function setDaoAcquisitionWallet(address _address) external onlyDevOrOwner {
        wallet4 = _address;
    }
    function setDaoRewardsWallet(address _address) external onlyDevOrOwner {
        wallet5 = _address;
    }
    function setDaoDevWallet(address _address) external onlyDevOrOwner {
        wallet6 = _address;
    }
    function setTechnologyWallet(address _address) external onlyDevOrOwner {
        wallet7 = _address;
    }
    
    /**
    * @notice returns the URI that is used for the metadata
    */
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
    * @notice withdraw the funds from the contract to a specificed address. 
    */
    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;

        uint256 wallet1Share = (balance / 100) * 14;
        uint256 wallet2Share = (balance / 100) * 8;
        uint256 wallet3Share = (balance / 100) * 16;
        uint256 wallet4Share = (balance / 100) * 18;
        uint256 wallet5Share = (balance / 100) * 7;
        uint256 wallet6Share = (balance / 100) * 15;
        uint256 wallet7Share = (balance / 100) * 22;

        (bool sent1, bytes memory data1) = wallet1.call{value: wallet1Share}("");
        require(sent1, "Failed to send Ether to Wallet 1");
        (bool sent2, bytes memory data2) = wallet2.call{value: wallet2Share}("");
        require(sent2, "Failed to send Ether to Wallet 2");
        (bool sent3, bytes memory data3) = wallet3.call{value: wallet3Share}("");
        require(sent3, "Failed to send Ether to Wallet 3");
        (bool sent4, bytes memory data4) = wallet4.call{value: wallet4Share}("");
        require(sent4, "Failed to send Ether to Wallet 4");
        (bool sent5, bytes memory data5) = wallet5.call{value: wallet5Share}("");
        require(sent5, "Failed to send Ether to Wallet 5");
        (bool sent6, bytes memory data6) = wallet6.call{value: wallet6Share}("");
        require(sent6, "Failed to send Ether to Wallet 6");
        (bool sent7, bytes memory data7) = wallet7.call{value: wallet7Share}("");
        require(sent7, "Failed to send Ether to Wallet 7");

    }
    
    /**
     * @dev notice if called by any account other than the dev or owner.
     */
    modifier onlyDevOrOwner() {
        require(owner() == msg.sender || _dev[msg.sender], "Ownable: caller is not the owner or dev");
        _;
    }  

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Adds a new dev role user
     */
    function addDev(address _newDev) external onlyOwner {
        _dev[_newDev] = true;
    }

    /**
     * @notice Removes address from dev role
     */
    function removeDev(address _removeDev) external onlyOwner {
        delete _dev[_removeDev];
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    /**
    * @notice Initialize the contract and it's inherited contracts, data is then stored on the proxy for future use/changes
    *
    * @param name_ the name of the contract
    * @param symbol_ the symbol of the contract
    */
    function initialize(string memory name_, string memory symbol_) public initializer {   
        __ERC721A_init(name_, symbol_);
        wallet1 = address(0x50A199ecAa59f5C8d015D1Bd160Ee764DdFE802D);
        wallet2 = address(0xb05dbaAE91621738b076A75fc22D8Df581ccFE09);
        wallet3 = address(0x3E635dee0E109B91ec3881002b9992Bd6179698A);
        wallet4 = address(0xB6025052325d4C3e4e3E04139B3Ba8b9bd5b7D57);
        wallet5 = address(0x29eCE03c2792Fd6004F6e09FA0E936F159E910c4);
        wallet6 = address(0x62518A35D0393A6aE48B0F869637a4F5d36D2483);
        wallet7 = address(0x8a1A2CcF20822d3b02691326eb74a0b7f4087DeC);
        MAX_SUPPLY = 5000;
        MAX_TOKENS_PER_WALLET = 10;
        TOKEN_PRICE = 2 ether;
        BASE_URI = "https://enefte.info/d8adao/metadata.php?token_id=";
        saleOpens = 1668223320;
        saleCloses = 99999999999999;
        
        _dev[msg.sender] = true;
        _owner = msg.sender;
        _mint(address(0x2749Fa69c1f011b1a0164A01A35BEF781832d21D), 100);
        
    }

}