// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./ERC721AUpgradeable.sol";
import "./Initializable.sol";
import "./MerkleProofUpgradeable.sol";

/*
* @title Metashima - Created by Dimension Studio
* @author lileddie.eth / Enefte Studio
*/
contract MetashimaV2 is Initializable, ERC721AUpgradeable {

    uint64 public MAX_SUPPLY;
    uint64 public PHASE_ONE_SUPPLY;
    uint64 public PHASE_TWO_SUPPLY;
    uint64 public TOKEN_PRICE;
    uint64 public TOKEN_PRICE_PRESALE;
    uint64 public MAX_TOKENS_PER_WALLET;

    uint64 public saleOpens;
    uint64 public saleCloses;    
    uint64 public presaleOpens;
    uint64 public presaleCloses;
    
    bytes32 private merkleRoot;

    string private BASE_URI;
      
    mapping(address => bool) private _dev;  
    address private _owner;
    
    /**
    * @notice minting process for the main sale
    *
    * @param _numberOfTokens number of tokens to be minted
    */
    function mint(uint64 _numberOfTokens) external payable  {
        require(block.timestamp >= saleOpens && block.timestamp <= saleCloses, "Public sale closed");
        require(totalSupply() + _numberOfTokens <= PHASE_ONE_SUPPLY, "Not enough left");

        require(TOKEN_PRICE * _numberOfTokens <= msg.value, 'Missing eth');

        _safeMint(msg.sender, _numberOfTokens);
    }

    /**
    * @notice minting process for the presale, validates against an off-chain whitelist.
    *
    * @param _numberOfTokens number of tokens to be minted
    * @param _merkleProof the merkle proof for that user
    */
    function mintPresaleMerkle(uint64 _numberOfTokens, bytes32[] calldata _merkleProof) external payable  {
        require(block.timestamp >= presaleOpens && block.timestamp <= presaleCloses, "Presale closed");
        require(totalSupply() + _numberOfTokens <= PHASE_ONE_SUPPLY, "Not enough left");
        
        uint64 mintsForThisWallet = mintsForWallet(msg.sender);
        mintsForThisWallet += _numberOfTokens;
        require(mintsForThisWallet <= MAX_TOKENS_PER_WALLET, "Max tokens reached per wallet");

        require(TOKEN_PRICE_PRESALE * _numberOfTokens <= msg.value, 'Missing eth');

        // Validate against the merkletree root
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, leaf), "Invalid proof. Not whitelisted.");

        _safeMint(msg.sender, _numberOfTokens);
        
        _setAux(msg.sender,mintsForThisWallet);
    }
    
    /**
    * @notice airdrop a number of NFTs to a specified address - used for giveaways etc.
    *
    * @param _numberOfTokens number of tokens to be sent
    * @param _userAddress address to send tokens to
    */
    function airdrop(uint64 _numberOfTokens, address _userAddress) external onlyOwner {
        require(totalSupply() + _numberOfTokens <= MAX_SUPPLY, "Not enough left");
        _safeMint(_userAddress, _numberOfTokens);
    }

    /**
    * @notice set the merkle root for the presale whitelist verification
    *
    * @param _merkleRoot the new merkle root
    */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyDevOrOwner {
        merkleRoot = _merkleRoot;
    }

    /**
    * @notice read the mints made by a specified wallet address.
    *
    * @param _wallet the wallet address
    */
    function mintsForWallet(address _wallet) public view returns (uint64) {
        return _getAux(_wallet);
    }

    /**
    * @notice set the timestamp of when the presale should begin
    *
    * @param _openTime the unix timestamp the presale opens
    * @param _closeTime the unix timestamp the presale closes
    */
    function setPresaleTimes(uint64 _openTime, uint64 _closeTime) external onlyDevOrOwner {
        presaleOpens = _openTime;
        presaleCloses = _closeTime;
    }
    
    /**
    * @notice set the timestamp of when the main sale should begin
    *
    * @param _openTime the unix timestamp the sale opens
    * @param _closeTime the unix timestamp the sale closes
    */
    function setSaleTimes(uint64 _openTime, uint64 _closeTime) external onlyDevOrOwner {
        saleOpens = _openTime;
        saleCloses = _closeTime;
    }

    
    /**
    * @notice set the maximum number of tokens that can be bought by a single wallet
    *
    * @param _quantity the amount that can be bought
    */
    function setMaxPerWallet(uint64 _quantity) external onlyDevOrOwner {
        MAX_TOKENS_PER_WALLET = _quantity;
    }

    /**
    * @notice sets the URI of where metadata will be hosted, gets appended with the token id
    *
    * @param _uri the amount URI address
    */
    function setBaseURI(string memory _uri) external onlyDevOrOwner {
        BASE_URI = _uri;
    }
    
    /**
    * @notice returns the URI that is used for the metadata
    */
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    /**
    * @notice withdraw the funds from the contract to a specificed address. 
    *
    * @param _wallet the wallet address to receive the funds
    */
    function withdrawBalance(address _wallet) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_wallet).transfer(balance);
        delete balance;
    }
    
    /**
     * @dev notice if called by any account other than the dev or owner.
     */
    modifier onlyDevOrOwner() {
        require(owner() == msg.sender || _dev[msg.sender], "Ownable: caller is not the owner or dev");
        _;
    }  

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Adds a new dev role user
     */
    function addDev(address _newDev) external onlyOwner {
        _dev[_newDev] = true;
    }

    /**
     * @notice Removes address from dev role
     */
    function removeDev(address _removeDev) external onlyOwner {
        delete _dev[_removeDev];
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }

    /**
    * @notice Initialize the contract and it's inherited contracts, data is then stored on the proxy for future use/changes
    */
    function initialize() public initializer { }


    /** 14th June 2022 Upgrade
    *   New prepareMintClose() function to drop supply available and set the close date while we are at it.
    *   Initialize function emptied to reduce deployment cost - it is not used when upgrading.
    *   No other changes to past code.
    */

    /**
    * @notice Update supply caps to close sale.
    */
    function prepareMintClose() external onlyDevOrOwner {
        PHASE_ONE_SUPPLY = 4720;
        saleCloses = 1656018000;
    }

}