// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Accountable.sol";

pragma solidity ^0.8.0;

contract Alias is ERC721Enumerable, Ownable, Accountable {
    string private _baseTokenURI;

    uint256 public constant MAX_SUPPLY = 8501;        // One too high
    uint256 public constant RESERVES = 76;            // One too high
    uint256 public priceWhitelist = 5 * 10 ** 16;     // .05 ETH
    uint256 public pricePublic = 7 * 10 ** 16;        // .07 ETH
    uint256 public saleTimeWhitelist = 1634421600;    // Saturday, October 16, 2021 6:00:00 PM EST
    uint256 public saleTimePublic = 1634680800;       // Tuesday, October 19, 2021 6:00:00 PM EST
    uint256 public maxPerTransaction = 6;             // One too high

    mapping(address => uint256) addressToWhitelistMintsAvailable;

    constructor(
        string memory baseURI,
        address[] memory _splits,
        uint256[] memory _splitWeights
    ) 
        ERC721("Alias", "ALIAS")
        Accountable(_splits, _splitWeights)
    {
        setBaseURI(baseURI);
    }

    modifier mintIsValid() {
        require(tx.origin == msg.sender, "Sender must call transaction directly.");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI; 
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPriceWhitelist(uint256 _newWEIPrice) external onlyOwner {
        priceWhitelist = _newWEIPrice;
    }

    function setPricePublic(uint256 _newWEIPrice) external onlyOwner {
        pricePublic = _newWEIPrice;
    }
    
    function setSaleTimeWhitelist(uint256 _newTime) external onlyOwner {
        saleTimeWhitelist = _newTime;
    }

    function setSaleTimePublic(uint256 _newTime) external onlyOwner {
        saleTimePublic = _newTime;
    }

    function setMaxPerTransaction(uint256 _newMax) external onlyOwner {
        maxPerTransaction = _newMax;
    }

    /**
     * @dev When setting the integers of this function they need to be set one too high.
     */
    function setWhitelistMints(address[] calldata _whitelistAddresses, uint256[] calldata _whitelistMints) external onlyOwner {
        for (uint256 i; i < _whitelistAddresses.length; i++) {
            addressToWhitelistMintsAvailable[_whitelistAddresses[i]] = _whitelistMints[i];
        }
    }

    /**
     * NOTE: This function is super weird looking and we are actually subtracting one. 
     * We are doing this because the value is always stored as one higher than it 
     * really is to avoid gte calls for whitelist max cap management however if they are
     * not whitelisted 0 is still returned.
     */
    function getWhitelistMints(address _whitelistAddress) public view returns (uint256) {
        uint256 mintsAvailable = addressToWhitelistMintsAvailable[_whitelistAddress];
        if(mintsAvailable == 0) {
            return mintsAvailable;
        }
        return mintsAvailable - 1;
    }

    function _mint(uint256 totalSupply, uint256 _count) internal {
        uint256 tokenId;
        for (uint256 i; i < _count; i++) {
            tokenId = totalSupply + i;
            _safeMint(msg.sender, tokenId);
        }
    }

    /**
     * NOTE: This function allows the passing of count however a maximum cap of 40 is 
     * recommended to prevent any unexpected issues like running out of gas.
     */
    function collectReserves(uint256 _count) external onlyOwner {
        require(block.timestamp < saleTimeWhitelist,
            "Whitelist sale has already started."
        );

        uint256 totalSupply = totalSupply();
        require(totalSupply + _count < RESERVES, "Beyond max limit");
        
        _mint(totalSupply, _count);
    }

    function mintWhitelist(uint256 _count) external payable mintIsValid {
        require(block.timestamp >= saleTimeWhitelist && block.timestamp < saleTimePublic, 
            "Whitelist sale is not active."
        );
        uint256 totalSupply = totalSupply();
        require(totalSupply + _count < MAX_SUPPLY, "Exceeds max supply.");
        require(addressToWhitelistMintsAvailable[msg.sender] > _count,
            "Exceeds wallet whitelist mints."
        );
        require(_count < maxPerTransaction, "Exceeds max per transaction.");
        require(priceWhitelist * _count == msg.value, "Transaction value incorrect.");

        addressToWhitelistMintsAvailable[msg.sender] -= _count;
        _mint(totalSupply, _count);
        tallySplits();
    }

    function mint(uint256 _count) external payable mintIsValid {
        require(block.timestamp >= saleTimePublic, "Sale is not active.");
        uint256 totalSupply = totalSupply();
        require(totalSupply + _count < MAX_SUPPLY, "Exceeds max supply.");
        require(_count < maxPerTransaction, "Exceeds max per transaction.");
        require(pricePublic * _count == msg.value, "Transaction value incorrect.");

        _mint(totalSupply, _count);
        tallySplits();
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
}
