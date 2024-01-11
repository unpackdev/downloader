//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";

contract Reveal is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    string public baseURI;
    bytes32 public root;
    uint256 public constant totalTokenCount = 12;
    uint256 public constant dropSupply = 3;
    uint256 public supply = 3;
    uint256 public mintPrice;
    uint256 public drop;
    uint256 public immutable intialSupply;
    bool public saleIsActive;

    mapping(uint256 => uint256) public redeemTime;
    mapping(address=>bool) public claimed;
    mapping(uint256 => address) public redeemed;

    constructor() ERC721("Reveal", "RVL") {
        baseURI = "https://mainnet-sample-assets.s3.eu-west-2.amazonaws.com/reveal/";
        redeemTime[0] = 1673172139; // Sunday, 8 January 2023 15:32:19 GMT+05:30
        intialSupply = supply;
        for (uint256 i; i < supply; ++i) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, tokenId);
        }
    }

    function setSaleState(bool newState) external onlyOwner {
        saleIsActive = newState;
    }

    function updateSupply(uint256 _redeemTime, uint256 _price) external onlyOwner {
        require(supply + dropSupply <= totalTokenCount, "Total Supply Reached");
        drop += 1;
        redeemTime[drop] = _redeemTime;
        supply += dropSupply;
        mintPrice = _price;
    }

    function updateRedeemTime(uint256 _drop, uint256 _redeemTime) external onlyOwner {
        redeemTime[_drop] = _redeemTime;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function updateBaseURI(string calldata _URI) external onlyOwner {
        baseURI = _URI;
    } 

    function updateMerkleRoot(bytes32 _root) external onlyOwner {
        root = _root;
    } 

    function mintPreSale(bytes32[] calldata proof)
    external payable nonReentrant
    {
        require(saleIsActive, "Sale is inactive");
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        require(msg.value == mintPrice, "Purchase: Incorrect payment");
        require(tokenId <= supply, "Total supply reached");
        require(claimed[msg.sender] == false, "already claimed");
        claimed[msg.sender] = true;
        require(_verify(_leaf(msg.sender), proof), "Invalid merkle proof");
        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success, "Transfer failed");
        _safeMint(msg.sender, tokenId);
    }


    function adminMint() external onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= supply, "Total supply reached");
        _safeMint(msg.sender, tokenId);
    }

    function redeem(uint256 tokenId) external {
        require(ownerOf(tokenId) == _msgSender(), "Not the current owner of token");
        require(redeemed[tokenId] == address(0), "Token redeemed");
        if(tokenId<=intialSupply){
            require(block.timestamp<=redeemTime[0], "Redeem time finished");
            redeemed[tokenId] = msg.sender;
        }
        else{
            require(block.timestamp<=redeemTime[uint256((tokenId-(intialSupply + 1))/dropSupply) + 1], "Redeem time finished");
            redeemed[tokenId] = msg.sender;
        }
    }


    function getIdsOwnedUnRedeemed(address user) public view returns(uint256[] memory) {    
    uint256 numTokens = balanceOf(user);
    uint256[] memory uriList = new uint256[](numTokens);
    for (uint256 i; i < numTokens; i++) {
        uint256 tok  = tokenOfOwnerByIndex(user, i);
        if(redeemed[tok]==address(0)){
            uriList[i] = tok;
        }else{
            uriList[i] = 0;
        }
    }
    return(uriList);
    }

    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

   function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
