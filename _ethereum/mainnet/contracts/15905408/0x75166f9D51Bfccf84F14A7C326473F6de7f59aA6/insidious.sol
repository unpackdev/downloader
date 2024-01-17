//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

error InsidiousPepez_MaxPerWalletExceeded();
error InsidiousPepez_NotEnoughEther();
error InsidiousPepez_MintExceeded();
error InsidiousPepez_TransferFailed();
error InsidiousPepez_WhitelistMintIsNotOpen();
error InsidiousPepez_PublicMintIsNotOpen();
error InsidiousPepez_whitelistMintOver();


contract Insidious is ERC721A,Ownable {
    uint256 public constant WHITELIST_PRICE = 0.012 ether;
    uint256 public constant PUBlIC_MINT_PRICE = 0.015 ether;
    uint256 public constant TOTAL_SUPPLY = 999;
    uint256 public constant MAX_PER_WALLET = 2;
    
    uint256 private time;
    uint128 private whitelistStatus;
    uint128 private publicMintStatus;
    bytes32 public immutable root;

    
    constructor(bytes32 _root) ERC721A("Insidious Pepez", "INSIDIOUS PEPEZ ") {
        root = _root;
    }

    function openWhitelist() external onlyOwner {
       whitelistStatus = 1;
       time = block.timestamp;
    }


    function openPublicMint() external onlyOwner {
        publicMintStatus = 1;
    }

     modifier Checks(uint256 _quantity) {
      address user = msg.sender;

        ///if the balance of msg.sender is greater than 2 it should revert.
        if(balanceOf(user) > MAX_PER_WALLET) {
            revert InsidiousPepez_MaxPerWalletExceeded();
        }

        ///if the total NFT minted is greater than 999, it should revert.
        if(_quantity + _totalMinted() > TOTAL_SUPPLY) {
            revert InsidiousPepez_MintExceeded();
        }
    
         ///if the quantity inputed is greater than 2;
         if(_quantity > MAX_PER_WALLET) {
             revert InsidiousPepez_MintExceeded();
         }

       
        _;
    }

    function whitelistMint(uint256 quantity, bytes32[] memory proof) external Checks(quantity) payable {
         if(whitelistStatus !=1 ) {
             revert InsidiousPepez_WhitelistMintIsNotOpen();
         }
         require(isValid(proof ,keccak256(abi.encodePacked(msg.sender))), "Not Whitelisted");
         ///if ether sent is less than 0.015 ;
          if (msg.value < quantity * WHITELIST_PRICE) {
            revert InsidiousPepez_NotEnoughEther();
        }

        if(block.timestamp > time + 1800 seconds ) {
            revert InsidiousPepez_whitelistMintOver();
        }
        
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);
    }

       function publicMint(uint256 quantity) external Checks(quantity) payable {
         if( publicMintStatus !=1 ) {
             revert InsidiousPepez_PublicMintIsNotOpen();
         }

            ///if ether sent is less than 0.015 ;
        if (msg.value < quantity * PUBlIC_MINT_PRICE) {
            revert InsidiousPepez_NotEnoughEther();
        }
        _mint(msg.sender,quantity);
    }
    
    function withdrawETH() external payable onlyOwner {
        uint256 amount = address(this).balance;
       (bool success, ) = msg.sender.call{value : amount}("");
        if(!success) {
         revert InsidiousPepez_TransferFailed();}
     }

     function specialMint(uint256 quantity, bytes32[] memory proof) external onlyOwner {
          require(isValid(proof ,keccak256(abi.encodePacked(msg.sender))), "Not Whitelisted");
         _mint(msg.sender,quantity);
     }

     
     function isValid(bytes32[] memory proof, bytes32 leaf) internal view returns (bool) {
        return MerkleProof.verify(proof,root,leaf);
    }

    function _baseURI() internal pure override returns (string memory )  {
        return "https://ipfs.io/ipfs/bafybeif4rf5gjswdzwgk6z6dsw43b6nvx2svg4hvarl4gueuxekzbits2a/";

    }
        

} 
