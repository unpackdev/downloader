// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC1155.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Strings.sol"; 
import "./draft-EIP712.sol";
import "./ReentrancyGuard.sol";

/// @author yuru@GASPACK twitter.com/0xYuru
/// @dev aa0cdefd28cd450477ec80c28ecf3574 0x8fd31bb99658cb203b8c9034baf3f836c2bc2422fd30380fa30b8eade122618d3ca64095830cac2c0e84bc22910eef206eb43d54f71069f8d9e66cf8e4dcabec1c 
contract JukiResource is ERC1155, Pausable, EIP712, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;
    
    mapping(address => bool) private rewardContracts;
    mapping(uint256 => bool) public tokenIds;

    string private baseURI;
    string public name = "Jukiverse Resources";
    string public symbol = "JRESOURCE";
    bool public isActive;
    address public signer;
    bytes32 public constant RESOURCES_TYPEHASH = 
        keccak256("Resources(address player,uint256[] tokenIds,uint256[] tokenAmounts,uint256 nonce)"); 

    event Claimed(address owner, uint256 nonce);

    modifier notContract() {
        require(!_isContract(_msgSender()), "NOT_ALLOWED_CONTRACT");
        require(_msgSender() == tx.origin, "NOT_ALLOWED_PROXY");
        _;
    }
    modifier approvedCaller(){
        require(rewardContracts[msg.sender], "Invalid Caller");
        _;
    }
    mapping(address => uint256) public playerNonce;

    constructor(string memory _uri, address _signer, address _dev) 
        ERC1155(_uri)
        EIP712("JUKIRESOURCE", "1.0.0")
    {
        baseURI = _uri;
        signer = _signer;
        tokenIds[1] = true;
        tokenIds[2] = true;
        tokenIds[3] = true;
        tokenIds[888] = true;
        isActive = true;
        _mint(_dev, 1, 1, "");
        _mint(_dev, 2, 1, "");
        _mint(_dev, 3, 1, "");
        _mint(_dev, 888, 1, "");
        _transferOwnership(_dev);
    }

    function appendToken(uint256 _tokenId)
        external 
        onlyOwner
    {
        tokenIds[_tokenId] = true;
    }

    function setRewardContract(address _contractAddress, bool _status) 
        external
        onlyOwner
    {
        rewardContracts[_contractAddress] = _status;
    }

    function burn(address _from, uint256[] calldata _ids, uint256[] calldata _amounts)
        external
        approvedCaller 
    {
        _burnBatch(_from, _ids, _amounts);
    }
    
    function setBaseURI(string calldata _uri) 
        external
        onlyOwner
     {
        baseURI = _uri;
    }

    function mint(uint256[] calldata _tokenIds, uint256[] calldata _tokenAmounts, uint256 _nonce, bytes calldata _signature)
        external
        notContract
        nonReentrant
    {
        require(isActive, "NOT_ACTIVE");
        require(_verify(msg.sender, _tokenIds, _tokenAmounts, _nonce, _signature) == signer, "INVALID_SIGNATURE");
        require(playerNonce[msg.sender] == _nonce, "INVALID_NONCE");
        
        playerNonce[msg.sender]++;
        _mintBatch(msg.sender, _tokenIds, _tokenAmounts, "");
        emit Claimed(msg.sender, _nonce);
    }
    function gib(address _to, uint256[] calldata _ids, uint256[] calldata _amounts)
        external
        approvedCaller
    {
        _mintBatch(_to, _ids, _amounts, "");
    }

    /// @notice Set signer for whitelist/redeem NFT.  
    /// @param _signer address of signer 
    function setSigner(address _signer) 
        external 
        onlyOwner 
    {
        signer = _signer;
    }

    /// @notice Set signer for whitelist/redeem NFT.  
    /// @param _status state 
    function setActive(bool _status) 
        external 
        onlyOwner 
    {
        isActive = _status;
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _verify(address _player, uint256[] calldata _tokenIds, uint256[] calldata _tokenAmounts, uint256 _nonce, bytes calldata _sign)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(
                RESOURCES_TYPEHASH,
                _player,
                keccak256(abi.encodePacked(_tokenIds)),
                keccak256(abi.encodePacked(_tokenAmounts)),
                _nonce
            ))
        );
        return ECDSA.recover(digest, _sign);
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function uri(uint256 typeId)
        public
        view                
        override
        returns (string memory)
    {
        require(
            tokenIds[typeId],
            "URI requested for invalid token type"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString()))
                : baseURI;
    }
}