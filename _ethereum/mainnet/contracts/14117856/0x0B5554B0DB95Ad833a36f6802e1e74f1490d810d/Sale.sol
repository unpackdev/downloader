// SPDX-License-Identifier: MIT

/// @title RaidParty Sale Contract

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

import "./Hero.sol";
import "./Fighter.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./MerkleProof.sol";
import "./AccessControlEnumerable.sol";

pragma solidity ^0.8.0;

contract Sale is EIP712, AccessControlEnumerable {
    using ECDSA for bytes32;

    Hero public hero;
    Fighter public fighter;

    enum Pack {
        Gathering,
        Bash,
        Celebration,
        Party
    }

    string public constant TICKET_NAME = "Ticket";
    string public constant TICKET_VERSION = "1";
    bytes32 public constant TICKET_TYPEHASH =
        keccak256(
            "Ticket(uint8 pack,address user,uint256 expiresAt,bytes32 nonce)"
        );

    bytes32 public constant SALE_ADMIN_ROLE = keccak256("SALE_ADMIN_ROLE");

    struct Ticket {
        Pack pack;
        address user;
        uint256 expiresAt;
        bytes32 nonce;
    }

    mapping(Pack => uint256) public stock;
    mapping(bytes32 => bool) private _nonces;

    bool public isSaleActive;
    bool public isPresaleActive;
    uint256 public heroPrice = 1.6 ether;
    uint256 public fighterPrice = 0.4 ether;

    address public signer;
    address public immutable beneficiary;

    bytes32 public merkleRoot;

    constructor(
        address admin,
        address saleAdmin,
        address _beneficiary,
        Hero _hero,
        Fighter _fighter
    ) EIP712(TICKET_NAME, TICKET_VERSION) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(SALE_ADMIN_ROLE, saleAdmin);

        hero = _hero;
        fighter = _fighter;
        beneficiary = _beneficiary;

        stock[Pack.Gathering] = 2100;
        stock[Pack.Bash] = 1730;
        stock[Pack.Celebration] = 169;
        stock[Pack.Party] = 90;
    }

    function setSaleActive(bool _isSaleActive)
        external
        onlyRole(SALE_ADMIN_ROLE)
    {
        isSaleActive = _isSaleActive;
    }

    function setPresaleActive(bool _isPresaleActive)
        external
        onlyRole(SALE_ADMIN_ROLE)
    {
        isPresaleActive = _isPresaleActive;
    }

    function setHeroPrice(uint256 price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        heroPrice = price;
    }

    function setFighterPrice(uint256 price)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        fighterPrice = price;
    }

    function setMerkleRoot(bytes32 _merkleRoot)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            merkleRoot == bytes32(0),
            "Sale::setMerkleRoot: merkle root already set"
        );

        merkleRoot = _merkleRoot;
    }

    function setSigner(address _signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        signer = _signer;
    }

    function cancelTicket(bytes32 nonce) external onlyRole(SALE_ADMIN_ROLE) {
        _nonces[nonce] = true;
    }

    function presale(Pack pack, bytes32[] calldata proof) external payable {
        require(isPresaleActive, "Sale::presale: presale must be active");
        if (pack != Pack.Gathering && pack != Pack.Bash) {
            revert("Sale::presale: invalid pack selected");
        }

        bytes32 leaf = _leaf();
        (uint256 heroes, uint256 fighters) = _calculateTokens(pack);
        require(stock[pack] > 0, "Sale::presale: pack is no longer available");
        require(
            _calculatePrice(heroes, fighters) == msg.value,
            "Sale::presale: incorrect ether sent"
        );

        _verifyMerkle(leaf, proof);
        stock[pack] -= 1;
        _nonces[leaf] = true;

        hero.mint(msg.sender, heroes);
        fighter.mint(msg.sender, fighters);
    }

    function purchase(Ticket calldata ticket, bytes calldata signature)
        external
        payable
    {
        assembly {
            if iszero(eq(caller(), origin())) {
                revert(0, 0)
            }
        }

        require(isSaleActive, "Sale::sale: sale must be active");
        (uint256 heroes, uint256 fighters) = _calculateTokens(ticket.pack);
        require(!_nonces[ticket.nonce], "Sale::purchase: nonce already used");
        require(
            stock[ticket.pack] > 0,
            "Sale::purchase: pack is no longer available"
        );
        require(
            _calculatePrice(heroes, fighters) == msg.value,
            "Sale::purchase: incorrect ether sent"
        );

        _verifySignature(ticket, signature);
        stock[ticket.pack] -= 1;
        _nonces[ticket.nonce] = true;

        hero.mint(msg.sender, heroes);
        fighter.mint(msg.sender, fighters);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success, ) = beneficiary.call{value: address(this).balance}("");
        require(success, "Sale::withdraw: failed to withdraw");
    }

    /** INTERNAL */

    function _calculateTokens(Pack pack)
        internal
        pure
        returns (uint256, uint256)
    {
        if (pack == Pack.Gathering) {
            return (1, 1);
        } else if (pack == Pack.Bash) {
            return (1, 2);
        } else if (pack == Pack.Celebration) {
            return (1, 3);
        } else if (pack == Pack.Party) {
            return (2, 6);
        }
    }

    function _calculatePrice(uint256 heroes, uint256 fighters)
        internal
        view
        returns (uint256)
    {
        return heroes * heroPrice + fighters * fighterPrice;
    }

    function _leaf() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender));
    }

    function _verifyMerkle(bytes32 leaf, bytes32[] calldata proof)
        internal
        view
    {
        require(
            merkleRoot != bytes32(0),
            "Sale::_verifyMerkle: merkle root not set"
        );
        require(!_nonces[leaf], "Sale::_verifyMerkle: leaf already used");
        require(
            MerkleProof.verify(proof, merkleRoot, leaf),
            "Sale::_verifyMerkle: invalid proof"
        );
    }

    function _verifySignature(Ticket calldata ticket, bytes calldata signature)
        internal
        view
    {
        require(ticket.user == msg.sender, "Sale::purchase: invalid purchaser");
        require(
            ticket.expiresAt >= block.timestamp,
            "Sale::_validateSignature: expired ticket"
        );
        require(
            !_nonces[ticket.nonce],
            "Sale::_validateSignature: nonce already used"
        );
        bytes32 hash = _ticketHash(ticket);
        require(
            signer == ECDSA.recover(hash, signature),
            "Sale::_validateSignature: invalid signer"
        );
    }

    function _ticketHash(Ticket calldata ticket)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        TICKET_TYPEHASH,
                        ticket.pack,
                        ticket.user,
                        ticket.expiresAt,
                        ticket.nonce
                    )
                )
            );
    }
}
