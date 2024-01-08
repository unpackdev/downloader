pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./IERC721.sol";
import "./Ownable.sol";

/// @title Wrapt
/// @author jdhurwitz
/// @author inexplicable

contract Wrapt is ERC1155(""), Ownable{

    event BoxMinted(address _from, address _recipient, address _nftAddress, uint256 _nftTokenID, uint16 _boxID);
    event BoxTransferred(address _nftOwner, address _from, address _to, address _nftAddress, uint256 _nftTokenID, uint16 _boxID);
    event BoxUnwrapped(address _nftOwner, address _unwrapper, address _nftAddress, uint256 _nftTokenID);
    
    mapping(address => mapping(uint256 => address)) public nftAddress_nftTokenID_recipientAddress; //used for permission

    bool public MINT_ACTIVE = true;

    constructor(string memory _URI) {
        _setURI(_URI);
    }

    function setURI(string memory _baseURI)external onlyOwner{
        _setURI(_baseURI);
    }

    function toggleMintActive() external onlyOwner{
        MINT_ACTIVE = !MINT_ACTIVE;
    }

    /* These two functions are overidden to prevent an edge case / unhappy scenario. 
    A user could call ERC1155's safeTransferFrom and send the giftbox erc1155 token 
    to someone who doesn't have the necessary permissions to claim it. So it becomes
    a dead gift box. Transfer gift will allow transfer & update permissions properly.*/
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        pure
        override
    { revert("External cannot call transfer."); } 

     function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        pure
        override
    { revert("External cannot call batch transfer."); } 

    function wrapAndSend(address _recipient, address _nftAddress, uint256 _nftTokenID, uint16 _boxID) external {
        require(MINT_ACTIVE = true, "Minting not active.");
        require(nftAddress_nftTokenID_recipientAddress[_nftAddress][_nftTokenID] == address(0), "You have already sent this NFT to someone.");
        require( IERC721(_nftAddress).ownerOf(_nftTokenID)==msg.sender, "Cannot send a gift for an NFT you do not own.");
        _mint(_recipient, _boxID, 1, "");
        emit BoxMinted(msg.sender, _recipient, _nftAddress, _nftTokenID, _boxID);
        nftAddress_nftTokenID_recipientAddress[_nftAddress][_nftTokenID] = _recipient;   

    }

    function transferGift(address _nftOwner, address _recipient, address _nftAddress, uint256 _nftTokenID, uint16 _boxID) external{
        require(nftAddress_nftTokenID_recipientAddress[_nftAddress][_nftTokenID] == msg.sender, 
        "You are not the owner, so you do not have permission to transfer this gift box.");

        super.safeTransferFrom(msg.sender, _recipient, _boxID, 1, "");
        nftAddress_nftTokenID_recipientAddress[_nftAddress][_nftTokenID] = _recipient;
        emit BoxTransferred(_nftOwner, msg.sender, _recipient, _nftAddress, _nftTokenID, _boxID);
    }

    function unwrap(address _nftOwner, address _nftAddress, uint256 _nftTokenID) external {
        require(nftAddress_nftTokenID_recipientAddress[_nftAddress][_nftTokenID] == msg.sender, 
        "You are not the recipient, so you do not have permission to open this gift box.");

        IERC721(_nftAddress).transferFrom(_nftOwner, msg.sender, _nftTokenID);        
        emit BoxUnwrapped(_nftOwner, msg.sender, _nftAddress, _nftTokenID);

        nftAddress_nftTokenID_recipientAddress[_nftAddress][_nftTokenID] = address(0);
    }


    function withdraw() external onlyOwner{
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

}