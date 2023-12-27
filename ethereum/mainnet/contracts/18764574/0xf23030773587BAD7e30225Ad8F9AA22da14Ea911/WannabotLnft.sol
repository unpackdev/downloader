// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Supply.sol";

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract WannabotLnft is ERC1155Supply, Ownable, Pausable {
    mapping(uint256 => uint256) public tokenPrices;
    mapping(uint => string) public tokenURI;
    address public d3NftAddress;

    mapping(address => uint256) private mintedAmount;
    uint256 public combinedTotalSupply=0;

    string public name;
    string public symbol;

    constructor(address _d3NftAddress) ERC1155("") {
        name = "Wanna.bot";
        symbol = "WANNABOT";
        tokenPrices[1] = 0.1 ether;
        tokenPrices[2] = 0.066 ether;
        setURI(1, "ipfs://QmcgJyjCgGVpcQGXJeJgCGFUFttrbYAziDi9tadYPA93LF");
        setURI(2, "ipfs://QmNtHdKGRrq8PmbVXHHDD8oLec5f8YhWgfUXeRsDq7WMaY");
        d3NftAddress = _d3NftAddress;
        pause();
    }

    function mint(uint256 tokenID, uint256 amount) whenNotPaused public payable {
        uint256 price = tokenPrices[tokenID];
        require(price > 0, "Token not available for minting");
        require(msg.value >= price * amount, "Insufficient funds to mint");

        uint256 totalMinted = mintedAmount[msg.sender] + amount;
        require(
            totalMinted <= checkERC721Balance(msg.sender),
            "Total mint amount exceeds balance of D3 NFT"
        );

        combinedTotalSupply+=amount;
        mintedAmount[msg.sender] = totalMinted;
        _mint(msg.sender, tokenID, amount, "");
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool os, ) = payable(owner()).call{value: balance}("");
        require(os, "Failed to send Ether");
    }

    function setTokenPrice(uint256 tokenID, uint256 price) public onlyOwner {
        tokenPrices[tokenID] = price;
    }

    function setURI(uint _id, string memory _uri) public onlyOwner {
        tokenURI[_id] = _uri;
        emit URI(_uri, _id);
    }

    function uri(uint _id) public view override returns (string memory) {
        return tokenURI[_id];
    }

    function checkERC721Balance(address owner) public view returns (uint256) {
        IERC721 erc721 = IERC721(d3NftAddress);
        return erc721.balanceOf(owner);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
