// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Burnable.sol";

/**
 * @title MiceHouse contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */


contract Mice is ERC721Burnable {
    using SafeMath for uint256;

    uint256 public mintPrice;
    uint256 public maxMintAmount;
    uint256 public MAX_MICE_SUPPLY;
    uint256 public currentMintCount;

    string public PROVENANCE_HASH = "";
    bool public isLaunch;
    bool public saleIsActive;

    mapping (address => bool) public whitelist;
    address private wallet = 0xCf203C89B09367FD47eD83fF3315f057523b7E63;

    constructor() ERC721("The Mice House", "TMH") {
        MAX_MICE_SUPPLY = 3500;
        mintPrice = 45000000000000000; // 0.045 ETH
        maxMintAmount = 25;
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
     * Set price to mint a Mice.
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * Set maximum count to mint per once.
     */
    function setMaxToMint(uint256 _maxMintAmount) external onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    /*     
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        PROVENANCE_HASH = _provenanceHash;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    /*
    * Pause sale if active, make active if paused
    */
    function setSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
    * If isLaunch is false, it means presale.
    */
    function setLaunch(bool _isLaunch) external onlyOwner {
        isLaunch = _isLaunch;
    }

    /*
    * Whitelist wallets
    */
    function setWhitelist(address[] memory walletList) external onlyOwner {
        for (uint i=0; i<walletList.length; i++) {
            whitelist[walletList[i]] = true;
        }
    }

    /**
     * Mint Mices by owner
     */
    function reserveMices(address to, uint256 numberOfTokens) external onlyOwner {
        require(to != address(0), "Invalid address to reserve.");
        require(currentMintCount.add(numberOfTokens) <= MAX_MICE_SUPPLY, "Reserve would exceed max supply");
        
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(to, currentMintCount + i);
        }

        currentMintCount = currentMintCount.add(numberOfTokens);
    }

    /**
    * Mints tokens
    */
    function mintMices(uint256 numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to mint");
        require(numberOfTokens <= maxMintAmount, "Invalid amount to mint per once");
        require(currentMintCount.add(numberOfTokens) <= MAX_MICE_SUPPLY, "Purchase would exceed max supply");
        require(mintPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        require(isLaunch || whitelist[_msgSender()], "You have not permission to mint");
        
        for(uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, currentMintCount + i);
        }

        currentMintCount = currentMintCount.add(numberOfTokens);
    }

    function withdraw() external onlyOwner {
        payable(wallet).transfer(address(this).balance);
    }
}