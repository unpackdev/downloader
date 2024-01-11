// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./draft-EIP712.sol";
import "./Counters.sol";

/**
 *  @title NFT Smart Contract
 *  @author 0x7c7 labs
 *  @notice ERC721 contract for stand-alone NFT collections with lazy-minting
 *  @dev Enables lazy-minting by any user via precomputed signatures
 */
contract NPHM is ERC721, EIP712 {
    event IdFloorSet(uint256 idFloor);
    event Receipt(uint256 value);
    event Withdrawal(uint256 value);
    event BaseMintPriceSet(uint256 baseMintPrice);
    event PriceSet(uint256 id, uint256 price);
    event Bought(uint256 id, address buyer);

    address public immutable owner;

    uint256 private constant MAX_INT = type(uint256).max;

    uint256 public baseMintPrice;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    uint256 public constant MAX_SUPPLY = 10000;

    uint256 public idFloor;
    uint256 public immutable royaltyBasisPoints;

    mapping(uint256 => string) private tokenURIs;
    mapping(uint256 => uint256) private prices;

    bool public mintIsActive = true;

    /**
     *  @dev Constructor immutably sets "owner" to the message sender; be sure to deploy contract using the account of the creator/artist/brand/etc.
     *  @param _name ERC721 token name
     *  @param _symbol ERC721 token symbol
     *  @param _baseMintPrice The initial mint price in wei
     *  @param _royaltyBasisPoints Percentage basis-points for royalty on secondary sales, eg 495 == 4.95%
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _baseMintPrice,
        uint256 _royaltyBasisPoints
    ) ERC721(_name, _symbol) EIP712("NPHM", "1.0.0") {
        owner = _msgSender();
        baseMintPrice = _baseMintPrice;
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    /**
     *  @notice Receive ETH
     */
    receive() external payable {
        emit Receipt(msg.value);
    }

    /**
     *  @notice Withdraw ETH balance
     */
    function withdraw() external {
        require(_msgSender() == owner, "unauthorized to withdraw");
        uint256 balance = address(this).balance;
        
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "transfer failed");
        emit Withdrawal(balance);
    }

    /**
     *  @notice Minting by the agent only
     *  @param recipient The recipient of the NFT
     *  @param id The intended token id
     *  @param uri The intended token URI
     */
    function mintAuthorized(
        address recipient,
        uint256 id,
        string memory uri
    ) external {
        require(_msgSender() == owner, "unauthorized to mint");
        require(vacant(id));
        _mint(recipient, id, uri);
    }

    /**
     *  @notice Minting at baseMintPrice, given the owner's signature of the specified arguments
     *  @param id The intended token id
     *  @param uri The intended token URI
     *  @param signature The ERC712 signature
     */
    function mint(
        uint256 id,
        string memory uri,
        bytes calldata signature
    ) external payable {
        mintAtPrice(MAX_INT, id, uri, signature);
    }

    /**
     *  @notice Minting at price, given the owner's signature over the specified arguments
     *  @param price Minting price in wei. If MAX_INT, baseMintPrice applies.
     *  @param id The intended token id
     *  @param uri The intended token URI
     *  @param signature The ERC712 signature
     */
    function mintAtPrice(
        uint256 price,
        uint256 id,
        string memory uri,
        bytes calldata signature
    ) public payable {
        require(
            (price == MAX_INT && msg.value == baseMintPrice) ||
                msg.value == price,
            "incorrect ETH sent"
        );
        require(mintable(price, id, uri, signature));
        _mint(_msgSender(), id, uri);
    }

    /**
     *  @notice Checks availability for minting, and validity of the owner's signature
     *  @param price Minting price in wei. If MAX_INT, baseMintPrice applies.
     *  @param id The intended token id
     *  @param uri The intended token URI
     *  @param signature The ERC712 signature
     */
    function mintable(
        uint256 price,
        uint256 id,
        string memory uri,
        bytes calldata signature
    ) public view returns (bool) {
        require(vacant(id));
        require(
            owner == ECDSA.recover(_hash(price, id, uri), signature),
            "signature invalid or signer unauthorized"
        );
        return true;
    }

    /**
     *  @notice Checks availability for minting
     *  @param id The token id
     */
    function vacant(uint256 id) public view returns (bool) {
        require(!_exists(id), "tokenId already minted");
        require(id >= idFloor, "tokenId below floor");
        return true;
    }

    /**
     *  @notice Sets the price at which a token may be bought. A zero price cancels the sale.
     *  @param id The token id
     *  @param _price The token price in wei
     */
    function setPrice(uint256 id, uint256 _price) external {
        require(_msgSender() == ownerOf(id), "caller is not token owner");
        prices[id] = _price;
        emit PriceSet(id, _price);
    }

    /**
     *  @notice Returns the price at which a token may be bought. Zero means the token is not for sale.
     *  @param id The token id
     */
    function priceOf(uint256 id) external view returns (uint256) {
        return prices[id];
    }

    /**
     *  @notice Transfers the token to the caller, and transfers the paid ETH to its owner (minus royalty)
     *  @param id The token id
     */
    function buy(uint256 id) external payable {
        require(_msgSender() != ownerOf(id), "caller is token owner");
        require(prices[id] > 0, "token not for sale");
        require(msg.value == prices[id], "incorrect ETH sent");
        address seller = ownerOf(id);
        delete prices[id];
        _safeTransfer(seller, _msgSender(), id, "");
        Address.sendValue(
            payable(seller),
            (10000 - royaltyBasisPoints) * (msg.value / 10000)
        );
        emit Bought(id, _msgSender());
    }

    /**
     *  @notice Sets the mint price
     *  @param _baseMintPrice The new mint price
     */
    function setBaseMintPrice(uint256 _baseMintPrice) external {
        require(_msgSender() == owner, "unauthorized to set baseMintPrice");
        baseMintPrice = _baseMintPrice;
        emit BaseMintPriceSet(_baseMintPrice);
    }

    /**
     *  @notice Disables minting of ids below floor, thus revoking any signatures that include them
     *  @param floor The floor for new token ids minted from now
     */
    function setIdFloor(uint256 floor) external {
        require(_msgSender() == owner, "unauthorized to set idFloor");
        idFloor = floor;
        emit IdFloorSet(idFloor);
    }

    /**
     * @dev remaining supply
     */
    function remainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - _tokenSupply.current();
    }

    /**
     * @dev get total supply
     */
    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }

    /**
     *  @notice Returns the token URI, given the token id
     *  @param id The token id
     */
    function tokenURI(uint256 id) public view override returns (string memory) {
        return tokenURIs[id];
    }

    /**
     *  @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Minting also increments totalSupply
     */
    function _mint(
        address recipient,
        uint256 id,
        string memory uri
    ) internal {
        
        require(mintIsActive, "mint are not for now yet");
        //save gas fee
        uint256 mintIndex = _tokenSupply.current() + 1; 
        require(mintIndex <= MAX_SUPPLY, "mint enough over 10000");

        // Mint. That's the easy part.
        _tokenSupply.increment();
        _safeMint(recipient, id);
        _setTokenURI(id, uri);

    }

    /**
     * @dev Recreates the hash that the signer (may have) signed
     */
    function _hash(
        uint256 price,
        uint256 id,
        string memory uri
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "mint(uint256 price,uint256 tokenId,string tokenURI)"
                        ),
                        price,
                        id,
                        keccak256(bytes(uri))
                    )
                )
            );
    }

    /**
     * @dev record a token's URI against its id
     */
    function _setTokenURI(uint256 id, string memory uri) internal {
        require(bytes(uri).length != 0, "tokenURI cannot be empty");
        tokenURIs[id] = uri;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
        delete prices[tokenId];
    }

     // Go go go!
    function toggleMint(bool status) external {
        require(_msgSender() == owner, "unauthorized to set mint");
        mintIsActive = status;
    }

}
