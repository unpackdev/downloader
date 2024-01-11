//        __   __     _____    _____    _____  
//       /\_\ /_/\   /\___/\  /\ __/\ /\_____\ 
//      ( ( (_) ) ) / / _ \ \ ) )__\/( (_____/ 
//       \ \___/ /  \ \(_)/ // / /    \ \__\   
//       / / _ \ \  / / _ \ \\ \ \_   / /__/_  
//      ( (_( )_) )( (_( )_) )) )__/\( (_____\ 
//       \/_/ \_\/  \/_/ \_\/ \/___\/ \/_____/ 
//
//
                                                                                                                                                                                            

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract HACE is ERC721A, Ownable {

    using Strings for uint256;

    mapping (address => uint256) private mintedWL;

    uint256 public maxSupply = 10000;
    uint256 private pricePublic = 0.4 ether;
    uint256 private priceWL = 0.2 ether;    
    uint256 public maxPerTxPublic = 10;
    uint256 public maxPerWL = 5;
    
    bytes32 public merkleRoot = "";
    string private baseURI = "";
    string public provenance = "";
    string public uriNotRevealed = "";
    
    bool public paused = true;
    bool public isRevealed;
    bool private useWhitelist;
    
    event Minted(address caller);

    constructor() ERC721A("HACE", "HACE") {}
    
    function mintPublic(uint256 qty) external payable{
        require(!paused, "Minting is paused");
        require(useWhitelist == false, "Sorry, we are still on whitelist mode!");
        
        uint256 supply = totalSupply();
        require(supply + qty <= maxSupply, "Sorry, not enough left!");
        require(qty <= maxPerTxPublic, "Sorry, too many per transaction");
        require(msg.value >= pricePublic * qty, "Sorry, not enough amount sent!"); 
        
        _safeMint(msg.sender, qty);

        emit Minted(msg.sender);
    }

    function mintGiveaway(address _to, uint256 qty) external onlyOwner{
        uint256 supply = totalSupply();
        require(supply + qty <= maxSupply, "Sorry, not enough left!");
        _safeMint(_to, qty);
    }

    // whitelist mint, allows wallets on the whitelist to mint
    function mintWL(uint256 qty, bytes32[] memory proof) external payable {
        require(!paused, "Minting is paused");
        require(useWhitelist, "Whitelist sale must be active to mint.");
        
        uint256 supply = totalSupply();
        
        // check if the user was whitelisted
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(_verify(leaf, proof), "You are not whitelisted.");
        
        require(msg.value >= priceWL * qty, "Sorry, not enough amount sent!"); 
        require(mintedWL[msg.sender] + qty <= maxPerWL, "Sorry, you have reached the WL limit.");
        require(supply + qty <= maxSupply, "Sorry, not enough left!");
        require(qty <= maxPerWL, "Sorry, too many per transaction");
        
        mintedWL[msg.sender] += qty;
        _safeMint(msg.sender, qty);
        
        emit Minted(msg.sender);
    }
    
    
    function remaining() public view returns(uint256){
        uint256 left = maxSupply - totalSupply();
        return left;
    }

    function usingWhitelist() public view returns(bool) {
        return useWhitelist;
    }

    function getPriceWL() public view returns (uint256){
        return priceWL;
    }

    function getPricePublic() public view returns (uint256){
        return pricePublic;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (isRevealed == false) {
            return uriNotRevealed;
        }
        string memory base = baseURI;
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString(), ".json")) : "";
    }

    // verify merkle tree leaf
    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool){
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    // ADMIN FUNCTIONS
    
    function flipUseWhitelist() public onlyOwner {
        useWhitelist = !useWhitelist;
    }

    function flipPaused() public onlyOwner {
        paused = !paused;
    }

    // close minting forever!
    function closeMinting() public onlyOwner {
        uint256 supply = totalSupply();
        maxSupply = supply;
    }
    
    function flipRevealed(string memory _URI) public onlyOwner {
        baseURI = _URI;
        isRevealed = !isRevealed;
    }

    function setMaxPerWL(uint256 _max) public onlyOwner {
        maxPerWL = _max;
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    function setUriNotRevealed(string memory _URI) public onlyOwner {
        uriNotRevealed = _URI;
    }

    function setPriceWL(uint256 _newPrice) public onlyOwner {
        priceWL = _newPrice;
    }

    function setPricePublic(uint256 _newPrice) public onlyOwner {
        pricePublic = _newPrice;
    }

    function setMaxPerTx(uint256 _newMax) public onlyOwner {
        maxPerTxPublic = _newMax;
    }

    function setProvenanceHash(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    // Set merkle tree root
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
           
        require(payable(0x4309cd37bbDbf7dcc10007185d17E2EdAaC5f031).send(balance));
        
    }


    
    
    receive() external payable {}
    
    
    
}