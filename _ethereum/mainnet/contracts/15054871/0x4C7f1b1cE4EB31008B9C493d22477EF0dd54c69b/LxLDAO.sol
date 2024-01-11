
/*
          _____           _______                   _____                    _____                                                                                                            _____            _____                    _____                    _____          
         /\    \         /::\    \                 /\    \                  /\    \                                                 ______                                                   /\    \          /\    \                  /\    \                  /\    \         
        /::\____\       /::::\    \               /::\____\                /::\    \                                               |::|   |                                                 /::\____\        /::\    \                /::\    \                /::\    \        
       /:::/    /      /::::::\    \             /:::/    /               /::::\    \                                              |::|   |                                                /:::/    /        \:::\    \              /::::\    \              /::::\    \       
      /:::/    /      /::::::::\    \           /:::/    /               /::::::\    \                                             |::|   |                                               /:::/    /          \:::\    \            /::::::\    \            /::::::\    \      
     /:::/    /      /:::/~~\:::\    \         /:::/    /               /:::/\:::\    \                                            |::|   |                                              /:::/    /            \:::\    \          /:::/\:::\    \          /:::/\:::\    \     
    /:::/    /      /:::/    \:::\    \       /:::/____/               /:::/__\:::\    \                                           |::|   |                                             /:::/    /              \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \    
   /:::/    /      /:::/    / \:::\    \      |::|    |               /::::\   \:::\    \                                          |::|   |                                            /:::/    /               /::::\    \      /::::\   \:::\    \      /::::\   \:::\    \   
  /:::/    /      /:::/____/   \:::\____\     |::|    |     _____    /::::::\   \:::\    \                                         |::|   |                                           /:::/    /       ____    /::::::\    \    /::::::\   \:::\    \    /::::::\   \:::\    \  
 /:::/    /      |:::|    |     |:::|    |    |::|    |    /\    \  /:::/\:::\   \:::\    \                                  ______|::|___|___ ____                                  /:::/    /       /\   \  /:::/\:::\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\    \ 
/:::/____/       |:::|____|     |:::|    |    |::|    |   /::\____\/:::/__\:::\   \:::\____\                                |:::::::::::::::::|    |                                /:::/____/       /::\   \/:::/  \:::\____\/:::/  \:::\   \:::\____\/:::/__\:::\   \:::\____\
\:::\    \        \:::\    \   /:::/    /     |::|    |  /:::/    /\:::\   \:::\   \::/    /                                |:::::::::::::::::|____|                                \:::\    \       \:::\  /:::/    \::/    /\::/    \:::\   \::/    /\:::\   \:::\   \::/    /
 \:::\    \        \:::\    \ /:::/    /      |::|    | /:::/    /  \:::\   \:::\   \/____/                                  ~~~~~~|::|~~~|~~~                                       \:::\    \       \:::\/:::/    / \/____/  \/____/ \:::\   \/____/  \:::\   \:::\   \/____/ 
  \:::\    \        \:::\    /:::/    /       |::|____|/:::/    /    \:::\   \:::\    \                                            |::|   |                                           \:::\    \       \::::::/    /                    \:::\    \       \:::\   \:::\    \     
   \:::\    \        \:::\__/:::/    /        |:::::::::::/    /      \:::\   \:::\____\                                           |::|   |                                            \:::\    \       \::::/____/                      \:::\____\       \:::\   \:::\____\    
    \:::\    \        \::::::::/    /         \::::::::::/____/        \:::\   \::/    /                                           |::|   |                                             \:::\    \       \:::\    \                       \::/    /        \:::\   \::/    /    
     \:::\    \        \::::::/    /           ~~~~~~~~~~               \:::\   \/____/                                            |::|   |                                              \:::\    \       \:::\    \                       \/____/          \:::\   \/____/     
      \:::\    \        \::::/    /                                      \:::\    \                                                |::|   |                                               \:::\    \       \:::\    \                                        \:::\    \         
       \:::\____\        \::/____/                                        \:::\____\                                               |::|   |                                                \:::\____\       \:::\____\                                        \:::\____\        
        \::/    /         ~~                                               \::/    /                                               |::|___|                                                 \::/    /        \::/    /                                         \::/    /        
         \/____/                                                            \/____/                                                 ~~                                                       \/____/          \/____/                                           \/____/         
                                                                                                                                                                                                                                                                                
*/
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract LxLDAO is Ownable, ERC721A {
    using Strings for uint256;

    address TREASURY_ADD;

    // token amount for different generations
    uint256[] public gLimits = [1, 7, 77, 777, 7777];
    uint256[] public gSupplys = [1, 8, 85, 862, 8639];

    // attributes for different generations
    mapping (uint256 => string)  private baseURIForG;
    mapping (uint256 => uint256) public mintPriceForG;
    mapping (uint256 => bytes32) public merkleRootForG;
    mapping (uint256 => bool)    public isRevealForG;
    mapping (uint256 => string)  private tokenURIOf;
    mapping (uint256 => uint256) public currentSupplyForG;
    mapping (address => bool)    public wlIsMintedByUser;

    modifier callerIsUser() {
        if (tx.origin != msg.sender) {
            revert CallIsAnContract(tx.origin, msg.sender);
        }
        _;
    }

    modifier notZeroAddress(address addr) {
        if (addr == address(0)) {
            revert NotZeroAddress(addr);
        }
        _;
    }

    constructor(string memory uri, address g0Owner) ERC721A("LxLDAO", "LxLD", 8639) notZeroAddress(g0Owner) {
        tokenURIOf[0] = uri;
        TREASURY_ADD = msg.sender;

        _safeMint(g0Owner, 1);
        currentSupplyForG[0] = 1;
    } 

    /*------------------------------- views -------------------------------*/

    function _baseURI(uint256 g) internal view returns (string memory) {
        return baseURIForG[g];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256 g = tokenGeneration(tokenId);
        string memory baseURI = _baseURI(g);

        return
        bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : tokenURIOf[tokenId];
    }

    function tokenGeneration(uint256 tokenId)
        public
        view
        returns (uint256 g) 
    {
        if (tokenId < gLimits[0]) {
            g = 0;
        } else if (tokenId < gLimits[1]) {
            g = 1;
        } else if (tokenId < gLimits[2]) {
            g = 2;
        } else if (tokenId < gLimits[3]) {
            g = 3;
        } else if (tokenId < gLimits[4]) {
            g = 4;
        } else {
            revert InvalidTokenId();
        }
    }

    /*------------------------------- writes -------------------------------*/

    function publicMint(uint256 generation, uint8 quantity)
        public
        payable
        callerIsUser
    {
        uint256 generationPrice = mintPriceForG[generation];

        if (generationPrice == 0) {
            revert PublicSaleNotStart();
        }
        
        //Max supply
        if (currentSupplyForG[generation] + quantity > gLimits[generation]) {
            revert OverGenerationSupply(generation);
        }

        //Require enough ETH
        if (msg.value < quantity * generationPrice) {
            revert NotEnoughEth(msg.value, quantity * generationPrice);
        }

        //Mint the quantity
        _safeMint(msg.sender, quantity);
        currentSupplyForG[generation] += quantity;

        emit PublicMint(generation, quantity);
    }

    function mintWL(uint256 generation, address user, bytes32[] calldata merkleProof) 
        public 
        callerIsUser 
        notZeroAddress(user)
    {
        if (wlIsMintedByUser[user]) {
            revert WlMintOverOnce(user);
        }

        if (currentSupplyForG[generation] + 1 > gLimits[generation]) {
            revert OverGenerationSupply(generation);
        }
        
        bytes32 leaf = keccak256(abi.encodePacked(user, generation));
        bool valid = MerkleProof.verify(merkleProof, merkleRootForG[generation], leaf);
        if (!valid) {
            revert MerkleProofFail();
        }

        _safeMint(user, 1);

        wlIsMintedByUser[user] = true;
        currentSupplyForG[generation] += 1;

        emit MintWL(generation, user);
    }

    //send remaining NFTs to treasury
    function setRoot(uint256 generation, bytes32 root) external onlyOwner {
        merkleRootForG[generation] = root;

        emit SetMerkleRoot(generation, root);
    }

    function setBaseURI(uint256 generation, string memory baseURI) public onlyOwner {
        baseURIForG[generation] = baseURI;
        isRevealForG[generation] = true;

        emit SetBaseURI(generation, baseURI);
    }

    function updatePrice(uint256 generation, uint256 price) external onlyOwner {
        mintPriceForG[generation] = price;

        emit UpdatePrice(generation, price);
    }

    function withdrawFunds() external onlyOwner {
        uint256 finalFunds = address(this).balance;
        payable(TREASURY_ADD).transfer(finalFunds);

        emit WithdrawFunds(finalFunds);
    }

    function setTreasury(address newTreasury) external onlyOwner {
        TREASURY_ADD = newTreasury;

        emit SetTreasury(newTreasury);
    }

    /*------------------------------- errors -------------------------------*/
    error PublicSaleNotStart();
    error InvalidTokenId();
    error NotEnoughEth(uint256 deposit, uint256 fee);
    error WlMintOverOnce(address user);
    error MerkleProofFail();
    error OverGenerationSupply(uint256 generation);
    error NotZeroAddress(address addr);
    error CallIsAnContract(address origin, address caller);

    /*------------------------------- events -------------------------------*/
    
    event PublicMint(uint256 generation, uint256 quantity);
    event MintWL(uint256 generation, address user);
    event SetMerkleRoot(uint256 generation, bytes32 root);
    event SetBaseURI(uint256 generation, string baseURI);
    event UpdatePrice(uint256 generation, uint256 price);
    event WithdrawFunds(uint256 finalFunds);
    event SetTreasury(address newTreasury);
}
