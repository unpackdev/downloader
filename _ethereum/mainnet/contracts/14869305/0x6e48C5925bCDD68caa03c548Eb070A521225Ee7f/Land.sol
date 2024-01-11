// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

/// @author: upheaver.eth

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./IERC20Upgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./IERC1155Upgradeable.sol";

import "./CountersUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./AdminControlUpgradeable.sol";
import "./ILand.sol";
import "./console.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                           //
//                                  __       ______   __   __   _____                                        //
//                                 /\ \     /\  __ \ /\ "-.\ \ /\  __-.                                      //
//                                 \ \ \____\ \  __ \\ \ \-.  \\ \ \/\ \                                     //
//                                  \ \_____\\ \_\ \_\\ \_\\"\_\\ \____-                                     //
//                                   \/_____/ \/_/\/_/ \/_/ \/_/ \/____/                                     //
//                                                                                                           //
//                                                  By ForeverLands.xyz                                      //
//                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract Land is Initializable, ReentrancyGuardUpgradeable, AdminControlUpgradeable, ERC721BurnableUpgradeable, UUPSUpgradeable, ILand {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    
    CountersUpgradeable.Counter private _tokenIdCounter;
    CountersUpgradeable.Counter private _burnedCounter;

    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;
    
    string private _baseURIPrefix;
    address private _ERC721TokenAddress;
    address private _ERC1155TokenAddress;
    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    address payable private _recovery;
    address private _signer;
    bytes32[] _colonized;

    bool public discoveryEnabled;
    bool public colonizationEnabled;
    bool public portalsEnabled;
    bool public explorationEnabled;
    bool public mergeEnabled;
    uint256 public availableLand;

    struct Colony {
        address founder;
        uint256 level;
        EnumerableSetUpgradeable.AddressSet settlers;
        EnumerableSetUpgradeable.UintSet portals;
        mapping (address => uint256) shares;
    }

    mapping(uint256 => uint256) private _explorationLevel;
    mapping(uint256 => Colony) private _colonies;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _availableLand) initializer public {
        __ERC721_init("Land by ForeverLands", "LAND");
        __ERC721Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        _recovery = payable(owner());
        _tokenIdCounter.increment();
        availableLand = _availableLand;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        _burnedCounter.increment();
        emit Burn(tokenId);
        super._burn(tokenId);
    }

    function setBaseURI(string calldata uri) external override adminRequired {
        _baseURIPrefix = uri;
    }

    function setAvailableLand(uint256 count) external override adminRequired {
        require(count >= 0, "Invalid count");
        availableLand = count;
    }

    function setRecoveryAddress(address payable recovery) external override adminRequired {
        _recovery = recovery;
    }

    function setSignerAddress(address signer) external override adminRequired {
        _signer = signer;
    }

    function getSignerAddress() external view override returns (address) { 
        return _signer;
    }

    function safeMint(address to) external override adminRequired {
        _mintLand(to);
    }

    function colonize(bytes memory signature, address _from, uint256 _tokenId, uint256 _action) external override {
        require(colonizationEnabled, "Colonization inactive");
        require(_signer != address(0x0), "Signer not set");
        require(hasColony(_tokenId) == false, "Colony exists");
        require(_from == ownerOf(_tokenId), "Must be token owner");
        bytes32 hash = getMessageHash(_from, _tokenId, _action);
        address recovered = recoverSigner(hash, signature);
        if(recovered == _signer && _action == 1) {
            _createColony(_tokenId, _from);
        }
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override nonReentrant returns(bytes4) {
        _onERC1155Received(from, id, value, data);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override nonReentrant returns(bytes4) {
        require(ids.length == 1 && ids.length == values.length, "Invalid input");
        _onERC1155Received(from, ids[0], values[0], data);
        return this.onERC1155BatchReceived.selector;
    }

    // burn shard
    // burn other lands with variable failure rate to explore land, by default 20%.

    function _onERC1155Received(address from, uint256 id, uint256 value, bytes calldata data) private {
        require(msg.sender == _ERC1155TokenAddress && id == 1, "Invalid NFT");

        uint256 action;
        uint256 tokenId;
        uint256 colonyId;

        if (data.length == 32) {
            (action) = abi.decode(data, (uint256));
        } else if (data.length == 64) {
            (action, tokenId) = abi.decode(data, (uint256, uint256));
        } else if (data.length == 96) {
            (action, tokenId, colonyId) = abi.decode(data, (uint256, uint256, uint256));
        } else {
            revert("Invalid data");
        }

        if (action == 0) {
            /** Discover Land by burning Explorers */
            require(discoveryEnabled, "Discovery inactive");
            require(availableLand >= value, "Not enough stock");
        } else if (action == 1) {
            /** Explore Land by burning Explorers */
            require(explorationEnabled, "Exploration inactive");
            require(from == ownerOf(tokenId), "Must be token owner");
            require((_explorationLevel[tokenId] + value) <= 7, "Exploration limit");
        } else if (action == 2) {
            /** Colonize Land by burning Explorers */
            require(colonizationEnabled, "Colonization inactive");
            require(hasColony(tokenId), "No colony exists"); 
            require(_explorationLevel[tokenId] == 7, "Land must be fully Explored");
        } else if (action == 3) {
            /** Create Portals between any land and Colony */
            require(portalsEnabled, "Portals inactive");
            require(value == 1, "Can link one at a time");
            require(from == ownerOf(tokenId), "Must be token owner");
            require(hasColony(colonyId), "No colony exists");
            require(hasPortal(colonyId, tokenId) == false, "Portal exists");
        } else {
            revert("Invalid data");
        }

        // Burn it
        try IERC1155Upgradeable(msg.sender).safeTransferFrom(address(this), address(0xdEaD), id, value, data) {
        } catch (bytes memory) {
            revert("Burn failure");
        }

        if (action == 0) {
            availableLand -= value;
            for (uint i = 0; i < value; i++) {
                _mintLand(from);
            }
        } else if (action == 1) {
            _exploreLand(tokenId, value);
        } else if (action == 2) {
            _settleColony(from, tokenId, value);
        } else if (action == 3) {
            _createPortal(from, tokenId, colonyId);
        } else {
            revert("Invalid data");
        }
    }

    function onERC721Received(
        address,
        address from,
        uint256 receivedTokenId,
        bytes calldata data
    ) external override nonReentrant returns (bytes4) {
        require(msg.sender == _ERC721TokenAddress, "Invalid NFT");

        if (data.length != 64) revert("Invalid data");
        (uint256 action, uint256 tokenId) = abi.decode(data, (uint256, uint256));
        if (action != 10) revert("Invalid data");

        require(mergeEnabled, "Merge inactive");
        require(colonizationEnabled == false, "Colonization active");
        require(from == ownerOf(tokenId), "Must be token owner");

        // Burn it
        try IERC721Upgradeable(msg.sender).transferFrom(address(this), address(0xdEaD), receivedTokenId) {
        } catch (bytes memory) {
            revert("Burn failure");
        }
        if (action == 10) {
            _mergeOne(receivedTokenId, tokenId);
        }

        return this.onERC721Received.selector;
    }

    function _mergeOne(uint256 tokenFrom, uint256 tokenTo) private {
        uint256 left = _explorationLevel[tokenFrom] + 1;
        uint256 right = _explorationLevel[tokenTo];
        uint256 sum = left + right;
        if(sum < 7) {
            _explorationLevel[tokenTo] = sum;
        } else {
            _explorationLevel[tokenTo] = 7;
        }
        _burnedCounter.increment();
        emit Merge(tokenFrom, tokenTo);
        emit Burn(tokenFrom);
    }

    function _mintLand(address to) private {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        emit Discover(tokenId);
    }

    function _exploreLand(uint256 tokenId, uint256 count) internal {
        _explorationLevel[tokenId] += count;
        emit Explore(tokenId, count);
    }

    function _settleColony(address from, uint256 tokenId, uint256 count) internal {
        _colonies[tokenId].level += count;
        _colonies[tokenId].settlers.add(from);
        _colonies[tokenId].shares[from] += count;
        emit Settle(from, tokenId, count);
    }

    function _createColony(uint256 tokenId, address founder) internal {
        Colony storage colony = _colonies[tokenId];
        colony.founder = founder;
        emit Colonize(tokenId, founder);
    }

    function _createPortal(address from, uint256 tokenId, uint256 colonyId) internal {
        Colony storage colony = _colonies[colonyId];
        colony.portals.add(tokenId);
        emit Portal(from, tokenId, colonyId);
    }

    function hasColony(uint256 tokenId) public view override returns(bool) {
        return _colonies[tokenId].founder != address(0x0);
    }

    function hasPortal(uint256 colonyId, uint256 tokenId) public view override returns(bool) {
        return _colonies[colonyId].portals.contains(tokenId);
    }
    
    function getColony(uint256 tokenId) external view override returns (uint256, address, address[] memory, uint256[] memory, uint256[] memory) {
        uint256 len = _colonies[tokenId].settlers.length();
        uint256[] memory shares = new uint256[](len);
        address[] memory settlers = _colonies[tokenId].settlers.values();
        uint256[] memory portals = _colonies[tokenId].portals.values();
        for (uint i = 0; i < len; i++) {
            shares[i] = _colonies[tokenId].shares[settlers[i]];
        }
        return (_colonies[tokenId].level, _colonies[tokenId].founder, settlers, shares, portals);
    }

    function getExplorationLevel(uint256 tokenId) external view override returns (uint256) {
        return _explorationLevel[tokenId];
    }

    function getColonyLevel(uint256 tokenId) external view override returns(uint256) {
        return _colonies[tokenId].level;
    }

    function getColonyFounder(uint256 tokenId) external view override returns (address) {        
        return _colonies[tokenId].founder;
    }

    function getOwnershipShare(uint256 tokenId, address owner) external view override returns(uint256) {
        return _colonies[tokenId].shares[owner];
    }

    function getColonySettlers(uint256 tokenId) external view override returns (address[] memory) {
        return _colonies[tokenId].settlers.values();
    }

    function getColonyPortals(uint256 tokenId) external view override returns (uint256[] memory) {
        return _colonies[tokenId].portals.values();
    }

    function enableDiscovery() external override adminRequired {
        discoveryEnabled = true;
        emit ActivateDiscovery();
    }

    function disableDiscovery() external override adminRequired {
        discoveryEnabled = false;
        emit DeactivateDiscovery();
    }

    function enableExploration() external override adminRequired {
        explorationEnabled = true;
        emit ActivateExploration();
    }

    function disableExploration() external override adminRequired {
        explorationEnabled = false;
        emit DeactivateExploration();
    }

    function enablePortals() external override adminRequired {
        portalsEnabled = true;
        emit ActivatePortals();
    }

    function disablePortals() external override adminRequired {
        portalsEnabled = false;
        emit DeactivatePortals();
    }

    function enableColonization() external override adminRequired {
        colonizationEnabled = true;
        emit ActivateColonization();
    }

    function disableColonization() external override adminRequired {
        colonizationEnabled = false;
        emit DeactivateColonization();
    }

    function enableMerge() external override adminRequired {
        mergeEnabled = true;
        emit ActivateMerge();
    }

    function disableMerge() external override adminRequired {
        mergeEnabled = false;
        emit DeactivateMerge();
    }

    function updateERC1155Address(address erc1155address) external override adminRequired {
        _ERC1155TokenAddress = erc1155address;
    }

    function updateERC721Address(address erc721address) external override adminRequired {
        _ERC721TokenAddress = erc721address;
    }

    function getERC721Address() external view override returns (address) {
        return _ERC721TokenAddress;
    }

    function getERC1155Address() external view override returns (address) { 
        return _ERC1155TokenAddress;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControlUpgradeable, ERC721Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || ERC721Upgradeable.supportsInterface(interfaceId) 
            || AdminControlUpgradeable.supportsInterface(interfaceId) || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 
            || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    function updateRoyalties(address payable recipient, uint256 bps) external override adminRequired {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    function getRoyalties(uint256) external view override returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view override returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view override returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view override returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }

    function getEthBalance() external view override returns (uint256) {
        return address(this).balance;
    }

    function totalSupply() external view override returns (uint256) {
        return _tokenIdCounter.current() - _burnedCounter.current() - 1;
    }

    function withdraw(uint256 amount) external override adminRequired {
        _recovery.transfer(amount);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external virtual override adminRequired {
        IERC20Upgradeable(tokenAddress).transferFrom(address(this), _recovery, tokenAmount);
    }

    function recoverERC721(address tokenAddress, uint256 tokenId) external virtual override adminRequired {
        IERC721Upgradeable(tokenAddress).transferFrom(address(this), _recovery, tokenId);
    }

    function recoverERC1155(address tokenAddress, uint256 tokenId, uint256 amount) external virtual override adminRequired {
        IERC1155Upgradeable(tokenAddress).safeTransferFrom(address(this), _recovery, tokenId, amount, "");
    }

    function recoverSigner(bytes32 hash, bytes memory signature) public pure returns (address) {
        bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return ECDSAUpgradeable.recover(messageDigest, signature);
    }

    function getMessageHash(address _from, uint256 _tokenId, uint256 _action) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_from, _tokenId, _action));
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        adminRequired
        override
    {}
}