// SPDX-License-Identifier: MIT

/**
                                                                                                    
                                             ,       @                                              
                                    ,,*@(@@@@@@\@@@@,@@#&@@&@(%@%                                   
                                 .@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@# %                               
                           .&@(@@@@@@@@@@@@@@@@&@@@@&@@@@@@@@@@@@@@&@@@@#                           
                          \\@@@@@@@&@@(@@\%@@@@@%@@@@@@@@@@@@@@@@@@@@@@@\@                          
                      (&&&@@@@@@@&@@@%&&&&%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@                      
                     **  @@@@&@@@@@@#*%#*%&@@@@@@@&@@&@&@@@@@@@@@@@@@@@@@@@@@*%                     
                     .@@@@@@@@@@@@#(&@##@&#\@#@@&@.@@@@@@&%@@@@@@@@@@@@@@@@@@%@@                    
                      #&@@@@@@@@@@@@@(%@(&@%@@@@&&*@&@@@@#@(@@@@&@@@@@@@@@@@@@                      
                      @@@@@@@@@@@@@@@@@@@@\%&@&%\****(%&&%\@@@@@@@@@@@@@@@@@@*%@                    
                     .@@@@@@@@@@@@@@@@@@@&\**((\\#**\\\(\*\\@@@@@@@@@@@@@@@@@@&.                    
                     @@&@@@@@@@@@@@@@@&@@@\*****#,**(\**\\\@@@@@@@@@@@@@@@@@&@..                    
                       (@@@@@@@@@@@@@@@@@%&\\\\\\\((\\\\((\@&@@@@@@@@&@@@@@@@\&                     
               &,.(    .@.@@@@@@@@@@@@@@@@@*((*@%%(##&%(\\@@@@@@@@@@@@@@&@@&# *                     
               * .(       &@#@@@@@@@@@@@@@@@@\\\*&(##\(\@@@@@@@@@@@@@@@@@@@  (                      
               %%%%     .  @ @@&@@@@@@@@@@@@@%((\\\\(\\#@@@@@@@@@@@@@@@@@& *                        
              &%&&(@        ,( @@#@@@@@@@@@@@@(((((((\\\&@@@@@@@@@@@@@@@ ,                          
             @@&@@&@@         %  @@@@@&@(@\%*(((((((((((\&&@#%@@@(.@@                               
             &&@@@@@@         \.,**,\,,*..,#%%\\(((((((( # .. ..,,,,,,#                             
           \(\&#&@&@(      #***,,..... ....#**\.\#  .\%*\,..  . ......(..#                          
          %\@.%%  \\#    ,.*.......,, ......*\\#%\\*,\*#,*..  .. ....,   ...                        
          ,,((\#@&%*\*   .,...,,,,,,, ..  ..*\\\\\\*****(...#,........     ...                      
          \((\&  &&@%\  ,,....,,,,,,....    .\*********,.. .%@.....,(...     ..,                    
           *(&\ .@&@#&  *,...,\,***,.. #     .********* .   .,...,,,\,,,..      ...                 
             %#%#%%#(*  ,,....,(*(,,,,,,,      *******( .  %*,,\\&@,\**,,..       ..,               
               \(\\((\(,,,... ,,(**,...    * , (******.  *\(*,*,(.,*( \**,,.        ..*             
               *((\\(\\....   ,*,\**,....     .\\\\\\(. * ( ..,,..,*     ,,,. ...       ,           
               *\((\(((*......,*,#******,,****\\####(#*\****#*@,**\(       #,,,,.        .          
               *\((\\(#,\, ...,,. ,*\******\\\\\\\\\\(%\\\,.\(\,*\*          ,**,. ......,,,        
               .\((((( .,,...,*\  \****,,,,,**,(********,,,*,,*,,,.            ***,,\,*..   ..      
               ..%((,.  ..*,.**    *,,,,,.,,.,,.*****.#,,*,,*,,,*,               .     ......,      
               \....     ..,,*     ,,,,,,,,.....*****.*,,,,#(%\,*\               .......  ..        
                ..,..     .**.    (,,,...,,,,...*****....,.,..\((*          *    ........#          
                ,...... . ,((    (,,,......,,,,**\\\\...... %&%#((*       .   .........             
                  ....... ,\    .,,,.........*,**\\\\,*      ..(%%#(\  ,,.  .,......\               
                  \...,, .*    ,,,,,,,,,,,....,*\\\\\,,   ....,,,.&((((((% .,....,,                 
                     *.(     (,*,..  .,,*#\,...,\\\\\*. ..,,*(*,,,,.\\\\\\(   ..                    
                            (,.,..    .,,.\   .,\\\\\\.   \..,**,..,, (\& *(.(                      
                            ,,...        *    .*\(\\\#,    ,    ....,.,.(                           

                                             Divas by BLAQ

This generative 10k Divas by BLAQ collection is part of an overall 13k collection utilizing approximately 200 hand-drawn traits. The 10k NFTs herein draw from the core set, but exclude approximately 22 traits that are specific to Delta Sigma Theta Sorority, Inc. This set's sister collection of 3k NFTs (under a separate smart contract) draws from the same core, but incorporates Delta Sigma Theta related traits. Each Divas by BLAQ NFT is programmatically unique across both collections. IP rights for each Divas by BLAQ NFT passes to the owner of that NFT, so you're free to use your Divas by BLAQ NFT for personal and/or commercial use so long as you own it.

In each Divas by BLAQ artwork, every stroke of the brush, every pixel, and every algorithmically-generated masterpiece is an ode to the indomitable spirit of Black women. These are not just artworks; they are tributes to the ultimate queens who have left an indelible mark on the world with their strength, courage, and grace.

Prepare to be inspired, uplifted, and moved by the empowering narratives woven into every stroke of these art pieces. Join us on this journey of celebrating Black women and supporting a worthy cause. Together, we can make a difference and honor the legacy of those who've shaped our world. Welcome to the Divas by BLAQ experience.

Learn more at: https://divasbyblaq.art/

*/

pragma solidity 0.8.19;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./PaymentSplitter.sol"; 
import "./MerkleProof.sol";

contract DIVAS is Ownable, ERC721A, PaymentSplitter {

    uint public maxSupply  = 10000; 
    uint public mintPrice  = 0.05 ether;
    uint public promoPrice = 0.05 ether;
    bool public presaleIsLive = false;
    string public provenanceHash;
    uint public reservedNFTs;
    bool public saleIsLive = false;
    uint public transactionLimit = 10;        // ETH-mint limit
    uint public walletLimit = 100;            
    string private contractURIval;
    string private metadataURI;
    bool private mintLock;
    bool private provenanceLock = false;
    uint id = totalSupply();

    // Merkle tree:
    bytes32 public merkleRoot;
    mapping(address => bool) public allowlistClaimed;

    struct Account {
        uint nftsReserved;
        uint mintedNFTs;
        uint isAdmin;
    }
    mapping(address => Account) public accounts;

    struct AffiliateAccount {
    	uint affiliateFee;
    	uint affiliateUnpaidSales;
    	uint affiliateTotalSales;
    	uint affiliateAmountPaid;
        address affiliateReceiver;
        bool affiliateIsActive;
    }
    mapping(string => AffiliateAccount) public affiliateAccounts;

    event Mint(address indexed sender, uint totalSupply);
    event PermanentURI(string _value, uint256 indexed _id);
    event Burn(address indexed sender, uint indexed _id);

    address[] private _distro;
    uint[] private _distro_shares;

    string[] private affiliateDistro;

    // Merkle tree (add bytes32 _merkleRoot)
    constructor(address[] memory distro, uint[] memory distro_shares, address[] memory teamclaim, bytes32 _merkleRoot)
        ERC721A("DIVAS By Blaq", "DIVAS")
        PaymentSplitter(distro, distro_shares)
    {
        // All images to be stored on Arweave permaweb.
        // Centralized metadata server until mint-out; then changing to Arweave.
        metadataURI = "https://ipfs.io/ipfs/QmVPLq3wPzs1K429DLJy8iJuSdRWoVDiTb4TA8JFi7fNGb/"; 

        accounts[msg.sender] = Account( 0, 0, 0 );

        accounts[teamclaim[0]] = Account(100, 0, 1); //  team
        accounts[teamclaim[1]] = Account( 20, 0, 1); //  J
        accounts[teamclaim[2]] = Account( 25, 0, 1); //  W
        accounts[teamclaim[3]] = Account( 20, 0, 1); //  G
        reservedNFTs = 165;                           

        _distro = distro;
        _distro_shares = distro_shares;

        // Merkle tree:
        merkleRoot = _merkleRoot;

    }

    // (^_^) Modifiers (^_^) 

    modifier minAdmin1() {
        require(accounts[msg.sender].isAdmin > 0 , "Error: Level 1(+) admin clearance required.");
        _;
    }

    modifier minAdmin2() {
        require(accounts[msg.sender].isAdmin > 1, "Error: Level 2(+) admin clearance required.");
        _;
    }

    modifier noReentrant() {
        require(!mintLock, "Error: No re-entrancy.");
        mintLock = true;
        _;
        mintLock = false;
    } 


    // (^_^) Overrides (^_^) 

    // ERC721A: Start token IDs at 1 instead of 0
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }    
    
    // OZ Payment Splitter, make release() restricted to minAdmin2
    function release(address payable account) public override minAdmin2 {
        super.release(account);
    }

    // OZ Payment Splitter, make release() restricted to minAdmin2
    function release(IERC20 token, address account) public override minAdmin2 {
        super.release(token, account);
    }


    // (^_^) Setters (^_^) 

    function adminLevelRaise(address _addr) external onlyOwner { 
        accounts[_addr].isAdmin ++; 
    }

    function adminLevelLower(address _addr) external onlyOwner { 
        accounts[_addr].isAdmin --; 
    }

    function provenanceHashLock() external onlyOwner {
        provenanceLock = true;
    }
    
    function provenanceSet(string memory _provenanceHash) external onlyOwner {
        require(provenanceLock == false);
        provenanceHash = _provenanceHash;
    }  

    function reservesDecrease(uint _decreaseReservedBy, address _addr) external onlyOwner {
        require(reservedNFTs - _decreaseReservedBy >= 0, "Error: This would make reserved less than 0.");
        require(accounts[_addr].nftsReserved - _decreaseReservedBy >= 0, "Error: User does not have this many reserved NFTs.");
        reservedNFTs -= _decreaseReservedBy;
        accounts[_addr].nftsReserved -= _decreaseReservedBy;
    }

    function reservesIncrease(uint _increaseReservedBy, address _addr) external onlyOwner {
        require(reservedNFTs + totalSupply() + _increaseReservedBy <= maxSupply, "Error: This would exceed the max supply.");
        reservedNFTs += _increaseReservedBy;
        accounts[_addr].nftsReserved += _increaseReservedBy;
        if ( accounts[_addr].isAdmin == 0 ) { accounts[_addr].isAdmin ++; }
    }

    function salePresaleActivate() external minAdmin2 {
        presaleIsLive = true;
    }

    function salePresaleDeactivate() external minAdmin2 {
        presaleIsLive = false;
    } 

    function salePublicActivate() external minAdmin2 {
        saleIsLive = true;
    }

    function salePublicDeactivate() external minAdmin2 {
        saleIsLive = false;
    } 

    function setBaseURI(string memory _newURI) external minAdmin2 {
        metadataURI = _newURI;
    }

    function setContractURI(string memory _newURI) external onlyOwner {
        contractURIval = _newURI;
    }

    // We allow max supply to be reset, but it can *never* exceed the original 10k max.
    function setMaxSupply(uint _maxSupply) external onlyOwner {
        require(_maxSupply <= 10000, 'Error: New max supply cannot exceed original max.');        
        maxSupply = _maxSupply;
    }

    function setMintPrice(uint _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    // We are not planning to use this, but need it in case we change our mind.
    function setPromoPrice(uint _newPrice) external onlyOwner {
        promoPrice = _newPrice;
    }

    function setTransactionLimit(uint _newTxLimit) external onlyOwner {
        transactionLimit = _newTxLimit;
    }

    function setWalletLimit(uint _newLimit) external onlyOwner {
        walletLimit = _newLimit;
    }


    // (^_^) Getters (^_^)

    // -- For OpenSea
    function contractURI() public view returns (string memory) {
        return contractURIval;
    }

    // -- For Metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return metadataURI;
    }  


    // (^_^) Main NFT Drop Mgmt. Functions (^_^) 

    function airDropNFT(address[] memory _addr) external minAdmin2 {
        require(totalSupply() + _addr.length <= (maxSupply - reservedNFTs), "Error: You would exceed the airdrop limit.");
        for (uint i = 0; i < _addr.length; i++) {
             _safeMint(_addr[i], 1);
             emit Mint(msg.sender, totalSupply());
        }
    }

    function claimReserved(uint _amount) external minAdmin1 {
        require(_amount > 0, "Error: Need to have reserved supply.");
        require(accounts[msg.sender].nftsReserved >= _amount, "Error: You are trying to claim more NFTs than you have reserved.");
        require(totalSupply() + _amount <= maxSupply, "Error: You would exceed the max supply limit.");
        accounts[msg.sender].nftsReserved -= _amount;
        reservedNFTs -= _amount;
        _safeMint(msg.sender, _amount);
        emit Mint(msg.sender, totalSupply());
    }

    // (^_^) Basic mint function (^_^) 
    // At the request of the devs at our CC payment processor, we are omitting wallet limits here.
    // But, in truth, we don't feel that we *need* a wallet limit on this mint anyway. 
    // We have left limits in place for other minting functions herein.
    function contractMint(uint _amount) external payable noReentrant {
        require(saleIsLive, "Error: Sale is not active. Via contractMint().");
        require(totalSupply() + _amount <= (maxSupply - reservedNFTs), "Error: Purchase would exceed max supply. Via contractMint().");
        require(msg.value >= (mintPrice * _amount), "Error: Not enough ether sent. Via contractMint().");
	    accounts[msg.sender].mintedNFTs += _amount;
        _safeMint(msg.sender, _amount);
        emit Mint(msg.sender, totalSupply());
    }    

    // (^_^) Mint function to accommodate our affiliate program, if used (^_^) 
    function mint(uint _amount, bool isAffiliate, string memory affiliateRef) external payable noReentrant {
        require(saleIsLive, "Error: Sale is not active.");
        require(totalSupply() + _amount <= (maxSupply - reservedNFTs), "Error: Purchase would exceed max supply.");
        require((_amount + accounts[msg.sender].mintedNFTs) <= walletLimit, "Error: You would exceed the wallet limit.");
        require(_amount <= transactionLimit, "Error: You would exceed the transaction limit.");
        if(isAffiliate) {
            require(msg.value >= (promoPrice * _amount), "Error: Not enough ether sent.");
        	bool isActive = affiliateAccounts[affiliateRef].affiliateIsActive;
        	require(isActive, "Error: Affiliate account invalid or disabled.");
       		affiliateAccounts[affiliateRef].affiliateUnpaidSales += _amount;
       		affiliateAccounts[affiliateRef].affiliateTotalSales += _amount;
        } else {
            require(msg.value >= (mintPrice * _amount), "Error: Not enough ether sent.");
        }
	    accounts[msg.sender].mintedNFTs += _amount;
        _safeMint(msg.sender, _amount);
        emit Mint(msg.sender, totalSupply());
    }

    function burn(uint _id) external returns (bool, uint) {
        require(msg.sender == ownerOf(_id) || msg.sender == getApproved(_id) || isApprovedForAll(ownerOf(_id), msg.sender), "Error: You must own this token to burn it.");
        _burn(_id);
        emit Burn(msg.sender, _id);
        return (true, _id);
    }

    // DIVAS drop:  I'm leaving the following function in case needed, but we do not
    // expect to pay out using this function for this drop.

    // Payout Function 1 --> Distribute Shares to Affiliates *and* Payees (DSAP)
    // In addition to including this, we also modified the PaymentSplitter
    // release() function to make it minAdmin2 (to ensure that affiliate funds 
    // will always be paid out prior to defined shares).
    function distributeSharesAffilsAndPayees() external minAdmin2 noReentrant {
        // A. Payout affiliates:
        for (uint i = 0; i < affiliateDistro.length; i++) {
            // The ref name -- eg. jim, etc.
		    string memory affiliateRef = affiliateDistro[i];
            // The wallet addr to be paid for this affiliate:
		    address DSAP_receiver_wallet = affiliateAccounts[affiliateRef].affiliateReceiver;
            // The fee due per sale for this affiliate:
		    uint DSAP_fee = affiliateAccounts[affiliateRef].affiliateFee;
            // The # of mints they are credited with:
		    uint DSAP_mintedNFTs = affiliateAccounts[affiliateRef].affiliateUnpaidSales;
            // Payout calc:
            uint DSAP_payout = DSAP_fee * DSAP_mintedNFTs;
            if ( DSAP_payout == 0 ) { continue; }
            // Require that the contract balance is enough to send out ETH:
		    require(address(this).balance >= DSAP_payout, "Error: Insufficient balance");
            // Send payout to the affiliate:
	       	(bool sent, bytes memory data) = payable(DSAP_receiver_wallet).call{value: DSAP_payout}("");
		    require(sent, "Error: Failed to send ETH to receiver");	
            // Update total amt earned for this person:
		    affiliateAccounts[affiliateRef].affiliateAmountPaid += DSAP_payout;
            // Set their affiliateUnpaidSales back to 0:
		    affiliateAccounts[affiliateRef].affiliateUnpaidSales = 0;
        }
        // B. Then pay defined shareholders:
        for (uint i = 0; i < _distro.length; i++) {
            release(payable(_distro[i]));
        }
    }    

    // DIVAS drop: We will payout using this function.

    // Payout Function 2 --> Standard distribute per OpenZeppelin payment splitter.
    // If we use affilaites, then this is present as a backup distrubute mechanism only.
    // If we do not use affilaites, then we would use this one.
    function distributeSharesPayeesOnly() external onlyOwner {
        for (uint i = 0; i < _distro.length; i++) {
            release(payable(_distro[i]));
        }
    }


    // (^_^) GenNFTs Affiliate Program functions (^_^) 
    // Functionality created by GenerativeNFTs.io to aid in influencer trust and transparency.
    // We are including this here just in case we decide to leverage this type of promotion.
    // As of launch time, we do not expect to use it. But, as they say: "Better to have it and 
    // not need it than to need it and not have it." If you're an influencer interested in 
    // being an affiliate for this or other drops, DM @SwiggaJuice
    // REMINDER: REF codes s/b lowercase alpha-numeric.
    function genNftsAffiliateAdd(address _addr, string memory affiliateRef, uint fee) external onlyOwner { 
        
        // REMINDER: Submit fee in WEI!
        // require(fee > 0, "Error: Fee must be > 0 (and s/b in WEI).");
        // For DIVAS... submit 0 for fee, as we will not be paying out via smart contract, 
        // but we WILL use this to track affilaite sales.

        // ORDER: fee, minted NFTs, ttl minted, ttl amt earned, wallet, active:
        affiliateAccounts[affiliateRef] = AffiliateAccount(fee, 0, 0, 0, _addr, true);
        affiliateDistro.push(affiliateRef);
    }

    function genNftsAffiliateDisable(string memory affiliateRef) external onlyOwner {
       	require(affiliateAccounts[affiliateRef].affiliateFee > 0 , "Error: Affiliate reference likely wrong.");
        affiliateAccounts[affiliateRef].affiliateIsActive = false;
    }

    function genNftsAffiliateEnable(string memory affiliateRef) external onlyOwner { 
       	require(affiliateAccounts[affiliateRef].affiliateFee > 0 , "Error: Affiliate reference likely wrong.");
        affiliateAccounts[affiliateRef].affiliateIsActive = true;
    }

    function genNftsLookupAffilRef(address _addr) public view returns (string memory) { 
        for (uint i = 0; i < affiliateDistro.length; i++) {
   		    string memory affiliateRef = affiliateDistro[i];
            address thisWallet = affiliateAccounts[affiliateRef].affiliateReceiver;
            if ( thisWallet==_addr ) { return affiliateRef; }
        }
    }


    // (^_^) Merkle tree functions (^_^) 

    function allowlistMint(bytes32[] calldata _merkleProof, uint _amount) external payable noReentrant {
        require(presaleIsLive, "Error: Allowlist Sale is not active.");
        require(totalSupply() + _amount <= (maxSupply - reservedNFTs), "Error: Purchase would exceed max supply.");
        require((_amount + accounts[msg.sender].mintedNFTs) <= walletLimit, "Error: You would exceed the wallet limit.");
        require(_amount <= transactionLimit, "Error: You would exceed the transaction limit.");
        require(msg.value >= (mintPrice * _amount), "Error: Not enough ether sent.");
        require(!allowlistClaimed[msg.sender], "Error: You have already claimed all of your NFTs.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Error: You are not allowlisted.");
        if ( ( _amount + accounts[msg.sender].mintedNFTs ) == walletLimit ) {
            allowlistClaimed[msg.sender] = true;
        }
	    accounts[msg.sender].mintedNFTs += _amount;
        _safeMint(msg.sender, _amount);
        emit Mint(msg.sender, totalSupply());
    } 

    function allowlistNewMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    } 

    // (^_^) THE END, FRENs! (^_^)
    // LFG!  Jim@GenerativeNFTs.io  |  @SwiggaJuice  :-)
    // .... - - .--. ... ---... -..-. -..-. .-.. .. -. -.- - .-. .-.-.- . . -..-. .--- .. -- -.. . .

}
