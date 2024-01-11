// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./ECDSA.sol";
import "./Base64.sol";
import "./Strings.sol";

contract RabbitHoleCredential is
    Initializable,
    ERC721Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;
    string private baseURI;
    string private id;
    address private signer;

    event Mint(address indexed minter, uint256 tokenId, uint256 blockNumber);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _id,
        address _signer
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        id = _id;
        signer = _signer;
    }

    function mint(bytes32 _hash, bytes memory _signature) external {
        require(recoverSigner(_hash, _signature) == signer);
        require(keccak256(abi.encodePacked(msg.sender, id)) == _hash);
        require(balanceOf(msg.sender) == 0);

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId);
        emit Mint(msg.sender, tokenId, block.number);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function changeSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function changeId(string memory _id) external onlyOwner {
        id = _id;
    }

    function setApprovalForAll(address _operator, bool _approved)
        public
        virtual
        override
    {
        require(_approved == false);
        _setApprovalForAll(msg.sender, _operator, false);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function recoverSigner(bytes32 _hash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
        );
        return ECDSA.recover(messageDigest, _signature);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 startTokenId
    ) internal virtual override whenNotPaused {
        require(balanceOf(msg.sender) == 0, "Cannot transfer token");
        super._beforeTokenTransfer(from, to, startTokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}
