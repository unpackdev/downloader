/* 


:::::::::: :::     ::: :::::::::: :::::::::  :::   ::: ::::    ::: :::::::::: :::::::::::     
:+:        :+:     :+: :+:        :+:    :+: :+:   :+: :+:+:   :+: :+:            :+:         
+:+        +:+     +:+ +:+        +:+    +:+  +:+ +:+  :+:+:+  +:+ +:+            +:+         
+#++:++#   +#+     +:+ +#++:++#   +#++:++#:    +#++:   +#+ +:+ +#+ :#::+::#       +#+         
+#+         +#+   +#+  +#+        +#+    +#+    +#+    +#+  +#+#+# +#+            +#+         
#+#          #+#+#+#   #+#        #+#    #+#    #+#    #+#   #+#+# #+#            #+#         
##########     ###     ########## ###    ###    ###    ###    #### ###            ###    

::::    ::::  ::::::::::: ::::    ::: ::::::::::: :::::::::     :::      ::::::::   ::::::::  
+:+:+: :+:+:+     :+:     :+:+:   :+:     :+:     :+:    :+:  :+: :+:   :+:    :+: :+:    :+: 
+:+ +:+:+ +:+     +:+     :+:+:+  +:+     +:+     +:+    +:+ +:+   +:+  +:+        +:+        
+#+  +:+  +#+     +#+     +#+ +:+ +#+     +#+     +#++:++#+ +#++:++#++: +#++:++#++ +#++:++#++ 
+#+       +#+     +#+     +#+  +#+#+#     +#+     +#+       +#+     +#+        +#+        +#+ 
#+#       #+#     #+#     #+#   #+#+#     #+#     #+#       #+#     #+# #+#    #+# #+#    #+# 
###       ### ########### ###    ####     ###     ###       ###     ###  ########   ########  

                                                                                  
*/

// SPDX-License-Identifier: MIT
// dev @MetonymyMachine
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

contract Mintpass_EveryNFT is ERC721, Ownable {
    using Counters for Counters.Counter;   
    Counters.Counter private _tokenIdCounter;
    uint256 _price = 0.1 ether;
    uint256 _presaleprice = 0.065 ether;
    uint256 tokenSupply = 1000;
    uint256 public _perWalletLimit = 5;
    uint256 public _perWalletPresaleLimit = 3;
    string public _baseTokenURI;
    bool public saleIsActive = false;
    bool public PresaleIsActive = false;
    address a1 = 0x5a106B86c1D9C18AeE3c1576178E45D943874E47;
    address a2 = 0x2B105347d8f7F198b57D40f1e24eef54530826a5;
    mapping(address => uint256) public addressMintedBalance;
    bytes32 public root;

    constructor() ERC721("Mintpass EveryNFT", "MNTP") {
        setBaseURI("https://mintpass.herokuapp.com/id/");
        root = 0x0;
       mint(a2,20);
    
    }

    function mintPresale(uint256 mintCount, bytes32[] memory proof) external payable {
        require(PresaleIsActive, "Mintpass Presale not active");
        require(msg.value >= _presaleprice * mintCount, "Amount of Ether sent too small");
        require(mintCount < 3, "Mintpass quantity must be 2 or less");
        require((_tokenIdCounter.current() + mintCount) <= tokenSupply, "Sold out! No more Mintpasses are available");
        require(_verify(_leaf(msg.sender), proof), "Invalid merkle proof - please mint only on our website and make sure you are on the whitelist.");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + mintCount <= _perWalletPresaleLimit, "Minting of up to 2 Mintpasses per whitelisted wallet allowed!");

        mint(msg.sender,mintCount);
    }

    function mintPublic(uint256 mintCount) external payable {
        require(saleIsActive, "sale not active");
        require(msg.value >= _price * mintCount, "Amount of Ether sent too small");
        require(mintCount < 6, "Mintpass quantity must be less than or equal to 5");
        require((_tokenIdCounter.current() + mintCount) <= tokenSupply, "Sold out! No more Mintpasses are available");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + mintCount <= _perWalletLimit, "Minting of up to 5 mintpasses per wallet allowed!");

        mint(msg.sender,mintCount);
    }

    function mint(address addr, uint256 mintCount) private {
        require((_tokenIdCounter.current() + mintCount) <= tokenSupply, "Sold out! No more mintpasses are available");
        for(uint i = 0;i<mintCount;i++)
        {
            _safeMint(addr, _tokenIdCounter.current());
            _tokenIdCounter.increment();
            addressMintedBalance[msg.sender]++;
        }
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
    
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }


    function getPrice() external view returns (uint256) {
        return _price;
    }

    function setPrice(uint256 price) external onlyOwner {
        _price = price;
    }

    function getPresalePrice() external view returns (uint256) {
        return _presaleprice;
    }

    function setPresalePrice(uint256 presaleprice) external onlyOwner {
        _presaleprice = presaleprice;
    }

    function setPerWallet(uint256 limit) external onlyOwner {
        _perWalletLimit = limit;
    }

    function setPerWalletPresale(uint256 limit) external onlyOwner {
        _perWalletPresaleLimit = limit;
    }

    function setRoot(bytes32 merkleroot) external onlyOwner {
        root = merkleroot;
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

    function setTotalSupply(uint256 supply) external onlyOwner {
        tokenSupply = supply;
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
        require((_tokenIdCounter.current() + mintCount) <= tokenSupply, "Sold out! No more mintpasses are available");
        mint(addr,mintCount);
    }

}