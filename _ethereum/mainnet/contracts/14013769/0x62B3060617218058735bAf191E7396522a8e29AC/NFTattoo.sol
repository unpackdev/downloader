// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract nftattoo is ERC721, Ownable {
    bool public isActive = true;
    string private _baseURIextended;
    uint16 private totalSupply_ = 0;
    uint16 private nbFreeMint = 0;
    address payable public immutable shareholderAddress;
    uint16[] private forbiddenPixels;

    mapping(uint16 => uint16) idToPixel;
    mapping(address => uint16[]) ownerToPixel;
    uint16[] lstSold;

    constructor(address payable shareholderAddress_)
        ERC721("The Non-Fungible Tattoo", "PIXEL")
    {
        require(shareholderAddress_ != address(0));
        shareholderAddress = shareholderAddress_;
        _baseURIextended = "ipfs://";

        totalSupply_ = 1;
        _safeMint(shareholderAddress_, 0);

        forbiddenPixels.push(271);
        forbiddenPixels.push(272);
        forbiddenPixels.push(273);
        forbiddenPixels.push(331);
        forbiddenPixels.push(332);
        forbiddenPixels.push(333);
        forbiddenPixels.push(391);
        forbiddenPixels.push(392);
        forbiddenPixels.push(393);
        forbiddenPixels.push(106);
        forbiddenPixels.push(107);
        forbiddenPixels.push(740);
        forbiddenPixels.push(741);
        forbiddenPixels.push(800);
        forbiddenPixels.push(801);
        forbiddenPixels.push(1542);
        forbiddenPixels.push(1602);
        forbiddenPixels.push(1945);
        forbiddenPixels.push(1946);
        forbiddenPixels.push(1947);
        forbiddenPixels.push(2005);
        forbiddenPixels.push(2006);
        forbiddenPixels.push(2007);
        forbiddenPixels.push(2881);
        forbiddenPixels.push(2882);
        forbiddenPixels.push(2941);
        forbiddenPixels.push(2942);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function totalSupply() public view returns (uint16) {
        return totalSupply_;
    }

    function setNbFree(uint16 nbFree) external onlyOwner {
        nbFreeMint = nbFree;
    }

    function setSaleState(bool newState) public onlyOwner {
        isActive = newState;
    }

    function mint(uint16[] memory pixels) public payable {
        require(isActive, "Sale must be active to mint pixels");
        require(
            totalSupply_ + pixels.length <= 4774,
            "Purchase would exceed max supply of tokens"
        );
        require(
            0.069 ether * pixels.length <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint16 i = 0; i < pixels.length; i++) {
            for (uint8 j = 0; j < forbiddenPixels.length; j++) {
                require(pixels[i] != forbiddenPixels[j], "This pixel is not for sale!");
            }
            uint16 mintIndex = totalSupply_ + 1;
            if (totalSupply_ < 4774) {
                idToPixel[mintIndex] = pixels[i];
                ownerToPixel[msg.sender].push(pixels[i]);
                lstSold.push(pixels[i]);
                totalSupply_ = totalSupply_ + 1;
                _safeMint(msg.sender, pixels[i]);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(shareholderAddress, balance);
    }

    function soldPixels() public view returns (uint16[] memory) {
        return lstSold;
    }

    function owned(address ownerAddress) public view returns (uint16[] memory) {
        return ownerToPixel[ownerAddress];
    }
}
