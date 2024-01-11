// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: @props
import "./ERC165.sol";
import "./ERC721.sol";
import "./ERC721Pausable.sol";
import "./ECDSA.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./Proofs.sol";
import "./IRoyalty.sol";
import "./IAllowlist.sol";
import "./IConfig.sol";

contract Props721 is
  IAllowlist,
  IConfig,
  ERC165,
  ERC721,
  Pausable,
  AccessControl,
  Ownable
{
    using Strings for uint256;
    using ECDSA for bytes32;

    event Minted(address indexed account, string tokens);

    mapping(uint256 => address) public allowedAddresses; //receivingWallet 0 | sigWallet 1 | royaltyContract 2
    string public baseURI;
    string public _contractURI;

    struct TokenPool{
      uint256 currentIndex;
      uint256 maxTokenIndex;
    }

    mapping(uint256 => TokenPool) public tokenPools;
    mapping(uint256 => bool) public royaltyTokens;

    bool[] private p;

    Allowlists public allowlists;
    Config public config;

    mapping(address => mapping(uint256 => uint256)) public mintedByAllowlist;

    bytes32 public constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");

    error MintQuantityInvalid();
    error MintClosed();
    error InsufficientFunds();
    error MerkleProofInvalid();

    constructor(string memory __name, string memory __symbol, string memory __baseURI, uint256[] memory __tokenIndexes, address __receivingWallet, address __signatureVerifier, bool[] memory __p) ERC721(__name, __symbol) {
        baseURI = __baseURI;
        allowedAddresses[0] = __receivingWallet;
        allowedAddresses[1] = __signatureVerifier;
        p = __p;
        for(uint256 i = 0; i < __tokenIndexes.length; i++) {
            tokenPools[i].currentIndex = __tokenIndexes[i];
            tokenPools[i].maxTokenIndex = i < __tokenIndexes.length - 1 ? __tokenIndexes[i+1] : 10000000;
        }

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTRACT_ADMIN_ROLE, msg.sender);

    }

    /*///////////////////////////////////////////////////////////////
                        Allowlist + Config Logic
    //////////////////////////////////////////////////////////////*/

    function setAllowlists(Allowlist[] calldata _allowlists)
        external
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
      allowlists.count = _allowlists.length;
      for (uint256 i = 0; i < _allowlists.length; i++) {
        allowlists.lists[i] = _allowlists[i];
      }
    }

     function updateAllowlistByIndex(Allowlist calldata _allowlist, uint256 i)
        external
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        allowlists.lists[i] = _allowlist;
    }

    function addAllowlist(Allowlist calldata _allowlist)
        external
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        allowlists.lists[allowlists.count] = _allowlist;
        allowlists.count++;
    }

    function setConfig(Config calldata _config)
        external
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
      config = _config;
    }

    function getP() external view onlyRole(CONTRACT_ADMIN_ROLE) returns(bool[] memory){
       return p;
    }

    function clearP() external onlyRole(CONTRACT_ADMIN_ROLE) {
       delete p;
    }

    function concatP(bool[] memory _p) external onlyRole(CONTRACT_ADMIN_ROLE) {
        for(uint256 i = 0; i < _p.length; i++) {
            p.push(_p[i]);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Getters
    //////////////////////////////////////////////////////////////*/


    /// @dev Returns the claim condition at the given uid.
    function getAllowlistById(uint256 _allowlistId) external view returns (Allowlist memory allowlist) {
        allowlist = allowlists.lists[_allowlistId];
    }

    /*///////////////////////////////////////////////////////////////
                        Mint
    //////////////////////////////////////////////////////////////*/

    //TODO:
   function mint(uint256[] calldata __quantities, bytes32[][] calldata __proofs, uint256[] calldata __allotments, uint256[] calldata __allowlistIds) external payable {
        uint256 _cost = 0;

         for(uint256 i = 0; i < __quantities.length; i++) {

             isSaleOpen(__allowlistIds[i]);
             revertOnMintCheck(msg.sender, __quantities[i], allowlists.lists[__allowlistIds[i]].tokenPool);
             revertOnMaxTokenCheck(msg.sender, __quantities[i], __allowlistIds[i]);
             revertOnArbitraryAllocationCheckFailure(
                 msg.sender,
                mintedByAllowlist[msg.sender][__allowlistIds[i]],
                __quantities[i],
                __proofs[i],
                __allowlistIds[i],
                __allotments[i]
             );

             _cost += allowlists.lists[__allowlistIds[i]].price * __quantities[i];
         }

          if(_cost > msg.value) revert InsufficientFunds();

          payable(allowedAddresses[0]).transfer(msg.value);

          string memory tokensMinted = "";
          for(uint256 i = 0; i < __quantities.length; i++) {
               mintedByAllowlist[msg.sender][__allowlistIds[i]] += __quantities[i];
               tokensMinted = string(abi.encodePacked(tokensMinted, __mint(msg.sender, __quantities[i], allowlists.lists[__allowlistIds[i]].tokenPool)));
          }

       emit Minted(msg.sender, tokensMinted);
    }


    function __mint(address __to, uint256 __quantity, uint256 __tokenPoolID) internal returns(string memory){
        revertOnMintCheck(__to, __quantity, __tokenPoolID);
        string memory tokensMinted = "";
        uint256 start = tokenPools[__tokenPoolID].currentIndex;
        for(uint256 i = start; i < start + __quantity; i++) {
            tokensMinted = string(abi.encodePacked(tokensMinted, Strings.toString(i), ","));
            royaltyTokens[i] = p[i-1];
            _safeMint(__to, i);
        }
        tokenPools[__tokenPoolID].currentIndex = start + __quantity;
        return tokensMinted;
    }

    function revertOnMintCheck(address __to, uint256 __quantity, uint256 __tokenPoolID) internal view{
      if(__quantity == 0 || tokenPools[__tokenPoolID].currentIndex + (__quantity - 1) >= tokenPools[__tokenPoolID].maxTokenIndex) revert MintQuantityInvalid();
    }

    function revertOnMaxTokenCheck(address __to, uint256 __quantity, uint256 __allowlistID) internal view{
      if( mintedByAllowlist[msg.sender][__allowlistID] + __quantity > allowlists.lists[__allowlistID].maxMintPerWallet) revert MintQuantityInvalid();
    }

    function isSaleOpen(uint256 __allowlistID) public view returns (bool){
        if (paused() || block.timestamp < allowlists.lists[__allowlistID].startTime || block.timestamp > allowlists.lists[__allowlistID].endTime) revert MintClosed();
        return true;
    }

     //TODO:
    function airdrop(address __to, uint256 __quantity, uint256 __tokenPoolID) external onlyRole(CONTRACT_ADMIN_ROLE){
        __mint(__to, __quantity, __tokenPoolID);
    }

     function fusion(
        uint256[] memory __inputTokenIDs,
        uint256[] memory __outputTokenIDs,
        bytes memory signature
    ) external{
        //TODO: check on server if owned
       require(ECDSA.recover(keccak256(abi.encodePacked(msg.sender, __inputTokenIDs,  __outputTokenIDs)).toEthSignedMessageHash(), signature) == allowedAddresses[1], "Invalid Signature");
        for(uint256 i = 0; i < __inputTokenIDs.length; i++) {
            _burn(__inputTokenIDs[i]);
        }
        string memory tokensMinted = "";
         for(uint256 i = 0; i < __outputTokenIDs.length; i++) {
             tokensMinted = string(abi.encodePacked(tokensMinted, Strings.toString(__outputTokenIDs[i]), ","));
             royaltyTokens[__outputTokenIDs[i]] = true;
             _safeMint(msg.sender, __outputTokenIDs[i]);
        }

        emit Minted(msg.sender, tokensMinted);
    }

     function setRevenueWallet(address __address) external onlyRole(CONTRACT_ADMIN_ROLE) {
        allowedAddresses[0] = __address;
    }

    function setSigVerifierWallet(address __address) external onlyRole(CONTRACT_ADMIN_ROLE) {
        allowedAddresses[1] = __address;
    }

    function setRoyaltyContract( address __address) external onlyRole(CONTRACT_ADMIN_ROLE) {
        allowedAddresses[2] = __address;
    }

    
    

    function revertOnArbitraryAllocationCheckFailure(address __address, uint256 __numMinted, uint256 __quantity, bytes32[] calldata __proof, uint256 __allowlistID, uint256 __allowed) internal view {
        Allowlist storage allowlist = allowlists.lists[__allowlistID];
        if(!allowlist.isActive) revert MintClosed();
        if(allowlist.typedata != bytes32(0)){
            if (__quantity > __allowed || ((__quantity + __numMinted) > __allowed)) revert MintQuantityInvalid();
             (bool validMerkleProof, uint256 merkleProofIndex) = MerkleProof.verify(
                __proof,
                allowlist.typedata,
                keccak256(abi.encodePacked(__address, __allowed))
            );
            if (!validMerkleProof) revert MerkleProofInvalid();
         }


    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl, ERC165) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), '.json'));
    }

     function setContractURI(string memory uri) external onlyRole(CONTRACT_ADMIN_ROLE){
        _contractURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        if (royaltyTokens[tokenId]) {
             IRoyalty(allowedAddresses[2]).toggleShares(from, to);
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

}
