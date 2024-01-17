// SPDX-License-Identifier: MIT

//   ____  _                 _ _                   ____                      
//  |  _ \| |_   _ _ __ __ _| (_)_______          |  _ \ __ _ _   _ ___  ___ 
//  | |_) | | | | | '__/ _` | | |_  / _ \  _____  | |_) / _` | | | / __|/ _ \
//  |  __/| | |_| | | | (_| | | |/ /  __/ |_____| |  __/ (_| | |_| \__ \  __/
//  |_|   |_|\__,_|_|  \__,_|_|_/___\___|         |_|   \__,_|\__,_|___/\___|
//                                | |__  _   _                               
//                                | '_ \| | | |                              
//                                | |_) | |_| |                              
//      _   _          _          |_.__/ \__, |                  __ _        
//     | |_| |__   ___| |__  _   _ _ __ _|___/____      ___ __  / _| |_      
//     | __| '_ \ / _ \ '_ \| | | | '__| '__/ _ \ \ /\ / / '_ \| |_| __|     
//     | |_| | | |  __/ |_) | |_| | |  | | | (_) \ V  V /| | | |  _| |_      
//      \__|_| |_|\___|_.__/ \__,_|_|  |_|  \___/ \_/\_/ |_| |_|_|  \__|     
// 
// 
// 
//                     %%                               %%                      
//                     %%                               %%                      
//                     %%%    %%%%%%%%     %%%%%%%%    %%%                      
//                     %% (%%  #%%%%   %%%   %%%%   %%  %%                      
//                     %%  %  %%    %%  %  %%    %%  %  %%                      
//                     %%  %  %%    %% %%% %%    %% .%  %%                      
//                     %%   %%   ,   %%   %%  .    %%   %%                      
//                     %%    %%%%%%%%%%   %%%%%%%%%%    %%                      
//                     %%    %%        %%%        %%    %%                      
//                     %%    %%                   %%    %%                      
//                     %%    %%                   %%    %%                      
//                     %%    %%                   %%    %%                      
//                     %%    %%                   %     %%                      
//                      %     %%                 %     %%                       
//                      %%      %%             %%      %%                       
//                       %%        %%%%   %%%%        %.                        
//                         %%                       %%                          
//                           %%                   %%                            
//                             %%%%/         %%%%%                              
//                             %       %%%       %                              
//                         %%%%%%%%           %%%%%%%%                          

//  Collective: The Burrow NFT - https://twitter.com/theburrownft
//  Coder: Orion Solidified, Inc. - https://twitter.com/DevOrionNFTs

//  Minting order provenance determined by using SHA-256 Cryptographic Algorithm to hash images
//  and token description and using MD5 Cryptographic Algorithm  to hash and generate a determine 
//  minting order.

//  Neither the contributing artists at The Burrow nor Orion Soldified, Inc were involved in 
//  determining minting order.

//  Once cryptographic minting order had been determined, data were added to artist and collector 
//  wallet mapping variables and artists were invited to mint tokens to their wallets and transferred 
//  either to the collector or the Burrow wallet.


pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Strings.sol";

contract PluralizePause is Ownable, ERC721, ReentrancyGuard {

    uint256 public totalSupply;
    uint256 public maxSupply;
    string internal baseTokenUri;

    mapping(address => uint256) public ArtistWallets;
    mapping(uint256 => address) public CollectorWallets;

    bool public hasBurrowMinted;
    bool public hasArtistMintingCompleted;

    address public burrowWallet;

    constructor() payable ERC721('Pluralize Pause', 'PLRP') {

        totalSupply = 0;
        maxSupply = 100;

        hasBurrowMinted = false;
        hasArtistMintingCompleted = false;

        burrowWallet = 0x0305B53717E3C36836FB8aD2449De33E75552e8c; 

    }

    modifier callerIsAWallet() {
        require(tx.origin ==msg.sender, "Another contract detected");
        _;
    }

    //Change Wallets - Failsafe
    function changeBurrowWallet(address burrowWallet_) external onlyOwner {
        burrowWallet = burrowWallet_;
    }    

    //Withdrawal pattern
    function withdraw() external onlyOwner {

        uint256 _totalWithdrawal = address(this).balance;
        (bool successBurrow, ) = burrowWallet.call{ value: _totalWithdrawal }('');
        require(successBurrow, 'withdraw to Burrow failed');
    }

   function toggleHasBurrowMinted() external onlyOwner {
        hasBurrowMinted = !hasBurrowMinted;
    }

   function toggleHasArtistMintingCompleted() external onlyOwner {
        hasArtistMintingCompleted = !hasArtistMintingCompleted;
    }

    //Add Addresses for Artist Mint
    function addToArtistWallets(address[] memory addresses, uint256[] memory tokenId_) external onlyOwner {
        require(addresses.length == tokenId_.length, "addresses does not match tokenId length");
        for (uint256 i = 0; i < addresses.length; i++) {
            ArtistWallets[addresses[i]] = tokenId_[i];
        }
    }

    //Add Addresses for Collector Mint
    function addToCollectorWallets(uint256[] memory tokenId_, address[] memory addresses) external onlyOwner {
        require(addresses.length == tokenId_.length, "addresses does not match tokenId length");
        for (uint256 i = 0; i < addresses.length; i++) {
            CollectorWallets[tokenId_[i]] = addresses[i];
        }
    }

    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {

        require(_exists(tokenId_), 'Token does not exist!');
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ".json"));
    }

    string private customContractURI = "https://orion.mypinata.cloud/ipfs/QmZfchpSNFVAAS4PV34VHC377k2o6JuRHXo5XvFgDxhvPu";

    function setContractURI(string memory customContractURI_) external onlyOwner {
        customContractURI = customContractURI_;
    }

    function contractURI() public view returns (string memory) {
        return customContractURI;
    }

    function burrowMint(uint256[] calldata tokenId_) external onlyOwner {
        require(!hasBurrowMinted, "Burrow has already minted");

        uint256 numberToMint = tokenId_.length;

        for(uint256 i = 0; i < numberToMint; i++) {
            
            require(!_exists(tokenId_[i]), 'Token Id Already minted!');

            totalSupply++;
            _safeMint(burrowWallet,tokenId_[i]);
        }

        hasBurrowMinted = !hasBurrowMinted;
    }

    function artistMint() external callerIsAWallet{

        require(hasBurrowMinted, "Burrow Multisig mint phase active!");
        require(!hasArtistMintingCompleted, "Artist Mint has not started!");

        uint256 tokenId_ = ArtistWallets[msg.sender];
        require(tokenId_ > 0, "Your Wallet Not found!");
        
        address collectorWallet = CollectorWallets[tokenId_];
        require(collectorWallet != address(0), "Collector Wallet cannot be empty!");

        totalSupply++;
        ArtistWallets[msg.sender] = 0;
        
        _safeMint(msg.sender, tokenId_);
        safeTransferFrom(msg.sender, collectorWallet, tokenId_);

    }

}