// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Context.sol";

contract Metaverse3022 is Context, Ownable, ERC721Enumerable, ERC721Burnable {
    
    address public TEAM_ACCOUNT1 = 0x0000000000000000000000000000000000000000;
    address public TEAM_ACCOUNT2 = 0x0000000000000000000000000000000000000000;

    mapping (address => bool) public presaleReserved;
    
    string private _baseTokenURI;
    string private _provenance;
    uint256 private _maxAllowedSupply;
    uint256 private _reserved;
    uint256 private _cap_txn;
    uint256 private _cap_wallet;
    uint256 private _price;
    uint256 private _tokenId;
    uint256 private _reservedTokenId;
    bool private _presale;
    bool private _isWhitelistDisabled;
    
    constructor(
        string memory baseURI,
        uint256 maxAllowedSupply,
        uint256 reserved,
        uint256 cap_txn,
        uint256 cap_wallet,
        uint256 price
    ) ERC721("3022 Metaverse", "3022") {
        // Set base host URL
        setBaseURI(baseURI);
        // Set cap limits
        setCapTxn(cap_txn);
        setCapWallet(cap_wallet);
        // Set claim price
        setPrice(price);
        // Set max allowed supply
        _maxAllowedSupply = maxAllowedSupply;
        
        // Init reserve amount (Counting zero)
        _reserved = reserved;
        // Init token ids after reserves (Counting zero)
        _tokenId = _reserved;
        
        // Init presale
        _presale = false;
        // Init whitelist as disable
        _isWhitelistDisabled = true;
        
    }
    
    event PresaleStatus(bool started);
    //event WhitelistedAccountAdded(address account);
    //event WhitelistedAccountRemoved(address account);
    event WhitelistedStatus(bool enabled);
    
    
    modifier isWhitelisted() {
        require(
		    _isWhitelistDisabled || presaleReserved[_msgSender()],
		    '3022 Metaverse: caller not whitelisted'
		);
		_;
    }
    
    modifier isContract() {
		require(
		    !Address.isContract(_msgSender()),
		    '3022 Metaverse: contracts not allowed'
		);
		_;
	}

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // Custom functions
    function presaleSlotAdd(address[] calldata account) external onlyOwner {
        
        for(uint256 i; i < account.length; i++) {
            presaleReserved[account[i]] = true;
            
            //emit WhitelistedAccountAdded(account[i]);
        }
    }
    
    function presaleSlotRemove(address[] calldata account) external onlyOwner {
        
        for(uint256 i; i < account.length; i++) {
            presaleReserved[account[i]] = false;
            
            //emit WhitelistedAccountRemoved(account[i]);
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function getContractURI() public view returns(string memory) {
        return _baseURI();
    }

    function getMaxAllowedSupply() public view returns (uint256) {
        return _maxAllowedSupply;
    }

    function nextTokenId() public view returns (uint256) {
        return _tokenId;
    }

    function nextReservedTokenId() public view returns (uint256) {
        return _reservedTokenId;
    }

    function setProvenance(string memory provenance) external onlyOwner {
        require(bytes(_provenance).length == 0, "3022 Metaverse: Provenance already set");
        _provenance = provenance;
    }

    function getProvenance() public view returns (string memory) {
        return _provenance;
    }
    

    function getCapTxn() public view returns (uint256) {
        return _cap_txn;
    }


    function setCapTxn(uint256 cap_txn) public onlyOwner {
        _cap_txn = cap_txn;
    }

    function getCapWallet() public view returns (uint256) {
        return _cap_wallet;
    }


    function setCapWallet(uint256 cap_wallet) public onlyOwner {
        _cap_wallet = cap_wallet;
    }

    function getReserved() public view returns (uint256) {
        return _reserved;
    }
    
    function getPrice() public view returns (uint256) {
        return _price;
    }


    function setPrice(uint256 newPrice) public onlyOwner {
        _price = newPrice;
    }

    function enableWhitelisting() external onlyOwner {
        _isWhitelistDisabled = false; 
        
        emit WhitelistedStatus(true);
    }
    
    function disableWhitelisting() external onlyOwner {
        _isWhitelistDisabled = true;
        
        emit WhitelistedStatus(false);
    }
    
    function startPresale() external onlyOwner {
        _presale = true;
        
        emit PresaleStatus(true);
    }


    function endPresale() external onlyOwner {
        _presale = false;
        
        emit PresaleStatus(false);
    }


    function claim(uint256 amount) external payable isWhitelisted isContract {
        
        uint256 supply = totalSupply();

        require(
            _presale, 
            "3022 Metaverse: Presale time has not started yet"
        );
        require(
            amount <= _cap_txn,
            "3022 Metaverse: Exceeds maximum allowed claims per txn"
        );
        require(
            balanceOf(_msgSender()) + amount <= _cap_wallet,
            "3022 Metaverse: Exceeds maximum allowed tokens per wallet"
        );
        require(
            (supply - _reservedTokenId) + amount <= _maxAllowedSupply - _reserved,
            "3022 Metaverse: Exceeds maximum tokens supply"
        );
        require(
            msg.value >= _price * amount,
            "3022 Metaverse: Wrong ETH amount sent"
        );

        for(uint256 i; i < amount; i++) {
            _safeMint(_msgSender(), _tokenId);
            _tokenId++;
        }
    }

    function mintFromReserves(address[] calldata to) external onlyOwner {
        
        require(
            to.length <= _reserved - _reservedTokenId,
            "3022 Metaverse: Exceeds maximum reserved tokens supply"
        );

        for(uint256 i; i < to.length; i++) {
            _safeMint(to[i], _reservedTokenId);
            _reservedTokenId++;
        }
    }
    
    function safeMint(address to, uint256 amount) external onlyOwner {

        uint256 supply = totalSupply();

        require(
            (supply - _reservedTokenId) + amount <= _maxAllowedSupply - _reserved,
            "3022 Metaverse: Exceeds maximum tokens supply"
        );

        for(uint256 i; i < amount; i++) {
            _safeMint(to, _tokenId);
            _tokenId++;
        }
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);

        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
    
    function setTeamAddresses(address[] calldata team) external onlyOwner {
        TEAM_ACCOUNT1 = team[0];
        TEAM_ACCOUNT2 = team[1];
    }

    function withdrawAll() external payable onlyOwner {
        uint256 _payable = address(this).balance / 100;

        Address.sendValue(payable(TEAM_ACCOUNT1), _payable * 80);
        Address.sendValue(payable(TEAM_ACCOUNT2), _payable * 20);
    }
}
