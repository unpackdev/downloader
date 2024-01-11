// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./TwoStepOwnable.sol";
import "./ERC1155Extended.sol";
import "./CommissionWithdrawable.sol";
import "./MerkleProof.sol";

/**
 *
 * ██████╗░██╗████████╗  ██████╗░██████╗░██╗███████╗███████╗░██████╗
 * ██╔══██╗██║╚══██╔══╝  ██╔══██╗██╔══██╗██║╚════██║██╔════╝██╔════╝
 * ██████╔╝██║░░░██║░░░  ██████╔╝██████╔╝██║░░███╔═╝█████╗░░╚█████╗░
 * ██╔═══╝░██║░░░██║░░░  ██╔═══╝░██╔══██╗██║██╔══╝░░██╔══╝░░░╚═══██╗
 * ██║░░░░░██║░░░██║░░░  ██║░░░░░██║░░██║██║███████╗███████╗██████╔╝
 * ╚═╝░░░░░╚═╝░░░╚═╝░░░  ╚═╝░░░░░╚═╝░░╚═╝╚═╝╚══════╝╚══════╝╚═════╝░
 *
 */

contract PITPrizes is ERC1155Extended, CommissionWithdrawable, TwoStepOwnable {
    address private constant _OPENSEA_PROXY_ADDRESS =
        0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    address private constant _OPENSEA_WALLET_ADDRESS =
        0x5b3256965e7C3cF26E11FCAf296DfC8807C01073;
    uint256 private constant _COMMISSION_PAYOUT_PER_MILLE = 50;
    mapping(uint256 => bytes32) private _merkleRootPerPrize;
    mapping(bytes32 => uint256) private _prizePerMerkleRoot;
    mapping(uint256 => mapping(address => bool)) private _addressClaimed;

    error AlreadyClaimed();
    error NotInWhitelist();

    modifier onlyWhitelisted(uint256 prizeId_, bytes32[] calldata proof_) {
        if (!isWhitelisted(prizeId_, msg.sender, proof_)) {
            revert NotInWhitelist();
        }
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_
    )
        ERC1155Extended(name_, symbol_, uri_, _OPENSEA_PROXY_ADDRESS)
        CommissionWithdrawable(
            _OPENSEA_WALLET_ADDRESS,
            _COMMISSION_PAYOUT_PER_MILLE
        )
    {}

    function _mintPrize(address to_, uint256 prizeId_) internal {
        _mint(to_, prizeId_, 1, "");
    }

    function _canClaim(uint256 prizeId_) internal view {
        if (_addressClaimed[prizeId_][msg.sender]) {
            revert AlreadyClaimed();
        }
    }

    function claimPrize(uint256 prizeId_, bytes32[] calldata proof_)
        external
        nonReentrant
        whenNotPaused
        onlyWhitelisted(prizeId_, proof_)
    {
        _canClaim(prizeId_);
        _mintPrize(msg.sender, prizeId_);
        _addressClaimed[prizeId_][msg.sender] = true;
    }

    function prizeId(bytes32 merkleRoot_)
        external
        view
        returns (uint256 prizeId_)
    {
        prizeId_ = _prizePerMerkleRoot[merkleRoot_];
    }

    function merkleRoot(uint256 prizeId_)
        external
        view
        returns (bytes32 merkleRoot_)
    {
        merkleRoot_ = _merkleRootPerPrize[prizeId_];
    }

    function setMerkleRoot(uint256 prizeId_, bytes32 merkleRoot_)
        external
        onlyOwner
    {
        _prizePerMerkleRoot[merkleRoot_] = prizeId_;
        _merkleRootPerPrize[prizeId_] = merkleRoot_;
    }

    function airdropPrizes(address[] calldata address_, uint256 prizeId_)
        external
        onlyOwner
        whenNotPaused
    {
        for (uint256 i; i < address_.length; i++) {
            _mintPrize(address_[i], prizeId_);
        }
    }

    function isWhitelisted(
        uint256 prizeId_,
        address address_,
        bytes32[] calldata proof_
    ) public view returns (bool) {
        return
            MerkleProof.verify(
                proof_,
                _merkleRootPerPrize[prizeId_],
                keccak256(abi.encodePacked(address_))
            );
    }

    function transferOwnership(address _newOwner)
        public
        virtual
        override(Ownable, TwoStepOwnable)
        onlyOwner
    {
        if (_newOwner == address(0)) {
            revert NewOwnerIsZeroAddress();
        }
        _potentialOwner = _newOwner;
    }
}
