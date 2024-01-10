//SPDX-License-Identifier: RatLab
// contract has been done by Ratlabs
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Counters.sol";

contract ERC721LetsCollect is ERC721Enumerable, Ownable {
    enum NFTType {
        Platinum,
        Gold,
        Silver,
        Bronze
    }

    using Strings for uint256;
    event Withdraw(address indexed to, uint256 indexed amount);

    using Counters for Counters.Counter;
    uint256 private __tokenIncrement;
    string public baseURI;

    mapping(string => NFTType) private __nftStringToTypes;
    mapping(NFTType => string) private __nftTypeToStrings;

    mapping(NFTType => uint256) private __prices;
    mapping(NFTType => uint256) private __maxSupplies;
    mapping(NFTType => uint256) private __currentSupplies;
    mapping(uint256 => NFTType) private __tokenTypes;

    constructor(string memory baseURI_) ERC721("LetsCollect", "LCT") {
        __tokenIncrement = 0;
        setBaseURI(baseURI_);

        __nftStringToTypes["Plantinum"] = NFTType.Platinum;
        __nftStringToTypes["Gold"] = NFTType.Gold;
        __nftStringToTypes["Silver"] = NFTType.Silver;
        __nftStringToTypes["Bronze"] = NFTType.Bronze;

        __nftTypeToStrings[NFTType.Platinum] = "Plantinum";
        __nftTypeToStrings[NFTType.Gold] = "Gold";
        __nftTypeToStrings[NFTType.Silver] = "Silver";
        __nftTypeToStrings[NFTType.Bronze] = "Bronze";

        _setPrice(NFTType.Platinum, 3 ether);
        _setMaxSupply(NFTType.Platinum, 1);

        _setPrice(NFTType.Gold, 2 ether);
        _setMaxSupply(NFTType.Gold, 5);

        _setPrice(NFTType.Silver, 1 ether);
        _setMaxSupply(NFTType.Silver, 10);

        _setPrice(NFTType.Bronze, 0.5 ether);
        _setMaxSupply(NFTType.Bronze, 20);
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        __nftTypeToStrings[__tokenTypes[tokenId]],
                        "/",
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function _nftTypeFromString(string memory str)
        private
        view
        returns (NFTType)
    {
        return __nftStringToTypes[str];
    }

    function _setPrice(NFTType _nftType, uint256 price_) internal virtual {
        require(price_ >= 0.01 ether, "Price is not valid");
        __prices[_nftType] = price_;
    }

    function price(string memory _nftType) public view returns (uint256) {
        NFTType nftType = _nftTypeFromString(_nftType);
        return __prices[nftType];
    }

    function _setMaxSupply(NFTType _nftType, uint256 _amount) internal virtual {
        require(_amount >= 1, "Price is not valid");
        __maxSupplies[_nftType] = _amount;
    }

    function maxSupply(string memory _nftType) public view returns (uint256) {
        NFTType nftType = _nftTypeFromString(_nftType);
        return __maxSupplies[nftType];
    }

    function currentSupply(string memory _nftType)
        public
        view
        returns (uint256)
    {
        NFTType nftType = _nftTypeFromString(_nftType);
        return __currentSupplies[nftType];
    }

    function tokenType(uint256 tokenId) public view returns (string memory) {
        return __nftTypeToStrings[__tokenTypes[tokenId]];
    }

    function nextToken(NFTType _nftType) internal virtual returns (uint256) {
        uint256 _maxSupply = __maxSupplies[_nftType];
        uint256 _currentSupply = __currentSupplies[_nftType];

        require(_currentSupply < _maxSupply, "Exceeed to max supply");
        uint256 _tokenId = __tokenIncrement + 1;
        __tokenTypes[_tokenId] = _nftType;
        __tokenIncrement = _tokenId;
        __currentSupplies[_nftType] = _currentSupply + 1;
        return _tokenId;
    }

    function mint(string memory _nftType) public payable {
        NFTType nftType = __nftStringToTypes[_nftType];
        require(msg.value == __prices[nftType], "Price is not correct");

        uint256 id = nextToken(nftType);
        _safeMint(_msgSender(), id);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is not available");
        (payable(msg.sender)).transfer(balance);
        emit Withdraw(msg.sender, balance);
    }
}
