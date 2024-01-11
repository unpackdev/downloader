// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract TeddyBearz is ERC721A, Ownable{
    using Strings for uint256;

    //Supply
    uint256 public constant MAX_SUPPLY = 6250;
    uint256 public constant MAX_FREE_SUPPLY = 775; //275 from dev team + 500 free for community = 775
    uint256 public constant MAX_FREE_MINT = 2;
    uint256 public MAX_PUBLIC_MINT = 10;
    uint256 public PUBLIC_SALE_PRICE = .03 ether;

    string private baseTokenUri;

    bool public publicSale;
    bool public teamMinted;

    mapping(address => uint256) public totalFreeMint;
    mapping(address => uint256) public totalPublicMint;

    constructor() ERC721A("Teddy Bearz", "TBZ") {

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Teddy Bearz - Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        require(publicSale, "Teddy Bearz Public Sale Not Yet Active");

        uint256 newSupply = totalSupply() + _quantity;
        require(newSupply < MAX_SUPPLY, "Teddy Bearz Beyond Max Supply");

        bool freeSale = newSupply <= MAX_FREE_SUPPLY;
        if(freeSale) {
            //require(newSupply < MAX_FREE_SUPPLY + 1, "Teddy Bearz Free Mint is complete");
            require(totalFreeMint[msg.sender] < MAX_FREE_MINT + 1, "You have already minted 2 free Teddy Bearz"); //minted < 3
            require((totalFreeMint[msg.sender] + _quantity) < (MAX_FREE_MINT + 1), "You have selected too many Teddy Bearz to mint for free"); //minted + quantity < 3
            require(_quantity < (MAX_FREE_MINT + 1), "You have selected too many Teddy Bearz to mint for free"); //quantity less < 3

            totalFreeMint[msg.sender] += _quantity;
            _safeMint(msg.sender, _quantity);
        }

        if(!freeSale) {
            require(totalPublicMint[msg.sender] < (MAX_PUBLIC_MINT + 1), "You have already minted 10 Teddy Bearz"); //minted < 10
            require((totalPublicMint[msg.sender] + _quantity) < (MAX_PUBLIC_MINT + 1), "You have selected too many Teddy Bearz to mint"); //minted + quantity < 10
            require(_quantity < (MAX_PUBLIC_MINT + 1), "You have selected too many Teddy Bearz to mint"); //quantity < 10
            require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "Not enough Ethereum for quantity selected"); //not enough eth

            totalPublicMint[msg.sender] += _quantity;
            _safeMint(msg.sender, _quantity);
        }
    }

    function teamMint() external onlyOwner{
        require(!teamMinted, "Teddy Bearz Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 275);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns(uint256[] memory) {
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++){
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setPublicSalePrice(uint256 _publicSalePrice) external onlyOwner {
        PUBLIC_SALE_PRICE = _publicSalePrice;
    }

    function setPublicMaxMint(uint256 _publicMaxMint) external onlyOwner {
        MAX_PUBLIC_MINT = _publicMaxMint;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function withdraw() external onlyOwner {
        //10% to SC dev
        uint256 withdraw10EthDev10 = address(this).balance * 10/100;
        //5% to web dev
        uint256 withdrawWebDev5 = address(this).balance * 5/100;
        //10% to artist
        uint256 withdrawArtist10 = address(this).balance * 10/100;
        //5% to marketing
        uint256 withdrawMarketing5 = address(this).balance * 5/100;
        //70% to creator
        uint256 withdrawOwner70 = (address(this).balance - withdraw10EthDev10 - withdrawWebDev5 - withdrawArtist10 - withdrawMarketing5);
        payable(0x436DBFDA9cE8d5403C05EE7f8fede7d39FDe6888).transfer(withdraw10EthDev10);
        payable(0xB46eCbAC66746B00A926d433EB59fFfdDC315580).transfer(withdrawWebDev5);
        payable(0x7a7bE3347Cc5a836c923827c2876E1b1479c7c1B).transfer(withdrawArtist10);
        payable(0xa6E562B7aC88b33CFc186d2146E826f43eE76BAc).transfer(withdrawMarketing5);
        payable(0x6e2F6105F844c77864E221f47044b227FF089da7).transfer(withdrawOwner70);
        payable(msg.sender).transfer(address(this).balance);
    }
}