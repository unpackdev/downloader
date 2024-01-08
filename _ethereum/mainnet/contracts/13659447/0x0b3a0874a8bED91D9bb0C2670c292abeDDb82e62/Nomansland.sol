// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";
import "./SnoToken.sol";
import "./Auction.sol";

contract Nomansland is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public maxElements = 2048;
    mapping(address => uint) public totalSnoMelted;
    uint256 public constant PRICE = 100 * 1e18;
    uint256 public constant MAX_PER_MINT = 3;
    uint256 public constant MAX_BY_MINT = 20;
    
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    string public baseTokenURI;
    SnoToken public token;

    event CreateNFT(uint256 indexed id);
    constructor(SnoToken _token, string memory _initialBaseURI) ERC721("Nomansland", "NML") {
        token = _token;
        setBaseURI(_initialBaseURI);
    }

    modifier saleIsOpen {
        require(_totalSupply() <= maxElements, "Sales end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mint(uint256 _amount) public saleIsOpen {
        uint256 total = _totalSupply();
        uint256 count = _amount / PRICE;
        uint256 remainder = _amount % PRICE;
        if(remainder != 0){
            count += 1;
        }
        require(count <= MAX_PER_MINT, "Maximum 3 per mint");
        require(total + count <= maxElements, "Max limit");
        require(total <= maxElements, "Sales end");
        require(count <= MAX_BY_MINT, "Exceeds number");

        token.transferFrom(msg.sender, BURN_ADDRESS, _amount);
        totalSnoMelted[msg.sender] += _amount;

        if(remainder != 0){
            uint256 randomNumber = random() % PRICE;
            for (uint256 i = 0; i < count - 1; i++) {
                _mintAnElement(msg.sender);
            }
            if(randomNumber < remainder){
                _mintAnElement(msg.sender);
            }
        } else {
            for (uint256 i = 0; i < count; i++) {
                _mintAnElement(msg.sender);
            }
        }
    }
    
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateNFT(id);
    }

    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function ceil(uint256 a, uint256 m) private pure returns (uint256) {
        return (a + m - 1) / m * m;
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setSupply(uint256 _amount) public onlyOwner {
        require(_totalSupply() < _amount, "Must be more than minted supply");
        maxElements = _amount;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAll() public payable onlyOwner {
        require(address(this).balance > 0);
        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}