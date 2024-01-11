// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./AggregatorV3Interface.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";

abstract contract FayreMembershipCard721 is OwnableUpgradeable, ERC721EnumerableUpgradeable, ERC721BurnableUpgradeable {
    struct MembershipCardData {
        uint256 volume;
        uint256 nftPriceCap;
        uint256 freeMultiAssetSwapCount;
    }

    struct FreeMinterData {
        address freeMinter;
        uint256 amount;
    }

    struct MultichainClaimData {
        address to;
        uint256 fromTokenId;
        uint256 fromNetworkId;
        address fromContractAddress;
        uint256 destinationNetworkId;
        address destinationContractAddress;
        MembershipCardData membershipCardData;
    }

    event Mint(address indexed owner, uint256 indexed tokenId, string tokenURI, MembershipCardData membershipCardData);
    event MultichainTransferFrom(address indexed to, uint256 indexed tokenId, uint256 fromNetworkId, address fromContractAddress, uint256 destinationNetworkId, address destinationContractAddress, MembershipCardData membershipCardData);
    event MultichainClaim(address indexed to, uint256 indexed tokenId, uint256 indexed fromTokenId, uint256 fromNetworkId, address fromContractAddress, uint256 destinationNetworkId, address destinationContractAddress, MembershipCardData membershipCardData);
    event MultichainConsumeMembershipCard(address indexed owner, uint256 indexed tokenId, uint256 indexed blockNumber, uint256 fromNetworkId, address fromContractAddress, uint256 destinationNetworkId, address destinationContractAddress, uint256 volume, uint256 freeMultiAssetSwapCount);

    address public oracleDataFeed;
    mapping(uint256 => MembershipCardData) public membershipCardsData;
    uint256 public priceUSD;
    uint256 public startingVolume;
    uint256 public nftPriceCap;
    uint256 public freeMultiAssetSwapCount;
    uint256 public mintedSupply;
    uint256 public supplyCap;
    address public treasuryAddress;
    mapping(address => bool) public isValidator;
    mapping(address => bool) public isMembershipCardsManager;
    mapping(address => uint256) public remainingFreeMints;
    uint256 public validationChecksRequired;

    uint256 private _currentTokenId;
    string private _tokenURI;
    mapping(bytes32 => bool) private _isMultichainHashProcessed;
    uint256 private _networkId;

    modifier onlyMembershipCardsManager() {
        require(isMembershipCardsManager[msg.sender], "Only membership cards manager");
        _;
    }

    function setOracleDataFeedAddress(address newOracleDataFeed) external onlyOwner {
        require(newOracleDataFeed != address(0), "Cannot set address 0");

        oracleDataFeed = newOracleDataFeed;
    }

    function setTokenURI(string memory newTokenUri) external onlyOwner {
        _tokenURI = newTokenUri;
    }

    function setPrice(uint256 newPriceUSD) external onlyOwner {
        priceUSD = newPriceUSD;
    }

    function setStartingVolume(uint256 newStartingVolume) external onlyOwner {
        startingVolume = newStartingVolume;
    }

    function setNFTPriceCap(uint256 newNFTPriceCap) external onlyOwner {
        nftPriceCap = newNFTPriceCap;
    }

    function setFreeMultiAssetSwapCount(uint256 newFreeMultiAssetSwapCount) external onlyOwner {
        freeMultiAssetSwapCount = newFreeMultiAssetSwapCount;
    }

    function setSupplyCap(uint256 newSupplyCap) external onlyOwner {
        supplyCap = newSupplyCap;
    }

    function setTreasury(address newTreasuryAddress) external onlyOwner {
        require(newTreasuryAddress != address(0), "Cannot set address 0");

        treasuryAddress = newTreasuryAddress;
    }

    function setAddressAsValidator(address validatorAddress) external onlyOwner {
        isValidator[validatorAddress] = true;
    }

    function unsetAddressAsValidator(address validatorAddress) external onlyOwner {
        isValidator[validatorAddress] = false;
    }

    function setValidationChecksRequired(uint256 newValidationChecksRequired) external onlyOwner {
        validationChecksRequired = newValidationChecksRequired;
    }

    function setAddressAsMembershipCardsManager(address membershipCardsManagerAddress) external onlyOwner {
        isMembershipCardsManager[membershipCardsManagerAddress] = true;
    }

    function unsetAddressAsMembershipCardsManager(address membershipCardsManagerAddress) external onlyOwner {
        isMembershipCardsManager[membershipCardsManagerAddress] = false;
    }

    function setFreeMinters(FreeMinterData[] calldata freeMintersData) external onlyMembershipCardsManager {
        for (uint256 i = 0; i < freeMintersData.length; i++)
            remainingFreeMints[freeMintersData[i].freeMinter] = freeMintersData[i].amount;
    }

    function decreaseMembershipCardVolume(uint256 tokenId, uint256 amount) external onlyMembershipCardsManager {
        require(membershipCardsData[tokenId].volume >= amount, "Insufficient volume left");

        membershipCardsData[tokenId].volume -= amount;
    }

    function decreaseMembershipCardFreeMultiAssetSwapCount(uint256 tokenId, uint256 amount) external onlyMembershipCardsManager {
        require(membershipCardsData[tokenId].freeMultiAssetSwapCount >= amount, "Insufficient free multi-asset swaps left");

        membershipCardsData[tokenId].freeMultiAssetSwapCount -= amount;
    }

    function mint(address recipient) external payable returns(uint256) {
        mintedSupply++;

        if (supplyCap > 0)
            require(mintedSupply - 1 < supplyCap, "Supply cap reached");

        if (remainingFreeMints[msg.sender] > 0) {
            require(msg.value == 0, "Liquidity not needed");

            remainingFreeMints[msg.sender]--;   
        } else {
            require(msg.value > 0, "Must send liquidity");

            (, int256 ethUSDPrice, , , ) = AggregatorV3Interface(oracleDataFeed).latestRoundData();

            uint8 oracleDataDecimals = AggregatorV3Interface(oracleDataFeed).decimals();

            uint256 paidUSDAmount = (msg.value * uint256(ethUSDPrice)) / (10 ** oracleDataDecimals);

            require(paidUSDAmount >= priceUSD, "Insufficient funds");

            uint256 valueToRefund = 0;

            if (paidUSDAmount - priceUSD > 0) {
                valueToRefund = ((paidUSDAmount - priceUSD) * (10 ** oracleDataDecimals)) / uint256(ethUSDPrice);
                
                (bool refundSuccess, ) = msg.sender.call{value: valueToRefund }("");

                require(refundSuccess, "Unable to refund extra liquidity");
            }

            (bool liquiditySendToTreasurySuccess, ) = treasuryAddress.call{value: msg.value - valueToRefund }("");

            require(liquiditySendToTreasurySuccess, "Unable to send liquidity to treasury");
        }

        uint256 tokenId = _currentTokenId++;

        _mint(recipient, tokenId);

        membershipCardsData[tokenId].volume = startingVolume;
        membershipCardsData[tokenId].nftPriceCap = nftPriceCap;
        membershipCardsData[tokenId].freeMultiAssetSwapCount = freeMultiAssetSwapCount;

        emit Mint(recipient, tokenId, _tokenURI, membershipCardsData[tokenId]);

        return tokenId;
    }

    function multichainTransferFrom(address from, address to, uint256 tokenId, uint256 destinationNetworkId, address destinationContractAddress) external {
        transferFrom(from, address(this), tokenId);

        _burn(tokenId);

        emit MultichainTransferFrom(to, tokenId, _networkId, address(this), destinationNetworkId, destinationContractAddress, membershipCardsData[tokenId]);
    
        delete membershipCardsData[tokenId];
    }

    function multichainClaim(bytes calldata multichainClaimData_, uint8[] calldata v, bytes32[] calldata r, bytes32[] calldata s) external returns(uint256) {
        bytes32 generatedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(multichainClaimData_)));

        uint256 validationChecks = 0;

        for (uint256 i = 0; i < v.length; i++)
            if (isValidator[ecrecover(generatedHash, v[i], r[i], s[i])])
                validationChecks++;

        require(validationChecks >= validationChecksRequired, "Not enough validation checks");
        require(!_isMultichainHashProcessed[generatedHash], "Message already processed");

        MultichainClaimData memory multichainClaimData = abi.decode(multichainClaimData_, (MultichainClaimData));

        require(multichainClaimData.destinationContractAddress == address(this), "Multichain destination address must be this contract");
        require(multichainClaimData.destinationNetworkId == _networkId, "Wrong destination network id");

        _isMultichainHashProcessed[generatedHash] = true;

        uint256 mintTokenId = _currentTokenId++;

        _mint(multichainClaimData.to, mintTokenId);

        membershipCardsData[mintTokenId].volume = multichainClaimData.membershipCardData.volume;
        membershipCardsData[mintTokenId].nftPriceCap = multichainClaimData.membershipCardData.nftPriceCap;
        membershipCardsData[mintTokenId].freeMultiAssetSwapCount = multichainClaimData.membershipCardData.freeMultiAssetSwapCount;

        emit Mint(multichainClaimData.to, mintTokenId, _tokenURI, membershipCardsData[mintTokenId]);

        emit MultichainClaim(multichainClaimData.to, mintTokenId, multichainClaimData.fromTokenId, multichainClaimData.fromNetworkId, multichainClaimData.fromContractAddress, multichainClaimData.destinationNetworkId, multichainClaimData.destinationContractAddress, membershipCardsData[mintTokenId]);

        return mintTokenId;
    }

    function multichainConsumeMembershipCard(uint256 tokenId, uint256 destinationNetworkId, address destinationContractAddress, uint256 volume_, uint256 freeMultiAssetSwapCount_) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner of the specified tokenId");

        require(membershipCardsData[tokenId].volume >= volume_, "Not enough volume");

        membershipCardsData[tokenId].volume -= volume_;

        require(membershipCardsData[tokenId].freeMultiAssetSwapCount >= freeMultiAssetSwapCount_, "Not enough freeMultiAssetSwapCount");

        membershipCardsData[tokenId].freeMultiAssetSwapCount -= freeMultiAssetSwapCount_;
        
        emit MultichainConsumeMembershipCard(msg.sender, tokenId, block.number, _networkId, address(this), destinationNetworkId, destinationContractAddress, volume_, freeMultiAssetSwapCount_);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return _tokenURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns(bool) {
        return interfaceId == type(ERC721EnumerableUpgradeable).interfaceId || interfaceId == type(ERC721BurnableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function burn(uint256 tokenId) public override {
        super.burn(tokenId);

        mintedSupply--;
    }

    function __FayreMembershipCard721_init(string memory name_, string memory symbol_, uint256 priceUSD_, uint256 startingVolume_, uint256 supplyCap_, uint256 nftPriceCap_, uint256 freeMultiAssetSwapCount_) internal onlyInitializing {
        __Ownable_init();

        __ERC721_init(name_, symbol_);

        __ERC721Enumerable_init();

        __FayreMembershipCard721_init_unchained(priceUSD_, startingVolume_, supplyCap_, nftPriceCap_, freeMultiAssetSwapCount_);
    }

    function __FayreMembershipCard721_init_unchained(uint256 priceUSD_, uint256 startingVolume_, uint256 supplyCap_, uint256 nftPriceCap_, uint256 freeMultiAssetSwapCount_) internal onlyInitializing {
        _networkId = block.chainid;
        
        priceUSD = priceUSD_;

        startingVolume = startingVolume_;

        supplyCap = supplyCap_;

        nftPriceCap = nftPriceCap_;

        freeMultiAssetSwapCount = freeMultiAssetSwapCount_;

        validationChecksRequired = 1;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        ERC721EnumerableUpgradeable._beforeTokenTransfer(from , to, tokenId);
    }

    uint256[33] private __gap;
}