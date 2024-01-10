pragma solidity 0.8.13;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IERC20.sol";

contract RichMekaMerch is ERC721, Ownable {
    using Counters for Counters.Counter;

    uint256 _comissionValue = 0.01 ether;
    uint8 _maxTokensPerMint = 5;
    uint16 _maxTokensSupply = 500;
    Counters.Counter _tokenIds;
    IERC20 _serumContract = IERC20(0x980d58C980b41E780F940D8CbF3bC64674FE1bD1);
    address _DAOAddress = 0x830F79Bf3a95Ab5033A2523b3eeE648028b8287e;
    uint256 _tokenPrice = 35000000000000000000000;

    constructor() ERC721("RichMekaMerch", "RMM") {}

    function mint(uint8 amount) external payable {
        require(msg.value >= _comissionValue, "Ether value sent is not correct");
        require(amount <= _maxTokensPerMint, "Can only mint 5 tokens at a time");
        require(_tokenIds.current() + amount <= _maxTokensSupply, "Mint will exceed max supply of tokens");

        for (uint8 i = 0; i < amount; i++) {
            _tokenIds.increment();
            _mint(msg.sender, _tokenIds.current());
        }

        _serumContract.transferFrom(msg.sender, _DAOAddress, _tokenPrice * amount);
    }

    function setComissionValue(uint256 comissionValue) external onlyOwner {
        _comissionValue = comissionValue;
    }

    function setMaxTokensSupply(uint16 maxTokensSupply) external onlyOwner {
        _maxTokensSupply = maxTokensSupply;
    }

    function setTokenPrice(uint256 tokenPrice) external onlyOwner {
        _tokenPrice = tokenPrice;
    }

    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://metadata.richmeka.com/richmekamerch/";
    }
}