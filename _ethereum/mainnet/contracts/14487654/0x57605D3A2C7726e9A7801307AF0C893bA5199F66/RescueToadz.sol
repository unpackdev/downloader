/* SPDX-License-Identifier: MIT

  @**********@   @***********   @***********   @***********   #***@   @***(   ***********      @**********#   @***********   @***********   @*******@      .***********
  @***@@@@***@   @***@@@@@@@@   @***@@@@@@@@   @***@@@@@@@@   #***@   @***(   ****@@@@@@@      @@@@****@@@@   @***@@@@****   @***@@@@****   @***@@@@@@@@   .@@@@@@@%***
  @***    ***@   @***@          @***@          @***@          #***@   @***(   ****                 ****       @***@   ****   @***@   ****   @***@   (***           @***
  @*******       @*******       @***********   @***@          #***@   @***(   *******@             ****       @***@   ****   @***********   @***@   (***       %***@   
  @***@@@@@@@@   @***@@@@       @@@@@@@@****   @***@          #***@   @***(   ****@@@@             ****       @***@   ****   @***@@@@****   @***@   (***   .@@@@@@@@   
  @***    ***@   @***@                  ****   @***@          #***@   @***(   ****                 ****       @***@   ****   @***@   ****   @***@   (***   .***&       
  @***    ***@   @***********   @***********   @***********   #***********(   ***********          ****       @***********   @***@   ****   @*******@      .***********
  @@@@    @@@@   @@@@@@@@@@@@   @@@@@@@@@@@@   @@@@@@@@@@@@   #@@@@@@@@@@@(   @@@@@@@@@@@          @@@@       @@@@@@@@@@@@   @@@@@   @@@@   @@@@@@@@@      .@@@@@@@@@@@

*/

/**
 *   @title Rescue Toadz
 *   @author Vladimir Haltakov (@haltakov)
 *   @notice ERC1155 contract for a collection of Ukrainian themed Rescue Toadz
 *   @notice All proceeds from minting and capturing tokens are donated for humanitarian help for Ukraine via Unchain (0x10E1439455BD2624878b243819E31CfEE9eb721C).
 *   @notice The contract represents two types of tokens: single edition tokens (id <= SINGLE_EDITIONS_SUPPLY) and multiple edition POAP tokens (id > SINGLE_EDITIONS_SUPPLY)
 *   @notice Only the single edition tokens are allowed to be minted or captured.
 *   @notice The contract implements a special function capture, that allows anybody to transfer a single edition token to their wallet by matching or increasing the last donation.
 */

pragma solidity ^0.8.12;

import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract RescueToadz is ERC1155, Ownable, Pausable, ERC1155Supply {
    using Strings for uint256;

    // Number of single edition tokens. For each single edition token, there will be a corresponding multiple edition token.
    uint256 public constant SINGLE_EDITIONS_SUPPLY = 18;

    // Mint price
    uint256 public constant MINT_PRICE = 10000000 gwei;

    // Address of Unchain Ukraine where all funds will be donated for humanitarian help (see https://unchain.fund/ for details)
    address public constant CHARITY_ADDRESS =
        0x10E1439455BD2624878b243819E31CfEE9eb721C;

    // The last price a token was minted or captured for
    mapping(uint256 => uint256) private _lastPrice;

    // The last owner of a token. This applies only for single edition tokens
    mapping(uint256 => address) private _ownerOf;

    /**
     * @dev Default constructor
     */
    constructor()
        ERC1155("ipfs://QmXRvBcDGpGYVKa7DpshY4UJQrSHH4ArN2AotHHjDS3BHo/")
    {}

    /**
     * @dev Name of the token
     */
    function name() external pure returns (string memory) {
        return "Rescue Toadz";
    }

    /**
     * @notice Only allowed for tokens with id <= SINGLE_EDITIONS_SUPPLY
     * @notice Only one token for every id <= SINGLE_EDITIONS_SUPPLY is allowed to be minted (similar to an ERC721 token)
     * @dev Mint a token
     * @param tokenId id of the token to be minted
     */
    function mint(uint256 tokenId) external payable whenNotPaused {
        require(
            tokenId <= SINGLE_EDITIONS_SUPPLY,
            "Cannot mint token with id greater than SINGLE_EDITIONS_SUPPLY"
        );
        require(tokenId > 0, "Cannot mint token 0");
        require(!exists(tokenId), "Token already minted");
        require(msg.value >= MINT_PRICE, "Not enough funds to mint token");

        _ownerOf[tokenId] = msg.sender;
        _lastPrice[tokenId] = msg.value;
        _mint(msg.sender, tokenId, 1, "");

        (bool sent, ) = payable(CHARITY_ADDRESS).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @notice Only allowed for tokens with id <= SINGLE_EDITIONS_SUPPLY
     * @notice This function allows transferring a token from another wallet by paying more than the last price paid
     * @notice This function will mint a POAP token (id > SINGLE_EDITIONS_SUPPLY) in the wallet from which the token is captured
     * @dev Capture a token from another wallet
     * @param tokenId id of the token to be captured
     */
    function capture(uint256 tokenId) external payable whenNotPaused {
        require(
            tokenId <= SINGLE_EDITIONS_SUPPLY,
            "Cannot capture a token with id greater than SINGLE_EDITIONS_SUPPLY"
        );
        require(exists(tokenId), "Cannot capture a token that is not minted");
        require(
            msg.value >= _lastPrice[tokenId],
            "Cannot capture a token without paying at least the last price"
        );

        address lastOwner = _ownerOf[tokenId];
        _ownerOf[tokenId] = msg.sender;
        _lastPrice[tokenId] = msg.value;

        _safeTransferFrom(lastOwner, msg.sender, tokenId, 1, "");
        _mint(lastOwner, SINGLE_EDITIONS_SUPPLY + tokenId, 1, "");

        (bool sent, ) = payable(CHARITY_ADDRESS).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @notice Only allowed for tokens with id <= SINGLE_EDITIONS_SUPPLY
     * @dev Get the last price a token was minted or captured
     * @param tokenId id of the token to check
     */
    function lastPrice(uint256 tokenId) external view returns (uint256) {
        require(
            tokenId <= SINGLE_EDITIONS_SUPPLY,
            "Cannot get the last price of a token with id greater than SINGLE_EDITIONS_SUPPLY"
        );
        if (!exists(tokenId)) {
            return 0;
        }

        return _lastPrice[tokenId];
    }

    /**
     * @notice Only allowed for tokens with id <= SINGLE_EDITIONS_SUPPLY, because they are guaranteed to have a single edition
     * @dev Get the owner of a token with an id <= SINGLE_EDITIONS_SUPPLY
     * @param tokenId id of the token to get the owner of
     */
    function ownerOf(uint256 tokenId) external view returns (address) {
        require(
            tokenId <= SINGLE_EDITIONS_SUPPLY,
            "Cannot get the owner for token with id greater than SINGLE_EDITIONS_SUPPLY"
        );

        if (!exists(tokenId)) {
            return address(0);
        }

        return _ownerOf[tokenId];
    }

    /**
     * @notice Override the setApprovalForAll function to prevent selling the NFT on exchanges
     */
    function setApprovalForAll(address, bool) public virtual override {
        revert("setApprovalForAll is not supported");
    }

    /**
     * @dev Get the URI of a token
     * @param tokenId id of the token
     */
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(exists(tokenId), "URI query for nonexistent token");

        string memory baseURI = super.uri(tokenId);
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
     * @dev Change the base URI
     * @param newuri the new URI
     */
    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    /**
     * @dev Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
