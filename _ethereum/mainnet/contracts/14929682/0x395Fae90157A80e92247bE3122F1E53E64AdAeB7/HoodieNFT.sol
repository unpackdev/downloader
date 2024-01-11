// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";

contract HoodbenderzNFT is ERC721, Ownable, ReentrancyGuard {

    uint256 public ID = 1;

    uint256 public freeMintCounter = 0;
    uint256 public mintCounter = 0;

    uint256 public constant FREE_MINT_SUPPLY = 4500;
    uint256 public constant MINT_SUPPLY = 1055;

    uint256 public constant MAX_NFT_MINT_PER_WALLET = 10;
    uint256 public constant MAX_NFT_PER_FREE_MINT_TX = 2;
    uint256 public constant MAX_NFT_PER_MINT_TX = 5;

    uint256 public mintPrice;

    bool public mintable = false;

    mapping(address => bool) public freeMintMap;
    mapping(address => uint256) public mintMap;

    constructor(
        uint256 _mintPrice
    )ERC721("Hoodbenderz", "Hoodbenderz") {
        mintPrice = _mintPrice;
    }

    function setMintable(bool _mintable) external onlyOwner {
        mintable = _mintable;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    function transferETH() external onlyOwner nonReentrant {
        payable(msg.sender).transfer(address(this).balance);
    }

    function isFreeMint() public view returns (bool) {
        return freeMintCounter < FREE_MINT_SUPPLY;
    }

    function freeMint(uint256 amount) external nonReentrant notContract {
        
        require(mintable, "not mintable");
        require(isFreeMint(), "free mint ended");
        require(!freeMintMap[msg.sender], "already free minted");
        require(amount > 0, "Invalid nft amount");
        require(amount <= MAX_NFT_PER_FREE_MINT_TX, "max per txn for free mint amount exceeded");
        require(freeMintCounter + amount <= FREE_MINT_SUPPLY, "max free mint amount exceeded");

        freeMintMap[msg.sender] = true;
        freeMintCounter += amount;

        for(uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, ID);
        }

        ID += amount;

    }

    function mint(uint256 amount) payable external nonReentrant notContract {

        require(mintable, "not mintable");
        require(!isFreeMint(), "Please free mint");
        require(amount > 0, "Invalid nft amount");
        require(mintMap[msg.sender] + amount <= MAX_NFT_MINT_PER_WALLET, "max nft per wallet mint exceeded");
        require(amount <=  MAX_NFT_PER_MINT_TX, "max per txn for mint amount exceeded" );
        require(msg.value == mintPrice * amount, "invalid eth amount to mint");

        require(mintCounter + amount <= MINT_SUPPLY, "max mint amount exceeded");

        mintMap[msg.sender] += amount;
        mintCounter += amount;

        for(uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, ID);
        }

        ID += amount;

    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://nftstorage.link/ipfs/bafybeig5lwxzju2zn224tegg4a4gxukh22l6vmne2km6mmctfcu3aum7te/";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokenId > 0, "invalid token ID");
        require(tokenId < ID, "nft not mint yet");
        string memory uri = _baseURI();
        return string(abi.encodePacked(uri, Strings.toString(tokenId), ".json"));
    }

}
