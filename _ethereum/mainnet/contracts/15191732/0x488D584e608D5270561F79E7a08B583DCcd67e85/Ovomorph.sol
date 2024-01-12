// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";



contract Ovomorph is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    // WhiteLists for presale.
    mapping (address => uint) public _numberOfPresale;
    mapping (uint => uint) public _numberOfAction;
    mapping (uint => uint) public _timeOfLastAction;
    // mapping (address => uint[]) public _tokensOfWallet;

    address public POOL = 0x8bDc87BF6a9625205bCBeC270448f3C7bF4e00c3;
    uint256 public ETH_PRICE = 60000000000000000; // 0.06 ETH
    uint256 public FOOD_PRICE = 10000000000000000000000000000; // 10B
    uint256 public FOOD_FEED = 2000000000000000000000000000; // 2B
    uint256 public constant MAX_TOKENS = 10000;
    bool public saleIsActive = false;
    bool public eggIsActive = false;
    string public baseExtension = ".json";
    string private _baseURIextended;

    IERC20 public FOOD;
    
    constructor(
        address _food
    ) ERC721("Ovomorph", "EGG") {
        
        FOOD = IERC20(_food);
        //_numberOfPresale[0x84CCf38452Dc6bB59DBccD5E1BA465f7BF2e66a7] = 2;

    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string[6] memory action_list = ['Initial/', 'Turning/', 'Candling/', 'Pre-hatching/', 'Ovomorph/', 'Swarm/'];
    
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, action_list[_numberOfAction[tokenId]], tokenId.toString(), baseExtension))
            : "";
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipEggState() public onlyOwner {
        eggIsActive = !eggIsActive;
    }

    function EggList() public {
        require(eggIsActive, "Egglist must be active to mint Tokens");
        require(totalSupply() + _numberOfPresale[msg.sender] <= MAX_TOKENS, "Purchase would exceed max supply of tokens");

        for(uint i = 0; i < _numberOfPresale[msg.sender]; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
                // _tokensOfWallet[msg.sender].push(mintIndex);
            }
        }
        
        _numberOfPresale[msg.sender] = 0;
    }
    
    function mintWithEthToken(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(totalSupply() + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(ETH_PRICE * numberOfTokens <= msg.value, "You dont have enough Ether");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
                // _tokensOfWallet[msg.sender].push(mintIndex);
            }
        }
    }

    function mintWithFoodToken(uint numberOfTokens) public {
        require(tx.origin == msg.sender, "You dont own");
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(totalSupply() + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of tokens");

        FOOD.safeTransferFrom(msg.sender, address(this), numberOfTokens * FOOD_PRICE);

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
                // _tokensOfWallet[msg.sender].push(mintIndex);
            }
        }
    }


    function Incubating(uint tokenId) public {
        require(tx.origin == msg.sender, "You dont own");
        require(ownerOf(tokenId) == msg.sender, "You are not token's owner");
        require(_numberOfAction[tokenId] <= 5, "There is not an egg");
        require(block.timestamp >= (_timeOfLastAction[tokenId] + 24*3600), "Please wait for the next incubate");
        require(FOOD.balanceOf(msg.sender) >= FOOD_FEED, "FOOD tokens not enough");

        FOOD.transferFrom(msg.sender, POOL, FOOD_FEED);
        _numberOfAction[tokenId]++;
        _timeOfLastAction[tokenId] = block.timestamp;

    }

    function getTokensOfWallet(address wallet) public view returns(uint[] memory) {
        uint tokenBalance = balanceOf(wallet);
        uint[] memory res = new uint[](tokenBalance);
        for (uint i=0; i<tokenBalance; i++) {
            res[i] = tokenOfOwnerByIndex(wallet, i);
        }

        return res;
    }

    function getPresaleCount(address wallet) public view returns(uint) {
        return _numberOfPresale[wallet];
    }
    
    // Update Food Amount
    function setFoodFeed(uint _newPrice) external onlyOwner {
        FOOD_FEED = _newPrice;
    }

    // Update ETH Price
    function setEthPrice(uint _newPrice) external onlyOwner {
        ETH_PRICE = _newPrice;
    }

    // Update FOOD Price
    function setFoodPrice(uint _newPrice) external onlyOwner {
        FOOD_PRICE = _newPrice;
    }

    // Update POOL Address
    function setPoolAddress(address _newPool) external onlyOwner {
        POOL = _newPool;
    }

    function addWhiteList(address[] calldata _wallet, uint8 _count) external onlyOwner {
    for (uint256 i = 0; i < _wallet.length; i++) {
        _numberOfPresale[_wallet[i]] = _count;
    }
}

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}