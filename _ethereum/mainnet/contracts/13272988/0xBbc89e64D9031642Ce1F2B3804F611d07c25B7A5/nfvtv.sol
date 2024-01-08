//SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.6;

import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Strings.sol";
import "./hasSecondarySalesFee.sol";
interface iNftvClub {

    function price() external returns (uint256);

    function remainingAmount() external returns (uint256);

    function promoMint(uint256 amount) external;

    function buy(uint256 amount) external payable;

    function withdrawETH() external;

    function switchSaleOn() external;

    function switchSaleOff() external;

    function turnChannelsOn() external;

    function turnChannelsOff() external;

}

contract NftvClub is iNftvClub, ERC721Burnable, HasSecondarySaleFees, Ownable {

    using Strings for uint256;

    bool private _isOnSale;
    bool private _turnChannelsOn;
    string private baseURI;
    string private hiddenURI;
    uint256 private constant NFT_SUPPLY_AMOUNT = 10000;
    uint256 public nextTokenId;
    uint256 private _price = 0.03 ether;
    address payable[1] royaltyRecipient;

    constructor(
        string memory initialBaseURI,
        string memory initialHiddenURI,
        address payable[1] memory _royaltyRecipient
    )
    ERC721("NftvClub", "NFTV")
    HasSecondarySaleFees(new address payable[](0), new uint256[](0))
    {
        require(_royaltyRecipient[0] != address(0), "Invalid address");

        baseURI = initialBaseURI;
        hiddenURI = initialHiddenURI;
        royaltyRecipient = _royaltyRecipient;

        _isOnSale = false;
        _turnChannelsOn = false;

        address payable[] memory thisAddressInArray = new address payable[](1);
        thisAddressInArray[0] = payable(address(this));
        uint256[] memory royaltyWithTwoDecimals = new uint256[](1);
        royaltyWithTwoDecimals[0] = 1000;
        _setCommonRoyalties(thisAddressInArray, royaltyWithTwoDecimals);
    }

    function price() external override view returns (uint256) {
        return _price;
    }

    function remainingAmount() external override view returns (uint256) {
        return NFT_SUPPLY_AMOUNT - nextTokenId;
    }

    function promoMint(uint256 amount) external override onlyOwner {
        require(!_isOnSale, "On sale");
        require(nextTokenId < 1000, "All tokens for promotion are minted");

        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, nextTokenId++);
        }
    }

    function buy(uint256 amount) external payable override {
        require(_isOnSale, "Not on sale");
        require(0 != amount, "Incorrect amount");
        require(msg.value >= amount * _price, "Incorrect value");
        require(amount < 21, "Exceeded Mint Amount");

        require(nextTokenId + amount <= NFT_SUPPLY_AMOUNT, "No remaining tokens");
        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, nextTokenId++);
        }
    }

    function withdrawETH() external override {
        uint256 royalty = address(this).balance;

        Address.sendValue(payable(royaltyRecipient[0]), royalty);
    }

    function switchSaleOn() external override onlyOwner {
        _isOnSale = true;
    }

    function switchSaleOff() external override onlyOwner {
        _isOnSale = false;
    }
    
    function turnChannelsOn() external override onlyOwner {
        _turnChannelsOn = true;
    }

    function turnChannelsOff() external override onlyOwner {
        _turnChannelsOn = false;
    }

    function updateBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function updateHiddenURI(string calldata newHiddenURI) external onlyOwner {
        hiddenURI = newHiddenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(!_turnChannelsOn) {
            return string(abi.encodePacked(hiddenURI, ".json"));
        }

        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    receive() external payable {}

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, HasSecondarySaleFees)
    returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) ||
        HasSecondarySaleFees.supportsInterface(interfaceId);
    }
}
