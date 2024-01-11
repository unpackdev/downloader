// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.15;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./iczSpecialEditionTraits.sol";

contract czMain1 is Ownable, Pausable, ReentrancyGuard {

    constructor() {
        _pause();
    }

    /** CONTRACTS */
    iczSpecialEditionTraits public setContract;

    /** EVENTS */
    event ManySpecialTraitsMinted(address indexed owner, uint16 traitId, uint16 amount);

    /** PUBLIC VARS */
    bool public TRAIT_SALE_STARTED;
    address public wallet1Address;
    address public wallet2Address;

    /** PRIVATE VARS */
    mapping(address => bool) private _admins;
    mapping(address => uint8) private _specialTraitMints;
    
    /** MODIFIERS */
    modifier onlyAdmin() {
        require(_admins[_msgSender()], "Main: Only admins can call this");
        _;
    }

    modifier onlyEOA() {
        require(tx.origin == _msgSender(), "Main: Only EOA");
        _;
    }

    modifier requireVariablesSet() {
        require(address(setContract) != address(0), "Main: Special Edition Traits contract not set");
        require(wallet1Address != address(0), "Main: Withdrawal address wallet1Address must be set");
        require(wallet2Address != address(0), "Main: Withdrawal address wallet2Address must be set");
        _;
    }

    /** PUBLIC FUNCTIONS */
    function mintSpecialEditionTrait(uint16 traitId, uint16 amount) external payable whenNotPaused nonReentrant onlyEOA {
        require(TRAIT_SALE_STARTED, "Main: Trait sale has not started");
        iczSpecialEditionTraits.Trait memory _trait = setContract.getTrait(traitId);
        require(_trait.traitId == traitId, "Main: Trait does not exist");
        require(msg.value >= amount * _trait.price, "Main: Invalid payment amount");
        require(_specialTraitMints[_msgSender()] + amount <= 3, "Main: You cannot mint more Traits");

        for (uint i = 0; i < amount; i++) {
            _specialTraitMints[_msgSender()]++;
            setContract.mint(traitId, _msgSender());
        }

        emit ManySpecialTraitsMinted(_msgSender(), traitId, amount);
    }

    /** OWNER ONLY FUNCTIONS */
    function setContracts(address _setContract) external onlyOwner {
        setContract = iczSpecialEditionTraits(_setContract);
    }

    function setPaused(bool _paused) external requireVariablesSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function withdraw() external onlyOwner {
        uint256 totalAmount = address(this).balance;
        
        uint256 amountWallet1 = totalAmount * 25/100;
        uint256 amountWallet2 = totalAmount - amountWallet1;

        bool sent;
        (sent, ) = wallet1Address.call{value: amountWallet1}("");
        require(sent, "Main: Failed to send funds to wallet1Address");

        (sent, ) = wallet2Address.call{value: amountWallet2}("");
        require(sent, "Main: Failed to send funds to wallet2Address");
    }

    function setWallet1Address(address addr) external onlyOwner {
        wallet1Address = addr;
    }

    function setWallet2Address(address addr) external onlyOwner {
        wallet2Address = addr;
    }

    function addAdmin(address addr) external onlyOwner {
        _admins[addr] = true;
    }

    function removeAdmin(address addr) external onlyOwner {
        delete _admins[addr];
    }

    function setTraitSaleStarted(bool started) external onlyOwner {
        TRAIT_SALE_STARTED = started;
    }
}