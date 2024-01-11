//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Strings.sol";

contract APOTSOrigins is ERC721, Ownable, ReentrancyGuard {
    uint256 public immutable collectionSize;
    uint256 public totalSupply;
    uint32 public saleKey;
    uint64 public price = 0.01 ether;
    mapping(address => uint256) mintCount;

    constructor(uint256 collectionSize_)
        ERC721("A Piece of the Story Origins", "APOTSO")
    {
        collectionSize = collectionSize_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }


    function pickASentance(uint256 id) external payable callerIsUser {
        uint256 curPrice = uint256(price);
        require(saleKey == 1, "Mint is not active");
        require(id < collectionSize, "Not a valid ID: too high");
        require(msg.value == curPrice, "Not correct eth sent.");
        require(mintCount[msg.sender] < 10, "You have minted too many.");
        
        _safeMint(msg.sender, id);
        mintCount[msg.sender] += 1;
        totalSupply += 1;
    }

    function endMint() external onlyOwner {
        saleKey = 0;
    }

    function startMint() external onlyOwner {
        saleKey = 1;
    }

    function setPrice(uint64 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    // // METADATA FUNCTIONS

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function getTotalMinted() public view virtual returns (uint256) {
        return totalSupply;
    }

    // FUNCTIONS NOT FOR CONTRACT CALLS

    function mintedIds() public view virtual returns (uint256[] memory) {
        uint256[] memory array = new uint256[](uint256(collectionSize));
        for (uint256 i = 0; i < array.length; i++) {
            if (_exists(i)) {
                array[i] = 1;
            }
        }
        return array;
    }
}
