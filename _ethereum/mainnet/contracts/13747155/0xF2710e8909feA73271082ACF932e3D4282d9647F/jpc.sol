// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

contract Jpc is ERC721, ERC721Enumerable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PER_MINT = 20;
    uint256 public constant JPC_PRICE = 0.04 ether;
    string public constant CODE_CID = 'bafkreie2cpqpwcpawdat4zx2tcknhhaifpqfnrv5ozgo4mibqwdyowuf2q'; // ipfs cid of the jpc script. Unchangeable after deploy.
    string public baseTokenURI;
    bool public _saleIsActive = false;

    mapping(uint256 => bytes32) public tokenIdToHash;

    uint256[] public models = [4, 4, 1, 2, 1, 5, 3, 1, 2, 2, 1, 4, 3, 5, 6, 1, 2, 3, 1, 3, 2];
    uint256[] public compositeBoosts = [40, 10, 40, 20, 50, 30, 20, 50, 10, 30, 70, 40, 30, 80, 10, 20, 40, 20, 60, 10, 50, 30, 10, 60, 50, 70, 30, 60, 80, 40, 10, 70, 20, 10, 60, 90, 20, 40, 20, 50, 10, 20, 30, 10, 30];

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        setBaseURI(baseURI);
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdCounter.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mintTeamTokens(address _to, uint256 _count) public onlyOwner {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_SUPPLY, "Not enough left");
        require(total <= MAX_SUPPLY, "Sale is over");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function mint(address _to, uint256 _count) public payable {
        uint256 total = _totalSupply();
        require(_saleIsActive, "Sale paused");
        require(total + _count <= MAX_SUPPLY, "Not enough left to mint that many");
        require(total <= MAX_SUPPLY, "Sale is over");
        require(_count > 0, "Minimum of 1");
        require(_count <= MAX_PER_MINT, "Exceeds max per address");
        require(msg.value >= JPC_PRICE * _count, "Below minimum price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        // the functional metadata attributes can all be derived from the pseudorandom hash created below. 
        // Not impossible for a miner to withold a block and manipulate, but not easy to do and economics during the mint probably not good enough to attempt.
        bytes32 tHash = keccak256(abi.encodePacked(id, block.timestamp, blockhash(block.number - 1), _to));
        
        tokenIdToHash[id] = tHash;

        _tokenIdCounter.increment();
        _safeMint(_to, id);
    }

    function getModel(uint tokenId) public view returns (uint256) {
        uint seed = uint(tokenIdToHash[tokenId]);
        uint v = models[seed % models.length];
        return v;
    }

    function getCompositeBoost(uint tokenId) public view returns (uint256) {
        uint seed = uint(tokenIdToHash[tokenId]);
        uint v = compositeBoosts[seed % compositeBoosts.length];
        return v;
    }

    function getEntropy(uint tokenId) public view returns (uint256) {
        uint seed = uint(tokenIdToHash[tokenId]);
        uint v = seed % 10;
        return v;
    }

    function getPtu(uint tokenId) public view returns (uint256) {
        uint cBoost = getCompositeBoost(tokenId);
        uint m = getModel(tokenId);
        uint entropy = getEntropy(tokenId);
        uint ptu = _calcPtu(cBoost, m, entropy);
        return ptu;
    }

    function _calcPtu(uint compositeBoost, uint modelNumber, uint tEntropy) internal pure returns(uint256) {
        return (((compositeBoost + tEntropy) * modelNumber) * 10);
    }

    function getJpcSpecs(uint tokenId) public view returns (bytes32, uint256, uint256, uint256, uint256) {
        uint m = getModel(tokenId);
        uint cBoost = getCompositeBoost(tokenId);
        uint entropy = getEntropy(tokenId);
        uint ptu = _calcPtu(cBoost, m, entropy);

        return (tokenIdToHash[tokenId], m, cBoost, entropy, ptu);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function saleIsActive(bool val) public onlyOwner {
        _saleIsActive = val;
    }

    function widthdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        address payable _to = payable(msg.sender);

        (bool success, ) = _to.call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    } 
}