// SPDX-License-Identifier: MIT
// Creator: https://twitter.com/xisk1699

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract PeruvianDogClub is Ownable, ERC721A, ReentrancyGuard {

    uint16 public immutable MAX_TEAM_SUPPLY = 150;
    uint16 public teamCounter = 0;
    uint public immutable NON_HOLDER_REFERRER_ROYALTY = 1;
    uint public immutable HOLDER_REFERRER_ROYALTY = 10;

    address private immutable CEO_ADDRESS = 0xb2b65e2BF4Ed6988C377Fe601065E20d136eD31f;
    string public baseTokenURI;

    uint8 public saleStage; // 0: PAUSED | 1: SALE | 2: SOLDOUT

    mapping (uint => address) public referrerMapping;

    constructor() ERC721A('Peruvian Dog Club', 'PERUVIAN', 20, 3333) {
        saleStage = 0;
    }

    // UPDATE SALESTAGE

    function setSaleStage(uint8 _saleStage) external onlyOwner {
        require(saleStage != 2, "Cannot update if already reached soldout stage.");
        saleStage = _saleStage;
    }

    // PUBLIC MINT 

    function publicMint(uint _quantity, address referrer) external payable nonReentrant {
        require(saleStage == 1, "Sale is not active.");
        require(_quantity <= maxBatchSize, "Max mint at onece exceeded.");
        require(balanceOf(msg.sender) + _quantity <= 20, "Would reach max NFT per holder.");
        require(msg.value >= 0.015 ether * _quantity, "Not enough ETH.");
        require(totalSupply() + _quantity + (MAX_TEAM_SUPPLY-teamCounter) <= collectionSize, "Mint would exceed max supply.");
        require(msg.sender != referrer, "You cannot refer yourself.");

        if (referrer != address(0)) {
            _sendReferrerRoyalty(referrer);
        }

        _safeMint(msg.sender, _quantity);

        if (totalSupply() + (MAX_TEAM_SUPPLY-teamCounter) == collectionSize) {
            saleStage = 2;
        }
    }

    // REFERRER LOGIC

    function _sendReferrerRoyalty(address referrer) private {
        referrerMapping[totalSupply()] = referrer;
        if (balanceOf(referrer) > 0) {
            payable(referrer).transfer(msg.value*HOLDER_REFERRER_ROYALTY/100);
        } else {
            payable(referrer).transfer(msg.value*NON_HOLDER_REFERRER_ROYALTY/100);
        }
    }

    function getTokenReferrer(uint tokenId) external view returns (address referrerAddress) {       
        int loopLimit = int(tokenId)-int(maxBatchSize);
        address tokenHolder = ownerOf(tokenId);
        for (int i=int(tokenId); i>loopLimit; i--) {
            if (tokenHolder != ownerOf(uint(i))) {
                return referrerMapping[uint(i)+1];
            }
            if (i==0 || (loopLimit>=0&&i==loopLimit+1) || referrerMapping[uint(i)] != address(0)) {
                return referrerMapping[uint(i)];
            }
        }
    }

    // TEAM MINT

    function teamMint(address _to, uint16 _quantity) external onlyOwner {
        require(teamCounter + _quantity <= MAX_TEAM_SUPPLY, "Would exceed max team supply.");
        _safeMint(_to, _quantity);
        teamCounter += _quantity;
    }
    
    // METADATA URI

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenUri(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexisting token");
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, Strings.toString(tokenId), ".json")) : "https://gateway.pinata.cloud/ipfs/QmSTYnc1oUn5zrygL7mhASJNZujo4m4y1erm6987Bn89oA";
    }

    // WITHDRAW

    function withdraw() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        payable(CEO_ADDRESS).transfer(ethBalance);
    }
}