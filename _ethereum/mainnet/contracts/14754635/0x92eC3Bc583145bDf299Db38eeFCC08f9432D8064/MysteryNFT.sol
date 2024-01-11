// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Supply.sol";
import "./ECDSA.sol";

contract MysteryNFT is Ownable, Pausable, ERC1155Supply {

    constructor() ERC1155("") {
        maxId = 0;
    }

    string public name = "Xynergy Collection";

    using ECDSA for bytes32;

    //owner only------------------------------------------------------------

    //mint
    address public signerAddress;

    //basics
    uint256 public maxId;
    address public upgrader;
    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => uint256) public totalMinted;
    mapping(uint256 => string) public tokenUriSuffix;

    //locks
    bool public upgraderLocked = false;
    bool public signerLocked = false;
    bool public newTypeLock = false;
    bool public uriLocked = false;
    mapping(uint256 => bool) public maxSupplyLocked;
    mapping(uint256 => bool) public uriSuffixLocked;

    //state------------------------------------------------------------
    mapping(address => bool) public minted;


    //owner only functions------------------------------------------------------------

    
    //locks
    function upgraderLock() public onlyOwner {
        upgraderLocked = true;
    }
    function signerLock() public onlyOwner {
        signerLocked = true;
    }
    function uriLock() public onlyOwner {
        uriLocked = true;
    }
    function newTypeNFTLock() public onlyOwner {
        newTypeLock = true;
    }

    function maxSupplyLock(uint256 tokenId) public onlyOwner {
        maxSupplyLocked[tokenId] = true;
    }
    function uriSuffixLock(uint256 id) public onlyOwner {
        uriSuffixLocked[id] = true;
    }

    //signer for mint
    function updateSignerAddress(address signer) external onlyOwner {
        require(!signerLocked, 'Signer is locked!');
        signerAddress = signer;
    }

    //upgrader
    function updateUpgrader(address upgraderAddress) external onlyOwner {
        require(!upgraderLocked, 'Upgrader is locked!');
        upgrader = upgraderAddress;
    }

    //new type of nft + max supply
    function updateMaxId(uint256 maxIdCount) external onlyOwner {
        require(!newTypeLock, 'Max ID is locked!');
        maxId = maxIdCount;
    }

    function updateMaxSupply(uint256 tokenId, uint256 tokenMaxSupply) external onlyOwner {
        require(!maxSupplyLocked[tokenId], 'Cannot change current token max supply!');
        maxSupply[tokenId] = tokenMaxSupply;
    }

    //uri
    function setURI(string memory newuri) external onlyOwner {
        require(!uriLocked, 'Update uri is locked!');
        _setURI(newuri);
    }

    function setUriSuffix(uint256 id, string memory suffix) external onlyOwner {
        require(!uriSuffixLocked[id], 'Cannot change uri suffix');
        tokenUriSuffix[id] = suffix;
        
        emit URI(uri(id), id);
    }

    //pause
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }


    

    //user mint functions------------------------------------------------------------



    //only signed can mint, only when not paused
    function signature_mint(bytes memory signature, uint256 amount) external whenNotPaused{
        require(minted[msg.sender] == false, "Already minted");
        require(maxSupply[0] >= totalMinted[0] + amount, "Max Supply reached");
        require(maxSupply[0] >= totalSupply(0) + amount, "Max Supply reached");
        checkSignature(msg.sender, amount, signature);
        minted[msg.sender] = true;
        totalMinted[0] += amount; 
        _mint(msg.sender, 0, amount, "");
    }

    
    //upgrader functions------------------------------------------------------------


    //only upgrader contract can burn (after approval from owner)
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        require(msg.sender == upgrader, "Caller not upgrader");

        _burn(account, id, value);
    }

    //only upgrader contract can mint
    function mint(address account, uint256 id,  uint256 amount, bytes memory data)
        external
    {
        require(maxSupply[id] >= totalMinted[id] + amount, "Max Supply reached");
        require(maxSupply[id] >= totalSupply(id) + amount, "Max Supply reached");
        require(id<=maxId , "Exceeds MaxID");
        require(msg.sender == upgrader, "Caller not upgrader");
        totalMinted[id] += amount; 
        _mint(account, id, amount, data);
    }




    //read functions------------------------------------------------------------

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return bytes(tokenUriSuffix[tokenId]).length > 0 ? string(abi.encodePacked(super.uri(0) , tokenUriSuffix[tokenId])) : super.uri(0);
    }

    function checkSignature(address sender, uint256 amount, bytes memory signature) public view returns (bool){        
        bytes32 hash = keccak256(abi.encodePacked(sender, ":", amount));
        address signer = hash.toEthSignedMessageHash().recover(signature);
        require(signer == signerAddress, "Invalid signature");
        return true;
    }

}
