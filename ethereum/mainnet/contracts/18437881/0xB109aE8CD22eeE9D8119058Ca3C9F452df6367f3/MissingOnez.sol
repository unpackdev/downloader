// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControl.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./ERC2981.sol";
import "./Strings.sol";

import "./RandomPoolId.sol";
import "./M1ZPrices.sol";
import "./Withdraw.sol";
import "./StringUtils.sol";

contract MissingOnez is RandomPoolId, M1ZPrices, Withdraw, ERC721, ERC721Burnable, ERC721Enumerable, ERC2981, AccessControl {
    using Strings for uint256;
    using StringUtils for string;

    event Minted(uint256 timestamp, address sender, uint256 tokenId);
    event Revealed(uint256 timestamp, address sender, uint256 tokenId, uint256 id);
    event AutoRevealed(uint256 timestamp, address sender, uint256 tokenId, uint256 id);
    event SentCrossChain(uint256 timestamp, address sender, uint256[] tokenIds, uint256 destChainId);
    event ReceivedCrossChain(uint256 timestamp, address sender, uint256[] tokenIds, uint256[] ids, uint256 fromChainId);

    bytes32 public constant CROSS_CHAIN_ROLE = keccak256('CROSS_CHAIN_ROLE');

    uint96 public constant MAX_BATCH_MINT = 10;
    uint96 public constant ROYALTIES_VALUE = 500;

    string public baseURI;
    address public royaltyRecipient;
    string public unrevealedPath;
    uint256 public currentSupply;

    // tokenId mapped to randomly assigned id
    mapping(uint256 => uint256) private _tokenIdMap;

    mapping(uint256 => bool) public revealedTokenIds;

    bool public isMintOpen;

    constructor(
        address initialOwner,
        address _royaltyRecipient,
        uint256 _unitPrice,
        uint256 mintMinId,
        uint256 mintMaxId,
        string memory _unrevealedPath
    ) RandomPoolId(mintMinId, mintMaxId) M1ZPrices(_unitPrice) Withdraw(initialOwner) ERC721('Missing Onez', 'M1Z') {
        baseURI = 'https://cdn.madskullz.io/missingonez/metadata/';
        royaltyRecipient = _royaltyRecipient;
        unrevealedPath = _unrevealedPath;
        _setDefaultRoyalty(_royaltyRecipient, ROYALTIES_VALUE);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(CROSS_CHAIN_ROLE, _msgSender());
    }

    //////////////////////////////////////////
    // MINT
    //////////////////////////////////////////

    /**
     * @dev CALLED BY CHAINLINK
     * Free-mint method.
     * This method should be called either:
     * - by the M1ZDestinationMinter contract when called by CCIP (eg: paid mint from another chain)
     * - by the CROSS_CHAIN_ROLE to free mint M1Z for giveaways
     * @param amount quantity of M1Z to mint.
     * @param to sender of the cross-chain call.
     */
    function mint(uint256 amount, address to) external onlyRole(CROSS_CHAIN_ROLE) {
        require(isMintOpen, 'M1Z: mint is not open');
        randomMint(amount, to);
    }

    /**
     * Normal paid mint method.
     * This is the method used when minting on the current chain.
     * @param amount quantity of M1Z to mint.
     */
    function paidMint(uint256 amount) external payable {
        require(isMintOpen, 'M1Z: mint is not open');
        uint256 price = getPrice(amount);

        require(msg.value >= price, 'M1Z: did not send enough native tokens');
        randomMint(amount, _msgSender());
    }

    function randomMint(uint256 amount, address to) internal {
        require(amount > 0, 'M1Z: must mint at least one');
        require(amount <= MAX_BATCH_MINT, 'M1Z: cannot mint more than MAX_BATCH_MINT at once');
        require(amount <= supplyLeft(), 'M1Z: not enough supply left to mint');

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = currentSupply + _minId;
            _safeMint(to, tokenId);
            currentSupply++;

            emit Minted(block.timestamp, _msgSender(), tokenId);
        }
    }

    /**
     * @dev CALLED BY CHAINLINK
     * Cross-chain transfer mint method.
     * This method should only be called by the M1ZDestinationMinter contract when called by CCIP.
     * It's only used when transfering an NFT from one chain to another.
     * @param to sender of the cross-chain call.
     */
    function mintFromCrossChainTransfer(
        uint256[] calldata tokenIds,
        uint256[] calldata ids,
        address to,
        uint256 fromChainId
    ) external onlyRole(CROSS_CHAIN_ROLE) {
        require(tokenIds.length == ids.length, 'M1Z: arrays lengths do not match');
        require(tokenIds.length > 0, 'M1Z: must transfer at least one');
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _safeMint(to, tokenIds[i]);
            _tokenIdMap[tokenIds[i]] = ids[i];
            revealedTokenIds[tokenIds[i]] = true;
        }
        emit ReceivedCrossChain(block.timestamp, to, tokenIds, ids, fromChainId);
    }

    //////////////////////////////////////////
    // BURN
    //////////////////////////////////////////

    /**
     * @dev CALLED BY CHAINLINK
     */
    function burn(uint256 tokenId) public override(ERC721Burnable) onlyRole(CROSS_CHAIN_ROLE) {
        super.burn(tokenId);
    }

    //////////////////////////////////////////
    // REVEAL
    //////////////////////////////////////////

    function reveal(uint256 tokenId) external {
        _checkAuthorized(_ownerOf(tokenId), _msgSender(), tokenId);
        require(!revealedTokenIds[tokenId], 'M1Z: already revealed');

        uint256 id = _randomize();
        _tokenIdMap[tokenId] = id;
        revealedTokenIds[tokenId] = true;

        emit Revealed(block.timestamp, _msgSender(), tokenId, id);
    }

    function autoReveal(uint256 tokenId) external onlyOwner {
        require(!revealedTokenIds[tokenId], 'M1Z: already revealed');

        uint256 id = _randomize();
        _tokenIdMap[tokenId] = id;
        revealedTokenIds[tokenId] = true;

        emit AutoRevealed(block.timestamp, _msgSender(), tokenId, id);
    }

    //////////////////////////////////////////
    // GETTER
    //////////////////////////////////////////

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        if (revealedTokenIds[tokenId]) {
            return
                bytes(baseURI).length > 0
                    ? string(abi.encodePacked(baseURI, _tokenIdMap[tokenId].toString().padStart(4, '0'), '.json'))
                    : '';
        } else {
            return string(abi.encodePacked(baseURI, unrevealedPath));
        }
    }

    function supplyLeft() public view returns (uint256) {
        return maxSupply() - currentSupply;
    }

    //////////////////////////////////////////
    // SETTER
    //////////////////////////////////////////

    function setBaseUri(string calldata _baseUri) external onlyOwner {
        baseURI = _baseUri;
    }

    function setUnrevealedPath(string memory _unrevealedPath) external onlyOwner {
        unrevealedPath = _unrevealedPath;
    }

    function setRoyaltyRecipient(address _royaltyRecipient) external onlyOwner {
        royaltyRecipient = _royaltyRecipient;
        _setDefaultRoyalty(_royaltyRecipient, ROYALTIES_VALUE);
    }

    function setMintOpen(bool _isMintOpen) external onlyOwner {
        isMintOpen = _isMintOpen;
    }

    //////////////////////////////////////////
    // MANDATORY OVERRIDES
    //////////////////////////////////////////

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId) public view override(ERC2981, ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
