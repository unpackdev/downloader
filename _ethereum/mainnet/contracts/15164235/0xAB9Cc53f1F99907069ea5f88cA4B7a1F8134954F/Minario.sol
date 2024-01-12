// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Strings.sol"; 

contract Minario is ERC721A, Ownable {

    using Strings for uint256;

    mapping (address => bool) public statusAdmin;
    address public marketAddress;
    string public baseURI;

    event Minted(
        address owner,
        uint256 quantity,
        string pointerMoment,
        uint256 currentSupply
    );

    constructor() ERC721A("Minario Collections", "MINARIO") {
        statusAdmin[msg.sender] = true;
        baseURI = "https://minarionft.io/backend/api/nft-uri/";
    }

    function mint(
        address callerAddress,
        string memory pointerMoment
    ) external {
        require(_msgSender() == marketAddress, "The caller must be marketplace contract!");
        //this will check is the one who sign the message really from platform or not.
        _mint(callerAddress, 1);
        emit Minted(callerAddress, 1, pointerMoment, totalSupply());
    }

    //TODO:
    function batchMint(address[] memory to, uint256 amount, string[] memory pointerMoment) external {
        require(statusAdmin[msg.sender], "PERMISSION_INVALID");
        require(amount == to.length && amount == pointerMoment.length, "AMOUNT_LENGTH_MISMATCH");
        for (uint256 i = 0; i < amount; i++) {
            _mint(to[i], 1);
            emit Minted(to[i], 1, pointerMoment[i], totalSupply());
        }
    }

    function setMarketAddress(address _marketAddress) external onlyOwner {
        require(_marketAddress != address(0), "Address must not be zero!");
        marketAddress = _marketAddress;
    }

    function _startTokenId() internal pure override returns (uint256){
        return 1;
    }

    function toggleAdmin(address newAdmin) external onlyOwner {
        require(newAdmin != address(0), "Address must not be zero!");
        if(statusAdmin[newAdmin]){
            statusAdmin[newAdmin] = false;
        }else{
            statusAdmin[newAdmin] = true;
        }
    }
    
    /// @notice Set base URI for the NFT.  
    /// @param _uri base URI (can be ipfs/https)
    function setBaseURI(string calldata _uri) 
        external 
        onlyOwner 
    {
        baseURI = _uri;
    }

    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_id), "Token does not exist");
        return string(abi.encodePacked(baseURI, _id.toString()));
    }
}
