// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Burnable.sol";

/**
 * @title Baby Mice contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

interface IMice {
    function ownerOf(uint256 tokenId) external view  returns (address);
}

contract BabyMice is ERC721Burnable {
    using SafeMath for uint256;

    IMice public mice = IMice(0x20Ab7749AF10579160232E40eBb079d30Ff01581);

    uint256 public maxToMint;
    uint256 public mintPrice;
    uint256 public MAX_BABYMICE_SUPPLY;
    uint256 public currentMintCount;

    uint256 public totalClaimed;
    mapping (uint256 => bool) public babyClaimed;


    address private wallet = 0xCf203C89B09367FD47eD83fF3315f057523b7E63;
    bool public saleIsActive;

    constructor() ERC721("Baby Mice", "BMICE") {
        MAX_BABYMICE_SUPPLY = 5000;
        maxToMint = 25;
        mintPrice = 55000000000000000; // 0.055 ETH
        saleIsActive = false;
    }

    /**
     * Get the array of token for owner.
     */
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /**
     * Check if certain token id is exists.
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
    * Claim Baby Mice by OG Mice holders
    */
    function claimBaby(uint256[] memory ogMiceList) external {
        require(ogMiceList.length <= maxToMint, "Mint amount is bigger than max limit.");
        require(currentMintCount.add(ogMiceList.length) <= MAX_BABYMICE_SUPPLY, "This would exceed max supply");

        for(uint256 i = 0; i < ogMiceList.length; i++) {
            require(msg.sender == mice.ownerOf(ogMiceList[i]), "Invalid mice id.");
            require(!babyClaimed[ogMiceList[i]], "The baby already minted.");
            _safeMint(msg.sender, currentMintCount + i);
            babyClaimed[ogMiceList[i]] = true;
        }

        currentMintCount = currentMintCount.add(ogMiceList.length);
        totalClaimed = totalClaimed.add(ogMiceList.length);
    }

    /**
    * Reserve Baby Mice by Owner
    */
    function reserveBabyMiceByOwner(address _to, uint256 _count) external onlyOwner {
        require(_count <= maxToMint, "Mint count is bigger than maxToMint.");
        require(_to != address(0), "Invalid address to reserve.");
        require(currentMintCount.add(_count) <= MAX_BABYMICE_SUPPLY, "Reserve would exceed max supply");
        
        for (uint256 i = 0; i < _count; i++) {
            _safeMint(_to, currentMintCount + i);
        }

        currentMintCount = currentMintCount.add(_count);
    }

    /**
    * Mints Baby Mice
    */
    function mintBabyMice(uint256 _count) external payable {
        require(saleIsActive, "Sale must be active to mint");
        require(_count <= maxToMint, "Invalid amount to mint per one tx");
        require(currentMintCount.add(_count) <= MAX_BABYMICE_SUPPLY, "Purchase would exceed max supply");
        require(mintPrice.mul(_count) <= msg.value, "Ether value sent is not correct");
        
        for(uint256 i = 0; i < _count; i++) {
            _safeMint(msg.sender, currentMintCount + i);
        }

        currentMintCount = currentMintCount.add(_count);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    /**
     * Set maximum count to mint per once.
     */
    function setMaxToMint(uint256 _maxValue) external onlyOwner {
        maxToMint = _maxValue;
    }

    /**
     * Set price to mint a Mice.
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /*
    * Pause sale if active, make active if paused
    */
    function setSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdraw() external onlyOwner {
        payable(wallet).transfer(address(this).balance);
    }
}