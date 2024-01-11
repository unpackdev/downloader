//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./PaymentSplitter.sol";
import "./SafeMath.sol";

contract NFT is ERC721A, Ownable, Pausable, PaymentSplitter {
    using SafeMath for uint256;

    uint256 public constant maxSupply = 333;
    uint256 public constant max = 30;
    uint256 public price = 0.0088 ether;

    string public baseTokenURI;

    uint256[] private _shares = [65, 35];
    address[] private _shareholders = [
        0xB284b81a3B41cD87D8d5999e296b5441b434e08e,
        0xbA62693ccf70Af6d99106cE5a05F504cC74010B0
    ];

    constructor()
        ERC721A("Banana", "BANA")
        PaymentSplitter(_shareholders, _shares)
    {}

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    modifier enoughSupply(uint256 _amount) {
        require(
            _totalMinted().add(_amount) <= maxSupply,
            "Minting would exceed max supply"
        );
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        for (uint256 sh; sh < _shareholders.length; sh++) {
            address payable wallet = payable(_shareholders[sh]);
            release(wallet);
        }
    }

    function mint(uint256 _amount)
        external
        payable
        whenNotPaused
        enoughSupply(_amount)
    {
        require(msg.value >= price.mul(_amount), "Not enough ETH");
        require(
            _numberMinted(msg.sender).add(_amount) <= max,
            "Minting would exceed address allowance"
        );
        _safeMint(msg.sender, _amount);
    }

    function teamMint(uint256 _amount)
        external
        onlyOwner
        enoughSupply(_amount)
    {
        _safeMint(msg.sender, _amount);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        price = _mintPrice;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}
