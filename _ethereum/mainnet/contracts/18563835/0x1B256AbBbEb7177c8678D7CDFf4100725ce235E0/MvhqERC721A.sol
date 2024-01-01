//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC2981Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ERC721AUpgradeable.sol";
import "./IMvhqERC721A.sol";

import "./Signature.sol";

/// @title ERC721A Contract
contract MvhqERC721A is IMvhqERC721A, ERC721AUpgradeable, ERC2981Upgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    uint internal constant TXFEE_DEFAULT = 0.00099 ether;
    bool internal constant WHITELIST_ENABLED = true;
    bool internal constant MINT_ENABLED = true;
    address internal constant MVHQWALLET_DEFAULT = 0xC5da778D4Fd1aa06A4e5C37dFC01d45bb27f7B6A;
    address internal constant ROYALTY_RECEIVER_DEFAULT = 0xC5da778D4Fd1aa06A4e5C37dFC01d45bb27f7B6A;
    uint96 internal constant ROYALTY_FEE_DEFAULT = 0; // 5%

    mapping(bytes => bool) private signatureUsed;

    address public mvhq;

    address public mvhqWallet;

    address public signer;

    uint public reservedMinted;

    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    IMvhqERC721A.Config public mintConfig;

    /// @dev Allow for only mvhq
    modifier onlyMvhq() {
        require(msg.sender == mvhq, "Forbidden");
        _;
    }

    modifier onlyOwnerOrMvhq(){
        require(msg.sender == mvhq || msg.sender == owner());
        _;
    }

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
    ) external override virtual initializerERC721A initializer {
        validateTime(_startDate, _endDate);
        require(bytes(_name).length != 0, "Name is empty");
        require(bytes(_symbol).length != 0, "Symbol is empty");
        require(bytes(baseURI).length != 0, "BaseUri is empty");
        require(_mvhq != address(0), "Mvhq address is invalid");
        require(MVHQWALLET_DEFAULT != address(0), "Mvhq wallet address is invalid");
        require(TXFEE_DEFAULT > 0, "Transaction fee should greater than zero");
        require(_signer != address(0), "Signer address is invalid");
        require(_maxSupply == 0 || _maxReservedAmount < _maxSupply, "Reserved amount or max supply is invalid");
        require(
            _maxSupply > 0 || _maxPerMint > 0 || _maxPerWallet > 0,
            "Max supply, maxPerMint or maxPerWallet are invalid"
        );

        __ERC721A_init(_name, _symbol);
        __Ownable_init();

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
            maxReservedAmount: _maxReservedAmount,
            royaltyFee: ROYALTY_FEE_DEFAULT,
            contractURI: ""
        });

        mvhq = _mvhq;
        signer = _signer;
        mvhqWallet = MVHQWALLET_DEFAULT;

        _setDefaultRoyalty(ROYALTY_RECEIVER_DEFAULT, mintConfig.royaltyFee);
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
    /// @param _quantity quantity NFT minted
    /// @param _receiver wallet receive NFTs
    /// @param signature signature which signer was signed.
    function validateMint(uint _quantity, address _receiver, bytes memory signature) internal view virtual {
        uint maxSupply = mintConfig.maxSupply;
        uint maxPerWallet = mintConfig.maxPerWallet;
        uint maxPerMint = mintConfig.maxPerMint;

        require(mintConfig.enableMint, "Mint feature was blocked");
        require(_receiver != address(0), "Receiver address is invalid");

        validateTimeMinting();
        require(
            maxSupply == 0 || _totalMinted() + _quantity <= maxSupply - mintConfig.maxReservedAmount,
            "Not enough NFTs left"
        );
        require(
            maxPerWallet == 0 || _numberMinted(_receiver) + _quantity <= maxPerWallet,
            "Cannot mint specified number of NFTs!"
        );
        require(maxPerMint == 0 || (_quantity > 0 && _quantity <= maxPerMint), "Cannot mint specified number of NFTs.");
        require(msg.value == (mintConfig.mintprice + mintConfig.txFee) * _quantity, "Value provided not exactly");

        require(Signature.getSigner(_receiver, signature) == signer, "Address is not in whitelist");
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721AUpgradeable, ERC2981Upgradeable) returns (bool) {
        return
            interfaceId == type(OwnableUpgradeable).interfaceId ||
            interfaceId == 0x7f5828d0 || // ERC173
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return mintConfig.baseTokenURI;
    }

    // Override of read function tokenURI when only one Piece of media over all tokenIDs
    //TODO: wrapper here.
    function tokenURI(uint256 tokenId) public view override returns (string memory){
        return _baseURI();
    }

    function setBaseURI(string memory _baseTokenURI) external override onlyOwner {
        require(bytes(_baseTokenURI).length > 0, "TokenURI cannot be empty");

        mintConfig.baseTokenURI = _baseTokenURI;

        emit SetConfig("BaseTokenURI", _baseTokenURI);
    }

    function setContractURI(string memory _contractURI) public override onlyOwner{
        mintConfig.contractURI = _contractURI;
        emit SetConfig("ContractURI", _contractURI);
    }

    function setSigner(address _signer) external override onlyMvhq {
        require(_signer != address(0) && _signer.code.length == 0, "signer address is invalid");
        signer = _signer;

        emit SetSigner(signer);
    }

    function setMvhq(address _mvhq) external override onlyMvhq {
        require(_mvhq != address(0), "Mvhq address is invalid");
        mvhq = _mvhq;

        emit SetMvhq(mvhq);
    }

    function setEnableMint(bool _enableMint) external override onlyOwner {
        mintConfig.enableMint = _enableMint;

        emit SetConfig("EnableMint", _enableMint ? "true" : "false");
    }

    function setTxFee(uint _txFee) external override onlyMvhq {
        mintConfig.txFee = _txFee;

        emit SetConfig("Txfee", StringsUpgradeable.toString(_txFee));
    }

    function setWhitelistEnabled(bool _whitelistEnabled) external override onlyMvhq {
        mintConfig.whitelistEnabled = _whitelistEnabled;

        emit SetConfig("WhitelistEnabled", _whitelistEnabled ? "true" : "false");
    }

    function setMvhqWallet(address _mvhqWallet) external override onlyMvhq {
        require(_mvhqWallet != address(0), "Invalid address");

        mvhqWallet = _mvhqWallet;
        emit SetMvhqWallet(mvhqWallet);
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external override onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function changeDates(uint256 _startDate, uint256 _endDate) external override onlyOwnerOrMvhq{
        validateTime(_startDate, _endDate);
        mintConfig.startDate = _startDate;
        mintConfig.endDate = _endDate;

        emit ChangeDates(_startDate, _endDate);
    }

    function mintNFTs(uint _quantity, address _receiver, bytes memory signature) external override payable nonReentrant {
        validateMint(_quantity, _receiver, signature);

        if (mintConfig.txFee > 0) {
            // caculate and send transaction fee to mvhq
            handleTxFee(_quantity);
        }

        uint fromId = _nextTokenId();

        if (_receiver == owner()) {
            saveOwnerTokenIds(fromId, _quantity);
        }

        _mint(_receiver, _quantity);

        // emit MintNFT(msg.sender, _receiver, _quantity, fromId);
    }

    /// @dev Caculated and send transaction fee to mvhq
    /// @param _count quantity NFTs
    function handleTxFee(uint _count) internal {
        uint256 amount = mintConfig.txFee * _count;
        (bool success, ) = mvhqWallet.call{value: amount}("");
        require(success, "Transfer failed.");

        emit TransferFee(mvhqWallet, amount);
    }

    function contractURI() public override view returns (string memory) {
        return string(mintConfig.contractURI);
    }

    function tokensOfOwner(address _owner) external override view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw() external override payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = owner().call{value: balance}("");
        require(success, "Transfer failed.");

        emit Withdraw(msg.sender, balance);
    }

    function reservedNFTs(uint _quantity) external override onlyOwner {
        uint maxReservedAmount = mintConfig.maxReservedAmount;

        require(reservedMinted + _quantity <= maxReservedAmount, "Not enough NFTs left to reserve");

        uint fromId = _nextTokenId();

        saveOwnerTokenIds(fromId, _quantity);

        _mint(owner(), _quantity);

        unchecked {
            reservedMinted = reservedMinted + _quantity;
        }

        emit MintNFT(msg.sender, owner(), _quantity, fromId);
        emit ReserveNFTs(_quantity);
    }

    /// @notice Get tokenId of owner by index (index in list token of owner)
    /// @param owner Address of owner
    /// @param index Index of token in list tokenIds of owner
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        if (index >= balanceOf(owner)) {
            revert ERC721OutOfBoundsIndex(owner, index);
        }
        return _ownedTokens[owner][index];
    }

    function saveOwnerTokenIds(uint fromId, uint _quantity) private {
        address owner = owner();
        uint256 length = balanceOf(owner);

        for (uint i = fromId; i < fromId + _quantity; i++) {
            _ownedTokens[owner][length + i - fromId] = i;
        }
    }
}
