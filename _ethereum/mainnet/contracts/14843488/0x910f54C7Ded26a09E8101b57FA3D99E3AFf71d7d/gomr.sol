//
//
//     ______     ______     ______      ______     __  __     ______   ______   ______        __    __     __  __        ______     ______     ______     __    __    
//     /\  ___\   /\  ___\   /\__  _\    /\  __ \   /\ \/\ \   /\__  _\ /\__  _\ /\  __ \      /\ "-./  \   /\ \_\ \      /\  == \   /\  __ \   /\  __ \   /\ "-./  \   
//     \ \ \__ \  \ \  __\   \/_/\ \/    \ \ \/\ \  \ \ \_\ \  \/_/\ \/ \/_/\ \/ \ \  __ \     \ \ \-./\ \  \ \____ \     \ \  __<   \ \ \/\ \  \ \ \/\ \  \ \ \-./\ \  
//     \ \_____\  \ \_____\    \ \_\     \ \_____\  \ \_____\    \ \_\    \ \_\  \ \_\ \_\     \ \_\ \ \_\  \/\_____\     \ \_\ \_\  \ \_____\  \ \_____\  \ \_\ \ \_\ 
//     \/_____/   \/_____/     \/_/      \/_____/   \/_____/     \/_/     \/_/   \/_/\/_/      \/_/  \/_/   \/_____/      \/_/ /_/   \/_____/   \/_____/   \/_/  \/_/                                                                                                                                                                  
//
//
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721AQueryable.sol";

contract GOMR is ERC721AQueryable, Ownable {

    using Strings for uint256;

    mapping (address => uint256) private mintedWL;
    mapping (address => uint256) private mintedPresale;

    bytes32 public merkleRootPresale = "";
    bytes32 public merkleRootWL = "";

    uint256 public maxSupply = 4444;
    
    uint256 private pricePresale = 0.15 ether;    
    uint256 private priceWL = 0.2 ether;    
    uint256 private pricePublic = 0.25 ether;

    // presale, max per wallet: 4, wl: 3, public: 10
    uint256 public maxPerTx = 10;
    uint256 public maxPerWalletPresale = 4;
    uint256 public maxPerWalletWL = 3;
    
    string private baseURI = "";
    string public provenance = "";
    string public uriNotRevealed = "";
    
    uint256 public saleStatus = 0; // 0 - presale, 1 - whitelist, 2 - public
    bool public paused = true;
    bool public isRevealed;

    event Minted(address caller);

    constructor() ERC721A("Get Outta My Room!", "GOMR") {}
    
    function mintPublic(uint256 qty) external payable{
        require(!paused, "Minting is paused");
        require(saleStatus == 2, 'Public minting not enabled');
        uint256 supply = totalSupply();
        require(supply + qty <= maxSupply, "Sorry, not enough left!");
        require(qty <= maxPerTx, "Sorry, too many per transaction");
        require(msg.value >= pricePublic * qty, "Sorry, not enough amount sent!"); 
        
        _safeMint(msg.sender, qty);

        emit Minted(msg.sender);
    }

    // Presale or whitelist mint
    function mintPresaleOrWL(uint256 qty, bytes32[] memory proof) external payable {
        require(saleStatus < 2, 'We are already on public sale');
        require(!paused, "Minting is paused");
        
        uint256 supply = totalSupply();
        uint256 price = priceWL;

        if(saleStatus == 0){
            // Presale
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(_verify(leaf, proof, false), "Sorry, you are not listed for presale");
            require(mintedPresale[msg.sender] < maxPerWalletPresale, "Sorry, you already own the max allowed for the presale");
            price = pricePresale;
        }else{
            // Whitelist
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(_verify(leaf, proof, true), "Sorry, you are not whitelisted");
            require(mintedWL[msg.sender] < maxPerWalletWL, "Sorry, you already own the max allowed for the whitelist");
        }
        
        require(supply + qty <= maxSupply, "Sorry, not enough left!");
        require(qty <= maxPerTx, "Sorry, too many per transaction");
        require(msg.value >= price * qty, "Sorry, not enough amount sent!"); 

        if(saleStatus == 0){
            mintedPresale[msg.sender] += qty;
        }else{
            mintedWL[msg.sender] += qty;
        }

        _safeMint(msg.sender, qty);

        emit Minted(msg.sender);
    }
    
    // getters
    function remaining() public view returns(uint256){
        uint256 left = maxSupply - totalSupply();
        return left;
    }

    // price
    function getPricePresale() public view returns (uint256){
        return pricePresale;
    }

    function getPriceWL() public view returns (uint256){
        return priceWL;
    }

    function getPricePublic() public view returns (uint256){
        return pricePublic;
    }
    
    // uri
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (isRevealed == false) {
            return uriNotRevealed;
        }
        string memory base = baseURI;
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString(), ".json")) : "";
    }

    // verify merkle tree leaf
    function _verify(bytes32 leaf, bytes32[] memory proof, bool wl)
    internal view returns (bool){
        if(wl){
            return MerkleProof.verify(proof, merkleRootWL, leaf);
        } else {
            return MerkleProof.verify(proof, merkleRootPresale, leaf);
        }
    }

    // ADMIN AREA
    
    // switches
    function updateSaleStatus(uint256 _status) public onlyOwner{
        // changes sale status: 0 -> presale, 1 -> whitelist, 2 -> public
        saleStatus = _status;
    }

    function flipPaused() public onlyOwner {
        paused = !paused;
    }

    function flipRevealed(string memory _URI) public onlyOwner {
        baseURI = _URI;
        isRevealed = !isRevealed;
    }

    // set maxes
    function setMaxPerWalletPresale(uint256 _max) public onlyOwner {
        maxPerWalletPresale = _max;
    }

    function setMaxPerWalletWL(uint256 _max) public onlyOwner {
        maxPerWalletWL = _max;
    }

    function setMaxPerTx(uint256 _newMax) public onlyOwner {
        maxPerTx = _newMax;
    }

    // set uris
    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    function setUriNotRevealed(string memory _URI) public onlyOwner {
        uriNotRevealed = _URI;
    }

    function setProvenanceHash(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    // set prices
    function setPricePresale(uint256 _newPrice) public onlyOwner {
        pricePresale = _newPrice;
    }

    function setPriceWL(uint256 _newPrice) public onlyOwner {
        priceWL = _newPrice;
    }

    function setPricePublic(uint256 _newPrice) public onlyOwner {
        pricePublic = _newPrice;
    }

    // Set merkle trees root
    function setMerkleRootPresale(bytes32 _merkleRoot) public onlyOwner {
        merkleRootPresale = _merkleRoot;
    }

    function setMerkleRootWL(bytes32 _merkleRoot) public onlyOwner {
        merkleRootWL = _merkleRoot;
    }

    // Admin functions
    function closeMinting() public onlyOwner {
        uint256 supply = totalSupply();
        maxSupply = supply;
    }

    function mintGiveaway(address _to, uint256 qty) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + qty <= maxSupply, "Sorry, not enough left!");
        _safeMint(_to, qty);
    }

    function withdraw() onlyOwner public {
        require(payable(0x4eA96bFB265A47C4485a8A164917a4e8487De928).send(address(this).balance));
    }
    
    receive() external payable {}
    
    
    
}