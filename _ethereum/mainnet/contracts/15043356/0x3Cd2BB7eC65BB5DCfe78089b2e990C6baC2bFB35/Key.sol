// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IERC2981.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

import "./ERC721A.sol";

import "./Voidish.sol";

/*********************************************************************************************************
 * This Key of Nothing is not for nought.
 * It is, perhaps, the requisite material to return your stolen valor, in a world that continues burning.
 *********************************************************************************************************/

contract Key is ERC721A, IERC2981, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    bool public forged;
    bool public unlocked;
    string public lock;
    Voidish public void;
    IERC721A public nothings;
    address public locksmith;
    address public gateway;
    uint256 public claimed;
    uint256 public constant locks = 1111;
    uint256 public constant forgotten = 408;
    string private constant oath = "I am not Something, maybe I am Nothing, but I am pure of heart, and I claim this Key to Something Greater";
    mapping(uint256 => bool) public bound;
    mapping(uint256 => bool) public somethings;
    mapping(address => bool) public nobody;

    constructor(address _nothings, address _void) ERC721A("keys", "KEY") {
        nothings = IERC721A(_nothings);
        void = Voidish(_void);
    }

    /**
     * You began as Nothing.
     * Unos Tres Octo was awakened, reborn as a hero.
     * You trusted the void with Nothing and we opened for you the gates of heaven and poured out for you overflowing bounties.
     */

    function fromsomethings(uint256[] calldata nothingIds) external nonReentrant {
        uint256 keys = _totalMinted();
        uint256 count = nothingIds.length;

        require(msg.sender == tx.origin, "no lockpicking");
        require(forged, "the keys are not yet forged");
        require(keys + count <= locks, "all locks now have their key");

        for (uint256 idx; idx < count; ++idx) {
            uint256 nothingId = nothingIds[idx];

            require(!somethings[nothingId], "something has already been retrieved");
            require(_senderhasnothing(nothingId), "cannot trade something that is not yours");
            require(void.hasBecomeSomething(nothingId), "return with something");

            somethings[nothingId] = true;
        }

        _mint(msg.sender, count);
    }

    /**
     * Our future is ephemeral.
     * Yet, there is no such thing as tomorrow, only Nothing.
     * You and I will never be because your time is now and my time is forever.
     * Accept our permanence and embrace this life.
     */

    function fromsomething(uint256 nothingId) external nonReentrant {
        uint256 keys = _totalMinted();

        require(msg.sender == tx.origin, "no lockpicking");
        require(forged, "the keys are not yet forged");
        require(!somethings[nothingId], "something has already been retrieved");
        require(_senderhasnothing(nothingId), "cannot trade something that is not yours");
        require(void.hasBecomeSomething(nothingId), "return with something");
        require(keys + 1 <= locks, "all locks now have their key");

        _mint(msg.sender, 1);
        somethings[nothingId] = true;
    }

    /**
     * All good gifts and every perfect gift begins as Nothing.
     */

    function fromnothing(address someplace, uint256 some) external onlyOwner {
        uint256 keys = _totalMinted();
        require(keys + some <= locks, "all locks now have their key");

        _mint(someplace, some);
    }

    /**
     * This is the way the universe begins.
     * This is the way the universe begins.
     * This is the way the universe begins.
     * Not with an explosion but with my Key.
     */

    function fromnobody(bytes calldata signature) external {
        uint256 keys = _totalMinted();

        require(msg.sender == tx.origin, "no lockpicking");
        require(msg.sender == _revealtrueidentity(signature), "you are not pure of heart");
        require(unlocked, "only something may retrieve a key");
        require(!nobody[msg.sender], "you already hold the key");
        require(keys + 1 <= locks, "all locks now have their key");
        require(claimed + 1 <= forgotten, "only remembered keys remain");

        _mint(msg.sender, 1);
        nobody[msg.sender] = true;
        ++claimed;
    }

    /**
     * Your soul is something which contains your everything.
     * Nothing contains no soul.
     * The soul, if we pursue Nothing, is the entire complex of bytes in which context you may exist, forever.
     */

    function bind(uint256 tokenId, bool _bind) external {
        require(msg.sender == gateway, "you lack the power");
        require(_exists(tokenId), "you are off key");

        bound[tokenId] = _bind;
    }

    function _senderhasnothing(uint256 tokenId) internal view returns (bool) {
        if (nothings.ownerOf(tokenId) == msg.sender) {
            return true;
        }
        (address renouncer, ) = void.vanished(tokenId);
        if (renouncer != address(0) && renouncer == msg.sender) {
            return true;
        }
        return false;
    }

    function _revealtrueidentity(bytes calldata signature) internal pure returns (address) {
        bytes32 hash = keccak256(bytes(oath));
        return hash.toEthSignedMessageHash().recover(signature);
    }

    function forge(bool _forged) external onlyOwner {
        forged = _forged;
    }

    function unlock(bool _unlocked) external onlyOwner {
        unlocked = _unlocked;
    }

    function changelock(string calldata _lock) external onlyOwner {
        lock = _lock;
    }

    function changelocksmith(address _locksmith) external onlyOwner {
        locksmith = _locksmith;
    }

    function changegateway(address _gateway) external onlyOwner {
        gateway = _gateway;
    }

    function alchemy() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success);
    }

    function alchemize(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (bound[startTokenId]) {
            revert("this key is bound to you");
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return lock;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "you are off key");
        return (locksmith, (salePrice * 7) / 100);
    }
}
