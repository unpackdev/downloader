// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./UUPSUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

import "./ISpaceCows.sol";

import "./Whitelisted.sol";
import "./Random.sol";

contract Sale is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable, Whitelisted {
    using StringsUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using Random for Random.Manifest;

    CountersUpgradeable.Counter private _tokenIdCounter;
    Random.Manifest private _manifest;

    string private _signingDomain;
    string private _signingVersion;

    uint256 public maxTokenSupply;
    uint256 public maxMintsPerTxn;
    uint256 public mintPrice;
    uint256 public maxPresaleMintsPerWallet;
    uint256 public teamReserved;
    uint256 public givewaysReserved;
    
    bool public presaleActive;
    bool public publicSaleActive;

    mapping(address => uint256) private _royaltyShares;
    mapping(address => uint256) private _whitelistBuys;
    mapping(address => uint256[]) private _reservedTokenIds;

    address[] private _royaltyAddresses;
    
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    ISpaceCows public spaceCows;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        uint256 _maxSupply,
        uint256 _maxMintsPerTxn,
        uint256 _mintPrice,
        uint256 _maxPresaleMintsPerWallet,
        uint256 _teamReserved,
        uint256 _givewaysReserved,
        string memory signingDomain_,
        string memory signingVersion_
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        _signingDomain = signingDomain_;
        _signingVersion = signingVersion_;

        maxTokenSupply = _maxSupply;
        maxMintsPerTxn = _maxMintsPerTxn;
        mintPrice = _mintPrice;
        maxPresaleMintsPerWallet = _maxPresaleMintsPerWallet;
        teamReserved = _teamReserved;
        givewaysReserved = _givewaysReserved;
        _manifest.setup(_maxSupply);

        presaleActive = false;
        publicSaleActive = false;

        _royaltyAddresses = [
            0xced6ACCbEbF5cb8BD23e2B2E8B49C78471FaAe20, // Wallet 1 address
            0x4386103c101ce063C668B304AD06621d6DEF59c9, // Wallet 2 address
            0x19Bb04164f17FF2136A1768aA4ed22cb7f1dAa00, // Wallet 3 address
            0x910040fA04518c7D166e783DB427Af74BE320Ac7 // Wallet 4 address
        ];

        _royaltyShares[_royaltyAddresses[0]] = 25; // Royalty for Wallet 1
        _royaltyShares[_royaltyAddresses[1]] = 25; // Royalty for Wallet 2
        _royaltyShares[_royaltyAddresses[2]] = 25; // Royalty for Wallet 3
        _royaltyShares[_royaltyAddresses[3]] = 25; // Royalty for Wallet 4
    }

    function setMaxTokenSupply(uint256 _newMaxSupply) external onlyOwner {
        maxTokenSupply = _newMaxSupply;
    }

    function setMaxMintsPerTxn(uint256 _newMaxMintsPerTxn) external onlyOwner {
        maxMintsPerTxn = _newMaxMintsPerTxn;
    }

    function setMintPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function setMaxPresaleMintsPerWallet(uint256 _newLimit) external onlyOwner {
        maxPresaleMintsPerWallet = _newLimit;
    }

    function setSpaceCowsAddress(address _newNftContract) external onlyOwner {
        spaceCows = ISpaceCows(_newNftContract);
    }

    function setPresaleActive() external onlyOwner {
        require(!isSaleActive(), "Sale started!");
        presaleActive = true;
    }

    function setPublicSaleActive() external onlyOwner {
        require(presaleActive, "Presale is not active!");
        publicSaleActive = true;
        presaleActive = false;
    }

    function isSaleActive() public view returns(bool) {
        if(presaleActive || publicSaleActive) {
            return true;
        } else {
            return false;
        }
    }

    function deactiveSales() external onlyOwner {
        publicSaleActive = false;
        presaleActive = false;
    } 

    function setWhitelistRoot(bytes32 _newWhitelistRoot) external onlyOwner {
        _setWhitelistRoot(_newWhitelistRoot);
    }

    function remaining() public view returns (uint256) {
        return _manifest.remaining();
    }

    function getReservedTokenIds(address _user) external view returns(uint256[] memory) {
        uint256[] memory tokenIds = _reservedTokenIds[_user];
        uint256 counter = 0;
        uint256 index = 0;

        for(uint256 i = 0; i < tokenIds.length; ++i) {
            if (tokenIds[i] > 0) {
                counter++;
            } else {
                continue;
            }
        }

        uint256[] memory _remainingTokenIds = new uint256[](counter);
        for(uint256 i = 0; i < tokenIds.length; ++i) {
            if (tokenIds[i] > 0) {
                _remainingTokenIds[index] = tokenIds[i];
                index++;
            } else {
                continue;
            }
        }

        return _remainingTokenIds;
    }

    function getWhitelistBuys(address _user) public view returns(uint256) {
        return _whitelistBuys[_user];
    }

    /*
    * Mint NFTs during pre-sale
    */
    function whitelistPurchase(uint256 numberOfTokens, bytes32[] calldata proof)
    external
    payable
    nonReentrant()
    onlyWhitelisted(msg.sender, address(this), proof) {
        uint256 mintIndex = _tokenIdCounter.current();
        address user = msg.sender; 

        require(presaleActive, "Presale is not started!");
        require(_whitelistBuys[user] + numberOfTokens <= maxPresaleMintsPerWallet, "You can only mint 10 token(s) on presale per wallet!");
        require(mintIndex + numberOfTokens + teamReserved + givewaysReserved <= maxTokenSupply, "Not enough tokens!");
        require(msg.value >= mintPrice * numberOfTokens, "Not enough ETH!");

        _whitelistBuys[user] += numberOfTokens;

        for(uint256 i = 0; i < numberOfTokens; i++) {
            _reservedTokenIds[user].push(_manifest.draw());
            _tokenIdCounter.increment();
        }

        emit PaymentReceived(msg.sender, msg.value);
    }

    /*
    * Mint NFTs during public sale
    */
    function publicPurchase(uint256 numberOfTokens)
    external
    payable
    nonReentrant() {
        uint256 mintIndex = _tokenIdCounter.current();
        address user = msg.sender; 

        require(publicSaleActive, "Sale not started!");
        require(numberOfTokens <= maxMintsPerTxn, "You can buy up to 10 per transaction");
        require(mintIndex + numberOfTokens + teamReserved + givewaysReserved <= maxTokenSupply, "Not enough tokens!");
        require(msg.value >= mintPrice * numberOfTokens, "Not enough ETH!");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            _reservedTokenIds[user].push(_manifest.draw());
            _tokenIdCounter.increment();
        }

        emit PaymentReceived(msg.sender, msg.value);
    }

    function mint(uint256[] memory _tiers, uint256[] memory _rates, bytes[] memory _signature) 
    external 
    nonReentrant() {
        address user = msg.sender;
        uint256[] memory tokenIds = _reservedTokenIds[user];
        require(tokenIds.length != 0, "No reserved token");
        uint256 index = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] > 0) {
                address signer = _verify(tokenIds[i], _tiers[index], _rates[index], _signature[index]);
                require(signer == owner(), "Signature didn't match");

                spaceCows.mint(user, tokenIds[i], _tiers[index], _rates[index]);
                delete _reservedTokenIds[user][i];
                index++;
            } else {
                continue;
            }
        }
    }

    // Mint NFTs for giveway and team
    function freeToken(address _user, uint256 _amount) external onlyOwner {
        uint256 mintIndex = _tokenIdCounter.current();
        require(mintIndex + _amount <= maxTokenSupply, "Not enough tokens!");

        for (uint256 i = 0; i < _amount; i++) {
            _reservedTokenIds[_user].push(_manifest.draw());
            _tokenIdCounter.increment();
        }
    }

    function freeMint(address _user, uint256[] memory _tiers, uint256[] memory _rates, bytes[] memory _signature) external onlyOwner {
        uint256[] memory tokenIds = _reservedTokenIds[_user];
        require(tokenIds.length != 0, "No reserved token");
        uint256 index = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] > 0) {
                address signer = _verify(tokenIds[i], _tiers[index], _rates[index], _signature[index]);
                require(signer == owner(), "Signature didn't match");

                spaceCows.mint(_user, tokenIds[i], _tiers[index], _rates[index]);
                delete _reservedTokenIds[_user][i];
                index++;
            } else {
                continue;
            }
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Empty balance");

        for (uint256 i = 0; i < _royaltyAddresses.length; i++) {
            uint256 payment = balance / 100 * _royaltyShares[_royaltyAddresses[i]];

            AddressUpgradeable.sendValue(payable(_royaltyAddresses[i]), payment);
            emit PaymentReleased(_royaltyAddresses[i], payment);                
        }
    }

    function _verify(uint256 tokenId, uint256 tier, uint256 rate, bytes memory signature) internal view returns (address) {
        bytes32 msgHash = keccak256(abi.encodePacked(_signingDomain, _signingVersion, address(this), tokenId, tier, rate));
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        return signedHash.recover(signature);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}