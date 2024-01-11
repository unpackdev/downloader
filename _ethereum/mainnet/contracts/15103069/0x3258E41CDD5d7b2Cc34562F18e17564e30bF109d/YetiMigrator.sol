//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "./IERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./YetiSigner.sol";

contract YetiMigrator is OwnableUpgradeable, IERC721ReceiverUpgradeable, YetiSigner{

    IERC721Upgradeable yeti;
    address public designatedSigner;

    event Locked(address user, uint[] tokenIds);
    event Withdrawn(address user, uint tokenId);

    mapping (address => mapping (uint => bool)) public nonce;

    function initialize(address _yeti,string memory domain, string memory version) public initializer{
        __Ownable_init();
        __YetiSigner_init(domain, version);
        yeti = IERC721Upgradeable(_yeti);
    }


    //@dev Sets the designated Signer
    //@param New wallet address who signs the message
    ///@dev Sets the designated Signer
    function setDesignatedSigner(address _signer) external onlyOwner{
        designatedSigner = _signer;
    }

    //@notice Use this function to lock your tokens in L1 and play the game on L2.
    //@param User's Yeti Ids they want to lock passed in an array.
    ///@notice Use this function to lock your tokens in L1 and play the game on L2.
    function StartGame(uint[] memory tokenIds) external{
        for(uint i = 0; i < tokenIds.length; i++){
            require(yeti.ownerOf(tokenIds[i]) == _msgSender(), "Caller not Owner");
            yeti.safeTransferFrom(_msgSender(), address(this), tokenIds[i]);
        }
        emit Locked(_msgSender(), tokenIds);
    }

    //@notice Use this function to Unlock L1 Yetis.
    //@param A tuple of userAddress, tokenId, level, exp, rarity, pass and signature generated.
    ///@notice Use this function to Unlock L1 Yetis.
    function  WithdrawToken(Rarity memory token) external{
        require (getSigner(token) == designatedSigner, "Not designated Signer");
        require (token.pass + 5 minutes >= block.timestamp, "Signer Expired");
        require (msg.sender == token.userAddress, "!User");
        require (!nonce[msg.sender][token.pass], "Signer Expired");
        nonce[msg.sender][token.pass] = true;
        yeti.safeTransferFrom(address(this), token.userAddress, token.tokenId);
        emit Withdrawn(token.userAddress, token.tokenId);
    }

    //@dev Setter for Yeti Address
    //@param new ERC721 contract address
    function setYetiAddress(address _yeti) external onlyOwner{
        yeti = IERC721Upgradeable(_yeti);
    }

    function onERC721Received(
        address,
        address ,
        uint,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}
