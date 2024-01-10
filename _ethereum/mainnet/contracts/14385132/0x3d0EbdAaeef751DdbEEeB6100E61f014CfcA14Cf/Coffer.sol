//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

contract Coffer is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    enum CofferType { COMMON, UNCOMMON, RARE, EPIC }

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public maxMintAmount = 30;
    bool public paused = true;
    
    uint256 discountPercent = 4; //in basis points (parts per 1,00)
    uint256 additionalDiscountPercent = 40; //in basis points (parts per 1,00)
    
    mapping(CofferType => uint256) private typeToSupply;
    mapping(CofferType => uint256) private typeToMaxSupply;
    mapping(CofferType => uint256) public typeToPrice;
    mapping(uint256 => CofferType) public idToType;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        typeToPrice[CofferType.COMMON] = 50000000000000000;//0.05
        typeToPrice[CofferType.UNCOMMON] = 150000000000000000;//0.15
        typeToPrice[CofferType.RARE] = 400000000000000000;//0.4
        typeToPrice[CofferType.EPIC] = 750000000000000000;//0.75

        typeToMaxSupply[CofferType.COMMON] = 4000;
        typeToMaxSupply[CofferType.UNCOMMON] = 2000;
        typeToMaxSupply[CofferType.RARE] = 1000;
        typeToMaxSupply[CofferType.EPIC] = 500;

        setBaseURI(_initBaseURI);

        _mintInternal(30, CofferType.UNCOMMON);
        _mintInternal(20, CofferType.EPIC);
        _mintInternal(15, CofferType.RARE);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _mintAmount, CofferType _type) public payable {
        require(!paused, "paused");
        require(_mintAmount <= maxMintAmount, "max amount exceeded");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        uint256 supply = getSupply(_type);
        require(supply + _mintAmount <= getMaxSupply(_type), "max limit exceeded");
        uint256 totalPrice = getPrice(_type).mul(_mintAmount).sub(getDiscount(getPrice(_type), _mintAmount));
        totalPrice = totalPrice.sub(getQuantityDiscount(getPrice(_type), _mintAmount));
        require(msg.value >= totalPrice, "insufficient funds");

        _mintInternal(_mintAmount, _type);
    }

    function _mintInternal(uint256 _mintAmount, CofferType _type) internal {
        uint256 totalSupply = totalSupply();

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, totalSupply.add(i));
            typeToSupply[_type] += 1;
            idToType[totalSupply.add(i)] = _type;
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        getTypeById(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(bool state) public onlyOwner {
        paused = state;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function getSupply(CofferType _type) public view returns (uint256) {
        return typeToSupply[_type];
    }
    
    function getMaxSupply(CofferType _type) public view returns (uint256) {
        return typeToMaxSupply[_type];
    }
    
    function getPrice(CofferType _type) public view returns (uint256) {
        return typeToPrice[_type];
    }
    
    function getTypeById(uint256 _id) public view returns (CofferType) {
        return idToType[_id];
    }
    
    function getDiscount(uint256 _price, uint256 _quantity) public view returns (uint256) {
        uint256 bp = 100;
        return _quantity.mul(_price).div(bp).mul(additionalDiscountPercent);
    }
 
    function getQuantityDiscount(uint256 _price, uint256 _quantity) public view returns (uint256) {
        uint256 bp = 100;
        return _quantity.mul(_price).div(bp).mul(discountPercent).mul(_quantity.div(5));
    }

    function getAdditionalDiscountPercent() public view returns (uint256) {
        return additionalDiscountPercent;
    }
}
