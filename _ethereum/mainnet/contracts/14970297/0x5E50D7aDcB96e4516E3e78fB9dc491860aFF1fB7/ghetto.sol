// SPDX-License-Identifier: MIT
// Creator: twitter.com/runo_dev

// Moonturtlez - ERC-721A based NFT contract

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract GhettoCulture is ERC721A, Ownable, ReentrancyGuard {
    uint256 public MAX_SUPPLY = 5069;

    bool private _wlStatus = false;
    bool private _publicStatus = false;
    uint256 private _cooldownDuration = 60 * 15;

    string private _baseTokenURI;
    bytes32 private _wlMerkleRoot;
    mapping(address => bool) private _whitelistClaimed;
    mapping(address => uint256) private _nextMintTime;

    constructor() ERC721A("Ghetto Culture", "GHETTO") {}

    function isWlMintActive() public view returns (bool) {
        return _wlStatus;
    }

    function isPublicMintActive() public view returns (bool) {
        return _publicStatus;
    }

    function getClaimMerkleRoot() external view returns (bytes32) {
        return _wlMerkleRoot;
    }

    function getNextMintTimestamp(address account)
        public
        view
        returns (uint256)
    {
        return _nextMintTime[account];
    }

    function canMint(address account) public view returns (bool) {
        return block.timestamp >= getNextMintTimestamp(account);
    }

    function isWhitelistClaimed(address account) public view returns (bool) {
        return _whitelistClaimed[account];
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= totalSupply()
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function whitelistMint(bytes32[] calldata merkleProof)
        external
        nonReentrant
        callerIsUser
        verify(msg.sender, merkleProof, _wlMerkleRoot)
    {
        if (!isWlMintActive()) revert("Whitelist mint not started");
        bool res = _mint();
        if (res) {
            _whitelistClaimed[msg.sender] = true;
        }
    }

    function publicMint() external nonReentrant callerIsUser {
        if (!isPublicMintActive()) revert("Public mint not started");
        _mint();
    }

    function ownerMint(address to, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > MAX_SUPPLY)
            revert("Amount exceeds supply");
        _safeMint(to, quantity);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setWlMerkleRoot(bytes32 root) external onlyOwner {
        _wlMerkleRoot = root;
    }

    function toggleWlMintStatus() external onlyOwner {
        _wlStatus = !_wlStatus;
    }

    function togglePublicMintStatus() external onlyOwner {
        _publicStatus = !_publicStatus;
    }

    function withdrawAll() external onlyOwner {
        withdraw(owner(), address(this).balance);
    }

    function _mint() internal callerIsOnCd returns (bool) {
        if (totalSupply() + 1 > MAX_SUPPLY) revert("Amount exceeds supply");
        _nextMintTime[msg.sender] = block.timestamp + _cooldownDuration;
        _safeMint(msg.sender, 1);
        return true;
    }

    function withdraw(address account, uint256 amount) internal {
        (bool os, ) = payable(account).call{value: amount}("");
        require(os, "Failed to send ether");
    }

    function _baseURI()
        internal
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        return _baseTokenURI;
    }

    modifier callerIsOnCd() {
        require(
            canMint(msg.sender),
            "Slow down a bit you fuck, you are on cooldown! (15 min per tx)"
        );
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier verify(
        address account,
        bytes32[] calldata proof,
        bytes32 merkleRoot
    ) {
        require(
            MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(account))
            ),
            "Invalid attempt!"
        );
        _;
    }
}
