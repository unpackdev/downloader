// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Address.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

/// @custom:security-contact dev@futurekimono.com
contract ChampionsReserve is ERC721A, ReentrancyGuard, Pausable, AccessControl {
    using ECDSA for bytes32;
    using Address for address;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private _buri = "https://meta.ftu.re/champions-reserve/";

    enum State {
        FiatSale,
        PublicSale,
        Finished
    }

    enum Tiers {
        Nemesis,
        Phenom,
        Reaper,
        Ghost,
        Akuma
    }

    mapping(Tiers => uint16) public MAX_SUPPLY;
    mapping(Tiers => uint16) public MINT_COUNT;
    uint16 public constant MAX_TOKEN = 8888;

    State public _state = State.FiatSale;

    uint256 public _mintFee;
    address private _signer;
    mapping(bytes => bool) public usedToken;

    event PublicMinted(address minter, uint256 tokenId, Tiers tier);
    event BalanceWithdrawn(address recipient, uint256 value);

    constructor(address signer, uint256 mintFee)
        ERC721A("Champions Reserve", "CR2022", 20, 20)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        MAX_SUPPLY[Tiers.Nemesis] = 7631;
        MAX_SUPPLY[Tiers.Phenom] = 1099;
        MAX_SUPPLY[Tiers.Reaper] = 99;
        MAX_SUPPLY[Tiers.Ghost] = 49;
        MAX_SUPPLY[Tiers.Akuma] = 10;
        _signer = signer;
        _mintFee = mintFee;
    }

    function _baseURI() internal view override returns (string memory) {
        return _buri;
    }

    function setBaseURI(string memory buri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _buri = buri;
    }

    function setMintFee(uint256 mintFee)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
         _mintFee = mintFee;
    }

    function _hash(
        Tiers tier,
        string calldata salt,
        address _address
    ) public view returns (bytes32) {
        return keccak256(abi.encode(tier, salt, address(this), _address));
    }

    function _verify(bytes32 hash, bytes memory token)
        public
        view
        returns (bool)
    {
        return (_recover(hash, token) == _signer);
    }

    function _recover(bytes32 hash, bytes memory token)
        public
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function publicMint(Tiers tier, uint256 amount)
        external
        payable
        nonReentrant
    {
        require(_state == State.PublicSale, "Public sale is not active.");
        require(amount > 0, "Amount must be greater than 0.");
        require(!Address.isContract(msg.sender), "Contracts are not allowed");
        require(totalSupply() + amount < MAX_TOKEN, "exceeding max supply.");
        uint256 fee = amount * _mintFee;
        if (tier == Tiers.Nemesis) {
            require(
                MINT_COUNT[Tiers.Nemesis] + amount <= MAX_SUPPLY[Tiers.Nemesis],
                "exceeding max nemesis."
            );
        } else if (tier == Tiers.Phenom) {
            require(
                MINT_COUNT[Tiers.Phenom] + amount <= MAX_SUPPLY[Tiers.Phenom],
                "exceeding max phenom."
            );
            fee = fee * 2;
        } else {
            revert("invalid tier");
        }
        require(msg.value >= fee, "Ether value sent is incorrect.");
        MINT_COUNT[tier] += 1;
        emit PublicMinted(msg.sender, amount, tier);
        _safeMint(msg.sender, amount);
    }

    function airdrop(
        address[] calldata recipient,
        bytes[] calldata tokens,
        Tiers tier
    ) external nonReentrant onlyRole(MINTER_ROLE) {
        require(_state != State.Finished, "already finished.");
        require(!Address.isContract(msg.sender), "Contracts are not allowed");
        require(
            totalSupply() + recipient.length <= MAX_TOKEN,
            "exceeding max supply."
        );

        require(
            MINT_COUNT[tier] + recipient.length <= MAX_SUPPLY[tier],
            "exceeding max supply."
        );
        uint16 _valid = 0;
        for (uint256 index = 0; index < recipient.length; index++) {
            if (!usedToken[tokens[index]]) {
                usedToken[tokens[index]] = true;
                _valid += 1;
                _safeMint(recipient[index], 1);
            }
        }
        MINT_COUNT[tier] = MINT_COUNT[tier] + _valid;
    }

    function mintWithToken(
        Tiers tier,
        string calldata salt,
        bytes calldata token
    ) external nonReentrant {
        require(_state != State.Finished, "Sale is finished.");
        require(!Address.isContract(msg.sender), "Contracts are not allowed");
        require(totalSupply() + 1 < MAX_TOKEN, "exceeding max supply.");
        require(!usedToken[token], "The token has been used.");
        require(
            _verify(_hash(tier, salt, msg.sender), token),
            "Invalid token."
        );

        require(
            MINT_COUNT[tier] + 1 <= MAX_SUPPLY[tier],
            "exceeding max supply."
        );

        usedToken[token] = true;
        MINT_COUNT[tier]++;

        _safeMint(msg.sender, 1);
    }

    function withdrawAll(address payable recipient)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 balance = address(this).balance;
        (bool sent, bytes memory data) = recipient.call{value: balance}("");
        require(sent, "Failed to send Ether");
        emit BalanceWithdrawn(recipient, balance);
    }

    function setState(State state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _state = state;
    }
}
