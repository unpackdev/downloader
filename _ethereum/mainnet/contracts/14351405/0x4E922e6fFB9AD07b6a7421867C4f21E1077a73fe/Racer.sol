// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "./ERC721.sol";
import "./IERC20.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./AccessControlEnumerable.sol";

contract Racer is
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable,
    AccessControlEnumerable,
    Ownable
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SPENDER_ROLE = keccak256("SPENDER_ROLE");

    Counters.Counter internal _tokenIdTracker;

    string internal _baseTokenURI;

    // Mappings from token ID to value
    mapping(uint256 => uint256) internal _dna;
    mapping(uint256 => string) internal _canonicalURI;
    mapping(uint256 => uint256) internal _meltTokensInToken;
    mapping(uint256 => uint256) public birthday;
    mapping(uint256 => bool) public uriLocked;

    uint256 internal _allocatedMeltTokens;
    uint256 internal _minimumMeltValue = 1000 * 10**18;
    address public meltTokenAddress; // ERC20 token used to stuff NFTs
    IERC20 internal _MELT;

    event Melt(
        uint256 indexed racerId,
        uint256 dna,
        uint256 birthday,
        uint256 meltValue,
        address tokenTo
    );

    event PermanentURI(string _value, uint256 indexed _id);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address _meltTokenAddress
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        meltTokenAddress = _meltTokenAddress;
        _allocatedMeltTokens = 0;
        _MELT = IERC20(_meltTokenAddress);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _tokenIdTracker.increment(); // Start NFT IDs @ 1
    }

    function lockURI(uint256 tokenID) public onlyRole(URI_SETTER_ROLE) {
        uriLocked[tokenID] = true;
        emit PermanentURI(_canonicalURI[tokenID], tokenID);
    }

    function setCanonicalURI(string memory uri, uint256 tokenId)
        public
        onlyRole(URI_SETTER_ROLE)
    {
        require(!uriLocked[tokenId], "URI locked");
        _canonicalURI[tokenId] = uri;
    }

    function setCanonicalURIs(string[] memory uris, uint256[] memory tokenIds)
        public
        onlyRole(URI_SETTER_ROLE)
    {
        require(uris.length == tokenIds.length, "arrays different sizes");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _canonicalURI[tokenIds[i]] = uris[i];
        }
    }

    /* ERC721 Mint / Pause / Burn */

    function newToken(
        uint256 dna,
        address tokenReceiver,
        uint256 tokensAllocated
    ) public onlyRole(MINTER_ROLE) whenNotPaused {
        require(
            tokensAllocated >= _minimumMeltValue,
            "Must contain minimum melt value"
        );

        require(
            unallocatedBalance() >= tokensAllocated,
            "Not enough melt tokens in contract to mint new token"
        );

        uint256 currentID = _tokenIdTracker.current();
        _dna[currentID] = dna;
        _meltTokensInToken[currentID] = tokensAllocated;
        _allocatedMeltTokens += tokensAllocated;
        birthday[currentID] = block.timestamp;
        _mint(tokenReceiver, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory URI)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (bytes(_canonicalURI[tokenId]).length > 0) {
            URI = _canonicalURI[tokenId];
        } else {
            string memory baseURI = _baseURI();
            URI = bytes(baseURI).length > 0 ? baseURI : "";
        }
    }

    function pause() public virtual onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public virtual onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /* TOKEN INFO */
    function getDNA(uint256 tokenID) public view returns (uint256 dna) {
        return _dna[tokenID];
    }

    function nextTokenId() public view returns (uint256 nextId) {
        nextId = _tokenIdTracker.current();
    }

    function getBirthdays(uint256[] memory tokenIDs)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory birthdayList = new uint256[](tokenIDs.length);
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            birthdayList[i] = birthday[tokenIDs[i]];
        }
        return birthdayList;
    }

    /* TOKEN INTERACTIONS */
    function meltToken(uint256 tokenID) public {
        require(
            ownerOf(tokenID) == _msgSender(),
            "Only token holder can melt token"
        );

        require(
            _MELT.balanceOf(address(this)) >= _meltTokensInToken[tokenID],
            "Not enough $SLIVER in contract to MELT racer"
        );

        _MELT.transfer(_msgSender(), _meltTokensInToken[tokenID]);
        _allocatedMeltTokens = _allocatedMeltTokens >
            _meltTokensInToken[tokenID]
            ? _allocatedMeltTokens -= _meltTokensInToken[tokenID]
            : 0;
        emit Melt(
            tokenID,
            _dna[tokenID],
            birthday[tokenID],
            _meltTokensInToken[tokenID],
            _msgSender()
        );
        _meltTokensInToken[tokenID] = 0;
        _dna[tokenID] = 0;
        birthday[tokenID] = 0;
        burn(tokenID);
    }

    function meltTokenBalance() public view returns (uint256 totalBalance) {
        return (_MELT.balanceOf(address(this)));
    }

    function unallocatedBalance() internal view returns (uint256 balance) {
        if (_MELT.balanceOf(address(this)) > _allocatedMeltTokens) {
            balance = _MELT.balanceOf(address(this)) - _allocatedMeltTokens;
        } else {
            balance = 0;
        }
    }

    // called to add directly from user's wallet to melt token
    function addMeltTokensToToken(uint256 tokenID, uint256 amountToSend)
        public
    {
        // this only works if this contract is first authorized to spend user's Melt token.
        // Should call authorize on ERC20 token directly from front end (user) first
        require(
            _MELT.allowance(_msgSender(), address(this)) >= amountToSend,
            "contract not allowed to spend user tokens"
        );
        _MELT.transferFrom(_msgSender(), address(this), amountToSend);
        _meltTokensInToken[tokenID] += amountToSend;
        _allocatedMeltTokens += amountToSend;
    }

    function getMeltValue(uint256 tokenID) public view returns (uint256 value) {
        return (_meltTokensInToken[tokenID]);
    }

    /* ADMIN FUNCTIONS */

    function setNewAdmin(address newAdmin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(DEFAULT_ADMIN_ROLE, getRoleMember(DEFAULT_ADMIN_ROLE, 0));
        _setupRole(DEFAULT_ADMIN_ROLE, newAdmin);
        transferOwnership(newAdmin);
    }

    /* RACER WALLET INTERACTIONS */
    function withdrawMeltTokensTo(
        address toAddress,
        uint256 amount,
        uint256 tokenID
    ) public onlyRole(SPENDER_ROLE) {
        require(
            getMeltValue(tokenID) >= (_minimumMeltValue + amount),
            "Not enough tokens in NFT"
        );
        _MELT.transfer(toAddress, amount);
        _meltTokensInToken[tokenID] = _meltTokensInToken[tokenID] > amount
            ? _meltTokensInToken[tokenID] - amount
            : 0;
        _allocatedMeltTokens = _allocatedMeltTokens > amount
            ? _allocatedMeltTokens - amount
            : 0;
    }

    function allocateMeltTokens(uint256 tokenID, uint256 amount)
        public
        onlyRole(SPENDER_ROLE)
    {
        require(
            unallocatedBalance() >= amount,
            "Not enough unallocated tokens in contract"
        );
        _meltTokensInToken[tokenID] += amount;
        _allocatedMeltTokens += amount;
    }

    function deallocateMeltTokens(uint256 tokenID, uint256 amount)
        public
        onlyRole(SPENDER_ROLE)
    {
        require(
            _meltTokensInToken[tokenID] >= (_minimumMeltValue + amount),
            "Not enough tokens in NFT to deallocate"
        );
        _meltTokensInToken[tokenID] = _meltTokensInToken[tokenID] > amount
            ? _meltTokensInToken[tokenID] - amount
            : 0;
        _allocatedMeltTokens = _allocatedMeltTokens > amount
            ? _allocatedMeltTokens - amount
            : 0;
    }

    function withdrawUnallocatedTokensTo(address toAddress, uint256 amount)
        public
        onlyRole(SPENDER_ROLE)
    {
        require(
            unallocatedBalance() >= amount,
            "Not enough unallocated tokens in contract"
        );
        _MELT.transfer(toAddress, amount);
    }
}
