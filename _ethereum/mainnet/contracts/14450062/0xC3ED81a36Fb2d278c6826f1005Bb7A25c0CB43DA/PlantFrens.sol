//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSA.sol";

error PublicMintingNotEnabled();
error InvalidEthValue();
error WhitelistMintingNotEnabled();
error WhitelistTierNotEnabled();
error InvalidWhitelistTier();
error DirectMintDisallowed();
error InvalidHash();
error MintingIsEnabled();
error MintExceedsMaxSupply();
error TxOriginNotSender();
error QuantityExceedsMaxPerAddress();
error TransferFailed();

contract PlantFrens is ERC721A, Ownable {

    /*

    ..........      ......              ......          ....     ...    ............
    -%@@@@@@@@@@#:  .+@@@@@@=          :+*@@@@@@*+:     +@@@@@%-  +@@@*::#@@@@@@@@@@@@@+
    #@@@@@@@@@@@@@+ :@@@@@@@@+        :#@@@@@@@@@@+   .@@@@@@@@@%+@@@@@==@@@@@@@@@@@@@@@
    #@@@@@@@@@@@@@@+:@@@@@@@@+        *@@@@@@@@@@@@+  .@@@@@@@@@@@@@@@@==@@@@@@@@@@@@@@@
    #@@@@@@=@@@@@@@*:@@@@@@@@+       +@@@@@@@@@@@@@@+ .@@@@@@@@@@@@@@@@= -##@@@@@@@%#+..
    #@@@@@@@@@@@@@@+:@@@@@@@@%+...  .#@@@@@@@%@@@@@@@+.@@@@@@@@@@@@@@@@=   .@@@@@@@+
    #@@@@@@@@@@@@*: :@@@@@@@@@@@@@* #@@@@@@@@*@@@@@@@%.@@@@@@@@@@@@@@@@=   .@@@@@@@+
    #@@@@@@@@@+=:   :@@@@@@@@@@@@@@.#@@@@@@@@@@@@@@@@%.@@@@@@#*@@@@@@@@=   .@@@@@@@+
    =%@@@%=         .*@@@@@@@@@@@@+ =%@@@@@++++@@@@@%= +@@@@#: .*@@@@@#:     +@@@@#-
    ....            ............   ......    ......   ....     .....        ....
    ..............   ............      ............    ......    ...      ...........
    =%@@@@@@@@@@@@%=.*@@@@@@@@@@@@*.  =%@@@@@@@@@@@%= .*@@@@@%= .*@@@#: -*#@@@@@@@@@@%*+
    #@@@@@@@@@@@@@@*:@@@@@@@@@@@@@@@:*@@@@@@@@@@@@@@#.@@@@@@@@@%*@@@@@-:#@@@@@@@@@@@@@@@
    #@@@@@@@@@@@@@%-:@@@@@@@##@@@@@@:*@@@@@@@@@@@@@%=.@@@@@@@@@@@@@@@@-+@@@@@@@@@@@@@@@+
    #@@@@@@@@@+=:.  :@@@@@@@@@@@@@@#.*@@@@@@@@@+:..  .@@@@@@@@@@@@@@@@- -#@@@@@@@@@@#-
    #@@@@@@@@@@@%=  :@@@@@@@@@@@@@=  *@@@@@@@@@%:    .@@@@@@@@@@@@@@@@- .-=+@@@@@@@@@@*:
    #@@@@@@@@@@@@=  :@@@@@@@@@@@@@@#.*@@@@@@@@@#***+..@@@@@@@@@@@@@@@@--%@@@@@@@@@@@@@@@
    #@@@@@@-----.   :@@@@@@@@@@@@@@@:*@@@@@@@@@@@@@@#.@@@@@@**@@@@@@@@-+@@@@@@@@@@@@@@@%
    -%@@@%=         .+@@@@*: .*@@@@+. :+*@@@@@@@@@@%- +@@@@*: .*@@@@@*. :+*@@@@@@@@@#+=

    */

    /// @author devberry.eth

    using Strings for uint256;
    using ECDSA for bytes32;

    mapping(address => uint256) totalMintedByAddress;

    uint256 public immutable maxSupply;
    uint256 public immutable maxMintQtyPerAddress;

    uint256 public mintingState; // 0 = closed // 1 = whitelist T1 // 2 = whitelist T1 & T2 // 3 = public & whitelist //

    uint256 public constant mintPrice = 0.07 ether;

    string public baseURI;

    address public signerAddress;

    address private constant devberry = 0x1E9a5429b0d38f5482090f04ac84494A6eA12C89;
    address private constant deepe = 0xfEB02e94b708a5F806341A0C628ACA28FA156f4D;
    address private constant cosmo = 0x83be849f0f51D23F17e49838f2811E3178226d6a;

    bool private bonusPaid;

    constructor(
        uint256 _maxSupply,
        uint256 _maxMintQtyPerAddress,
        address _signerAddress
    ) ERC721A("Plant Frens Genesis", "PLANTFRENS") {
        maxSupply = _maxSupply;
        maxMintQtyPerAddress = _maxMintQtyPerAddress;
        setSignerAddress(_signerAddress);
    }

    /** @dev Mints Plant Frens during public phase.
      * @param quantity Quantity of desired Plant Frens.
      */

    function publicMint(uint256 quantity) public payable {
        if (mintingState < 3) revert PublicMintingNotEnabled();
        if (msg.value != mintPrice * quantity) revert InvalidEthValue();
        if (totalMintedByAddress[msg.sender] + quantity > maxMintQtyPerAddress)
            revert QuantityExceedsMaxPerAddress();
        internalMint(quantity);
    }

    /** @dev Returns message hash based on sender address and minting tier.
      * @param sender Transaction sender's address.
      * @param tier Whitelist minting tier.
      */

    function hashTransaction(address sender, uint256 tier)
        private
        pure
        returns (bytes32)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender, tier))
            )
        );
        return hash;
    }

    /** @dev Checks to see if a message's hash and signature match.
      * @param hash Re-created hash of signed message.
      * @param signature Signature of signed message.
      */

    function matchAddressSigner(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return signerAddress == hash.recover(signature);
    }

    /** @dev Mints Plant Frens during whitelist phase.
      * @param hash Hash of signed message.
      * @param signature Signature of signed message.
      * @param tier Tier of whitelisted minting.
      * @param quantity Quantity of desired Plant Frens.
      */

    function whitelistMint(
        bytes32 hash,
        bytes memory signature,
        uint256 tier,
        uint256 quantity
    ) public payable {
        if (mintingState < 1) revert WhitelistMintingNotEnabled();
        if (mintingState < tier) revert InvalidWhitelistTier();
        if (msg.value != mintPrice * quantity) revert InvalidEthValue();
        if (hashTransaction(msg.sender, tier) != hash) revert InvalidHash();
        if (!matchAddressSigner(hash, signature)) revert DirectMintDisallowed();
        if (totalMintedByAddress[msg.sender] + quantity > maxMintQtyPerAddress)
            revert QuantityExceedsMaxPerAddress();
        internalMint(quantity);
    }

    /** @dev Reserve mint function to allow for auction pieces to be minted before whitelist minting.
      * @param quantity Quantity of desired Plant Frens.
      */

    function reserveMint(uint256 quantity) public onlyOwner {
        if (mintingState > 0) revert MintingIsEnabled();
        internalMint(quantity);
    }

    /** @dev Internal mint function to simplify other mint functions.
      * @param quantity Quantity of desired Plant Frens.
      */

    function internalMint(uint256 quantity) private {
        if (quantity + totalSupply() > maxSupply) revert MintExceedsMaxSupply();
        if (tx.origin != msg.sender) revert TxOriginNotSender();
        totalMintedByAddress[msg.sender] += quantity;
        _safeMint(msg.sender, quantity, "");
    }

    /** @dev Sets minting state to allow/disallow minting of Plant Frens.
      * @param _mintingState Desired minting state ( 0 - 3 ).
      */

    function setMintingState(uint256 _mintingState) public onlyOwner {
        mintingState = _mintingState;
    }

    /** @dev Sets signer address for signature verification.
      * @param _signerAddress Signer's address.
      */

    function setSignerAddress(address _signerAddress) public onlyOwner {
        signerAddress = _signerAddress;
    }

    /** @dev Sets base tokenURI for Plant Frens' metadata.
      * @param __baseURI Metadata URI.
      */

    function setBaseURI(string calldata __baseURI) public onlyOwner {
        baseURI = __baseURI;
    }

    /** @dev Returns tokenURI for given Plant Fren.
      * @param tokenId Plant Fren token ID.
      */

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
    }

    /** @dev Returns baseURI for tokenURI.
      */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /** @dev Returns starting tokenId. Will always be 1.
      */

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /** @dev Withdraws entire ether balance and disperses it to agreed parties.
      */

    function withdraw() public onlyOwner {
        // 20%              Devberry
        // 5% + 0.5 ether   Deepe
        // 5% + 0.5 ether   0xCosmo
        uint256 fivePercent = (address(this).balance - (!bonusPaid ? 1 ether : 0)) / 20;

        (bool successDevberry, ) = address(devberry).call{
            value: fivePercent * 4
        }("");
        if (!successDevberry) revert TransferFailed();

        (bool successDeepe, ) = address(deepe).call{
            value: fivePercent + (!bonusPaid ? 0.5 ether : 0)
        }("");
        if (!successDeepe) revert TransferFailed();

        (bool successCosmo, ) = address(cosmo).call{
            value: fivePercent + (!bonusPaid ? 0.5 ether : 0)
        }("");
        if (!successCosmo) revert TransferFailed();

        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        if (!success) revert TransferFailed();

        bonusPaid = true;
    }
}
