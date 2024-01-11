// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// import "./ERC1155Pausable.sol";
import "./ERC1155.sol";
import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

/*
  __________  ____  __________  __________________________  _____
 /_  __/ __ \/ __ \/ ____/ __ \/  _/_  __/_  __/ ____/ __ \/ ___/
  / / / / / / /_/ / /   / /_/ // /  / /   / / / __/ / /_/ /\__ \ 
 / / / /_/ / ____/ /___/ _, _// /  / /   / / / /___/ _, _/___/ / 
/_/  \____/_/    \____/_/ |_/___/ /_/   /_/ /_____/_/ |_|/____/ 

*/

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract TopCritters is ERC1155, EIP712, Ownable {
    string public name = "TopCritters";
    string public symbol = "TC";

    bool private _paused = false;
    bool private _isMarketplacesApproved = true;
    bool private _allowMultipleMints = false;
    address private _signer;
    string private _baseTokenURI;

    struct MintKey {
        address wallet;
        uint16 tokenId;
    }

    bytes32 private constant MINTKEY_TYPE_HASH =
        keccak256("MintKey(address wallet,uint16 tokenId)");

    mapping(address => mapping(uint256 => bool)) private addressHasMinted;
    address private immutable _openSeaProxyRegistryAddress;
    address private immutable _looksRareTransferManagerAddress;

    constructor(
        address openSeaProxyRegistryAddress,
        address looksRareTransferManagerAddress,
        address signer,
        string memory baseTokenURI,
        bool isMarketplacesApproved,
        bool paused
    ) ERC1155(baseTokenURI) EIP712(name, "1") {
        _openSeaProxyRegistryAddress = openSeaProxyRegistryAddress;
        _looksRareTransferManagerAddress = looksRareTransferManagerAddress;
        _signer = signer;
        _baseTokenURI = baseTokenURI;
        _isMarketplacesApproved = isMarketplacesApproved;
        _paused = paused;
    }

    modifier whenNotPaused() {
        require(!isPaused(), "TP: Contract is paused");
        _;
    }

    function changePauseState(bool newState) external onlyOwner {
        require(_paused != newState, "TP: Contract already in this state");
        _paused = newState;
    }

    function changeAllowMultipleMintsState(bool newState) external onlyOwner {
        require(_allowMultipleMints != newState, "TP: Contract already in this state");
        _allowMultipleMints = newState;
    }

    function setBaseTokenURI(string calldata baseTokenURI) external onlyOwner {
        _setURI(baseTokenURI);
    }

    /**
     * Sets whether the Marketplaces addresses are active and should be automatically approved
     */
    function setMarketplacesApproved(bool isMarketplacesApproved) external onlyOwner {
        _isMarketplacesApproved = isMarketplacesApproved;
    }

    function mintMultiple(bytes[] calldata signatures, MintKey[] calldata mintKeys)
        external
        whenNotPaused
    {
        require(tx.origin == msg.sender, "TP: We like real minters");
        require(signatures.length == mintKeys.length, "TP: Not enough signatures or mintKeys");
        uint256[] memory tokenIds = new uint256[](mintKeys.length);
        uint256[] memory amounts = new uint256[](mintKeys.length);
        for (uint256 i = 0; i < signatures.length; i++) {
            if (!_allowMultipleMints) {
                require(
                    !addressHasMinted[msg.sender][mintKeys[i].tokenId],
                    "TP: Address already minted"
                );
            }
            require(verify(signatures[i], mintKeys[i]), "TP: Could not be verified");
            addressHasMinted[msg.sender][mintKeys[i].tokenId] = true;
            tokenIds[i] = mintKeys[i].tokenId;
            amounts[i] = 1;
        }
        _mintBatch(msg.sender, tokenIds, amounts, "");
    }

    function verify(bytes calldata signature, MintKey calldata mintKey)
        public
        view
        returns (bool)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(MINTKEY_TYPE_HASH, mintKey.wallet, mintKey.tokenId))
        );

        return ECDSA.recover(digest, signature) == _signer;
    }

    /**
     * Gasless listing on OpenSea and LooksRare
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(_openSeaProxyRegistryAddress);
        if (
            _isMarketplacesApproved &&
            (address(proxyRegistry.proxies(owner)) == operator ||
                _looksRareTransferManagerAddress == operator)
        ) return true;

        return super.isApprovedForAll(owner, operator);
    }

    function hasAddressMinted(address wallet, uint16 tokenId) external view returns (bool) {
        return addressHasMinted[wallet][tokenId];
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function isPaused() public view returns (bool) {
        return _paused;
    }

    function allowMultipleMints() public view returns (bool) {
        return _allowMultipleMints;
    }
}
