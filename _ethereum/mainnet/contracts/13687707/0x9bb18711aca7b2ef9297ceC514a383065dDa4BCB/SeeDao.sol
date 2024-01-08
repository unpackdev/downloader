// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";


contract SeeDao is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    
    IERC721 public v3Token;
    IERC20 public rally;
    IERC20 public bank;
    IERC20 public fwb;
    IERC20 public ff;

    string public baseTokenURI;


    uint256 public singlePrice;
    uint256 public limit = 150;
    uint256 public bankBalance = 2000000000000000000000;
    uint256 public rallyBalance = 400000000000000000000;
    uint256 public fwbBalance = 2000000000000000000;
    uint256 public ffBalance = 50000000000000000000;
    bool public onSale;

    mapping (uint256 => bool) public claimed;
    mapping (address => bool) public daoClaimed;
    mapping (uint256 => bytes32) public roots;
    mapping (uint256 => mapping(address => bool)) public minted;


    constructor(address token, address rallyAddr, address bankAddr, address fwbAddr, address ffAddr) ERC721("SeeDao", "SEED") {
        v3Token = IERC721(token);
        rally = IERC20(rallyAddr);
        bank = IERC20(bankAddr);
        fwb = IERC20(fwbAddr);
        ff = IERC20(ffAddr);
    }

    /** mint */
    function _mintSeed(uint256 num, address to) internal {
        for(uint256 i = 0; i < num; i++) {
            uint256 tokenIndex = totalSupply();
            _safeMint(to, tokenIndex);
        }
    }
    
    // mint for sale
    function mint(uint256 num) external payable {
        require(onSale, "not on sale");
        uint256 totalPrice = num.mul(singlePrice);
        require(msg.value >= totalPrice, "wrong ether value");
        _mintSeed(num, msg.sender);
    }

    // claim for OG
    function claim(uint256 tokenId) public {
        require(v3Token.ownerOf(tokenId) == msg.sender, "not owner");
        require(!claimed[tokenId], "already claimed");
        _mintSeed(1, msg.sender);
        claimed[tokenId] = true;
    }

    // claim for hodl
    function claimDAO() public {
        require(
            rally.balanceOf(msg.sender) >= rallyBalance || 
            bank.balanceOf(msg.sender) >= bankBalance ||
            fwb.balanceOf(msg.sender) >= fwbBalance ||
            ff.balanceOf(msg.sender) >= ffBalance,
            "low balance"
        );
        require(!daoClaimed[msg.sender], "already claimed");
        require(limit > 0, "out of supply");
        _mintSeed(1, msg.sender);
        limit = limit.sub(1);
        daoClaimed[msg.sender] = true;
    }

    // mint for whitelist
    function mintWhiteList(uint256 id, bytes32[] calldata proof) external {
        require(!minted[id][msg.sender], "already minted");
        require(
            MerkleProof.verify(
                proof, roots[id], keccak256(abi.encodePacked(msg.sender))
            ), 
            "invalid proof");
        _mintSeed(1, msg.sender);
        minted[id][msg.sender] = true;
    }

    function verifyWhiteList(uint256 id, address user, bytes32[] calldata proof) external view returns (bool) {
        return MerkleProof.verify(proof, roots[id], keccak256(abi.encodePacked(user)));
    }

    function giveAway(address to, uint256 num) public onlyOwner {
        _mintSeed(num, to);
    }

    function setPrice(uint256 price) public onlyOwner {
        singlePrice = price;
    }

    function setRoot(uint256 id, bytes32 root) public onlyOwner {
        roots[id] = root;
    }

    function pauseSale() public onlyOwner {
        require(onSale, "already paused");
        onSale = false;
    }

    function unpauseSale() public onlyOwner {
        require(!onSale, "already unpaused");
        onSale = true;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    receive() external payable {}
    
    function withdraw() public onlyOwner {
        uint256 val = address(this).balance;
        payable(owner()).transfer(val);
    }
}
