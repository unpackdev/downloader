// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma abicoder v2; // required to accept structs as function parameters

import "./ERC721.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";

/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy {

}

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ChooseYourReality is ERC721, EIP712, ERC721Enumerable {
    using Counters for Counters.Counter;

    event Redeemed(address indexed from, uint256 tokenId);
    event SetBaseURI(address indexed from, string uri);
    event SetContractURI(address indexed from, string uri);
    event Widthdrawn(address indexed from);

    uint16 public constant MAX_PILLS_COUNT = 10000;
    uint8 public constant MAX_MINT_COUNT_PER_ADDRESS = 1;

    string private constant SIGNING_DOMAIN = "PILL-VOUCHER";
    string private constant SIGNATURE_VERSION = "1";

    Counters.Counter private _tokenIds;

    /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
    struct Voucher {
        /// @notice The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
        uint256 minPrice;
        /// @notice The side you chose. BLUE, RED, or ?.
        string side;
        /// @notice The rarity. UR, SSR, SR, R, N, or ?.
        string rarity;
        /// @notice The message.
        string message;
        /// @notice The challenge.
        string challenge;
        /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
        bytes signature;
    }

    // @notice Represents a minted NFT, which includes below information.
    struct Pill {
        string side;
        string rarity;
        string message;
    }

    // @notice Represents openSea proxy registry address.
    address public osRegistryAddress =
        0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    // @notice Represents owner address.
    address payable public owner;

    // @notice Represents tokenId to pill map
    mapping(uint256 => Pill) public pills;
    // @notice Represents used voucher map
    mapping(string => bool) public usedVoucherList;
    // @notice Represents address to mint count map
    mapping(address => uint8) private _mintedList;

    // @notice Represents base uri for this contract.
    string public baseURI;
    // @notice Represents contract metadata uri.
    string private contractMetadataURI;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    constructor(address payable _owner)
        ERC721("ChooseYourReality", "CYR")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        owner = _owner;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return
            ERC721Enumerable.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId);
    }

    receive() external payable {}

    /// @notice Returns the chain id of the current blockchain.
    /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
    ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /// @notice Redeems an Voucher for an actual NFT, creating it in the process.
    /// @param redeemer The address of the account which will receive the NFT upon success.
    /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
    function redeem(
        address redeemer,
        Voucher calldata voucher,
        string memory side
    ) public payable {
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);

        // make sure that the signer is authorized to mint NFTs
        require(signer == owner, "Signature invalid or unauthorized");

        // make sure that per address can mint only max mint count.
        require(
            MAX_MINT_COUNT_PER_ADDRESS > _mintedList[redeemer],
            "Reached minting limit"
        );

        require(!usedVoucherList[voucher.challenge], "Voucher Already used");

        // make sure that the tokenId is not greater than maxCount.
        require(MAX_PILLS_COUNT > _tokenIds.current(), "All pills minted");

        // make sure that the redeemer is paying enough to cover the buyer's cost.
        // many of them are fair free mint, but some rares require you to pay cost.
        require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");

        require(
            keccak256(abi.encodePacked(side)) ==
                keccak256(abi.encodePacked("BLUE")) ||
                keccak256(abi.encodePacked(side)) ==
                keccak256(abi.encodePacked("RED")),
            "Invalid side"
        );

        // first increment tokenIds
        _tokenIds.increment();
        // get new tokenId to assign
        uint256 newTokenId = _tokenIds.current();
        // assign the token to the signer, to establish provenance on-chain
        _mint(signer, newTokenId);

        // transfer the token to the redeemer. _transfer does not require approvals
        _transfer(signer, redeemer, newTokenId);

        // count up
        _mintedList[redeemer] += 1;

        // Mark as used
        usedVoucherList[voucher.challenge] = true;

        // set infromation
        pills[newTokenId].rarity = voucher.rarity;
        pills[newTokenId].message = voucher.message;

        if (
            keccak256(abi.encodePacked(voucher.rarity)) ==
            keccak256(abi.encodePacked("N"))
        ) {
            pills[newTokenId].side = side; // BLUE or RED
        } else {
            pills[newTokenId].side = voucher.side; // Your choice
        }

        // emit event
        emit Redeemed(redeemer, newTokenId);
    }

    /// @notice Withdraw fee.
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Not Enough Balance Of Contract");
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
        emit Widthdrawn(msg.sender);
    }

    /// @notice Contract URI
    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    /// @notice Updates contractURI
    /// @dev Will revert if not owner.
    /// @param contractUri A new contract URI.
    function setContractURI(string memory contractUri) external onlyOwner {
        contractMetadataURI = contractUri;
        emit SetContractURI(msg.sender, contractUri);
    }

    /// @notice Updates baseURI
    /// @dev Will revert if not owner.
    /// @param baseUri A new base URI.
    function setBaseURI(string memory baseUri) external onlyOwner {
        baseURI = baseUri;
        emit SetBaseURI(msg.sender, baseUri);
    }

    /// @notice Updates message
    /// @dev Will revert if not token owner.
    /// @param tokenId target tokenId.
    /// @param message A new message.
    function setMessage(uint256 tokenId, string memory message) external {
        require(ownerOf(tokenId) == msg.sender, "Only pill owner");
        pills[tokenId].message = message;
    }

    /// @notice Updates osRegistryAddress
    /// @dev Will revert if not owner.
    /// @param newAddress A new address.
    function setOSRegistryAddress(address newAddress) external onlyOwner {
        osRegistryAddress = newAddress;
    }

    /**
    An override to whitelist the OpenSea proxy contract to enable gas-free
    listings. This function returns true if `_operator` is approved to transfer
    items owned by `_owner`.
    @param _owner The owner of items to check for transfer ability.
    @param _operator The potential transferrer of `_owner`'s items.
  */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(osRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }
        return super.isApprovedForAll(_owner, _operator);
    }

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher A Voucher to hash.
    function _hash(Voucher calldata voucher) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Voucher(uint256 minPrice,string side,string rarity,string message,string challenge)"
                        ),
                        voucher.minPrice,
                        keccak256(bytes(voucher.side)),
                        keccak256(bytes(voucher.rarity)),
                        keccak256(bytes(voucher.message)),
                        keccak256(bytes(voucher.challenge))
                    )
                )
            );
    }

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher A Voucher describing an unminted NFT.
    function _verify(Voucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher); // as challenge
        return ECDSA.recover(digest, voucher.signature);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
