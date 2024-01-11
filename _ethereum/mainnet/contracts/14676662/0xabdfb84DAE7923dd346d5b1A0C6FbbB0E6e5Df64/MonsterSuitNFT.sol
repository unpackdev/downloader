// SPDX-License-Identifier: MIT
// Developed by BlockLabz

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
                                                                                                                      
//                           @@@@@@@                                                             @@@@@@@                           
//                          @@@@@@@@@                                                           @@@@@@@@@                          
//                          @@@@@@@@@                                                           @@@@@@@@@                          
//       @@                   @@@@                                                                @@@@@                   @@       
//     @@                                                                                                                   @@     
//   @@                   @@@                      @@@                         @@@                     @@@                    @@   
// @@                   @@....@@                @@.....@@                   @@....@@                @@....@@                   @@ 
//  @@              @@@.........@@@         @@@............@@@         @@@............@@@        @@@.........@@@               @@  
//    @@          @@.................@@  @@....................@@   @@....................@@ @@.................@@@          @@    
//     @@         @@.............................................................................................@@         @@     
//       @@       @@.............................................................................................@@       @@       
//         @@     @@.............................................................................................@@     @@         
//           @@@  @@.............................................................................................@@  @@@           
//          @@@@@@@@.............................................................................................@@@@@@@           
//          @..........................................................................................................@           
//          @@........................................................................................................@@           
//          @@........................................................................................................@@           
//          @@.........@@...................................................................................@@........@@           
//          @@.....@@   @@................................................................................@@   @@.....@@           
//            @@@@@@       @@...........................................................................@@       @@@@@@            
//             @@@           @@.......................................................................@@           @@@      

contract MonsterSuitNFT is ERC721A, Ownable
{
    using Strings for string;

    uint16 public reservedTokensMinted = 0;
    uint16 public PER_ADDRESS_LIMIT = 4;
    uint16 public constant MAX_SUPPLY = 10000;
    uint16 public constant NUMBER_RESERVED_TOKENS = 500;
    uint256 public PRICE = 70000000000000000;
    
    bool public revealed = false;
    bool public saleIsActive = false;
    bool public preSaleIsActive = false;

    string private _baseTokenURI;
    string public notRevealedUri;
    bytes32 rootA;
    bytes32 rootB;
    bytes32 rootC;
    bytes32 rootD;
    mapping(address => uint16) public addressMintedBalance;

    constructor() ERC721A("Monster Suit", "MS") {}

    function saleMint(uint16 amount) external payable
    {
        require(saleIsActive, "Sale is not active");
        require(addressMintedBalance[msg.sender] + amount <= PER_ADDRESS_LIMIT, "Max NFT per address exceeded");
        require(totalSupply() + amount <= MAX_SUPPLY - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for this transaction");
        require(msg.sender == tx.origin, "Transaction from smart contract not allowed");
        
        addressMintedBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function presaleMintA(uint16 amount, bytes32[] memory proof) external payable
    {
        require(preSaleIsActive, "Presale is not active");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, rootA, leaf), "Address not allowed at this time");
        require(addressMintedBalance[msg.sender] + amount <= 1, "Quantity exceeds whitelist allowance");
        require(totalSupply() + amount <= MAX_SUPPLY - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for this transaction");
        require(msg.sender == tx.origin, "Transaction from smart contract not allowed");
        
        addressMintedBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function presaleMintB(uint16 amount, bytes32[] memory proof) external payable
    {
        require(preSaleIsActive, "Presale is not active");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, rootB, leaf), "Address not allowed at this time");
        require(addressMintedBalance[msg.sender] + amount <= 2, "Quantity exceeds whitelist allowance");
        require(totalSupply() + amount <= MAX_SUPPLY - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for this transaction");
        require(msg.sender == tx.origin, "Transaction from smart contract not allowed");
        
        addressMintedBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function presaleMintC(uint16 amount, bytes32[] memory proof) external payable
    {
        require(preSaleIsActive, "Presale is not active");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, rootC, leaf), "Address not allowed at this time");
        require(addressMintedBalance[msg.sender] + amount <= 3, "Quantity exceeds whitelist allowance");
        require(totalSupply() + amount <= MAX_SUPPLY - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for this transaction");
        require(msg.sender == tx.origin, "Transaction from smart contract not allowed");
        
        addressMintedBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function presaleMintD(uint16 amount, bytes32[] memory proof) external payable
    {
        require(preSaleIsActive, "Presale is not active");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, rootD, leaf), "Address not allowed at this time");
        require(addressMintedBalance[msg.sender] + amount <= 4, "Quantity exceeds whitelist allowance");
        require(totalSupply() + amount <= MAX_SUPPLY - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for this transaction");
        require(msg.sender == tx.origin, "Transaction from smart contract not allowed");
        
        addressMintedBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function mintReservedTokens(address to, uint16 amount) external onlyOwner 
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        reservedTokensMinted += amount;

        _safeMint(to, amount); 
    }

    function setPrice(uint256 newPrice) external onlyOwner 
    {
        PRICE = newPrice;
    }

    function setPerAddressLimit(uint16 newLimit) external onlyOwner 
    {
        PER_ADDRESS_LIMIT = newLimit;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function flipSaleState() external onlyOwner
    {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() external onlyOwner
    {
        preSaleIsActive = !preSaleIsActive;
    }
    
    function setRootA(bytes32 _root) external onlyOwner
    {
        rootA = _root;
    }
    
    function setRootB(bytes32 _root) external onlyOwner
    {
        rootB = _root;
    }
    
    function setRootC(bytes32 _root) external onlyOwner
    {
        rootC = _root;
    }

    function setRootD(bytes32 _root) external onlyOwner
    {
        rootD = _root;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
  
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(revealed == false) 
        {
            return notRevealedUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }

    function withdraw() external onlyOwner
    {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%***********************%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*******%%%%%%%%%%%%%*******%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%****%%%%%****%%%%%%%****%%%%%****%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%****%%%%%%%%%****%%%****%%%%%%%%%****%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%*****%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%*******%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%****%%%%%****%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%****01000010%****%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%****01101100%011011****%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%*****11%01100011%01101011****%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%***********************%%%%%%%%%%%%%%%%%%%%%%%%%***********************%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%*****01001100%01100001%011****%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%****00010%01111010%****%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%****%%%%%%%%%****%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%****%%%%%****%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%*******%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%*****%%%%%%%%%%%%%%%****%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%****%%%%%%%%%****%%%****%%%%%%%%%****%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%****%%%%%****%%%%%%%****%%%%%****%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*******%%%%%%%%%%%%%*******%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%***********************%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%