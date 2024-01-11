// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./GamearoundNFT.sol";

// Gamearound Ecosystem Genesis Token
/// @custom:security-contact claudio@gamearound.com
contract GenesisGuild is GamearoundNFT {
    using Counters for Counters.Counter;

    uint256 public maxSupply = 4500;    // Maximum supply of NFTs
    uint256 public dropsSupply = 150;     // Reserved supply for drops

    uint256 public maxPurchase = 3; // Max number of NFT that can be sold in one purchase.

    // Mint Funds
    uint256 mintFundShare = 10;       // Share hold on the mint fund
    uint256 _tempMintFundValue = 0;   // Value hold on the mint fund while an edition is selling
    uint256 mintFundValue = 0;       // Value hold on the mint fund
    uint256 mintFundsPaid = 0;       // All paid mint fund so far
    
    // Genesis Funds
    uint256 genesisFundValue = 0;       // Value hold on the genesis fund
    uint256 genesisFundsPaid = 0;       // All paid genesis fund so far

    // Royalty Funds
    uint256 royaltyFundShare = 10;       // Share hold on the mint fund

    Counters.Counter private _editionCounter; // Current edition in sales
    Counters.Counter private _dropCounter; // Count the NFT drops

    uint256[5] editions = [100, 250, 500, 1500, 2000]; // NFT Editions sizes
    uint256[5] sellout = [100, 350, 800, 2350, 4350]; // NFT Editions sizes
    uint256[5] prices = [0.5 ether, 1.0 ether, 1.5 ether, 1.75 ether, 2.0 ether]; // NFT Editions prices in Ether
    uint256[5] shares = [15, 35, 50, 0, 0]; // NFT Editions shares percentage
    
    bool need_wl = false; // Enable whitelist

    bytes32 public constant WL_MINT_ROLE = keccak256("WL_MINT_ROLE");

    // Mapping Mint Fund withdraws
    mapping(uint256 => uint256) private _mintFundTotal;
    // Mapping Genesis Fund withdraws
    mapping(uint256 => uint256) private _genesisFundTotal;

    bool allowTransfers;

    /************************/
    /* Deploy               */
    /************************/

    constructor() GamearoundNFT("Gamearound Genesis Guild", "GEN") {
    }

    /************************/
    /* Modifiers            */
    /************************/
    
    modifier canDrop() {
        require(_dropCounter.current() < dropsSupply, "Sold out");
        _;
    }

    modifier notSoldOut() {
        require(_tokenIdCounter.current() < sellout[_editionCounter.current()], "Sold out");
        _;
    }

    modifier isSoldOut() {
        require(_tokenIdCounter.current() >= sellout[_editionCounter.current()], "Not sold out");
        _;
    }

    /************************/
    /* Public functions     */
    /************************/

    function currentEdition() public view returns (uint256) {
        return _editionCounter.current() + 1;
    }

    function currentPrice() public view returns (uint256) {
        return prices[_editionCounter.current()];
    }

    function currentSold() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function currentDrops() public view returns (uint256) {
        return _dropCounter.current();
    }

    function tokenEdition(uint256 tokenId) public view returns (uint256) {
        uint256 ed = 5;
        for(uint256 i = 0; i < sellout.length; i++) {
            if (tokenId <= sellout[i]) {
                return (i + 1);
            }
        } 
        return ed;
    }

    function mintFundPaid(uint256 tokenId) public view  returns (uint256) {
        return _mintFundTotal[tokenId];
    }
        
    function genesisFundPaid(uint256 tokenId) public view  returns (uint256) {
        return _genesisFundTotal[tokenId];
    }

    // Distribute the value of the mint fund to all holders acording to the shares table
    function remainMintFund(uint256 tokenId) public view  returns (uint256) {
        require(_msgSender() == ownerOf(tokenId), "Not token onwer");
        if (mintFundValue > 0) {
            uint256 edition = tokenEdition(tokenId);
            uint256 share = shares[edition - 1]; 
            if (share > 0) {
                // Return the remaning value
                return (((mintFundValue * share) / 100) / editions[edition - 1]) - mintFundPaid(tokenId);
            }
        }
        return 0;
    }

    // Distribute the value of the mint fund to all holders acording to the shares table
    function remainGenesisFund(uint256 tokenId) public view  returns (uint256) {
        require(_msgSender() == ownerOf(tokenId), "Not token onwer");
        if (genesisFundValue > 0) {
            uint256 minted = _tokenIdCounter.current();
            if (minted > 0) {
                // Return the remaning value
                return (genesisFundValue / minted) - genesisFundPaid(tokenId);
            }
        }
        return 0;
    }

    // Distribute the value of the mint fund to all holders acording to the shares table
    function claimMintFund(uint256 tokenId) public payable {
        uint256 funds = remainMintFund(tokenId);
        require(funds > 0, "No funds");
        payable(_msgSender()).transfer(funds);
        _mintFundTotal[tokenId] += funds;
        mintFundsPaid += funds;
    }

    function claimGenesisFund(uint256 tokenId) public payable {
        uint256 funds = remainGenesisFund(tokenId);
        require(funds > 0, "No funds");
        payable(_msgSender()).transfer(funds);
        _genesisFundTotal[tokenId] += funds;
        genesisFundsPaid += funds;
    }

    /************************/
    /* Owner only           */
    /************************/

    function setWhitelists(address[] calldata recipients) public onlyRole(MINTER_ROLE) {
        for(uint256 i = 0; i < recipients.length; i++) {
            _grantRole(WL_MINT_ROLE, recipients[i]);
        }
    }


    function withdraw() public payable onlyRole(FUNDS_ROLE) {
        uint balance = address(this).balance;
        payable(_msgSender()).transfer(balance - (mintFundValue - mintFundsPaid) - genesisFundValue);
    }

    // Withdraw everything in case of emergency
    function emergency() public payable onlyRole(FUNDS_ROLE) {
        uint balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    // Modify the base price for an edition
    function setPrice(uint256 _edition, uint256 _newCost) public onlyRole(MINTER_ROLE) {
        require((_edition - 1) < prices.length, "No edition");
        prices[_editionCounter.current()] = _newCost;
    }
    
    // Modify the whitelist need for an edition
    function enableWhitelist(bool _need) public onlyRole(MINTER_ROLE) {
        need_wl = _need;
    }

    // Modify the base edition values
    function setEditon(uint256[] calldata _newMax, uint256[] calldata _newShares) public onlyRole(MINTER_ROLE) {
        uint256 total = 0;
        for(uint256 i = 0; i < _newMax.length; i++) {
            if (i < editions.length) {
                editions[i] = _newMax[i];                
                sellout[i] = _newMax[i] + total;
                total += _newMax[i];
                if (i < _newShares.length) {
                    shares[i] = _newShares[i];
                }
            }
        }
    }

    // Force transfer to start. This by pass the sould out transfer lock
    function unlockTransfers(bool _status) public onlyRole(MINTER_ROLE) {
        allowTransfers = _status;
    }

    // Next edition
    function newEditionSales() public isSoldOut onlyRole(MINTER_ROLE) {
        require(_editionCounter.current() < (editions.length - 1), "No editions");
        _editionCounter.increment();
    }

    // Modify the edition counter
    function setEditionIndex(uint256 _index) public onlyRole(MINTER_ROLE) {
        require((_index - 1) < editions.length, "No editions");
        _editionCounter.reset();
        if (_index > 1) {
            for(uint256 i = 1; i < _index; i++) {
                _editionCounter.increment();
            }
        }
    }

    // Add funds to Genesis Fund
    function addFunds() public payable onlyRole(FUNDS_ROLE) {
        require(msg.value > 0, "No ether");
        genesisFundValue += msg.value;
     }

    /************************/
    /* NFT Mint             */
    /************************/
    
    // Mint many NFTs
    function mint(uint numberOfTokens) public notSoldOut payable {
        require(numberOfTokens <= maxPurchase, "Exceed max nfts at a time");
        require(_canSell(numberOfTokens), "Exceed max of nfts");
        require(msg.value >= (currentPrice() * numberOfTokens), "Value too low");
    
        _checkWhitelist();
        for(uint i = 0; i < numberOfTokens; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current(); // NFT index starts at 1
            _safeMint(_msgSender(), tokenId);        }
     }

    // Drop NFTs
    function drop(address to) public canDrop onlyRole(MINTER_ROLE) {
        uint256 tokenId = _dropCounter.current() + maxSupply - dropsSupply + 1; // Index starts at 1
        _dropCounter.increment();
        _safeMint(to, tokenId);
    }

    // Mint one NFT
    function mintDrop(address to) public notSoldOut onlyRole(MINTER_ROLE) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current(); // NFT index starts at 1
        _safeMint(to, tokenId);
     }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId ) 
        internal
        override 
        {
            super._beforeTokenTransfer(from, to, tokenId);
            // If it is an NFT TRANSFER
            if ((from != address(0)) && (to != address(0))) {
              require(_canTransfer(), "Not sold out");
            }
        }

    // Overrrides
    function _afterTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override
    {
        super._afterTokenTransfer(from, to, tokenId);

        // If it is a MINT
        if (from == address(0)) {
            // If it is not a drop, hold a share of each mint
            if (_needAddToMintFund(tokenId)) {
                _addToMintFund(currentPrice());
            }
            if (_isSoldOut(tokenId)) {
                _setMintFunds();
            }
        }
    }

    /************************/
    /* Private utilities    */
    /************************/

    function _addToMintFund(uint256 value) private {
       _tempMintFundValue += (value * mintFundShare) / 100;
    }

    function _needAddToMintFund(uint256 tokenId) private view returns (bool) {
        // If it is not a drop, and it is not the first edition
       return ((tokenId < (maxSupply - dropsSupply + 1)) && (tokenId > sellout[0]));
    }

    function _isSoldOut(uint256 tokenId) private view returns (bool) {
        return (tokenId >= sellout[_editionCounter.current()]);
    }

    // Transfer from temporary to mint funds
    function _setMintFunds() private {
        mintFundValue += _tempMintFundValue; // Add the collected mint fund
        _tempMintFundValue = 0;             // Reset the temporary storage
    }

    function _canTransfer() private view returns (bool) {
        return (allowTransfers || (_tokenIdCounter.current() >= sellout[sellout.length - 1]));
    }

    function _checkWhitelist() private view {
        if (need_wl) {
            require(hasRole(WL_MINT_ROLE, _msgSender()), "Not whitelisted");
        }
    }

    function _canSell(uint256 numberOfTokens) private view returns (bool) {
        return (_tokenIdCounter.current() + numberOfTokens <= sellout[_editionCounter.current()]);
   }
}