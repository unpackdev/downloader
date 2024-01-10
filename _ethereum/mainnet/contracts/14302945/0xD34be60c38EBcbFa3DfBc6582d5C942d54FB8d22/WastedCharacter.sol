//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./SafeERC20Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract WastedCharacter is
    ERC721EnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;

    modifier onlyNotOnPause() {
        require(!paused, "WAC: paused");
        _;
    }

    event CharacterCreated(address owner, uint256 characterId);
    event BlacklistCharacter(uint256 characterId, bool isLocked);
    event CharacterBought(address buyer, uint256 amount);

    uint256[] private _characters;
    uint256 public maxMint;
    uint256 public feePerCharacter;
    uint256 public maxPerBought;
    bool public paused;

    string private _uri;

    mapping(uint256 => bool) public blacklist;

    function initialize(
        string memory baseURI,
        uint256 _maxMint,
        uint256 _maxPerBought,
        uint256 _feePerCharacter
    ) public initializer {
        __ERC721_init_unchained("WastedCharacter", "WAC");
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        maxMint = _maxMint;
        maxPerBought = _maxPerBought;
        _uri = baseURI;
        feePerCharacter = _feePerCharacter;
    }

    function setFee(uint256 _feePerCharacter) external onlyOwner {
        feePerCharacter = _feePerCharacter;
    }

    function setMaxMint(uint256 _newMaxMint) external onlyOwner {
        require(_newMaxMint >= _characters.length);
        maxMint = _newMaxMint;
    }

    function togglePaused() external onlyOwner {
        paused = !paused;
    }

    function setMaxPerBought(uint256 _newMaxPerBought) external onlyOwner {
        require(_newMaxPerBought > 0, "WAC: invalid");
        maxPerBought = _newMaxPerBought;
    }

    function addCharacterToBlacklist(uint256 characterId) external onlyOwner {
        require(_characters[characterId] == 1, "WAC: character invalid");
        blacklist[characterId] = true;

        emit BlacklistCharacter(characterId, true);
    }

    function removeCharacterFromBlacklist(uint256 characterId)
        external
        onlyOwner
    {
        require(_characters[characterId] == 1, "WAC: character invalid");
        blacklist[characterId] = false;
        emit BlacklistCharacter(characterId, false);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _uri = baseURI;
    }

    function isPaused() external view returns (bool) {
        return paused;
    }

    function isBlacklisted(uint256 characterId) external view returns (bool) {
        return blacklist[characterId];
    }

    function buyCharacter(uint256 amount) external payable onlyNotOnPause {
        require(_characters.length + amount <= maxMint, "WAC: out of range");
        require(amount != 0 && amount <= maxPerBought, "WAC: not eligible");
        require(msg.value == feePerCharacter * amount, "WAC: not enough");

        for (uint256 i = 0; i < amount; i++) {
            uint256 characterId = _createCharacter();
            _safeMint(msg.sender, characterId);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function _createCharacter() private returns (uint256 characterId) {
        _characters.push(1);
        characterId = _characters.length;

        (bool isTransferToOwner, ) = owner().call{value: feePerCharacter}("");
        require(isTransferToOwner);

        emit CharacterCreated(msg.sender, characterId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused, "WAC: paused");
        require(!blacklist[tokenId], "WAC: blacklisted");
    }
}
