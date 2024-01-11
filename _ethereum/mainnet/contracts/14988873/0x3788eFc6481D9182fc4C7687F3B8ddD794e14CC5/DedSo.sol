// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

//
//   _ .-') _     ('-.  _ .-') _       .-')                
//  ( (  OO) )  _(  OO)( (  OO) )     ( OO ).              
//   \     .'_ (,------.\     .'_    (_)---\_) .-'),-----. 
//   ,`'--..._) |  .---',`'--..._)   /    _ | ( OO'  .-.  '
//   |  |  \  ' |  |    |  |  \  '   \  :` `. /   |  | |  |
//   |  |   ' |(|  '--. |  |   ' |    '..`''.)\_) |  |\|  |
//   |  |   / : |  .--' |  |   / :   .-._)   \  \ |  | |  |
//   |  '--'  / |  `---.|  '--'  /.-.\       /   `'  '-'  '
//   `-------'  `------'`-------' `-' `-----'      `-----' 
//

// @truedrewco

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC1155.sol";
import "./MerkleProof.sol";

contract DedSo is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;

    string private _baseTokenURI;

    uint256 public constant MAX_SUPPLY = 2750;
    uint256 public constant MAX_PER_MINT = 8;
    
    uint256 public MINT_PRICE = 0.08 ether;

    bool public saleIsActive;
    bytes32 public merkleRoot;
    mapping(uint256 => bool) public freeMintClaims; // claimed free mints

    address r1 = 0x4bad2A4F5CF74ccd92C7a22CFc58604DEb63E39F; // ded.so

    constructor() ERC721("MysteryOfTheDeds", "DED") {
        _nextTokenId.increment();   // Start Token Ids at 1
        saleIsActive = false;       // Set sale to inactive
    }

    // normal mint
    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active yet.");
        require(numberOfTokens > 0, "Quantity must be greater than 0.");
        require(numberOfTokens <= MAX_PER_MINT, "Exceeds max per mint.");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Exceeds max supply.");
        require(msg.value >= numberOfTokens * currentPrice(), "Requires more eth.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, _nextTokenId.current());
            _nextTokenId.increment();
        }
    }

    // check for phase 1 token
    function tokenBalance(uint256 tokenID) public view returns (uint256) {
        return IERC1155(0x495f947276749Ce646f68AC8c248420045cb7b5e).balanceOf(msg.sender,tokenID); // mainnet deds phase 1
    }

    // phase 1 holder free mint
    function freeMint(uint256 tokenID, bytes32[] calldata proof) public payable {
        require(saleIsActive, "Sale is not active yet.");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Exceeds max supply.");

        require(!freeMintClaims[tokenID],"Free mint already claimed.");
        require(tokenBalance(tokenID) > 0, "Token not in wallet.");

        bytes32 tokenIDHash = keccak256(abi.encodePacked(tokenID));
        bytes32 leaf = keccak256(abi.encodePacked(tokenIDHash)); // double hashed because of the whole set up to verify OS contract collection
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Not a valid token ID.");

        _safeMint(msg.sender, _nextTokenId.current());
        _nextTokenId.increment();

        // mark as claimed
        freeMintClaims[tokenID] = true;
    }

    // airdrop mint
    function airdropMint(uint256 numberOfTokens, address recipient) external onlyOwner payable {
        require(saleIsActive, "Sale is not active yet.");
        require(numberOfTokens > 0, "Quantity must be greater than 0.");
        require(numberOfTokens <= MAX_PER_MINT, "Exceeds max per mint.");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Exceeds max supply.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(recipient, _nextTokenId.current());
            _nextTokenId.increment();
        }
    }

    // check if free mint has been claimed
    function freeMintClaimed(uint256 tokenID) public view returns (bool) {
        return freeMintClaims[tokenID];
    }

    // set merkle root
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // set current price
    function setCurrentPrice(uint256 _price) external onlyOwner {
        MINT_PRICE = _price;
    }

    // return current price
    function currentPrice() public view returns (uint256) {
        return MINT_PRICE;
    }

    // return how many tokens have been minted
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    // override the baseURI function
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // set or update the baseURI
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // toggle sale on or off
    function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // withdraw ETH balance
    function withdrawBalance() public onlyOwner {
        payable(r1).transfer(address(this).balance);   // Transfer remaining balance to Ded.so
    }

}