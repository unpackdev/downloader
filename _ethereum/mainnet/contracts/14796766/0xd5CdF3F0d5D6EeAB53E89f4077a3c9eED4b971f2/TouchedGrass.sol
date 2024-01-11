// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ERC721ABurnable.sol";

contract TouchedGrass is Ownable, ERC721A, ERC721ABurnable {

    using Strings for uint256;

    uint256 public price = 0.01 ether;
    uint256 public collectionSize = 1000;
    string private baseTokenURI;
    bool public publicSaleIsActive;
    address withdrawalAddress;

    constructor() ERC721A("Touched Grass", "GRASS") {}

    // Public mint
    function mint() external payable {
        require(
            publicSaleIsActive,
            "Public sale is not active"
        );
        require(
            _getAux(_msgSender()) == 0,
            "You have already minted"
        );
        require(
            msg.value == price,
            "Incorrect ETH value sent"
        );
        require(
            _totalMinted() + 1 <= collectionSize,
            "Exceeds max supply"
        );
        require(
            tx.origin == _msgSender(),
            "Not allowing contracts"
        );

        _setAux(_msgSender(), 1);
        _safeMint(_msgSender(), 1);
    }

    // Owner mint for team & treasury
    function ownerMint(uint256 _amount) external onlyOwner {
        require(
            _totalMinted() == 0,
            "Owner has already minted"
        );

        _safeMint(_msgSender(), _amount);
    }

    //// Override functions
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    //// Administrative functions
    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function flipPublicSaleState() external onlyOwner {
        publicSaleIsActive = !publicSaleIsActive;
    }

    function setWithdrawalAddress(address _address) external onlyOwner {
        withdrawalAddress = _address;
    }

    function withdraw() external onlyOwner {
        require(
            withdrawalAddress != address(0),
            "Withdrawal address must be set"
        );

        payable(withdrawalAddress).transfer(address(this).balance);
    }
}
