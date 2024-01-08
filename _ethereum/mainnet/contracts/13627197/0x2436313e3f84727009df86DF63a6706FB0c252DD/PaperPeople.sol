// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title Paper People ERC-721 token contract.
 * @author Josh Stow (https://github.com/jshstw)
 */
contract PaperPeople is ERC721Enumerable, Ownable, Pausable {
    using SafeMath for uint256;
    using Address for address payable;

    uint256 public constant PP_PREMINT = 40;
    uint256 public constant PP_SUPPLY = 8000;
    uint256 public constant PP_SUPPLY_PRE = 1000;
    uint256 public constant PP_PER_TRANS = 10;

    mapping(address => bool) private whitelist;

    string private _baseTokenURI;

    bool public saleLive;
    bool public presaleLive;
    uint256 public PP_PRICE = 0.04 ether;
    uint256 public PP_PRICE_PRE = 0.03 ether;

    constructor(string memory baseTokenURI) ERC721("Paper People", "PP") {
        _baseTokenURI = baseTokenURI;
        //_preMint(PP_PREMINT);
    }

    /**
     * @dev Mints number of tokens specified to wallet.
     * @param quantity uint256 Number of tokens to be minted
     */
    function buy(uint256 quantity) external payable whenNotPaused {
        require(
            !presaleLive,
            "Pape Men: Sale is currently in the presale stage"
        );
        require(saleLive, "Paper Men: Sale is not currently live");
        require(
            totalSupply() <= (PP_SUPPLY - quantity),
            "Paper Men: Quantity exceeds remaining tokens"
        );
        require(
            quantity <= PP_PER_TRANS,
            "Paper Men: Max tokens per transaction exceeded"
        );
        require(
            msg.value >= (quantity * PP_PRICE),
            "Paper Men: Insufficient funds"
        );

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, totalSupply().add(1));
        }
    }

    /**
     * @dev Mints number of tokens specified to wallet during presale.
     * @param quantity uint256 Number of tokens to be minted
     */
    function presaleBuy(uint256 quantity) external payable whenNotPaused {
        require(presaleLive, "Paper Men: Presale not currently live");
        require(!saleLive, "Paper Men: Sale is no longer in the presale stage");
        require(
            whitelist[msg.sender],
            "Paper Men: Caller is not eligible for presale"
        );
        require(
            totalSupply() <= (PP_SUPPLY_PRE - quantity),
            "Paper Men: Quantity exceeds remaining tokens"
        );
        require(
            quantity <= PP_PER_TRANS,
            "Paper Men: Max tokens per transaction exceeded"
        );
        require(
            msg.value >= (quantity * PP_PRICE_PRE),
            "Paper Men: Insufficient funds"
        );

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, totalSupply().add(1));
        }
    }

    /**
     * @dev Checks if wallet address is whitelisted.
     * @param wallet address Ethereum wallet to be checked
     * @return bool Presale eligibility of address
     */
    function isWhitelisted(address wallet) external view returns (bool) {
        return whitelist[wallet];
    }

    /**
     * @dev Add addresses to whitelist.
     * @param wallets address Ethereum wallets to authorise
     */
    function addToWhitelist(address[] calldata wallets) external onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            require(wallet != address(0), "Paper Men: Cannot add zero address");
            require(!whitelist[wallet], "Paper Men: Duplicate address");

            whitelist[wallet] = true;
        }
    }

    /**
     * @dev Remove addresses from whitelist.
     * @param wallets address Ethereum wallets to deauthorise
     */
    function removeFromWhitelist(address[] calldata wallets)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            require(wallet != address(0), "Paper Men: Cannot add zero address");

            whitelist[wallet] = false;
        }
    }

    /**
     * @dev Set base token URI.
     * @param newBaseURI string New URI to set
     */
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /**
     * @dev Returns token URI of token with given tokenId.
     * @param tokenId uint256 Id of token
     * @return string Specific token URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Paper Men: URI query for nonexistent token");
        return
            string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

    /**
     * @dev Toggles status of token presale. Only callable by owner.
     */
    function togglePresale() external onlyOwner {
        presaleLive = !presaleLive;
    }

    /**
     * @dev Toggles status of token sale. Only callable by owner.
     */
    function toggleSale() external onlyOwner {
        saleLive = !saleLive;
    }

    /**
     * @dev Set Pre Sale Price.
     * @param newPreSalePrice uint256 New Pre Sale Price to set
     */
    function setPreSalePrice(uint256 newPreSalePrice) external onlyOwner {
        PP_PRICE_PRE = newPreSalePrice;
    }

    /**
     * @dev Set Sale Price.
     * @param newSalePrice uint256 New Sale Price to set
     */
    function setSalePrice(uint256 newSalePrice) external onlyOwner {
        PP_PRICE = newSalePrice;
    }

    /**
     * @dev Withdraw funds from contract. Only callable by owner.
     */
    function withdraw() public onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }

    /**
     * @dev Pre mint n tokens to owner address.
     * @param n uint256 Number of tokens to be minted
     */
    function _preMint(uint256 n) private {
        //for (uint256 i = 0; i < n; i++) {
        //_safeMint(owner(), totalSupply().add(1));
        //}
    }
}
