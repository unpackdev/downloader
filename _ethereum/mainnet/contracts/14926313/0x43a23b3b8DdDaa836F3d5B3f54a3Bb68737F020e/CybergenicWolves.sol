// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./Ownable.sol";
import "./ERC721.sol";

contract CybergenicWolves is ERC721, Ownable {
    using Strings for uint256;
    string public baseURI;
    uint256 public price = 0.05 ether;
    uint256 public totalClones = 5000;
    uint256 public nftPerWhitelistedLimit = 10;
    bool public paused = true;
    uint256 public _supplyCounter = 0;
    bool public onlyWhitelisted = true;
    address[] public LabWhitelistAddresses;

    constructor() ERC721("Cybergenic Wolves Lab", "WOFE") {}

    function cloneWolf(uint256 _num) external payable {
        require(paused == false, "Lab closed");
        require(_num > 0, "Clone atleast 1 Wolf");
        require(_num <= 20, "Clone amount per production exceeded");
        require(
            _supplyCounter + _num <= totalClones,
            "total Clones limit exceeded"
        );

        if (onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "user is not LabWhitelisted");
            uint256 ownerMintedCount = balanceOf(msg.sender);
            require(
                ownerMintedCount + _num <= nftPerWhitelistedLimit,
                "max clones per Labwhitelisted exceeded"
            );
        }
        require(msg.value >= price * _num, "insufficient funds");

        for (uint256 i = 1; i <= _num; i++) {
            uint256 id = _supplyCounter + 1;
            _safeMint(msg.sender, id);
            _supplyCounter++;
        }
    }

    function LabGiveAway(uint256 _num, address _to) external onlyOwner {
        require(_num > 0, "mint atleast one ");
        require(
            _supplyCounter + _num <= totalClones,
            "max supply limit exceeded"
        );
        for (uint256 i = 1; i <= _num; i++) {
            uint256 id = _supplyCounter + 1;
            _safeMint(_to, id);
            _supplyCounter++;
        }
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < LabWhitelistAddresses.length; i++) {
            if (LabWhitelistAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function setOnlyWhitelisted(bool _state) external onlyOwner {
        onlyWhitelisted = _state;
    }

    function whitelistUsers(address[] calldata _users) external onlyOwner {
        delete LabWhitelistAddresses;
        LabWhitelistAddresses = _users;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function walletOfAddress(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_owner);
        uint256 counter = 0;
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint256 i = 1; i <= _supplyCounter; i++) {
            if (ownerOf(i) == _owner) {
                tokenIds[counter] = i;
                counter++;
            }
        }
        return tokenIds;
    }

    function withdraw() external payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os, "Withdraw Failed!");
    }
}
