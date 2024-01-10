// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";

interface IPassport1155 {
    function burn(
        address _address,
        uint256 _tokenId,
        uint256 _count
    ) external;

    function availableMint() external view returns (uint256);

    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract StrawhatzNFT is ERC721, Ownable, Pausable {
    address public secondAdmin;

    string public baseURI;
    IPassport1155 public mintPassContract;

    uint256 public index = 0;
    uint256 public PRICE_PER_NFT = 0.2 ether;
    uint256 public PRICE_PER_NFT_SPECIAL = 0.123 ether;

    bool public DIRECT_BUY_AVAILABLE = false;
    bool public DIRECT_BUY_SPECIAL_PRICE_AVAILABLE = false;

    mapping(address => uint256) public whitelist;

    constructor(address contractAddress, string memory newBaseURI) ERC721("Strawhatz", "STRAWHATZ") {
        mintPassContract = IPassport1155(contractAddress);
        baseURI = newBaseURI;
    }

    function exchange(uint256 tokenId, uint256 count) external whenNotPaused returns (uint256 oldIndex) {
        require(mintPassContract.balanceOf(msg.sender, tokenId) >= count, "Not enough mintpasses");
        mintPassContract.burn(msg.sender, tokenId, count);
        return finishPayment(count);
    }

    function buy(uint256 count) external whenNotPaused payable returns (uint256 oldIndex) {
        require(DIRECT_BUY_AVAILABLE, "Direct buy not yet available");
        require(msg.value == PRICE_PER_NFT * count, "Wrong value");
        require(count <= availableMint(), "Not enough tokens left");

        return finishPayment(count);
    }

    function buyForSpecialPrice(uint256 count) external whenNotPaused payable returns (uint256 oldIndex) {
        require(DIRECT_BUY_SPECIAL_PRICE_AVAILABLE, "Direct buy special price not yet available");
        require(whitelist[msg.sender] >= 0 + count, "Not in whitelist or used up amount");
        require(msg.value == PRICE_PER_NFT_SPECIAL * count, "Wrong value");
        require(count <= availableMint(), "Not enough tokens left");

        whitelist[msg.sender] -= count;

        return finishPayment(count);
    }

    function finishPayment(uint256 count) internal returns (uint256 oldIndex) {
        oldIndex = index;
        index += count;

        for (uint256 i = oldIndex; i < index; i++) {
            _safeMint(msg.sender, i);
        }
    }

    function setDirectBuy(bool _value) external onlyOwner {
        DIRECT_BUY_AVAILABLE = _value;
    }

    function setSpecialPriceDirectBuy(bool _value) external onlyOwner {
        DIRECT_BUY_SPECIAL_PRICE_AVAILABLE = _value;
    }

    function setPricePerNFT(uint256 _newPrice) external onlyOwner {
        PRICE_PER_NFT = _newPrice;
    }

    function setPriceSpecialPerNFT(uint256 _newPrice) external onlyOwner {
        PRICE_PER_NFT_SPECIAL = _newPrice;
    }

    function addToWhitelistSpecial(address[] memory _addrs, uint256 _amount) external {
        require(msg.sender == owner() || msg.sender == secondAdmin, "Only admins can add to whitelist");

        for (uint256 i = 0; i < _addrs.length; i++)
            whitelist[_addrs[i]] = _amount;
    }

    function setMintPassportContract(address contractAddress) external onlyOwner {
        mintPassContract = IPassport1155(contractAddress);
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function availableMint() public view returns (uint256) {
        return mintPassContract.availableMint();
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (id <= index) {
            return string(abi.encodePacked(baseURI, Strings.toString(id)));
        }
        return "";
    }

    function setSecondAdmin(address _admin) external onlyOwner {
        secondAdmin = _admin;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
