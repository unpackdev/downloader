// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "./ECDSA.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./ERC721TradableUpgradeable.sol";
import "./AScientistRepository.sol";
import "./IScientistCharacteristic.sol";

contract Scientist is
    IScientistCharacteristic,
    ERC721TradableUpgradeable,
    ERC2981Upgradeable,
    PausableUpgradeable,
    AScientistRepository,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    // Constants
    uint8 public constant LENGTH_OF_SCIENTIFIC_FIELDS = 6;
    uint8 public constant LENGTH_OF_PERSONALITY_DISORDERS = 5;
    uint8 public constant LENGTH_OF_AUTHORITY = 5;
    uint8 public constant LENGTH_OF_CONVENTIONS = 3;
    uint8 public constant LENGTH_OF_VIOLENCE = 6;
    uint8 public constant LENGTH_OF_VICES = 7;
    uint8 public constant LENGTH_OF_MAGNITUDE_OF_STRESS = 7;
    uint256 public constant MAX_MINTABLE = 10500;

    // Variables
    Counters.Counter private tokenIdCount;
    string public baseTokenURI;
    string public contractURI;
    bytes32 public stagesID;
    uint256 public price;
    uint256 public maxClaimed;
    uint256 public mintableAmount;
    uint256 public remainingAmount;
    uint96 public feeNumerator;
    address private proxyRegistryAddress;
    mapping(uint256 => ScientistTraits) public scientistTraits;
    bool public isCanTransfer;
    address public signer;
    mapping(bytes => uint256) public claimedTime;

    // Events
    event SetNewTranche(
        address signer,
        bytes32 stagesID,
        uint256 newPrice,
        uint256 newAmount,
        uint256 newMaxClaimed,
        uint256 timestamp
    );
    event MintForGift(
        address caller,
        address to,
        uint256 tokenId,
        uint256 timestamp
    );
    event SetBaseTokenURI(string uri, uint256 timestamp);
    event SetContractURI(string uri, uint256 timestamp);
    event SetProxyRegistry(address proxy, uint256 timestamp);

    /**
     * @dev validates signature
     */
    modifier isValidSign(
        address to,
        bytes calldata sig,
        uint256 index
    ) {
        bytes32 dataHash = keccak256(abi.encodePacked(to, stagesID, index));
        bytes32 ethSigHash = dataHash.toEthSignedMessageHash();
        require(_verifySig(ethSigHash, sig), "This wallet is not in whitelist");
        require(
            claimedTime[sig] < maxClaimed,
            "This wallet reached claimed times to mint Scientist"
        );
        claimedTime[sig]++;
        _;
    }

    function _verifySig(bytes32 ethSigHash, bytes calldata sig)
        internal
        view
        returns (bool)
    {
        address _signer = ethSigHash.recover(sig);
        require(_signer != address(0), "ECDSA: invalid signature");
        return _signer == signer;
    }

    function claimable(
        address account,
        bytes calldata sig,
        uint256 index
    ) external view returns (bool) {
        bytes32 dataHash = keccak256(
            abi.encodePacked(account, stagesID, index)
        );
        bytes32 ethSigHash = dataHash.toEthSignedMessageHash();
        return _verifySig(ethSigHash, sig) && claimedTime[sig] < maxClaimed;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        address _timelock
    ) external initializer {
        require(_proxyRegistryAddress != address(0), "Empty address");
        proxyRegistryAddress = _proxyRegistryAddress;
        timelock = _timelock;
        __ERC721_init(_name, _symbol);
        _initializeEIP712(_name);
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();
        baseTokenURI = "";
        contractURI = "";
        maxClaimed = 5;
    }

    function getProxyRegistryAddress()
        public
        view
        virtual
        override
        returns (address)
    {
        return proxyRegistryAddress;
    }

    function setProxyRegistryAddress(address newProxyRegistryAddress)
        external
        onlyTimelock
    {
        require(newProxyRegistryAddress != address(0), "Empty address");
        proxyRegistryAddress = newProxyRegistryAddress;
        emit SetProxyRegistry(newProxyRegistryAddress, block.timestamp);
    }

    function setBaseTokenURI(string memory uri) external onlyTimelock {
        baseTokenURI = uri;
        emit SetBaseTokenURI(uri, block.timestamp);
    }

    function setContractURI(string memory uri) external onlyTimelock {
        contractURI = uri;
        emit SetContractURI(uri, block.timestamp);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    function pause() external onlyTimelock {
        _pause();
    }

    function unpause() external onlyTimelock {
        _unpause();
    }

    function setNewTranche(
        address newSigner,
        bytes32 newStagesID,
        uint256 newPrice,
        uint256 newAmount,
        uint256 newMaxClaimed
    ) external onlyTimelock {
        require(newMaxClaimed > 0, "Invalid value");
        require(newSigner != address(0), "Empty address");
        signer = newSigner;
        maxClaimed = newMaxClaimed;
        stagesID = newStagesID;
        price = newPrice;
        remainingAmount = mintableAmount = newAmount;
        emit SetNewTranche(
            newSigner,
            newStagesID,
            newPrice,
            newAmount,
            newMaxClaimed,
            block.timestamp
        );
    }

    function _customBurn(uint256 tokenId) internal {
        require(scientists[tokenId].onSale == false, "Scientist is on sale");
        _removeScientist(msg.sender, tokenId);
        super._burn(tokenId);
        delete scientists[tokenId];
    }

    function burn(uint256 tokenId) external override {
        require(
            msg.sender == ownerOf(tokenId),
            "Caller is not owner of token id"
        );
        _customBurn(tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(isCanTransfer == true, "Can not transfer at this time");
        _removeScientist(from, tokenId);
        super._transfer(from, to, tokenId);
        _addScientist(to, tokenId);
    }

    function mintFor(
        address to,
        bytes calldata sign,
        uint256 index,
        ScientistTraits memory traits
    )
        external
        payable
        isValidSign(to, sign, index)
        nonReentrant
        isOperator
        whenNotPaused
    {
        _mintForGift(to, traits);
    }

    function mint(address to) external isOperator {
        _create(to);
    }

    function createMultiple(address to, uint256 amount) external isOperator {
        for (uint256 i = 0; i < amount; i++) {
            _create(to);
        }
    }

    function mintForGift(
        address to,
        bytes calldata sign,
        uint256 index,
        ScientistTraits memory traits
    )
        external
        payable
        isValidSign(msg.sender, sign, index)
        nonReentrant
        whenNotPaused
    {
        _mintForGift(to, traits);
    }

    function _mintForGift(address to, ScientistTraits memory traits) internal {
        require(
            traits.scientificField < LENGTH_OF_SCIENTIFIC_FIELDS &&
                traits.personalityDisorders < LENGTH_OF_PERSONALITY_DISORDERS &&
                traits.psychologicalForce.obedienceToAuthority <
                LENGTH_OF_AUTHORITY &&
                traits.psychologicalForce.obedienceToConventions <
                LENGTH_OF_CONVENTIONS &&
                traits.psychologicalForce.tendencyTowardViolence <
                LENGTH_OF_VIOLENCE &&
                traits.vice < LENGTH_OF_VICES &&
                traits.magnitudeOfStress < LENGTH_OF_MAGNITUDE_OF_STRESS,
            "Wrong traits for Scientist"
        );
        require(msg.value == price, "Invalid price");
        require(remainingAmount >= 1, "Sold out");
        remainingAmount--;
        _create(to);
        uint256 tokenId = tokenIdCount.current();
        scientistTraits[tokenId] = traits;
        emit MintForGift(msg.sender, to, tokenId, block.timestamp);
    }

    function _create(address _account) internal {
        require(
            tokenIdCount.current() < MAX_MINTABLE,
            "Can not create more Scientist"
        );
        tokenIdCount.increment();
        uint256 tokenId = tokenIdCount.current();
        _mint(_account, tokenId);
        _addScientist(_account, tokenId);
        _setTokenRoyalty(tokenId, msg.sender, feeNumerator);
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, AScientistRepository)
        returns (address)
    {
        return ERC721Upgradeable.ownerOf(tokenId);
    }

    function addScientist(address account, uint256 tokenId)
        external
        override
        isOperator
    {
        _addScientist(account, tokenId);
    }

    function removeScientist(uint256 _tokenId, address _owner)
        external
        override
        isOperator
    {
        _removeScientist(_owner, _tokenId);
    }

    function updateScientist(
        uint256 tokenId,
        ScientistData.Scientist memory scientistData,
        address account
    ) external override isOperator {
        _updateScientist(tokenId, scientistData, account);
    }

    function withdrawETH(address payable to) external onlyTimelock {
        uint256 balance = address(this).balance;
        to.transfer(balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setFeeNumerator(uint96 value) external onlyTimelock {
        feeNumerator = value;
    }

    function setIsCanTransfer(bool value) external onlyTimelock {
        isCanTransfer = value;
    }
}
