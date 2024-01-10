// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./IERC721Locker.sol";
import "./ISpermToken.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Kevinmom is ERC721A, Ownable, ReentrancyGuard {
    /* ========== VARIABLES ========== */

    string public baseURI = "";
    string public contractURI = "";
    string public constant baseExtension = ".json";

    address public sperm;

    uint256 public constant MAX_PER_EARLY_TX = 5;
    uint256 public constant MAX_PER_TX = 10;
    uint256 public constant MAX_SUPPLY = 4010;
    uint256 public constant EARLY_PERKS = 1010;
    uint256 public constant BASE_REWARD = 5000 ether;

    uint256 private earlyPrice = 0.00132 ether;
    uint256 private latePrice = 0.0066 ether;

    bool public paused = true;
    bool public rewardPaused = true;
    bool public notRevealed = true;

    // Mapping from token ID to locker address
    mapping(uint256 => address) private _lockedBy;
    mapping(address => uint256) public lockedAmount;
    mapping(address => uint256) public lastClaimed;

    /* ========== CONSTRUCTOR ========== */

    constructor(string memory baseURI_, address _sperm)
        ERC721A("Kevinmom", "KEVINMOM")
    {
        baseURI = baseURI_;
        sperm = _sperm;
        _safeMint(msg.sender, 10);
    }

    /* ========== OWNER FUNCTIONS ========== */

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send");
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function toggleRewardPause() external onlyOwner {
        rewardPaused = !rewardPaused;
    }

    function toggleReveal() external onlyOwner {
        notRevealed = !notRevealed;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function setToken(address _token) external onlyOwner {
        sperm = _token;
    }

    function setPrice(uint256 _earlyPrice, uint256 _latePrice)
        external
        onlyOwner
    {
        earlyPrice = _earlyPrice;
        latePrice = _latePrice;
    }

    /* ========== PUBLIC READ FUNCTIONS ========== */

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist.");
        return
            notRevealed ? baseURI : bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(_tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function lockedBy(uint256 tokenId) external view returns (address) {
        return _lockedBy[tokenId];
    }

    function getPendingReward(address _user)
        external
        view
        returns (uint256 rewards)
    {
        rewards = _getPendingReward(_user);
    }

    function price() external view returns (uint256 currentPrice) {
        currentPrice = _getCurrentPrice();
    }

    /* ========== PUBLIC MUTATIVE FUNCTIONS ========== */

    function mint(uint256 _amount) external payable {
        address _caller = msg.sender;
        require(!paused, "Son: Minting is paused");
        require(_amount > 0, "Son: Bad mints");

        require(totalSupply() + _amount <= MAX_SUPPLY, "Exceeds max supply");

        require(_amount <= _maxTx(), "Son: Exceeds max amount");
        require(msg.value >= _amount * _getCurrentPrice());

        _safeMint(_caller, _amount);
    }

    function harvestReward() external {
        _harvestReward();
    }

    function lock(uint256 tokenId) external nonReentrant {
        require(_lockedBy[tokenId] == address(0), "Son: already locked");

        require(
            ownerOf(tokenId) == msg.sender,
            "ERC721: transfer caller is not owner nor approved"
        );

        _lockedBy[tokenId] = msg.sender;
        lastClaimed[msg.sender] = block.timestamp;
        lockedAmount[msg.sender]++;

        if (_getPendingReward(msg.sender) > 0 && !paused) {
            _harvestReward();
        }

        require(
            _checkOnERC721Locked(ownerOf(tokenId), msg.sender, tokenId, ""),
            "Son: lock failed"
        );
    }

    function unlock(uint256 tokenId) external {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        require(_lockedBy[tokenId] == msg.sender, "Son: caller is not locker");
        require(
            _checkOnERC721Unlocked(ownerOf(tokenId), msg.sender, tokenId, ""),
            "Son: unlock failed"
        );

        delete _lockedBy[tokenId];
        lastClaimed[msg.sender] = block.timestamp;
        lockedAmount[msg.sender]--;

        if (_getPendingReward(msg.sender) > 0 && !paused) {
            _harvestReward();
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _getPendingReward(address _user) internal view returns (uint256) {
        return
            (lockedAmount[_user] *
                BASE_REWARD *
                (block.timestamp - lastClaimed[_user])) / 86400;
    }

    function _maxTx() internal view returns (uint256) {
        if (totalSupply() < EARLY_PERKS) {
            return MAX_PER_EARLY_TX;
        } else {
            return MAX_PER_TX;
        }
    }

    function _getCurrentPrice() internal view returns (uint256) {
        if (totalSupply() < EARLY_PERKS) {
            return earlyPrice;
        } else {
            return latePrice;
        }
    }

    function _harvestReward() internal {
        require(!rewardPaused, "Claiming reward has been paused");
        ISpermToken(sperm).mint(msg.sender, _getPendingReward(msg.sender));
        lastClaimed[msg.sender] = block.timestamp;
    }

    function _checkOnERC721Locked(
        address from,
        address locker,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        return true;
    }

    function _checkOnERC721Unlocked(
        address from,
        address locker,
        uint256 tokenId,
        bytes memory _data
    ) private pure returns (bool) {
        return true;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        if (_lockedBy[startTokenId] != to) {
            require(
                _lockedBy[startTokenId] == address(0),
                "Son: token transfer while locked"
            );
        } else {
            delete _lockedBy[startTokenId];
        }
    }
}
