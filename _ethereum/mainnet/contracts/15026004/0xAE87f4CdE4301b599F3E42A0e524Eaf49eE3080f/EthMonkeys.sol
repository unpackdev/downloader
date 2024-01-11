// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "./ERC721F.sol";
import "./Strings.sol";

 /**
 * @title EthMonkeys contract
 * @dev Extends ERC721F Non-Fungible Token Standard basic implementation.
 * Optimized to no longer use ERC721Enumarable , but still provide a totalSupply() implementation.
 * @author @simonbuidl.eth
 * 
 */

contract EthMonkeys is ERC721F {
    using Strings for uint256;
    
    uint256 public tokenPrice = 0.005 ether; 
    uint256 public constant MAX_TOKENS= 5005;
    
    uint public constant MAX_PURCHASE = 6; // set 1 to high to avoid some gas
    uint public constant MAX_RESERVE = 26; // set 1 to high to avoid some gas
    
    bool public saleIsActive;
    bool public preSaleIsActive;

    bytes32 public merkleRoot;

    address private constant DEV = 0x11145Fc22221d317784BD5Fdc5dd429354aa0D9C;

    mapping(address => bool) public isClaimed;
    mapping(address => uint256) private amount;
    
    event priceChange(address _by, uint256 price);
    
    constructor() ERC721F("EthMonkeys", "ETHM") {
        setBaseTokenURI("ipfs://QmemTBcuuKguEhrv9d15uzTRvBn8vrkeQX1qcyVQafXVVi/"); 
        _safeMint(DEV, 0);
    }

    /**
     * Mint Tokens to a wallet.
     */
    function adminMint(address to,uint numberOfTokens) public onlyOwner {    
        uint supply = totalSupply();
        require(supply + numberOfTokens <= MAX_TOKENS, "Reserve would exceed max supply of Tokens");
        require(numberOfTokens < MAX_RESERVE, "Can only mint 25 tokens at a time");
        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(to, supply + i);
        }
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
        if(saleIsActive){
            preSaleIsActive=false;
        }
    }
    /**
     * Pause sale if active, make active if paused
     */
    function flipPreSaleState() external onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }
 
     function updateMerkleRoot(bytes32 newRoot) public onlyOwner {
        merkleRoot = newRoot;
    }

      function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    /**
     * Mint your tokens here.
     */
    function preSaleMint(uint256 freeTokens, uint256 numberOfTokens, bytes32[] memory merkleProof) external payable{
            require(preSaleIsActive, "Presale is not active");

            //Check whitelist
            bytes32 node = keccak256(abi.encodePacked(freeTokens, msg.sender));
            require(verify(merkleProof, merkleRoot, node), 'Sender is not on the whitelist');

            require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

            require(numberOfTokens + freeTokens < MAX_PURCHASE, "Can only mint 5 tokens at a time");

            uint256 supply = totalSupply();
       

            if (!isClaimed[msg.sender]) {
                require(numberOfTokens + freeTokens > 0, "Total number of mints cannot be 0");
                require(supply + numberOfTokens + freeTokens <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
                require(amount[msg.sender]+numberOfTokens + freeTokens<MAX_PURCHASE);
                amount[msg.sender] += numberOfTokens + freeTokens;
                for(uint256 i; i < (numberOfTokens + freeTokens); i++){
                    _safeMint( msg.sender, supply + i );
                }
                isClaimed[msg.sender] = true;
            } else {
                require(numberOfTokens > 0, "Total number of mints cannot be 0");
                require(supply + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
                require(amount[msg.sender]+numberOfTokens <MAX_PURCHASE);
                amount[msg.sender] += numberOfTokens;
                for(uint256 i; i < (numberOfTokens); i++){
                    _safeMint( msg.sender, supply + i );
                }
            }
            
    }
        function mint(uint256 numberOfTokens) external payable{
            require(saleIsActive,"Sale NOT active yet");
            require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

            require(numberOfTokens > 0, "Total number of mints cannot be 0");
            require(numberOfTokens < MAX_PURCHASE, "Can only mint 5 tokens at a time");

            uint256 supply = totalSupply();
            require(supply + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");

            require(amount[msg.sender] + numberOfTokens < MAX_PURCHASE);
            amount[msg.sender] += numberOfTokens;
            for(uint256 i; i < (numberOfTokens); i++){
                _safeMint( msg.sender, supply + i );
            }
        
    }
    
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(DEV,(balance * 10) / 100);
        _withdraw(0x5409CfdF149d8BA163a58B25901C050d4DF8A122, (balance * 45) / 100);
        _withdraw(0x0b1B7DaAAD3912DDC1534f88ABE04679C51679c0, (balance * 45) / 100);
    }
}