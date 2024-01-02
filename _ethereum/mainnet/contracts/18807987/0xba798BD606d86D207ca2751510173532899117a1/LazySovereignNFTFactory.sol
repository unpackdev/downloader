// contracts/token/ERC721/sovereign/SovereignNFTContractFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Ownable.sol";
import "./Clones.sol";
import "./LazySovereignNFT.sol";
import "./LazySovereignNFTRoyaltyGuard.sol";
import "./LazySovereignNFTRoyaltyGuardDeadmanTrigger.sol";

contract LazySovereignNFTFactory is Ownable {

    bytes32 public constant LAZY_SOVEREIGN_NFT = keccak256("LAZY_SOVEREIGN_NFT");
    bytes32 public constant LAZY_ROYALTY_GUARD = keccak256("LAZY_ROYALTY_GUARD");
    bytes32 public constant LAZY_ROYALTY_GUARD_DEADMAN = keccak256("LAZY_ROYALTY_GUARD_DEADMAN");

    address public lazySovereignNFT;
    address public lazySovereignNFTRoyaltyGuard;
    address public lazySovereignNFTRoyaltyGuardDeadmanTrigger;

    event SovereignNFTContractCreated(
        address indexed contractAddress,
        address indexed owner
    );

    event SovereignNFTContractCreated(
        address indexed contractAddress,
        address indexed owner,
        bytes32 indexed contractType
    );

    constructor() {
        LazySovereignNFT lsovNFT = new LazySovereignNFT();
        lazySovereignNFT = address(lsovNFT);

        LazySovereignNFTRoyaltyGuard lsovNFTRG = new LazySovereignNFTRoyaltyGuard();
        lazySovereignNFTRoyaltyGuard = address(lsovNFTRG);

        LazySovereignNFTRoyaltyGuardDeadmanTrigger lsovNFTRGDT = new LazySovereignNFTRoyaltyGuardDeadmanTrigger();
        lazySovereignNFTRoyaltyGuardDeadmanTrigger = address(lsovNFTRGDT);
    }

    function setSovereignNFT(address _sovereignNFT, bytes32 _contractType)
        external
        onlyOwner
    {
        require(_sovereignNFT != address(0));
        if (_contractType == LAZY_SOVEREIGN_NFT) {
            lazySovereignNFT = _sovereignNFT;
            return;
        }
        if (_contractType == LAZY_ROYALTY_GUARD) {
            lazySovereignNFTRoyaltyGuard = _sovereignNFT;
            return;
        }
        if (_contractType == LAZY_ROYALTY_GUARD_DEADMAN) {
            lazySovereignNFTRoyaltyGuardDeadmanTrigger = _sovereignNFT;
            return;
        }
        require(false, "setSovereignNFT::Unsupported _contractType.");
    }


    function createSovereignNFTContract(
        string memory _name,
        string memory _symbol,
        uint256 _maxTokens,
        bytes32 _contractType
    ) public returns (address) {
        require(
            _maxTokens != 0,
            "createSovereignNFTContract::_maxTokens cant be zero"
        );

        address sovAddr;
        if (_contractType == LAZY_SOVEREIGN_NFT) {
            sovAddr = Clones.clone(lazySovereignNFT);
            LazySovereignNFT(sovAddr).init(_name, _symbol, msg.sender, _maxTokens);
        }
        if (_contractType == LAZY_ROYALTY_GUARD) {
            sovAddr = Clones.clone(lazySovereignNFTRoyaltyGuard);
            LazySovereignNFTRoyaltyGuard(sovAddr).init(
                _name,
                _symbol,
                msg.sender,
                _maxTokens
            );
        }
        if (_contractType == LAZY_ROYALTY_GUARD_DEADMAN) {
            sovAddr = Clones.clone(lazySovereignNFTRoyaltyGuardDeadmanTrigger);
            LazySovereignNFTRoyaltyGuardDeadmanTrigger(sovAddr).init(
                _name,
                _symbol,
                msg.sender,
                _maxTokens
            );
        }
        require(
            sovAddr != address(0),
            "createSovereignNFTContract::_contractType unsupported contract type."
        );
        emit SovereignNFTContractCreated(sovAddr, msg.sender);
        emit SovereignNFTContractCreated(sovAddr, msg.sender, _contractType);

        return address(sovAddr);
    }
}
