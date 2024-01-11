// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./Initializable.sol";
import "./ECDSAUpgradeable.sol";
import "./IERC20.sol";

contract BaoyueVase is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable
{
    uint256 public price;
    address private signerAddress;

    using ECDSAUpgradeable for bytes32;

    uint256 public maxSupply;
    uint256 public constant id = 1;

    string public name;
    string public symbol;

    IERC20 public payment_token;
    uint256 public amount_collected;

    bool public isPublicSaleActive;
    uint256 public maxPerMint;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 _maxSupply,
        string memory _name,
        string memory _symbol,
        IERC20 _payment_token
    ) public initializer {
        __ERC1155_init("ipfs://QmTMqvE4ELfyZMzSBENZpGFupRPpQS5GqW49juSvLWs3ge");
        __Ownable_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();

        price = 10000000000;
        signerAddress = 0x933Fb2676FF19128C82e9cFb9F80aD83FF04c2D7;

        maxSupply = _maxSupply;

        name = _name;
        symbol = _symbol;

        payment_token = _payment_token;

        isPublicSaleActive = false;

        maxPerMint = 10;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setPublicSaleActive(bool _isPublicSaleActive) public onlyOwner {
        require(
            isPublicSaleActive != _isPublicSaleActive,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        isPublicSaleActive = _isPublicSaleActive;
    }

    // For public mint only
    function setMaxPerMint(uint256 _maxPerMint) public onlyOwner {
        require(maxPerMint != _maxPerMint, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        maxPerMint = _maxPerMint;
    }

    function whitelistMint(
        bytes32 messageHash,
        bytes calldata signature,
        uint256 quantity,
        uint256 maximumAllowedMints,
        bytes memory data
    ) external {
        require(quantity <= maximumAllowedMints, "MINT_TOO_LARGE");
        require(
            hashMessage(msg.sender, maximumAllowedMints) == messageHash,
            "MESSAGE_INVALID"
        );
        require(
            verifyAddressSigner(messageHash, signature),
            "SIGNATURE_VALIDATION_FAILED"
        );

        uint256 currentSupply = totalSupply(id);
        require(
            currentSupply + quantity <= maxSupply,
            "NOT_ENOUGH_MINTS_AVAILABLE"
        );

        require(
            payment_token.transferFrom(
                msg.sender,
                address(this),
                price * quantity
            ),
            "Transfer failed."
        );
        amount_collected += (price * quantity);

        _mint(msg.sender, id, quantity, data);
    }

    function publicMint(uint256 quantity, bytes memory data) external {
        require(isPublicSaleActive, "PUBLIC_SALE_IS_NOT_ACTIVE");
        require(quantity <= maxPerMint, "MINT_TOO_LARGE");

        uint256 currentSupply = totalSupply(id);
        require(
            currentSupply + quantity <= maxSupply,
            "NOT_ENOUGH_MINTS_AVAILABLE"
        );

        require(
            payment_token.transferFrom(
                msg.sender,
                address(this),
                price * quantity
            ),
            "Transfer failed."
        );
        amount_collected += (price * quantity);

        _mint(msg.sender, id, quantity, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        require(price != _newMintPrice, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        price = _newMintPrice;
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        require(_signerAddress != address(0));
        signerAddress = _signerAddress;
    }

    function verifyAddressSigner(bytes32 messageHash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return
            signerAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

    function hashMessage(address sender, uint256 maximumAllowedMints)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(sender, maximumAllowedMints));
    }

    /**
     * @notice Allow contract owner to withdraw funds to its own account.
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawPaymentToken() external onlyOwner {
        require(
            payment_token.transfer(payable(owner()), amount_collected),
            "Transfer failed."
        );
        amount_collected = 0;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function mintToAddress(
        address toAddress,
        uint256 quantity,
        bytes memory data
    ) external onlyOwner {
        uint256 currentSupply = totalSupply(id);
        require(
            currentSupply + quantity <= maxSupply,
            "NOT_ENOUGH_MINTS_AVAILABLE"
        );

        _mint(toAddress, id, quantity, data);
    }
}
