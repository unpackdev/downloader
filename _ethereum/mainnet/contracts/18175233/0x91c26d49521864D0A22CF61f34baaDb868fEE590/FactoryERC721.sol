//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./CountersUpgradeable.sol";
import "./Initializable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Signature.sol";
import "./ERC2981Upgradeable.sol";

/// @title ERC721 Contract
contract FactoryERC721 is ERC721EnumerableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, UUPSUpgradeable, ERC2981Upgradeable{
    using CountersUpgradeable for CountersUpgradeable.Counter;

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
        uint reservedAmount;
        string contractURI;
    }

    event Withdraw(address indexed wallet, uint amount);
    event SetSigner(address);
    event SetMvhq(address);
    event SetMvhqWallet(address);
    event SetConfig(string, string);
    event ReserveNFTs(uint);

    uint public constant TXFEE_DEFAULT = 0.00099 ether;
    bool public constant WHITELIST_ENABLED = true;
    bool public constant MINT_ENABLED = true;
    address public constant MVHQWALLET_DEFAULT = 0xC5da778D4Fd1aa06A4e5C37dFC01d45bb27f7B6A;
    address public constant MVHQADMIN_DEFAULT = 0x252Ec76E22d50454197c8c27d7107a3eD7c9d57c;

    // quantity minted of user
    mapping(address => uint) public userMints;

    CountersUpgradeable.Counter internal tokenIds;
    
    address public mvhq;

    address public mvhqWallet;
    
    address public signer;

    uint public reservedMinted;

    Config public mintConfig;

    /// @dev Allow for only mvhq
    modifier onlyMvhq() {
        require(msg.sender == mvhq, "Forbidden");
        _;
    }

    /// @dev Initialize contract (constructor)
    /// @param _name name of NFT collection
    /// @param _symbol symbol of NFT collection 
    /// @param baseURI base uri for NFT metadata
    /// @param _contractBaseURI contract URI for Marketplaces
    /// @param _startDate start valid mint time, if startDate = 0 ==> unlimited
    /// @param _endDate end valid mint time, if endDate = 0 ==> unlimited
    /// @param _mintprice minimum mint price, start from 0
    /// @param _maxPerMint maximum quantity for each of mint transaction
    /// @param _maxSupply maximum supply of collection, 0 ==> unlimiteed
    /// @param _maxPerWallet maximum allowed mint per wallet, 0  ==> unlimited
    /// @param _signer Signer address
    /// @param _reservedAmount Maximum reserved amount
    function initialize(string memory _name, string memory _symbol, string memory baseURI, string memory _contractBaseURI, uint256 _startDate, uint256 _endDate, uint _mintprice, uint _maxSupply, uint _maxPerMint, uint _maxPerWallet, address _signer, uint _reservedAmount) public virtual initializer {
        validateTime(_startDate, _endDate);
        require(bytes(_name).length != 0, "Name is empty");
        require(bytes(_symbol).length != 0, "Symbol is empty");
        require(bytes(baseURI).length != 0, "baseURI is empty");
        require(bytes(_contractBaseURI).length != 0, "_contractBaseURI is empty");
        require(MVHQWALLET_DEFAULT != address(0), "Mvhq wallet address is invalid");
        require(TXFEE_DEFAULT > 0, "Transaction fee should greater than zero");
        require(_signer != address(0), "Signer address is invalid");
        require(_maxSupply == 0 || _reservedAmount < _maxSupply, "Reserved amount or max supply is invalid");

        __ERC721_init(_name, _symbol);
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ERC2981_init();

        mintConfig = Config({
            whitelistEnabled: WHITELIST_ENABLED,
            maxSupply: _maxSupply,
            mintprice: _mintprice,
            maxPerMint: _maxPerMint,
            maxPerWallet: _maxPerWallet,
            txFee: TXFEE_DEFAULT,
            startDate: _startDate,
            endDate: _endDate,
            baseTokenURI: baseURI,
            enableMint: MINT_ENABLED,
            reservedAmount: _reservedAmount,
            contractURI: _contractBaseURI
        });

        mvhq = MVHQADMIN_DEFAULT;
        signer = _signer;
        mvhqWallet = MVHQWALLET_DEFAULT;

        _setDefaultRoyalty(msg.sender, 0);
    }

    function _authorizeUpgrade(address) internal override onlyOwner{

    }

    // Royalty: interfaceId == type(ERC2981).interfaceId ||
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721EnumerableUpgradeable, ERC2981Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId ||
        interfaceId == 0x7f5828d0 || 
        super.supportsInterface(interfaceId);
        }

    function contractURI() public view returns (string memory) {
        return string(mintConfig.contractURI);
    }

    // Override of read function tokenURI when only one Piece of media over all tokenIDs
    function tokenURI(uint256 tokenId) public view override returns (string memory){
        return string(mintConfig.baseTokenURI);
    }

    /// @dev Check valid time when initialize contract
    /// @param _startDate start valid mint time, if startDate = 0 ==> unlimited
    /// @param _endDate end valid mint time, if endDate = 0 ==> unlimited
    function validateTime(uint256 _startDate, uint256 _endDate) internal view {
        require(_startDate == 0 || _startDate > block.timestamp, "StartDate is invalid");
        require(_endDate == 0 || (_endDate > _startDate), "EndDate or StartDate is invalid");
    }

    /// @dev Check valid time when minting NFT
    function validateTimeMinting() private view {
        uint startDate = mintConfig.startDate;
        uint endDate = mintConfig.endDate;

        require(startDate == 0 || block.timestamp >= startDate, "Mint event is not started yet");
        require(endDate == 0 || block.timestamp < endDate, "Mint event is closed");
    }

    /// @dev Validate when minting NFT
    /// @param _count quantity NFT minted
    /// @param _receiver wallet receive NFTs
    /// @param signature signature which signer was signed.
    function validateMint(uint _count, address _receiver, bytes memory signature) internal view virtual {
        uint totalMinted = tokenIds.current();
        uint maxSupply = mintConfig.maxSupply;
        uint maxPerWallet = mintConfig.maxPerWallet;
        uint maxPerMint = mintConfig.maxPerMint;

        require(mintConfig.enableMint, "Mint feature was blocked");
        validateTimeMinting();
        require(maxSupply == 0 || totalMinted + _count <= maxSupply - mintConfig.reservedAmount, "Not enough NFTs left");
        require(maxPerWallet == 0 || userMints[_receiver] + _count <= maxPerWallet, "Cannot mint specified number of NFTs!");
        require(maxPerMint == 0 || (_count > 0 && _count <= maxPerMint), "Cannot mint specified number of NFTs.");
        require(msg.value == (mintConfig.mintprice + mintConfig.txFee)*(_count), "Value provided not exactly");

        require(Signature.getSigner(_receiver, signature) == signer, "Address is not in whitelist");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return mintConfig.baseTokenURI;
    }

    /// @dev Setting baseUri
    /// @param _baseTokenURI new baseUri
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        mintConfig.baseTokenURI = _baseTokenURI;

        emit SetConfig("BaseTokenURI", _baseTokenURI);
    }

    /// @dev Setting signer
    /// @param _signer New signer
    function setSigner(address _signer) public onlyMvhq {
        require(_signer != address(0), "signer address is invalid");
        signer = _signer;

        emit SetSigner(signer);
    }


    /// @dev Setting mvhq address
    /// @param _mvhq New mvhq
    function setMvhq(address _mvhq) public onlyMvhq {
        require(_mvhq != address(0), "Mvhq address is invalid");
        mvhq = _mvhq;

        emit SetMvhq(mvhq);
    }


    /// @dev Setting enable mint or Disable
    /// @param _enableMint Enable mint or Disable
    function setEnableMint(bool _enableMint) public onlyOwner {
        mintConfig.enableMint = _enableMint;

        emit SetConfig("EnableMint", _enableMint ? "true" : "false");
    }


    /// @dev Setting transaction fee
    /// @param _txFee Transaction fee value (unit wei)
    function setTxFee(uint _txFee) public onlyMvhq {
        mintConfig.txFee = _txFee;

        emit SetConfig("Txfee", Strings.toString(_txFee));
    }


    /// @dev Setting enable check whitelist or uncheck it
    /// @param _whitelistEnabled Transaction fee value (unit wei)
    function setWhitelistEnabled(bool _whitelistEnabled) public onlyMvhq {
        mintConfig.whitelistEnabled = _whitelistEnabled;

        emit SetConfig("WhitelistEnabled", _whitelistEnabled ? "true" : "false");
    }

    /// @dev Setting mvhq wallet
    /// @param _mvhqWallet Wallet which receive transaction fees
    function setMvhqWallet(address _mvhqWallet) public onlyMvhq {
        require(_mvhqWallet != address(0), "Invalid address");

        mvhqWallet = _mvhqWallet;
        emit SetMvhqWallet(mvhqWallet);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @notice Mint one or many NFTs
    /// @dev Mint NFTs and send transaction fee to mvhq, use signature to check whitelist
    /// @param _count quantity NFT minted
    /// @param _receiver wallet receive NFTs
    /// @param signature signature which signer was signed.
    function mintNFTs(uint _count, address _receiver, bytes memory signature) external payable nonReentrant {
        validateMint(_count, _receiver, signature);

        if (mintConfig.txFee > 0){
            // caculate and send transaction fee to mvhq
            handleTxFee(_count);
        }
        
        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT(_receiver);
        }
    }

    function setContractURI(string memory _contractURI) public onlyOwner{
        mintConfig.contractURI = _contractURI;
        emit SetConfig("ContractURI", _contractURI);
    }

    /// @dev Mint one NFTs for receiver
    /// @param _receiver wallet will receive NFT
    function _mintSingleNFT(address _receiver) internal {
        uint newTokenID = tokenIds.current();
        _safeMint(_receiver, newTokenID);

        // count quantity minted for user _receiver
        userMints[_receiver]++;
        tokenIds.increment();

    }

    /// @dev Caculated and send transaction fee to mvhq
    /// @param _count quantity NFTs
    function handleTxFee(uint _count) internal {
        uint256 amount = mintConfig.txFee * _count;
        (bool success, ) = mvhqWallet.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function tokensOfOwner(address _owner) external view returns (uint[] memory) {

        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    /// @notice Withdraw all contract's balance and send to owner
    function withdraw() public payable onlyOwner() {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = owner().call{value: balance}("");
        require(success, "Transfer failed.");
        
        emit Withdraw(msg.sender, balance);
    }

    function reservedNFTs(uint amount) public onlyOwner {
        uint reservedAmount = mintConfig.reservedAmount;

        require(reservedMinted + amount <= reservedAmount, "Not enough NFTs left to reserve");

        for (uint i = 0; i < amount; i++) {
            _mintSingleNFT(owner());
        }

        reservedMinted = reservedMinted + amount;

        emit ReserveNFTs(amount);
    }

}