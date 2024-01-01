//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title The interface for the ERC721A Contract
interface IMvhqERC721A {
    struct Config {
        bool whitelistEnabled;
        uint maxSupply;
        uint mintprice;
        uint maxPerMint;
        uint maxPerWallet;
        uint txFee;
        uint256 startDate;
        uint256 endDate;
        string baseTokenURI;
        bool enableMint;
        uint maxReservedAmount;
        uint96 royaltyFee;
        string contractURI;
    }

    event MintNFT(address indexed sender, address indexed receiver, uint amount, uint fromId);
    event Withdraw(address wallet, uint amount);
    event SetSigner(address signer);
    event SetMvhq(address indexed);
    event SetMvhqWallet(address);
    event TransferFee(address, uint256);
    event SetConfig(string, string);
    event ChangeDates(uint256, uint256);
    event ReserveNFTs(uint);

    error ERC721OutOfBoundsIndex(address owner, uint256 index);

    /// @dev Initialize contract (constructor)
    /// @param _name name of NFT collection
    /// @param _symbol symbol of NFT collection
    /// @param baseURI base uri for NFT metadata
    /// @param _startDate start valid mint time, if startDate = 0 ==> unlimited
    /// @param _endDate end valid mint time, if endDate = 0 ==> unlimited
    /// @param _mintprice minimum mint price, start from 0
    /// @param _maxSupply maximum NFT supply of this collection
    /// @param _maxPerMint maximum quantity for each of mint transaction
    /// @param _signer Signer address
    /// @param _mvhq Address of mvhq.
    /// @param _maxReservedAmount Maximum reserved amount
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory baseURI,
        uint256 _startDate,
        uint256 _endDate,
        uint _mintprice,
        uint _maxSupply,
        uint _maxPerMint,
        uint _maxPerWallet,
        address _signer,
        address _mvhq,
        uint _maxReservedAmount
    ) external;

    /// @dev Setting baseUri
    /// @param _baseTokenURI new baseUri
    function setBaseURI(string memory _baseTokenURI) external;

    /// @dev Setting contractURI
    /// @param _contractURI new contractURI
    function setContractURI(string memory _contractURI) external;

    /// @dev view contractURI
    function contractURI() external view returns (string memory);

    /// @dev Setting signer
    /// @param _signer New signer
    function setSigner(address _signer) external; 

    /// @dev Setting mvhq address
    /// @param _mvhq New mvhq
    function setMvhq(address _mvhq) external;

    /// @dev Setting enable mint or Disable
    /// @param _enableMint Enable mint or Disable
    function setEnableMint(bool _enableMint) external;

    /// @dev Setting transaction fee
    /// @param _txFee Transaction fee value (unit wei)
    function setTxFee(uint _txFee) external;

    /// @dev Setting enable check whitelist or uncheck it
    /// @param _whitelistEnabled Transaction fee value (unit wei)
    function setWhitelistEnabled(bool _whitelistEnabled) external;

    /// @dev Setting mvhq wallet
    /// @param _mvhqWallet Wallet which receive transaction fees
    function setMvhqWallet(address _mvhqWallet) external;

    /// @dev set royalty
    /// @param receiver Royalty receiver
    /// @param feeNumerator fee in 1/100 % units
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    /// @notice Mint one or many NFTs
    /// @dev Mint NFTs and send transaction fee to mvhq, use signature to check whitelist
    /// @param _quantity quantity NFT minted
    /// @param _receiver wallet receive NFTs
    /// @param signature signature which signer was signed.
    function mintNFTs(uint _quantity, address _receiver, bytes memory signature) external payable; 

    /// @dev Change start and End date
    /// @param _startDate quantity NFT minted
    /// @param _endDate wallet receive NFTs
    function changeDates(uint256 _startDate, uint256 _endDate) external;

    /// @notice check list tokenIds of Owner
    /// @dev Get list tokenIds of owner
    /// @param _owner address of owner
    function tokensOfOwner(address _owner) external view returns(uint[] memory);

    /// @notice Withdraw all contract's balance and send to owner
    function withdraw() external payable;

    /// @notice Mint NFT without fee for owner this contract
    /// @param _quantity quantity of NFT which will minted
    function reservedNFTs(uint _quantity) external;
}