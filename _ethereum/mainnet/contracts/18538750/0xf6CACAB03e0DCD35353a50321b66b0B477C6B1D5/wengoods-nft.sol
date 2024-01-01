// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./ERC721AUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";

contract WengoodsNFT is ERC721AUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    uint256 public mintingPrice;
    uint256 public constant MAX_SUPPLY = 13332;
    string public _baseURL;
    address payable public treasuryWallet;

    function initialize(uint256 _mintingPrice, address _treasuryWallet, string memory baseUrl) initializerERC721A initializer public {
        __ERC721A_init('Wengoods - Mission G.O.R.G', 'WEN');
        __Ownable_init(_msgSender());
        mintingPrice =  _mintingPrice;
        treasuryWallet = payable(_treasuryWallet);
        _baseURL = baseUrl;
    }

    function setTreasuryWallet(address wallet) external onlyOwner {
        treasuryWallet = payable(wallet);
    }

    function setPresalePrice(uint256 newPrice) external onlyOwner {
        mintingPrice = newPrice;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseURL = newBaseURI;
    }

    function buyPresale(uint256 numberOfTokens) external payable whenNotPaused {
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(mintingPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _mint(msg.sender, numberOfTokens);
        (bool success, ) = treasuryWallet.call{value: msg.value}("");
        require(success, "Transfer failed");
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalMinted();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}