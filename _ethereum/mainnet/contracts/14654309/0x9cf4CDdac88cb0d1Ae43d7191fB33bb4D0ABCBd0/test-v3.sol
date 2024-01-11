// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";

// ███████  █████  ██      ████████ ██    ██     ███████ ██ ██████  ███████ ███    ██      ██████ ██████  ███████ ██     ██ 
// ██      ██   ██ ██         ██     ██  ██      ██      ██ ██   ██ ██      ████   ██     ██      ██   ██ ██      ██     ██ 
// ███████ ███████ ██         ██      ████       ███████ ██ ██████  █████   ██ ██  ██     ██      ██████  █████   ██  █  ██ 
//      ██ ██   ██ ██         ██       ██             ██ ██ ██   ██ ██      ██  ██ ██     ██      ██   ██ ██      ██ ███ ██ 
// ███████ ██   ██ ███████    ██       ██        ███████ ██ ██   ██ ███████ ██   ████      ██████ ██   ██ ███████  ███ ███  
// By the Salty Pirate Crew: 0x7a4b1a8bb6e40cbce837fb72603c8a4a20d0b3e1
contract SaltySirenCrew is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    uint256 public constant MAX_SUPPLY = 1200;
    uint256 public constant STARTING_INDEX = 58;
    uint256 public constant AIRDROP_BUFFER = 143;

    Counters.Counter private _totalSupply;
    address private _signer;
    string public baseURI;

    enum ContractState { PAUSED, UNLOCKONLY, AIRDROPONLY, UNLOCKAIRDROP }
    ContractState public currentState = ContractState.PAUSED;

    constructor(address __signer, string memory _URI) ERC721("SaltySirenCrew", "SSC") {
        _signer = __signer;
        baseURI = _URI;
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    // Sets a new contract state: PAUSED, UNLOCKONLY, AIRDROPONLY, UNLOCKAIRDROP
    function setContractState(ContractState _newState) external onlyOwner {
        currentState = _newState;
    }

    // Returns the total supply minted
    function totalSupply() public view returns (uint256) {
        return _totalSupply.current();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Verifies that the sender is whitelisted
    function _verifySignature(
        bytes calldata signature, 
        uint256 tokenId, 
        address caller
    ) internal view returns (bool) {
        return keccak256(abi.encodePacked(tokenId, caller))
            .toEthSignedMessageHash()
            .recover(signature) == _signer;
    }

    function unlockSiren(bytes calldata signature, uint256 _tokenId) public nonReentrant {
        require(
            _tokenId >= STARTING_INDEX && _tokenId <= MAX_SUPPLY - AIRDROP_BUFFER, 
            "Outside of unlock range"
        );
        require(
            _verifySignature(
                signature, 
                _tokenId, 
                msg.sender), 
            "Signature is invalid"
        );
        require(
            currentState == ContractState.UNLOCKONLY || currentState == ContractState.UNLOCKAIRDROP, 
            "Contract cannot unlock Siren"
        );
        require(!_exists(_tokenId), "Token cannot exist");                
        _safeMint(msg.sender, _tokenId);
        _totalSupply.increment();
    }

    function airdrop(uint256 tokenId, address to) public onlyOwner nonReentrant {
        require(
            tokenId > MAX_SUPPLY - AIRDROP_BUFFER && tokenId < MAX_SUPPLY, 
            "Outside of airdrop range");
        require(
            currentState == ContractState.AIRDROPONLY || currentState == ContractState.UNLOCKAIRDROP, 
            "Contract cannot airdrop"
        );
        require(!_exists(tokenId), "Token cannot exist");        
        _safeMint(to, tokenId);
        _totalSupply.increment();
    }

    function airdropSpecial(uint256 tokenId, address to) public onlyOwner nonReentrant {
        require(
            tokenId >= 0 && tokenId < STARTING_INDEX, 
            "Outside of airdrop range"
        );
        require(
            currentState == ContractState.AIRDROPONLY || currentState == ContractState.UNLOCKAIRDROP, 
            "Contract cannot airdrop"
        );
        require(!_exists(tokenId), "Token cannot exist");          
        _safeMint(to, tokenId);
        _totalSupply.increment();
    }

    // Withdraw funds
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }
}