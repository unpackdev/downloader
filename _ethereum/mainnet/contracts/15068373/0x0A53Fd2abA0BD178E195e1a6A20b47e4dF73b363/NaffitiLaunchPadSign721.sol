// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC165.sol";
import "./ERC2981.sol";
import "./ERC721A.sol";

/**
 *  @title  Naffiti Launchpad NFTs Signature Version
 *  @author Naffiti
 *  @dev    Using ERC721A for the base contract and EIP-712 standard for minting
 */
contract NaffitiLaunchPadSign721 is
    ERC165,
    ERC721A,
    ERC2981,
    Pausable,
    Ownable,
    EIP712("NaffitiLaunchPadSign721", "v1.2.0")
{
    using Strings for uint256;

    mapping(address => uint256) private mintedAmount;

    string private contractURILink;
    string private baseURI;

    address public immutable SIGNER;
    address public immutable RECEIVE_COMMISSION_ADDRESS;

    uint256 public immutable COMMISSION_PERCENTAGE;
    uint256 public immutable MAX_SUPPLY;

    bytes32 public constant TICKET_HASH_TYPE =
        keccak256(
            "MintTicket(address recipient,uint256 price,uint256 maxMintPerPeriod,uint256 maxMintPerTx,uint256 maxMint,"
            "uint256 afterTimestamp,uint256 beforeTimestamp,uint256 nonce)"
        );

    struct MintTicket {
        address recipient;
        uint256 price;
        uint256 maxMintPerPeriod;
        uint256 maxMintPerTx;
        uint256 maxMint;
        uint256 afterTimestamp;
        uint256 beforeTimestamp;
        uint256 nonce;
    }

    event BaseURISet(string baseURI);
    event NFTMinted(uint256 startId, uint256 mintAmount, address recipient, uint256 price, address contractAddress);

    error FailedETHTransfer();
    error InsufficientFunds();
    error InvalidMintAmount();
    error InvalidMintAmountPerPeriod();
    error InvalidMintAmountPerTx();
    error InvalidRoyaltyPercentage();
    error InvalidSignature();
    error InvalidTimestamp();
    error UnexistentToken();
    error UnexpectedMintAmount();

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        string memory _contractURILink,
        uint256 _maxSupply,
        address _signer,
        address _receiveCommissionAddress,
        uint256 _commissionPercentage,
        address _receiveRoyaltyAddress,
        uint256 _royaltyPercentage,
        address _contractOwner
    ) ERC721A(_name, _symbol) {
        SIGNER = _signer;
        RECEIVE_COMMISSION_ADDRESS = _receiveCommissionAddress;
        COMMISSION_PERCENTAGE = _commissionPercentage;
        MAX_SUPPLY = _maxSupply;

        baseURI = _uri;
        contractURILink = _contractURILink;
        _setDefaultRoyalty(_receiveRoyaltyAddress, uint96(_royaltyPercentage));

        if (_contractOwner != msg.sender) _transferOwnership(_contractOwner);
    }

    function mint(
        uint256 _mintAmount,
        bytes calldata _payload,
        bytes calldata _signature,
        bytes calldata _data
    ) public payable whenNotPaused {
        MintTicket memory arg = abi.decode(_payload, (MintTicket));
        if (
            ECDSA.recover(
                _hashTypedDataV4(
                    keccak256(
                        abi.encode(
                            TICKET_HASH_TYPE,
                            arg.recipient,
                            arg.price,
                            arg.maxMintPerPeriod,
                            arg.maxMintPerTx,
                            arg.maxMint,
                            arg.afterTimestamp,
                            arg.beforeTimestamp,
                            arg.nonce
                        )
                    )
                ),
                _signature
            ) != SIGNER
        ) revert InvalidSignature();

        if (_mintAmount > arg.maxMintPerTx) revert InvalidMintAmountPerTx();

        uint256 oldSupply = totalSupply();
        if (oldSupply + _mintAmount > arg.maxMintPerPeriod) revert InvalidMintAmountPerPeriod();
        if (oldSupply + _mintAmount > MAX_SUPPLY) revert UnexpectedMintAmount();

        mintedAmount[arg.recipient] += _mintAmount;
        if (mintedAmount[arg.recipient] > arg.maxMint) revert InvalidMintAmount();

        if (block.timestamp <= arg.afterTimestamp) revert InvalidTimestamp();
        if (block.timestamp >= arg.beforeTimestamp) revert InvalidTimestamp();
        if (msg.value < arg.price * _mintAmount) revert InsufficientFunds();

        _safeMint(arg.recipient, _mintAmount, _data);

        emit NFTMinted(oldSupply, _mintAmount, arg.recipient, arg.price, address(this));
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (!_exists(_tokenId)) revert UnexistentToken();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "/", _tokenId.toString(), ".json")) : "";
    }

    function setBaseURI(string calldata _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
        emit BaseURISet(_newBaseURI);
    }

    function setIsPaused(bool status) public onlyOwner {
        if (status) _pause();
        else _unpause();
    }

    /**
     *  @dev Our platform will receive a part of the funds to be the commission
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool cs, ) = payable(RECEIVE_COMMISSION_ADDRESS).call{ value: (balance * COMMISSION_PERCENTAGE) / 10000 }("");
        if (!cs) revert FailedETHTransfer();
        balance = address(this).balance;
        (bool ts, ) = payable(owner()).call{ value: balance }("");
        if (!ts) revert FailedETHTransfer();
    }

    /**
     *  @notice Owner is not allowed to set the royalty higher than 10%
     *  @dev We support 2 decimal places for the royalty (e.g. 5.5% = 5500, 6.25% = 62500)
     *       Always time 10000 before updating (5.5 * 10000 = 5500, 6.25 * 10000 = 62500)
     */
    function setRoyaltyInfo(address _receiveRoyaltyAddress, uint96 _percentage) public onlyOwner {
        if (_percentage > 1000) revert InvalidRoyaltyPercentage();
        _setDefaultRoyalty(_receiveRoyaltyAddress, _percentage);
    }

    /**
     *  @dev EIP-165: Standard Interface Detection - https://eips.ethereum.org/EIPS/eip-165
     */
    function supportsInterface(bytes4 _interfaceId) public view override(ERC2981, ERC721A, ERC165) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    /**
     *  @dev OpenSea Contract-level Metadata https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public view returns (string memory) {
        return contractURILink;
    }

    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURILink = _contractURI;
    }
}
