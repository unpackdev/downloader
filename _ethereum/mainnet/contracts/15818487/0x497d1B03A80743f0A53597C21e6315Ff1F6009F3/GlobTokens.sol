//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./SafeMath.sol";
import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";

contract GlobTokens is
    Initializable,
    ERC721Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeMath for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public _baycGenesisTokenIds;

    uint256 public MAX_SUPPLY_BAYC_GENESIS;
    uint256 public MAX_PER_TRANSACTION_BAYC_GENESIS;
    uint256 public MAX_PER_WALLET_BAYC_GENESIS;
    uint256 public PRICE_BAYC_GENESIS;

    mapping(address => bool) public _admins;
    string public baseTokenURI;

    function initialize() public initializer {
        __ERC721_init("Glob Genesis Token", "GST");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        pause();
        MAX_SUPPLY_BAYC_GENESIS = 250;
        MAX_PER_TRANSACTION_BAYC_GENESIS = 20;
        MAX_PER_WALLET_BAYC_GENESIS = 5;
        PRICE_BAYC_GENESIS = 0.5 ether;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "the caller is on another contract");
        _;
    }

    modifier callerIsOwnerOrAdmin() {
        require(
            msg.sender == owner() || _admins[msg.sender],
            "address is not owner or admin"
        );
        _;
    }

    function mintBaycGenesis(uint256 _count) external payable callerIsUser {
        uint256 totalMinted = _baycGenesisTokenIds.current();
        require(
            totalMinted.add(_count) <= MAX_SUPPLY_BAYC_GENESIS,
            "max supply reached"
        );
        require(
            _count > 0 && _count <= MAX_PER_TRANSACTION_BAYC_GENESIS,
            "max per transaction reached"
        );
        require(
            msg.value >= PRICE_BAYC_GENESIS.mul(_count),
            "not enough ether to purchase BAYC Genesis"
        );
        require(
            balanceOf(msg.sender) + _count <= MAX_PER_WALLET_BAYC_GENESIS,
            "max token per wallet exceeded"
        );
        for (uint256 i = 0; i < _count; i++) {
            _mintEachBaycGenesis();
        }
    }

    function _mintEachBaycGenesis() private {
        uint256 newTokenID = _baycGenesisTokenIds.current() + 1;
        _safeMint(msg.sender, newTokenID);
        _baycGenesisTokenIds.increment();
    }

    function setMaxSupplyBaycGenesis(uint256 number)
        external
        callerIsOwnerOrAdmin
    {
        MAX_SUPPLY_BAYC_GENESIS = number;
    }

    function setPriceBaycGenesis(uint256 number) external callerIsOwnerOrAdmin {
        PRICE_BAYC_GENESIS = number;
    }

    function setMaxPerTransactionBaycGenesis(uint256 number)
        external
        callerIsOwnerOrAdmin
    {
        MAX_PER_TRANSACTION_BAYC_GENESIS = number;
    }

    function permitAdmin(address admin) external onlyOwner {
        _admins[admin] = true;
    }

    function removeAdmin(address admin) external onlyOwner {
        delete _admins[admin];
    }

    function pause() public callerIsOwnerOrAdmin {
        _pause();
    }

    function unpause() public callerIsOwnerOrAdmin {
        _unpause();
    }

    function withdrawFunds() external callerIsOwnerOrAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "zero balance.");
        payable(0xd3b0c0d84489e2ecB654B964a09634Fb826E8cDE).transfer(balance);
    }

    function withdrawFallback() public payable callerIsOwnerOrAdmin {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI)
        public
        callerIsOwnerOrAdmin
    {
        baseTokenURI = _baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}
