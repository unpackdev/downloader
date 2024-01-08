// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Dirtypanties
/// @author: devcryptodude

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Strings.sol";


contract DirtyPantiesSeason0 is ReentrancyGuard, Ownable, ERC721{


    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public maxPanties = 200;
    uint256 public claimedPanties;
    bool public active;

    string private _prefixURI;

    event Activate();
    event Deactivate();


    bytes32 public constant SEASON0_TYPEHASH = keccak256("DirtyPantiesSeason0(address buyer,uint256 tokenId)");
    address public signerAddress;


    /* royalties */
    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;

    bytes4 private constant _INTERFACE_ID_ROYALTIES = 0xbb3bafd6; //bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a; //bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    constructor(address _signerAddress) ERC721("DirtyPantiesSeason0", "DirtyPantiesSeason0"){

        _royaltyRecipient = payable(msg.sender);
        _royaltyBps = 1000;
        signerAddress = _signerAddress;
        active = true;
        _prefixURI = "https://ipfs.io/ipfs/bafybeiay2p7jqcvbzs3hmihgwqgkwcf5krxuhbe7bbqaqedngdhwwylanq/season0/";
    }


   function submitConfirmation(address _addr,uint256 _tokenID,bytes memory signature)
        public pure returns (address signer){
        bytes32 digest = prefixed(keccak256(abi.encodePacked(SEASON0_TYPEHASH,_addr,_tokenID)));
        signer = digest.recover(signature);
    }

    /**
    * @dev Return totalSupply
    */
    function totalSupply() public view returns(uint){
        return claimedPanties;
    }


    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
            return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
    * @dev setSignerAddr
    */
    function setSignerAddr(address _signerAddress) external onlyOwner{
        require(signerAddress != address(0),  "Na you can't change the signer");
        signerAddress = _signerAddress;
    }

    /**
     * @dev Activate mint
     */
    function activate() external onlyOwner{
        require(!active, "Already active");
        active = true;
        emit Activate();
    }

    /**
     * @dev Deactivate mint
     */
    function deactivate() external onlyOwner{
        active = false;
        emit Deactivate();
    }

    function setPrefixURI(string calldata uri) external onlyOwner {
        _prefixURI = uri;
    }

    function setMaxPanties(uint256 _maxPanties) external onlyOwner {
        maxPanties = _maxPanties;
    }


    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return string(abi.encodePacked(_prefixURI, tokenId.toString()));
    }

    /**
     * @dev Claim panties
     */
    function claimSeason0(uint256 _tokenId,bytes memory signature) external nonReentrant {
        require(active, "Inactive");

        require(!_exists(_tokenId), "ERC721: NFT already claimed");
        claimedPanties++;
        require(claimedPanties <= maxPanties, "Too many requested");

        address recoverAddr = submitConfirmation(msg.sender,_tokenId,signature);
        require( recoverAddr == signerAddress && recoverAddr != address(0),"Bad Signer Address");

        _mint(msg.sender, _tokenId);
    }


    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || interfaceId == _INTERFACE_ID_ROYALTIES
               || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

     /**
     * ROYALTIES implem: check EIP-2981 https://eips.ethereum.org/EIPS/eip-2981
     **/

    function updateRoyalties(address payable recipient, uint256 bps) external onlyOwner {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }

}
