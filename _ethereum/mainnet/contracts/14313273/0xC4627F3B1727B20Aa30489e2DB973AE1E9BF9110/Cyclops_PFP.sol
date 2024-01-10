/* 
////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
//                                                                                                //
//            ::::::::  :::   :::  ::::::::  :::        ::::::::  :::::::::   ::::::::            //
//           :+:    :+: :+:   :+: :+:    :+: :+:       :+:    :+: :+:    :+: :+:    :+:           //
//           +:+         +:+ +:+  +:+        +:+       +:+    +:+ +:+    +:+ +:+                  //
//           +#+          +#++:   +#+        +#+       +#+    +:+ +#++:++#+  +#++:++#++           //
//           +#+           +#+    +#+        +#+       +#+    +#+ +#+               +#+           //  
//           #+#    #+#    #+#    #+#    #+# #+#       #+#    #+# #+#        #+#    #+#           //
//            ########     ###     ########  ########## ########  ###         ########            //
//                                                                                                //
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////
*/

// SPDX-License-Identifier: MIT
// dev @MetonymyMachine
pragma solidity ^0.8.12;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

abstract contract MNTPS {
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract Cyclops is ERC721, Ownable {
    using Counters for Counters.Counter;   
    Counters.Counter private _tokenIdCounter;
    uint256 _price = 0.077 ether;
    uint256 _allowlistprice = 0.066 ether;
    uint256 _mintpassprice = 0.055 ether;
    uint256 tokenSupply = 6666;
    uint256 public _perWalletLimit = 50;
    string public _baseTokenURI;
    MNTPS private mntps;
    bool public saleIsActive = false;
    bool public PresaleIsActive = false;
    address private a1 = 0xeDBAa0d77f3ead0da77396cE485B6b8b219aAf0a;
    address public _signingAddress = 0x1048Ded3a542e064C82161Ab8840152393E0477E;
    
    mapping(address => uint256) public addressMintedBalance;

    constructor(address dependentContractAddress) ERC721("Cyclops", "Cycs") {
        setBaseURI("https://cyclops-metadata.herokuapp.com/id/");
        
        mntps = MNTPS(dependentContractAddress);
    }
    function allowlistMint(uint256 mintCount,uint8 v, bytes32 r,bytes32 s,uint256 mint_allowed,uint256 free) external payable {
        require(PresaleIsActive, "Cyclops Presale not active");
        require(msg.value >= _allowlistprice * mintCount, "Amount of Ether sent too small");

        require(verifySignature(v,r,s,mint_allowed,free), "Invalid signature - please mint only on our website and make sure you are on the allowlist.");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + mintCount <= mint_allowed, "Individual minting limit for Cyclops on allowlist exceeded!");

        mint(msg.sender,mintCount);
    }

    function mintpassMint(uint256 mintCount) external payable {
        require(PresaleIsActive, "Cyclops Presale not active");
        require(msg.value >= _mintpassprice * mintCount, "Amount of Ether sent too small");
        
        uint256 balance = mntps.balanceOf(msg.sender);
        require(balance > 0, "Must hold at least one Mintpass to mint your Cyclops with this function");

        require(mintCount <= 10, "Cyclops quantity must be 10 or less");

        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + mintCount <= _perWalletLimit, "Maximum amount of Cyclops mints for this wallet exceeded!");

        mint(msg.sender,mintCount);
    }
    
    function cyclopsMint(uint256 mintCount,uint8 v, bytes32 r,bytes32 s,uint256 mint_allowed,uint256 free) external payable {
        require(PresaleIsActive, "Cyclops Presale not active");

        require(verifySignature(v,r,s,mint_allowed,free), "Invalid signature - please mint only on our website and make sure you are on the whitelist.");
        require(free == 1, "You are not allowed to claim a free Cyclop");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + mintCount <= mint_allowed, "This exceeds your allowed free Cyclops");

        mint(msg.sender,mintCount);

    }
    function publicMint(uint256 mintCount) external payable {
        require(saleIsActive, "sale not active");
        require(msg.value >= _price * mintCount, "Amount of Ether sent too small");
        require(mintCount <= 5, "Cyclops quantity must be 5 or less");

        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + mintCount <= _perWalletLimit, "Maximum amount of Cyclops mints for this wallet exceeded!");
 
        mint(msg.sender,mintCount);
    }

    function mint(address addr, uint256 mintCount) private {
        require((_tokenIdCounter.current() + mintCount) <= tokenSupply, "Sold out! No more Cyclops are available");
        for(uint i = 0;i<mintCount;i++)
        {
            _safeMint(addr, _tokenIdCounter.current());
            _tokenIdCounter.increment();
            addressMintedBalance[msg.sender]++;
        }
    }

     /**
    * toEthSignedMessageHash
    * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
    * and hash the result
    */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }


 //verify if the hash created with the signature is by signer or not
  function verifySignature(uint8 v, bytes32 r,bytes32 s,uint256 amountAllowed,uint256 free) public view returns (bool) {
    bytes32 messageHashed = keccak256(abi.encodePacked( msg.sender, amountAllowed,free));
    bytes32 hash = toEthSignedMessageHash(messageHashed);
    address signer = ecrecover(hash, v, r, s);
    require(signer != address(0), "invalid signature");
    if(signer == _signingAddress){
        return true;
    }else{
        return false;
    }
}

// price
    function getPrice() external view returns (uint256) {
        return _price;
    }
    function setPrice(uint256 price) external onlyOwner {
        _price = price;
    }
// Allowlist price
    function getAllowlistPrice() external view returns (uint256) {
        return _allowlistprice;
    }

    function setAllowlistPrice(uint256 price) external onlyOwner {
        _allowlistprice = price;
    }
// Mintpass price
    function getMintPassPrice() external view returns (uint256) {
        return _mintpassprice;
    }

    function setMintPassPrice(uint256 price) external onlyOwner {
        _mintpassprice = price;
    }

// Signing address
    function setSigningAddress (address addr) external onlyOwner {
        _signingAddress = addr;
    }

    function setPerWallet(uint256 limit) external onlyOwner {
        _perWalletLimit = limit;
    }


     function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

     function togglePresale() public onlyOwner {
        PresaleIsActive = !PresaleIsActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }


    function totalSupply() external view returns (uint256) {
        return tokenSupply;
    }

    function getCurrentId() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function getBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function withdraw() external onlyOwner {
        payable(a1).transfer(address(this).balance);
    }

    function mintOwner(address addr, uint256 mintCount) external onlyOwner {
        mint(addr,mintCount);
    }

}
