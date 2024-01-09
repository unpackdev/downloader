// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Strings.sol";
import "./Mintable.sol";

contract ImpsToken is ERC721, Ownable, Mintable {

    using Strings for uint;
    using Address for address;
    using Address for address payable;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    mapping(address => uint) private _mints;

    string private _metaPath;
    bool private _imagesRevealed = false;
    uint internal _mintingFee = 6e16; //0,06ETH
    uint internal _maxNumberPerTx = 10;
    uint internal _totalMintLimitPerAddress = 6;
    uint internal _totalTokenCount;
    string internal constant HIDDEN_META_PATH = "https://cdn.immutableimps.com/meta/";

    event EthersWithdrawn(address indexed operator, address indexed to, uint amount);

    constructor(uint count, address _imx)
    ERC721("Immutable Imps", "IMPS")
    Mintable(msg.sender, _imx)
    {
        _totalTokenCount = count;
    }

    function totalTokenCount() public view returns(uint) {
        return _totalTokenCount;
    }

    function totalMintLimitPerAddress() public view returns(uint) {
        return _totalMintLimitPerAddress;
    }

    function setTotalMintLimitPerAddress(uint value) external onlyOwner {
        _totalMintLimitPerAddress = value;
    }

    function revealImages(string memory metaPath) external onlyOwner {
        require(bytes(metaPath).length > 12, "ImpsToken: suspicious path value");
        _imagesRevealed = true;
        _metaPath = metaPath;
    }

    function mintedBy(address user) public view returns(uint) {
        return _mints[user];
    }

    function mintingFee() public view returns(uint) {
        return _mintingFee;
    }

    function maxNumberPerTx() public view returns(uint) {
        return _maxNumberPerTx;
    }

    function setMaxNumberPerTx(uint newValue) external onlyOwner {
        _maxNumberPerTx = newValue;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory imgPath = _imagesRevealed ? _metaPath : HIDDEN_META_PATH;
        return string(abi.encodePacked(imgPath, tokenId.toString(), ".json"));
    }

    function mintGift(address to, uint number) external onlyOwner {
        require(to != address(0) && !to.isContract(), "ImpsToken: wrong address");
        require((_tokenIds.current() + number) <= totalTokenCount(), "ImpsToken: the limit of 6666 tokens is going to be exceeded");
        require(number <= maxNumberPerTx(), "ImpsToken: the given number exceeds the allowed max per transaction");

        for (uint i = 0; i < number; i++) {
            _tokenIds.increment();
            uint newTokenId = _tokenIds.current();
            _mint(to, newTokenId);
        }
    }

    function mint(address to, uint number) external payable {
        require(to != address(0) && !to.isContract(), "ImpsToken: wrong address");
        require((_tokenIds.current() + number) <= totalTokenCount(), "ImpsToken: the limit of 6666 tokens is going to be exceeded");
        require(number <= maxNumberPerTx(), "ImpsToken: the given number exceeds the allowed max per transaction");
        require((mintedBy(_msgSender()) + number) <= totalMintLimitPerAddress(), "ImpsToken: the limit of minting per address is going to be exceeded");
        require(msg.value >= number * mintingFee(), "ImpsToken: incorrect amount sent to the contract");

        for (uint i = 0; i < number; i++) {
            _tokenIds.increment();
            uint newTokenId = _tokenIds.current();
            _mint(to, newTokenId);
        }

        _mints[_msgSender()] += number;
    }


    function withdrawEthers(uint amount, address payable to) public virtual onlyOwner {
        to.sendValue(amount);
        emit EthersWithdrawn(_msgSender(), to, amount);
    }

    function _mintFor(address user, uint256 tokenId, bytes memory) internal override {
        require(tokenId <= totalTokenCount(), "ImpsToken: the limit of 6666 tokens is going to be exceeded");
    
        _safeMint(user, tokenId);
    }
}
