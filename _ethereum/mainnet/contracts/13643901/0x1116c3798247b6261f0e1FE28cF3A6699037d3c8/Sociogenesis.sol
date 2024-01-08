// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/*
 *   ____             _                                  _
 *  / ___|  ___   ___(_) ___   __ _  ___ _ __   ___  ___(_)___
 *  \___ \ / _ \ / __| |/ _ \ / _` |/ _ \ '_ \ / _ \/ __| / __|
 *   ___) | (_) | (__| | (_) | (_| |  __/ | | |  __/\__ \ \__ \
 *  |____/ \___/ \___|_|\___/ \__, |\___|_| |_|\___||___/_|___/
 *                            |___/
*/

import "./Ownable.sol";
import "./ERC721.sol";

/**
 * @title Sociogenesis
 * @notice NFT for https://sociogenesis.net/
 * @author Aaron Hanson <coffee.becomes.code@gmail.com>
 */
contract Sociogenesis is ERC721("Sociogenesis", "SGEN"), Ownable {

    /// The token price
    uint256 public constant TOKEN_PRICE = 0.0688 ether;

    /// The maximum token supply
    uint256 public constant MAX_SUPPLY = 2000;

    /// The maximum number of tokens that can be minted in one transaction
    uint256 public constant MAX_MINT_AMOUNT = 200;

    /// The current token supply
    uint256 public totalSupply;

    /// Whether or not the token sale is currently active
    bool public saleIsActive = false;

    /// The base token URI
    string public baseURI = "Not Yet Set";

    /**
     * @notice Emitted when the saleIsActive flag changes
     * @param isActive Indicates whether or not the sale is now active
     */
    event SaleStateChanged(
        bool indexed isActive
    );

    /**
     * @notice Mints tokens
     * @param _mintAmount Number of tokens to mint
     */
    function mint(
        uint256 _mintAmount
    )
        external
        payable
    {
        require(
            saleIsActive == true,
            "Sale must be active"
        );

        require(
            _mintAmount > 0,
            "Need at least 1 token"
        );

        require(
            _mintAmount <= MAX_MINT_AMOUNT,
            "Max 200 at a time"
        );

        unchecked {
            require(
                totalSupply + _mintAmount <= MAX_SUPPLY,
                "Not enough tokens left"
            );

            require(
                msg.value == TOKEN_PRICE * _mintAmount,
                "Ether amount not correct"
            );
        }

        _mintTokens(_mintAmount);
    }

    /**
     * @notice Sets a new base URI
     * @param _newBaseURI The new base URI
     */
    function setBaseURI(
        string memory _newBaseURI
    )
        external
        onlyOwner
    {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Activates or deactivates the sale
     * @param _isActive Whether to activate or deactivate the sale
     */
    function activateSale(
        bool _isActive
    )
        external
        onlyOwner
    {
        saleIsActive = _isActive;

        emit SaleStateChanged(
            _isActive
        );
    }

    /**
     * @notice Withdraws sale proceeds
     * @param _amount Amount to withdraw in wei
     */
    function withdraw(
        uint256 _amount
    )
        external
        onlyOwner
    {
        payable(_msgSender()).transfer(
            _amount
        );
    }

    /**
     * @notice Mints the initial batch of 50 tokens
     */
    function mintInitialBatch()
        external
        onlyOwner
    {
        require(
            totalSupply == 0,
            "Mint has already begun"
        );

        _mintTokens(50);
    }

    /**
     * @dev Base token minting function
     * @param _mintAmount Number of tokens to mint
     */
    function _mintTokens(
        uint256 _mintAmount
    )
        private
    {
        unchecked {
            for (uint256 i = 1; i <= _mintAmount; i++) {
                _safeMint(_msgSender(), totalSupply + i);
            }
            totalSupply += _mintAmount;
        }
    }
}
