/* 
.                                                                        
.    ███████████     ███████    ███████████     ███████                       
.   ░░███░░░░░███  ███░░░░░███ ░░███░░░░░███  ███░░░░░███                     
.    ░███    ░███ ███     ░░███ ░███    ░███ ███     ░░███                    
.    ░██████████ ░███      ░███ ░██████████ ░███      ░███                    
.    ░███░░░░░███░███      ░███ ░███░░░░░███░███      ░███                    
.    ░███    ░███░░███     ███  ░███    ░███░░███     ███                     
.    ███████████  ░░░███████░   ███████████  ░░░███████░                      
.   ░░░░░░░░░░░     ░░░░░░░    ░░░░░░░░░░░     ░░░░░░░                        
.                                                                                                                                                                                                                        
.      █████████     ███████    ██████   ██████ █████   █████████   █████████ 
.     ███░░░░░███  ███░░░░░███ ░░██████ ██████ ░░███   ███░░░░░███ ███░░░░░███
.    ███     ░░░  ███     ░░███ ░███░█████░███  ░███  ███     ░░░ ░███    ░░░ 
.   ░███         ░███      ░███ ░███░░███ ░███  ░███ ░███         ░░█████████ 
.   ░███         ░███      ░███ ░███ ░░░  ░███  ░███ ░███          ░░░░░░░░███
.   ░░███     ███░░███     ███  ░███      ░███  ░███ ░░███     ███ ███    ░███
.    ░░█████████  ░░░███████░   █████     █████ █████ ░░█████████ ░░█████████ 
.     ░░░░░░░░░     ░░░░░░░    ░░░░░     ░░░░░ ░░░░░   ░░░░░░░░░   ░░░░░░░░░  
.                                                                                                                                                                                                                 

   by Serkan Altuniğne
                                                                                  
*/

// SPDX-License-Identifier: MIT
// dev @MetonymyMachine
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

contract Bobos is ERC721, Ownable {
    using Counters for Counters.Counter;   
    Counters.Counter private _tokenIdCounter;
    bytes32 public root;
    uint256 _price = 0.05 ether;
    uint256 _presaleprice = 0.03 ether;
    uint256 tokenSupply = 6665;
    uint256 presaleSupply = 1999;
    uint256 public _perWalletLimit = 50;
    uint256 public _perWalletPresaleLimit = 3;
    string public _baseTokenURI;
    bool public saleIsActive = false;
    bool public PresaleIsActive = false;
    bool public presaleBackupActive = false;
    address a1 = 0xa9d3B122ba5D5a533C0837e986658F5635123A56;
    mapping(address => uint256) public addressMintedBalance;

    constructor() ERC721("Bobos", "BBs") {
        setBaseURI("https://nftscreen.art/bobos_unrevealed/");
        root = 0xc852b3fd1b593e8ea8e44318f41c1a15bffa2fa67c392b607017e2dd22d4bc49;
    }

    function mintPresale(uint256 mintCount, bytes32[] memory proof) external payable {
        require(PresaleIsActive, "Bobo Presale not active");
        require(msg.value >= _presaleprice * mintCount, "Amount of Ether sent too small");
        require(mintCount < 4, "Bobo quantity must be 3 or less");
        require((_tokenIdCounter.current() + mintCount) <= presaleSupply, "Presale supply exceeded - all the presale Bobos have been minted!");
        require(_verify(_leaf(msg.sender), proof), "Invalid merkle proof - please mint only on our website and make sure you are on the whitelist.");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + mintCount <= _perWalletPresaleLimit, "Minting of up to 3 Bobos per whitelisted wallet allowed!");

        mint(msg.sender,mintCount);
    }

    function mintPublic(uint256 mintCount) external payable {
        require(saleIsActive, "sale not active");
        require(msg.value >= _price * mintCount, "Amount of Ether sent too small");
        require(mintCount < 10, "Bobo quantity must be less than or equal to 9");
        require((_tokenIdCounter.current() + mintCount) <= tokenSupply, "Sold out! No more Bobos are available");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + mintCount <= _perWalletLimit, "Minting of up to 50 Bobos per wallet allowed!");

        mint(msg.sender,mintCount);
    }

    function mintBackup(uint256 mintCount) external payable {
        require(presaleBackupActive, "Bobo Presale not active");
        require(msg.value >= _presaleprice * mintCount, "Amount of Ether sent too small");
        require(mintCount < 4, "Bobo quantity must be less than or equal to 3");
        require((_tokenIdCounter.current() + mintCount) <= presaleSupply, "Presale supply exceeded - all the presale Bobos have been minted!");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + mintCount <= _perWalletPresaleLimit, "Minting of up to 3 Bobos per whitelisted wallet allowed!");

        mint(msg.sender,mintCount);
    }   

    function mint(address addr, uint256 mintCount) private {
        require((_tokenIdCounter.current() + mintCount) <= tokenSupply, "No Bobos available");
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

    function setPerWallet(uint256 limit) external onlyOwner {
        _perWalletLimit = limit;
    }

    function setPerWalletPresale(uint256 limit) external onlyOwner {
        _perWalletPresaleLimit = limit;
    }

     function setPresaleSupply(uint256 supply) external onlyOwner {
        presaleSupply = supply;
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

       function togglePresaleBackup() public onlyOwner {
        presaleBackupActive = !presaleBackupActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }


    function getTokenSupply() external view returns (uint256) {
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
        require((_tokenIdCounter.current() + mintCount) <= tokenSupply, "Sold out! No more Bobos are available");
        mint(addr,mintCount);
    }

}