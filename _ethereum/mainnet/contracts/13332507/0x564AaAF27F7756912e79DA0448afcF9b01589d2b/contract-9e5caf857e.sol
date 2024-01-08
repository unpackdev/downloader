// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

contract Toroids is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant MAX_TOKENS = 3080;
    uint256 public constant MAX_TOKENS_PER_ADDRESS = 500;
    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant MINT_LIMIT = 20;
    uint256 public constant PRESALE_MINT_LIMIT = 2;
    uint256 public constant PREPRESALE_MINT_LIMIT = 4;

    bool public isPrepresaleActive = false;
    bool public isPresaleActive = false;
    bool public isSaleActive = false;

    mapping(address => uint256) public prepresaleList;
    mapping(address => uint256) public presaleList;
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(bytes32 => uint256) public hashToTokenId;

    string private baseURI = "https://us-central1-toroids-by-lip.cloudfunctions.net/getMetadata?index=";

    event PrePresaleMint(address minter, uint256 amount);
    event PresaleMint(address minter, uint256 amount);
    event SaleMint(address minter, uint256 amount);

    constructor() ERC721("Toroids", "TOROIDS") {
        _tokenIdCounter.increment();
        _pause();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function turnOffPrepresale() external onlyOwner {
        isPrepresaleActive = false;
    }
    function turnOnPrepresale() external onlyOwner {
        isPrepresaleActive = true;
    }

    function turnOffPresale() external onlyOwner {
        isPresaleActive = false;
    }
    function turnOnPresale() external onlyOwner {
        isPresaleActive = true;
    }

    function turnOffSale() external onlyOwner {
        isSaleActive = false;
    }
    function turnOnSale() external onlyOwner {
        isSaleActive = true;
    }
    function switchToSale() external onlyOwner {
        isSaleActive = true;
        isPresaleActive = false;
        isPrepresaleActive = false;
    }

    // function addPresaleListMultiLimit(
    //     address[] calldata _addrs,
    //     uint256[] calldata _limit
    // ) external onlyOwner {
    //     require(_addrs.length == _limit.length);
    //     for (uint256 i = 0; i < _addrs.length; i++) {
    //         presaleList[_addrs[i]] = _limit[i];
    //     }
    // }
    function removePresaleList(
        address[] calldata _addrs
    ) external onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            presaleList[_addrs[i]] = 0;
        }
    }
    function removePrepresaleList(
        address[] calldata _addrs
    ) external onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            prepresaleList[_addrs[i]] = 0;
        }
    }
    function addPresaleList(
        address[] calldata _addrs
    ) external onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            //Confirm they aren't on prepresale
            if (prepresaleList[_addrs[i]]<=0){
                presaleList[_addrs[i]] = PRESALE_MINT_LIMIT;
            }
        }
    }
    function addPrepresaleList(
        address[] calldata _addrs
    ) external onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            prepresaleList[_addrs[i]] = PREPRESALE_MINT_LIMIT;
            presaleList[_addrs[i]] = 0;
        }
    }
    function prepresaleMint(uint256 amount) external payable {
        require(isPrepresaleActive, "Prepresale is not active");
        require(amount <= PREPRESALE_MINT_LIMIT, "More tokens at a time than allowed");

        uint256 senderLimit = prepresaleList[msg.sender];

        require(senderLimit > 0, "You have no tokens left");
        require(amount <= senderLimit, "Your max token holding exceeded");
        require(
            _tokenIdCounter.current() + amount <= MAX_TOKENS,
            "Max token supply exceeded"
        );
        require(msg.value >= amount * PRICE, "Insufficient funds");

        for (uint256 i = 0; i < amount; i++) {
            _hashmint(msg.sender);
            senderLimit -= 1;
        }

        prepresaleList[msg.sender] = senderLimit;
        emit PrePresaleMint(msg.sender, amount);
    }
    function presaleMint(uint256 amount) external payable {
        require(isPresaleActive, "Presale is not active");
        require(amount <= PRESALE_MINT_LIMIT, "More tokens at a time than allowed");

        uint256 senderLimit = presaleList[msg.sender];

        require(senderLimit > 0, "You have no tokens left");
        require(amount <= senderLimit, "Your max token holding exceeded");
        require(
            _tokenIdCounter.current() + amount <= MAX_TOKENS,
            "Max token supply exceeded"
        );
        require(msg.value >= amount * PRICE, "Insufficient funds");

        for (uint256 i = 0; i < amount; i++) {
            _hashmint(msg.sender);
            senderLimit -= 1;
        }

        presaleList[msg.sender] = senderLimit;
        emit PresaleMint(msg.sender, amount);
    }

    function mint(uint256 amount) external payable {
        require(isSaleActive, "Sale is not active");
        require(amount <= MINT_LIMIT, "More tokens at a time than allowed");
        require(
            balanceOf(msg.sender) + amount <= MAX_TOKENS_PER_ADDRESS,
            "Your max token holding exceeded"
        );
        require(
            _tokenIdCounter.current() + amount <= MAX_TOKENS,
            "Max token supply exceeded"
        );
        require(msg.value >= amount * PRICE, "Insufficient funds");

        for (uint256 i = 0; i < amount; i++) {
            _hashmint(msg.sender);
        }

        emit SaleMint(msg.sender, amount);
    }

    function gift(address to, uint256 amount) external onlyOwner {
        require(
            _tokenIdCounter.current() + amount <= MAX_TOKENS,
            "Max token supply exceeded"
        );
        for (uint256 i = 0; i < amount; i++) {
            _hashmint(to);
        }
    }

    function _hashmint(address to) internal {
        _safeMint(to, _tokenIdCounter.current());
        bytes32 hash = keccak256(abi.encodePacked(_tokenIdCounter.current(), msg.sender, block.number, blockhash(block.number - 1), msg.sender));
        tokenIdToHash[_tokenIdCounter.current()]=hash;
        hashToTokenId[hash]=_tokenIdCounter.current();
        _tokenIdCounter.increment();
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
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
