// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

interface IKeys {
    function ownerOf(uint256 tokenId) external view returns(address);
} 

interface IBooty {
    function burn(address _from, uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;
} 

contract PPChests is ERC721A, Ownable {
    using SafeMath for uint256;
    
    //Sale States
    bool public isKeyMintActive = false;
    bool public isAllowListActive = false;
    mapping(address => int) public numClaimed;
    
    
    //Key tracking
    IKeys public Keys;
    mapping(uint256 => bool) public keyUsed;
    
    //Booty
    IBooty public Booty;
    mapping(uint256 => uint256) public chestBalance;
    mapping(uint256 => uint256) public lastUpdate;
    event ChestBalanceUpdate(uint256 chestId, uint256 balance);
    
    //Privates
    string private _baseURIextended;
    address private signer;
    
    //In tenths of a percent
    uint256 public constant DAILY_RATE = 14;
    
    constructor() ERC721A("PixelPiracyChests", "PPCHESTS") {
    }
    //Key Minting
    function setKeys(address keysAddress) external onlyOwner {
        Keys = IKeys(keysAddress);
    }
    
    function setIsKeyMintActive(bool _isKeyMintActive) external onlyOwner {
        isKeyMintActive = _isKeyMintActive;
    }

    function mintWithKey(uint256[] calldata keyIds) external {
        require(isKeyMintActive, "Key mint is not active");          
        for (uint256 i = 0; i < keyIds.length; i++) {
            require(Keys.ownerOf(keyIds[i]) == msg.sender, "Cannot redeem key you don't own");
            require(keyUsed[keyIds[i]] == false, "Key has been used");
            keyUsed[keyIds[i]] = true;
        }
        _safeMint(msg.sender, keyIds.length);
    }
    //

    //Allowed Minting
    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function mintAllowList(address _address, int _numClaimed, bytes calldata _voucher) external {
        require(isAllowListActive, "Allow list is not active");
        require(numClaimed[_address] == _numClaimed, "Already claimed mint");
        require(msg.sender == _address, "Not your voucher");

        bytes32 hash = keccak256(
            abi.encodePacked(_address, _numClaimed)
        );
        require(_verifySignature(signer, hash, _voucher), "Invalid voucher");

        numClaimed[_address]++;
        _safeMint(_address, 1);
    }

    function _verifySignature(address _signer, bytes32 _hash, bytes memory _signature) private pure returns (bool) {
        return _signer == ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
    }
    //
    
    //Booty
    function setBooty(address bootyAddress) external onlyOwner {
        Booty = IBooty(bootyAddress);
    }
    
    function deposit(uint256 chestId, uint256 amount) external {
        require(msg.sender == ownerOf(chestId), "Cannot interact with a chest you do not own");
        chestBalance[chestId] += getPendingInterest(chestId);
        chestBalance[chestId] += amount;
        Booty.burn(msg.sender, amount);
        lastUpdate[chestId] = block.timestamp;
        emit ChestBalanceUpdate(chestId, chestBalance[chestId]);
    }
    
    function withdraw(uint256 chestId, uint256 amount) external {
        require(msg.sender == ownerOf(chestId), "Cannot interact with a chest you do not own");
        chestBalance[chestId] += getPendingInterest(chestId);
        require(chestBalance[chestId] >= amount, "Not enough Booty in chest");
        chestBalance[chestId] -= amount;
        Booty.mint(msg.sender, amount);
        lastUpdate[chestId] = block.timestamp;
        emit ChestBalanceUpdate(chestId, chestBalance[chestId]);
    }
    
    function claimInterest(uint256 chestId) external {
        require(msg.sender == ownerOf(chestId), "Cannot interact with a chest you do not own");
        chestBalance[chestId] += getPendingInterest(chestId);
        lastUpdate[chestId] = block.timestamp;
        emit ChestBalanceUpdate(chestId, chestBalance[chestId]);
    }
    
    function getPendingInterest(uint256 chestId) public view returns(uint256) {
        uint256 interest = chestBalance[chestId] * DAILY_RATE * (block.timestamp - lastUpdate[chestId]) / 86400000;
        //Max 4 weeks of interest
        uint256 maxInterest = chestBalance[chestId] * 2 / 5;
        return interest < maxInterest ? interest : maxInterest;
    }
    //

    //Overrides
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    //
}