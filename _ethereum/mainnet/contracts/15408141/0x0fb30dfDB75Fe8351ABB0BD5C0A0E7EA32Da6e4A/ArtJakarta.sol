// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol"; 

/// @author iqbalsyamil.eth (github.com/2pai)
/// @dev In collaboration Gaspack X Monday Art Club x Art Jakarta 
contract ArtJakarta is ERC1155, Ownable {
    using Strings for uint256;
    
    mapping(uint256 => bool) public tokenIds;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(address => mapping(uint256 => uint256)) public userLimit;

    address private immutable GaspackWallet = 0x83739A8Ec78f74Ed2f1e6256fEa391DB01F1566F;
    address private ArtJakartaWallet = 0x83739A8Ec78f74Ed2f1e6256fEa391DB01F1566F;

    string private baseURI;
    string public name = "ArtJakarta";
    string public symbol = "ARTJKT";
    uint256 public price = 0.07 ether;
    bool public isActive;
    

    constructor(string memory _uri) 
        ERC1155(_uri)
    {
        baseURI = _uri;
        isActive = true;
        tokenIds[1] = true;
        tokenIds[2] = true;
        tokenIds[3] = true;
    }

    function appendToken(uint256 _tokenId)
        external 
        onlyOwner
    {
        tokenIds[_tokenId] = true;
    }

    function setArtJakartaWallet(address _artjakartawallet) 
        external
        onlyOwner
    {
        ArtJakartaWallet = _artjakartawallet;
    }

    function setBaseURI(string calldata _uri) 
        external
        onlyOwner
    {
        baseURI = _uri;
    }

    function totalSupply(uint256 _id) public view returns(uint256) {
        return tokenSupply[_id];
    }

    function withdrawAll() 
        external 
        onlyOwner 
    {
        require(address(this).balance > 0, "BALANCE_ZERO");
        uint256 ArtJakartaWalletBalance = address(this).balance * 90 / 100;
        uint256 GaspackWalletBalance = address(this).balance * 10 / 100;

        sendValue(payable(GaspackWallet), GaspackWalletBalance);
        sendValue(payable(ArtJakartaWallet), ArtJakartaWalletBalance);
    }

    function sendValue(address payable recipient, uint256 amount) 
        internal
    {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function mint(uint256 _id)
        external
        payable
    {
        require(isActive, "NOT_ACTIVE");
        require(tokenIds[_id], "TOKEN_NOT_AVAILABLE");
        require(msg.value >= price, "INSUFFICIENT_FUNDS");
        require(tokenSupply[_id] < 10, "SUPPLY_EXCEEDED");
        require(userLimit[msg.sender][_id] < 1, "LIMIT");
        tokenSupply[_id]++;
        userLimit[msg.sender][_id]++;
        _mint(msg.sender, _id , 1, "");
    }
    function gib(address _to, uint256[] calldata _ids, uint256[] calldata _amounts)
        external
        onlyOwner
    {
        _mintBatch(_to, _ids, _amounts, "");
    }

    /// @notice Set state for purchasing NFT.  
    /// @param _status state 
    function setActive(bool _status) 
        external 
        onlyOwner 
    {
        isActive = _status;
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
        return string(abi.encodePacked(baseURI, typeId.toString()));
    }
}