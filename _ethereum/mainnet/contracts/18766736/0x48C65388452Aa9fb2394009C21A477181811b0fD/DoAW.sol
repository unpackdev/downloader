//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Metadata.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/*
------------------------------------------------------------------------------------------
  ████████                    ████████    ██        ██ 
  ██      ██      ██████    ██        ██  ██        ██ 
  ██        ██  ██      ██  ██        ██  ██        ██ 
  ██        ██  ██      ██  ████████████  ██        ██ 
  ██      ██    ██      ██  ██        ██  ██  ████  ██ 
  ████████        ██████    ██        ██    ██    ██  



██        ████████████████████        ████  ████████  ██
██  ██████  ██████      ████  ████████  ██  ████████  ██
██  ████████  ██  ██████  ██  ████████  ██  ████████  ██
██  ████████  ██  ██████  ██            ██  ████████  ██
██  ██████  ████  ██████  ██  ████████  ██  ██    ██  ██
██        ████████      ████  ████████  ████  ████  ████
------------------------------------------------------------------------------------------

DoAW
By Joan Heemskerk
Presented by Folia.app
*/

/// @title DoAW
/// @notice https://doaw.folia.app
/// @author @okwme
/// @dev ERC721Enumerable contract for DoAW. External upgradeable metadata.

contract DoAW is ERC721Enumerable, Ownable, ERC2981, ReentrancyGuard {
    bool public paused = false;
    uint256 public constant MAX_SUPPLY = 1024;
    uint256 public price = 0.055555555555555555 ether;
    address public metadata;
    address public splitter;
    uint256 public startdate = 1702404000; // Tue Dec 12 2023 18:00:00 GMT+0000 (7pm CEST Berlin, 6pm London, 1pm NYC, 10am LA)

    event EthMoved(
        address indexed to,
        bool indexed success,
        bytes returnData,
        uint256 amount
    );

    constructor(address metadata_, address splitter_) ERC721("DoAW", "DoAW") {
        metadata = metadata_;
        splitter = splitter_; // splitter doesn't need to be checked because it's checked in _setDefaultRoyalty
        _setDefaultRoyalty(splitter, 850); // 8.5%
    }

    /// @dev Allows minting by sending directly to the contract.
    fallback() external payable {
        mint();
    }

    /// @dev Allows minting by sending directly to the contract.
    receive() external payable {
        mint();
    }

    /**
     * @dev Converts a uint256 value to a bytes32 value.
     * @param entropy The uint256 value to be converted.
     * @return result the bytes32 value representing the converted uint256 value.
     */
    function uintToHexUtil(
        uint256 entropy
    ) public pure returns (bytes32 result) {
        return bytes32(entropy);
    }

    /**
     * @dev Converts a bytes32 value to a uint256 value.
     * @param entropy The bytes32 value to be converted.
     * @return result The uint256 value representing the converted bytes32 value.
     */
    function hexToUintUtil(
        bytes32 entropy
    ) public pure returns (uint256 result) {
        return uint256(entropy);
    }

    /// @dev overwrites the tokenURI function from ERC721
    /// @param id the id of the NFT
    /// @return string the URI of the NFT
    function tokenURI(
        uint256 id
    ) public view override(ERC721) returns (string memory) {
        return Metadata(metadata).getMetadata(id);
    }

    /// @dev mint token with default settings
    function mint() public payable {
        mint(msg.sender, 1);
    }

    /// @dev mint tokens with recipient as parameter
    /// @param recipient the recipient of tokens to mint
    function mint(address recipient) public payable {
        mint(recipient, 1);
    }

    /// @dev mint tokens with quantity as parameter
    /// @param quantity the quantity of tokens to mint
    function mint(uint256 quantity) public payable {
        mint(msg.sender, quantity);
    }

    /// @dev mint tokens with rcipient and quantity as parameters
    /// @param recipient the recipient of the NFT
    /// @param quantity the quantity of tokens to mint
    function mint(address recipient, uint256 quantity) public payable {
        require(!paused && block.timestamp >= startdate, "PAUSED");
        internalMint(recipient, quantity, makeEntropy(quantity));
    }

    /**
     * @dev Generates an array of random numbers based on the given quantity.
     * @param quantity The number of random numbers to generate.
     * @return entropy An array of random numbers.
     */
    function makeEntropy(
        uint256 quantity
    ) public view returns (uint256[] memory entropy) {
        entropy = new uint256[](quantity); // Initialize the entropy array with the specified quantity
        for (uint i = 0; i < quantity; i++) {
            entropy[i] = uint256(
                uint128(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                block.timestamp,
                                block.difficulty,
                                msg.sender,
                                i
                            )
                        )
                    )
                )
            );
        }
        return entropy;
    }

    /**
     * @dev Mint new tokens and distribute them to the specified recipient.
     * @param recipient The address of the recipient to receive the minted tokens.
     * @param quantity The number of tokens to mint.
     * @param entropy An array of entropy values used for minting.
     * @notice This function can only be called when the contract is not paused and after the start date.
     */
    function mint(
        address recipient,
        uint256 quantity,
        uint256[] memory entropy
    ) public payable {
        require(!paused && block.timestamp >= startdate, "PAUSED");
        internalMint(recipient, quantity, entropy);
    }

    /**
     * @dev Mint new tokens with a single entropy value and distribute them to the specified recipient.
     * @param recipient The address of the recipient to receive the minted tokens.
     * @param entropy The entropy value used for minting.
     * @notice This function can only be called when the contract is not paused and after the start date.
     */
    function mintWithEntropy(
        address recipient,
        uint256 entropy
    ) public payable {
        uint256[] memory entropyArray = new uint256[](1);
        entropyArray[0] = entropy;
        mint(recipient, 1, entropyArray);
    }

    /// @dev mint tokens with rcipient and quantity as parameters
    /// @param recipient the recipient of the NFT
    /// @param quantity the quantity of tokens to mint
    function internalMint(
        address recipient,
        uint256 quantity,
        uint256[] memory entropy
    ) internal nonReentrant {
        require(msg.value >= price * quantity, "WRONG PRICE");
        require(
            entropy.length == quantity,
            "ENTROPY LENGTH DOESN'T MATCH QUANTITY"
        );
        require(
            quantity == 1 || quantity == 3 || quantity == 5,
            "CAN'T MINT BESIDES QUANTITY OF 1, 3 OR 5"
        );
        if (totalSupply() + quantity > MAX_SUPPLY) {
            quantity = MAX_SUPPLY - totalSupply(); // This will throw an error if the amount is negative
            if (quantity == 0) {
                revert("MAX SUPPLY REACHED");
            }
        }
        uint256 payment = quantity * price;
        (bool sent, bytes memory data) = splitter.call{value: payment}("");
        emit EthMoved(splitter, sent, data, payment);
        for (uint i = 0; i < quantity; i++) {
            // ensures the entropy is only 16 bytes long
            _safeMint(
                recipient,
                entropy[i] & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            );
        }
        // call this after _safeMint so totalSupply updates before a re-entry mintcould be called
        // UPDATE: re-entry no longer possible with reentrancy guard
        if (payment < msg.value) {
            (sent, data) = msg.sender.call{value: msg.value - payment}("");
            emit EthMoved(msg.sender, sent, data, msg.value - payment);
        }
    }

    /// @dev only the owner can mint without paying
    /// @param recipient the recipient of the NFT
    /// @param quantity the quantity of tokens to mint
    function adminMint(
        address recipient,
        uint256 quantity,
        uint256[] memory entropy
    ) public payable onlyOwner {
        (bool sent, bytes memory data) = splitter.call{value: msg.value}("");
        emit EthMoved(splitter, sent, data, msg.value);
        for (uint i = 0; i < quantity; i++) {
            _safeMint(recipient, entropy[i]);
        }
    }

    function adminMint(
        address recipient,
        uint256 quantity
    ) public payable onlyOwner {
        adminMint(recipient, quantity, makeEntropy(quantity));
    }

    /// @dev set the metadata address as called by the owner
    /// @param metadata_ the address of the metadata contract
    function setMetadata(address metadata_) public onlyOwner {
        require(metadata_ != address(0), "NO ZERO ADDRESS");
        metadata = metadata_;
    }

    /// @dev only the owner can set the splitter address
    /// @param splitter_ the address of the splitter
    function setSplitter(address splitter_) public onlyOwner {
        require(splitter_ != address(0), "NO ZERO ADDRESS");
        splitter = splitter_;
    }

    /// @dev only the owner can set the price
    /// @param price_ the price of the NFT
    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    /// @dev only the owner can set the contract paused
    /// @param paused_ whether the contract is paused
    function setPause(bool paused_) public onlyOwner {
        paused = paused_;
    }

    /// @dev only the owner can set the startdate
    /// @param startdate_ the startdate of the mint event
    function setStartdate(uint256 startdate_) public onlyOwner {
        startdate = startdate_;
    }

    /// @dev set the royalty percentage as called by the owner
    /// @param royaltyReceiver the address of the royalty receiver
    /// @param royaltyPercentage the percentage of the royalty
    function setRoyaltyPercentage(
        address royaltyReceiver,
        uint96 royaltyPercentage
    ) public onlyOwner {
        _setDefaultRoyalty(royaltyReceiver, royaltyPercentage);
    }

    /**
     * @dev If mint fails to send ETH to splitter, admin can recover the payment.
     * This function is an extra precaution in case the split function breaks due to a hardfork.
     * @param _to The address to which the recovered ETH should be sent.
     */
    function recoverUnsuccessfulMintPayment(
        address payable _to
    ) public onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, bytes memory data) = _to.call{value: amount}("");
        emit EthMoved(_to, sent, data, amount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    /// @dev set the royalty percentage as called by the owner
    /// @param interfaceId the interface id
    /// @return bool whether the interface is supported
    /// @notice ERC2981, ERC721A, IERC721A are overridden to support multiple interfaces
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC2981, ERC721Enumerable) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
