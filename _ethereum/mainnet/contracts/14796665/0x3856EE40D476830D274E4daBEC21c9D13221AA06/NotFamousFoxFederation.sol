// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

//  _   _       _   ______                              ______        ______       _                _   _
// | \ | |     | | |  ____|                            |  ____|      |  ____|     | |              | | (_)
// |  \| | ___ | |_| |__ __ _ _ __ ___   ___  _   _ ___| |__ _____  _| |__ ___  __| | ___ _ __ __ _| |_ _  ___  _ __
// | . ` |/ _ \| __|  __/ _` | '_ ` _ \ / _ \| | | / __|  __/ _ \ \/ /  __/ _ \/ _` |/ _ \ '__/ _` | __| |/ _ \| '_ \
// | |\  | (_) | |_| | | (_| | | | | | | (_) | |_| \__ \ | | (_) >  <| | |  __/ (_| |  __/ | | (_| | |_| | (_) | | | |
// |_| \_|\___/ \__|_|  \__,_|_| |_| |_|\___/ \__,_|___/_|  \___/_/\_\_|  \___|\__,_|\___|_|  \__,_|\__|_|\___/|_| |_|
//
// smart contract.

contract NotFamousFoxFederation is ERC721A, Ownable, ReentrancyGuard {
    string public baseURI;
    string public fileExtension = ".json";
    uint256 public maxMint = 10;
    uint256 public maxMintFree = 1;
    uint256 public maxSupply = 5555;
    uint256 public price = 0.01 ether;
    bool public mintActive;

    constructor() ERC721A("NotFamousFoxFederation", "NFFF") {}

    function mint(uint256 _amount) external payable {
        require(mintActive, "Mint is inactive.");
        require(
            totalSupply() + _amount <= maxSupply,
            "Mint exceeds max supply."
        );
        require(_msgSender() == tx.origin, "Contracts are disabled.");
        require(_amount <= maxMint, "Mint exceeds max mint.");
        require(_amount > 0, "Mint amount can not be below 0.");
        require(msg.value == _amount * price, "Insufficient value.");

        _safeMint(_msgSender(), _amount);
    }

    function freeMint() external payable {
        require(mintActive, "Mint is inactive.");
        require(totalSupply() + 1 <= maxSupply, "Mint exceeds max supply.");
        require(_msgSender() == tx.origin, "Contracts are disabled.");
        require(
            uint256(_getAux(_msgSender())) + 1 <= maxMintFree,
            "Mint exceeds max free mint."
        );

        _setAux(_msgSender(), 1);
        _safeMint(_msgSender(), 1);
    }

    function toggleMintActive() external onlyOwner {
        mintActive = !mintActive;
    }

    function numMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxMint(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    function setMaxMintFree(uint256 _maxMintFree) external onlyOwner {
        maxMintFree = _maxMintFree;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Balance withdrawl unsuccessful.");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist.");
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(_tokenId),
                        fileExtension
                    )
                )
                : "";
    }
}
