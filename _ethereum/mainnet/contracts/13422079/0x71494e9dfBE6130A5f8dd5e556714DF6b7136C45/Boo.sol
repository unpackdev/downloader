//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./console.sol";

contract Boo is Ownable, ERC721Enumerable {
    using Strings for uint256;
    string private baseURI;
    uint256 public mintPrice;
    uint256 public itemLimit;
    uint256 private currentTokenId = 1;

    bool public enableWhitelist = true;
    mapping(address => bool) public isInWhitelist;

    uint256 public buyLimit;
    mapping(address => uint256) public buyCount;

    uint256 public salesStartTime;

    receive() external payable {}

    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseURI_,
        uint256 _mintPrice,
        uint256 _itemLimit,
        uint256 _salesStartTime,
        address _owner,
        uint256 _numItemsForOwner
    ) ERC721(_name, _symbol) {
        baseURI = baseURI_;
        mintPrice = _mintPrice;
        itemLimit = _itemLimit;
        salesStartTime = _salesStartTime;

        require(
            _numItemsForOwner <= _itemLimit,
            "numItemsForOwner exceeds itemLimit"
        );

        _setSalesStartTime(_salesStartTime);

        for (uint256 i = 0; i < _numItemsForOwner; i++) {
            _safeMint(_owner, currentTokenId);
            currentTokenId++;
        }

        transferOwnership(_owner);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function isAddressInWhitelist(address _address) public view returns (bool) {
        return isInWhitelist[_address];
    }

    function mintTo(address _to) external onlyOwner {
        require(currentTokenId <= itemLimit, "exceeds item limit");

        currentTokenId++;
        _safeMint(_to, currentTokenId - 1);
    }

    function buy() external payable {
        require(currentTokenId <= itemLimit, "exceeds item limit");
        require(
            block.timestamp >= salesStartTime,
            "sales period hasn't started"
        );
        require(
            !enableWhitelist || isInWhitelist[msg.sender],
            "address is not whitelisted"
        );
        require(msg.value >= mintPrice, "ETH amount sent is not enough");
        require(buyCount[msg.sender] < buyLimit, "buy limit reached");

        buyCount[msg.sender]++;
        currentTokenId++;
        _safeMint(msg.sender, currentTokenId - 1);
    }

    function setEnableWhitelist(bool _enable) external onlyOwner {
        enableWhitelist = _enable;
    }

    function setBuyLimit(uint256 _buyLimit) external onlyOwner {
        buyLimit = _buyLimit;
    }

    function _whitelistAddresses(address[] memory _addresses) internal {
        for (uint256 i = 0; i < _addresses.length; i++) {
            isInWhitelist[_addresses[i]] = true;
        }
    }

    function _setMintPrice(uint256 _mintPrice) internal {
        mintPrice = _mintPrice;
    }

    function whitelistAddresses(address[] memory _addresses)
        external
        onlyOwner
    {
        _whitelistAddresses(_addresses);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        _setMintPrice(_mintPrice);
    }

    function setSalesStartTime(uint256 _salesStartTime) external onlyOwner {
        _setSalesStartTime(_salesStartTime);
    }

    function _setSalesStartTime(uint256 _salesStartTime) internal {
        require(_salesStartTime < 1917739533, "invalid sales start time");
        salesStartTime = _salesStartTime;
    }

    function modifySalesCondition(
        bool _enableWhitelist,
        address[] memory addresses,
        uint256 _mintPrice,
        uint256 _buyLimit,
        uint256 _salesStartTime
    ) external onlyOwner {
        enableWhitelist = _enableWhitelist;
        mintPrice = _mintPrice;
        buyLimit = _buyLimit;
        _setSalesStartTime(_salesStartTime);
        _whitelistAddresses(addresses);
    }

    function tokenIdsByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokenIds = new uint256[](balanceOf(_owner));
        for (uint256 index = 0; index < balanceOf(_owner); index++) {
            tokenIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return tokenIds;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
