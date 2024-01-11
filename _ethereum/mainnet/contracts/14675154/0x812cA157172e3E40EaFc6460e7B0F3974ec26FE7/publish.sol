// SPDX-License-Identifier: MIT
//
// 0000000000000000000000000000000000000000000000000000000000000000
// 0000000000000000000000000000000000000000000000000000000000000000
// 0011111111000000000000000000000011111111110000000000111100111100
// 0011111111110000000000000000000011111111111100111100111100111100
// 0011110011111100000011110000000011110000111100111100111100111100
// 0011110000111100111111110000000011111111110000000000111100111100
// 0011110000111100111100000000000011111111110000111100111100111100
// 0011110011111100111100000000000011110000111100111100111100111100
// 0011111111110000111100001111000011111111110000111100111100111100
// 0011111111100000111100001111000011111111110000111100111100111100
// 0000000000000000000000000000000000000000000000000000000000000000
// 0000000000000000000000000000000000000000000000000000000000000000
// 0000001111111111111111111100000000000011111111111111111111111100
// 0000001111111111111111111100000000000011111111111111111111111100
// 0011111111111111111111111111110000111111111111111111111111111100
// 0011111111111111111111111111110000111111111111111111111111111100
// 0011111111000000000000111111110000111111110000000000000000000000
// 0011111111000000000000111111110000111111110000000000000000000000
// 0011111111000000000000111111110000111111110000000000000000000000
// 0011111111000000000000111111110000111111110001111111111111111100
// 0011111111000000000000111111110000111111110001111111111111111100
// 0011111111000000000000111111110000111111110001111111111111111100
// 0011111111000000000000111111110000111111110001111111111111111100
// 0011111111000000000000111111110000111111110000000000001111111100
// 0011111111000000000000111111110000111111110000000000001111111100
// 0011111111000000000000111111110000111111110000000000001111111100
// 0011111111111111111111111111110000111111111111111111111111111100
// 0011111111111111111111111111110000111111111111111111111111111100
// 0000001111111111111111111100000000000011111111111111111111111100
// 0000001111111111111111111100000000000011111111111111111111111100
// 0000000000000000000000000000000000000000000000000000000000000000
// 0000000000000000000000000000000000000000000000000000000000000000
//
// Generative Art Vending Machine for artworks of Dr. Bill Kolomyjec.
//
// -= Goat Studio =-
//

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract GenerativeArtVendingMachine is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bool public paused = true;
    mapping (uint256 => bool) public publicSaleActive;
    mapping (uint256 => uint256) public maxPrivatePurchases;
    mapping (uint256 => uint256) public maxCounts;
    mapping (uint256 => uint256) public counts;
    mapping (uint256 => uint256) public privatePrices;
    mapping (uint256 => address []) public privateLists;
    mapping (uint256 => string) baseURIs;
    mapping (uint256 => string) baseExtensions;
    mapping (uint256 => mapping (address => uint256)) public privatePurchasedCount;

    string private _name;
    string private _symbol;

    // Public sale params
    mapping (uint256 => uint256) public publicSaleDurations;
    mapping (uint256 => uint256) public publicSaleStartTimes;
    mapping (uint256 => uint256) public publicSaleEndingPrices;
    mapping (uint256 => uint256) public publicSaleStartingPrices;
    
    event PublicSaleStart(
        uint256 indexed _algo,
        uint256 indexed _saleDuration,
        uint256 indexed _saleStartTime
    );
    event PublicSalePaused(
        uint256 indexed _algo,
        uint256 indexed _currentPrice,
        uint256 indexed _timeElapsed
    );

    function setMaxPrivatePurchases(uint256 _algo, uint256 _max) external onlyOwner {
        maxPrivatePurchases[_algo]=_max;
    }

    function setPrivatePrice(uint256 _algo, uint256 _price) external onlyOwner {
        privatePrices[_algo]=_price;
    }

    function togglePublicSaleActive(uint256 _algo) external onlyOwner {
        publicSaleActive[_algo] = !publicSaleActive[_algo];
    }

    function startPublicSale(uint256 algo, uint256 saleDuration, uint256 saleStartPrice, uint256 saleEndingPrice)
        external
        onlyOwner
    {
        require(!publicSaleActive[algo], "Public sale has already begun");
        publicSaleDurations[algo] = saleDuration;
        publicSaleEndingPrices[algo] = saleEndingPrice;
        publicSaleStartingPrices[algo] = saleStartPrice;
        publicSaleStartTimes[algo] = block.timestamp;
        publicSaleActive[algo] = true;
        emit PublicSaleStart(algo, saleDuration, publicSaleStartTimes[algo]);
    }

    function pausePublicSale(uint256 _algo) external onlyOwner {
        require(publicSaleActive[_algo], "Public sale is not active");
        uint256 currentSalePrice = getAlgoPrice(_algo);
        publicSaleActive[_algo] = false;
        emit PublicSalePaused(_algo, currentSalePrice, getElapsedSaleTime(_algo));
    }
    
    function getRemainingSaleTime(uint256 _algo) external view returns (uint256) {
        require(publicSaleStartTimes[_algo] > 0, "Public sale hasn't started yet");
        if (getElapsedSaleTime(_algo) >= publicSaleDurations[_algo]) {
            return 0;
        }
       return (publicSaleStartTimes[_algo] + publicSaleDurations[_algo]) - block.timestamp;
    }

    function getElapsedSaleTime(uint256 _algo) internal view returns (uint256) {
        return
            publicSaleStartTimes[_algo] > 0 ? block.timestamp - publicSaleStartTimes[_algo] : 0;
    }

    function getAlgoPrice(uint256 _algo) public view returns (uint256) {
        if(publicSaleActive[_algo])
        {
            uint256 elapsed = getElapsedSaleTime(_algo);
            uint256 duration= publicSaleDurations[_algo];
            if (elapsed >=duration) {
                return publicSaleEndingPrices[_algo];
            } else {
                uint256 currentPrice = ((duration - elapsed) *
                    publicSaleStartingPrices[_algo]) / duration;
                return
                    currentPrice > publicSaleEndingPrices[_algo]
                        ? currentPrice
                        : publicSaleEndingPrices[_algo];
            }
        }
        else
        {
            uint256 privatePrice=privatePrices[_algo];
            require(privatePrice>0,"Sale is not active.");
            return privatePrice;
        }

    }

    function withdraw() external onlyOwner nonReentrant {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setMaxCount(uint256 algoID, uint256 maxCount) external onlyOwner {
        require(counts[algoID]<=maxCount,"Can not allow less than already minted");
        maxCounts[algoID]=maxCount;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Given token does not exist");
        uint256 algoID=_tokenId>>32;
        return string(abi.encodePacked(baseURIs[algoID], _tokenId.toString(), baseExtensions[algoID]));
    }

    function name() public override view returns (string memory) {
      return _name;
    }

    function symbol() public override view returns (string memory) {
      return _symbol;
    }

    function setBaseURI(uint256 _algo, string memory baseURI_) external onlyOwner {
        baseURIs[_algo]=baseURI_;
    }

    function setName(string memory _newName) public onlyOwner() {
        _name = _newName;
    }

    function setSymbol(string memory newSymbol) public onlyOwner() {
        _symbol = newSymbol;
    }

    function setbaseExtension(uint256 _algo, string memory _baseExtension) external onlyOwner() {
        baseExtensions[_algo]=_baseExtension;
    }

    constructor () ERC721("Generative Art Vending Machine","GAVM") { 
        _name = "Generative Art Vending Machine";
        _symbol = "GAVM";
    }

    function pause(bool _state) external onlyOwner {
        require(paused!=_state,"already set same state");
        paused=_state;
    }

    function setPrivateList(uint256 algo, address [] calldata _privateList) external onlyOwner {
        delete privateLists[algo];
        privateLists[algo]=_privateList;
    }

    function isInPrivateList(uint256 algo, address addr) public view returns (bool) {
        address [] memory privateList=privateLists[algo];
        for(uint256 i=0; i<privateList.length;i++) {
            if(privateList[i]==addr) {
                return true;
            }
        }
        return false;
    }
    
    function mint(
    uint256 _tokenId
    ) external payable {
        mintTo(msg.sender,_tokenId);
    }

    function mintTo(
    address _to,
    uint256 _tokenId
    ) public payable nonReentrant {
        require(!paused,"Sale is paused");

        uint256 algoID=_tokenId>>32;
        require(counts[algoID]<maxCounts[algoID],
            "Maximum count of tokens for selected algorighm has been reached.");
        
        if (msg.sender != owner()) {
            uint256 price = getAlgoPrice(algoID);
            require(msg.value>=price, "Incorrect transaction value.");
            if(!publicSaleActive[algoID]) {
                require(privatePrices[algoID]>0, "Private sale is not active.");
                require(isInPrivateList(algoID, msg.sender),"Address is not in private sale list.");
                uint256 purchaseCount=privatePurchasedCount[algoID][msg.sender];
                require(purchaseCount<maxPrivatePurchases[algoID],"Private sale limit reached for this address.");
                privatePurchasedCount[algoID][msg.sender]=purchaseCount+1;
            }
         }

        _safeMint(_to, _tokenId); 
        counts[algoID]=counts[algoID]+1;
    }
}