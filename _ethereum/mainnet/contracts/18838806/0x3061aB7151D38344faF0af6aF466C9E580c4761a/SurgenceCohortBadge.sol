// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract SurgenceCohortBadge is ERC721A("Surgence Cohort Badge", "SUGMI"), Ownable{

    string public baseURI;
    bool public isMintLive;
    bytes32 public root;

    event Attest(address indexed to, uint256 tokenId);
    event Revoke(address indexed to, uint256 tokenId);

    constructor (string memory _initialBaseURI, bytes32 _initRoot) {
        setBaseURI(_initialBaseURI);
        root = _initRoot;

        _safeMint(msg.sender, 1);
    }



    /**
     * @dev Owner function to issue/airdrop badges to one or multiple recipients
     * 
     * @param _recipients The recipients must be in the form of an array EX: [address1,address2...]
    */
    function adminBadgeIssuance(address[] calldata _recipients) external onlyOwner{

        for (uint i = 0; i < _recipients.length; i++) {
            _safeMint(_recipients[i], 1);
        }
    }

    /**
     * @dev SBT badge mint function guarded by MerkleProof verification
     * 
     * @param proof The proof generated and passed in through external source for claiming
    */
    function mint(bytes32[] calldata proof) public {
        require(isMintLive, "mint is not live");
        require(_getAux(_msgSender()) < 1, "badge already minted");

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

        require(MerkleProof.verify(proof, root, leaf), "invalid proof");

        _setAux(_msgSender(), 1);
        _safeMint(msg.sender, 1);
    }

    /**
     * @dev Owner function to revoke a tokenId by burning it
     * 
     * @param tokenId The desired tokenId to revoke and burn
    */
    function revoke(uint256 tokenId) external onlyOwner{
        _burn(tokenId);
    }


    /**
     * @dev Override function to prevent the transferring of the SBT badge
     * 
     * Note this override is what provides the NTT (non-transferable token) aspect to the SBT allowing only * address(0) to access the transfer function in order to mint a new badge or burn an existing one
    */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override virtual {
        require(from == address(0) || to == address(0), "soulbound token cannot be transferred");
    }

    /**
     * @dev Override function coupled with _beforeTokenTransfers to identify and emit correct event
     * 
     * Note if token @param from address(0) it is emitted as a mint through the "Attest" event
     * if token @param to address(0) it is emitted as a revoke/burn throught the "Revoke" event
    */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override virtual {
        if(from == address(0)){
            emit Attest(to, startTokenId);
        } else emit Revoke(to, startTokenId);
    }


    /**
     * @dev Owner function to set a new merkle root for whitelist modifications
     * 
     * @param _root The updated merkle root
    */
    function setRoot(bytes32 _root) external onlyOwner{
        root = _root;
    }

    /**
     * @dev Owner function to set the status of mint
     * 
     * @param _status The updated mint status (pass in "true" to enable mint and "false" to disable)
    */
    function setMintState(bool _status) external onlyOwner{
        isMintLive = _status;
    }

    /**
     * @dev Owner function to set the status of mint
     * 
     * @param _URI The updated uri link 
     * note format: ipfs://<CID>
    */
    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    /**
     * @dev Public view function returning if a user address has previously claimed their SBT badge
     * 
     * @param _address The desired address to query
    */
    function badgeClaimed(address _address) external view returns (bool) {
        return _getAux(_address) > 0;
    }

    /**
     * @dev Public view function returning the current metadata uri link
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Override function to start minted token id's at 1 instead of 0
    */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Public view function returning the metadata uri link for a specific tokenId
     * 
     * @param tokenId The desired tokenId to query
     * 
     * note in this case all tokenIds return same uri
    */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){

        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");

        return baseURI;
    }
}