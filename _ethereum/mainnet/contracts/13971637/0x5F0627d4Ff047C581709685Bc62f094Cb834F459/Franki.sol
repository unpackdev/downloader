// SPDX-License-Identifier: MIT
// Franki.wtf
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Franki is ERC721, ERC721Enumerable, Ownable {
    bool public saleIsActive = false;
    bool public claimIsActive = false;

    mapping(uint256 => uint256) private tokenMatrix;

    bool public isAllowListActive = false;
    uint256 public constant MAX_PUBLIC_MINT = 20;
    uint256 public constant MAX_ELEMENTS = 1000;
    uint256 public PRICE_PER_TOKEN = 0 ether;
    string public baseTokenURI = "https://ipfs.io/ipfs/QmSM8pmyEzyV12BdECzjj7bpxUV2Kfm6gwet78pB9RCA6H/";

    mapping(address => uint8) private _allowList;

    constructor() ERC721("Franki", "FRK") {}

    //Increase price per token
    function setPricePerToken(uint256 price) external onlyOwner {
        require(price > PRICE_PER_TOKEN, "New price is less than previous one");
        PRICE_PER_TOKEN = price;
    }

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function numAvailableToMintAllowList(address addr) external view returns (uint8) {
        return _allowList[addr];
    }

    function mintAllowList(uint8 numberOfTokens) external payable {
        uint256 totalSupply = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
        require(totalSupply + numberOfTokens <= MAX_ELEMENTS, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _allowList[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, _nextToken());
        }
    }

    //Allow free mint
    function setClaimState(bool newState) public onlyOwner {
        claimIsActive = newState;
    }

    function claim() public payable {
        uint256 totalSupply = totalSupply();
        require(claimIsActive, "Free claim must be allowed to mint tokens");
        require(totalSupply + 1 <= MAX_ELEMENTS, "Purchase would exceed max tokens");

        _safeMint(msg.sender, _nextToken());
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    //Payable mint
    function mint(uint numberOfTokens) public payable {
        uint256 totalSupply = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max available to purchase");
        require(totalSupply + numberOfTokens <= MAX_ELEMENTS, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, _nextToken());
        }
    }

    function _nextToken() internal returns (uint256) {
        uint256 maxIndex = MAX_ELEMENTS - totalSupply();
        uint256 random = uint256(keccak256(
            abi.encodePacked(
                msg.sender,
                block.coinbase,
                block.difficulty,
                block.gaslimit,
                block.timestamp
            )
        )) % maxIndex;

        uint256 value = 0;
        if (tokenMatrix[random] == 0) {
            value = random;
        } else {
            value = tokenMatrix[random];
        }
        if (tokenMatrix[maxIndex - 1] == 0) {
            tokenMatrix[random] = maxIndex - 1;
        } else {
            tokenMatrix[random] = tokenMatrix[maxIndex - 1];
        }

        return value;
    }

    //Reserve some NFTs for airdrops and community giveaways
    function reserve(uint numberOfTokens) public onlyOwner {
      uint256 totalSupply = totalSupply();
      require(totalSupply + numberOfTokens <= MAX_ELEMENTS, "Mint would exceed max tokens");
      for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, _nextToken());
      }
    }
        
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}