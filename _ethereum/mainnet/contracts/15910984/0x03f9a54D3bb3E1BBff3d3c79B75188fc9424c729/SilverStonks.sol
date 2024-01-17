// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract SilverStonks is ERC721A, Ownable {
    using SafeMath for uint256;
    uint256 public MAX_TOKENS = 9999;

    // Current price.
    uint256 public CURRENT_PRICE = 110000000000000000;

    // Define if sale is active
    bool public saleIsActive = false;

    // Base URI
    string private baseURI;

    constructor() ERC721A("SilverStonks", "SilverStonks") {}

    /*
     * Pause sale if active, make active if paused
     */
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function setCurrentPrice(uint256 currentPrice) public onlyOwner {
        CURRENT_PRICE = currentPrice;
    }

    /*
     * Set max tokens
     */
    function setMaxTokens(uint256 maxTokens) public onlyOwner {
        MAX_TOKENS = maxTokens;
    }

    /**
     * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
     */
    function setBaseURI(string memory BaseURI) public onlyOwner {
        baseURI = BaseURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Reserve tokens
     */
    function reserveTokens(uint256 quantity) public onlyOwner {
        require(
            totalSupply().add(quantity) <= MAX_TOKENS,
            "Purchase would exceed max supply of SilverStonks"
        );
        _mint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable {
        require(saleIsActive, "Mint is not available right now");
        require(
            CURRENT_PRICE.mul(quantity) <= msg.value,
            "Value sent is not correct"
        );
        require(
            totalSupply().add(quantity) <= MAX_TOKENS,
            "Purchase would exceed max supply of SilverStonks"
        );
        _mint(msg.sender, quantity);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
