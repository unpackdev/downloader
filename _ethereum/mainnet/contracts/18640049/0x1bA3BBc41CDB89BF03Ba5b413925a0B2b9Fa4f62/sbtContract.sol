// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./AccessControl.sol";
import "./Ownable2Step.sol";
import "./ReentrancyGuard.sol";
import "./ERC721URIStorage.sol";
import "./console.sol";

interface leafContract {
    function burn(uint256 _tokenId, address _address) external;
    function exists(uint256 _tokenId) external view returns (bool);
}

contract LeafSBTContract is ERC721URIStorage, Ownable2Step, AccessControl, ReentrancyGuard {

    address public leafAddress;

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

    event NFTMintEvent(
        uint256 tokenId,
        string tokenUrl,
        address userAddress
    );

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), 'Caller is not a minter');
        _;
    }

    constructor(address _leafAddress) ERC721("Leaft-SBT", "SBT") {
        require(msg.sender != address(0));
        require(_leafAddress != address(0));
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        leafAddress = _leafAddress;
    }

    function mintSBT(uint256 _tokenId, string memory _tokenUrl, address _address) external nonReentrant onlyMinter{
        require(_address != address(0),"Invalid address");
        require(!_exists(_tokenId), "tokenId already exists");
        bool exist =  leafContract(leafAddress).exists(_tokenId);
        console.log(" ~ file: sbtContract.sol:33 ~ mintSBT ~ exist:", exist);
        if(exist){
            leafContract(leafAddress).burn(_tokenId,_address);
        }
        _safeMint(_address, _tokenId);
        _setTokenURI(_tokenId, _tokenUrl);
        emit NFTMintEvent(
          _tokenId,
          _tokenUrl,
          _address
        );
    }

    function approve(address, uint256) public virtual override(ERC721) {
        require(false,"This token is SBT");
    }

    function setApprovalForAll(address, bool) public virtual override(ERC721) {
        require(false,"This token is SBT");
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override
    {
        require(from == address(0), "Token is not transferable");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}