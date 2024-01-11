// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";

contract SnackShopFounders is Initializable, ERC1155Upgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    
    //constant variables, mappings, and structs can be declared as usual
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    uint256 public constant founders_salePrice = 0.35 ether;
    mapping(uint => uint) public maxTokenSupply;
    mapping(uint => uint) public mintedSupply;
    mapping(address => mapping(uint => bool)) public whitelistClaimedPerSale;

    //normal state variables can be declared but must be given a value through the initializer function or left at default value
    uint256[] public availableTokens;
    uint256 public saleNumber;
    bytes32 public merkleRoot;
    bool public publicSaleStatus;
    bool public preSaleStatus;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC1155_init("ADD_URI_HERE_BEFORE_LAUNCH");
        __AccessControl_init();
        __UUPSUpgradeable_init();

        //assigning roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);

        //initial team mint
        _mint(msg.sender, 0, 5, "");
        _mint(msg.sender, 1, 5, "");
        _mint(msg.sender, 2, 5, "");
        _mint(msg.sender, 3, 5, "");
        _mint(msg.sender, 4, 5, "");

        //setting state variables
        merkleRoot = 0xeee32e4428b3ad7e13fd6700ee77f5c8fe2ff18a04dc776da1bac8e291d5c8e7;
        availableTokens = [0, 1, 2, 3, 4];
        maxTokenSupply[0] = 105;
        maxTokenSupply[1] = 105;
        maxTokenSupply[2] = 105;
        maxTokenSupply[3] = 105;
        maxTokenSupply[4] = 105;
        mintedSupply[0] = 5;
        mintedSupply[1] = 5;
        mintedSupply[2] = 5;
        mintedSupply[3] = 5;
        mintedSupply[4] = 5;
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    //UUPS upgrade function: must be in all future upgrades or contract will loose upgradability
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(DEFAULT_ADMIN_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //withdraw all Ether from contract
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success);
    }
    
    //change Merkle Root when changing to a new tree
    function setMerkleRoot(bytes32 newRoot) external onlyRole(URI_SETTER_ROLE) {
        merkleRoot = newRoot;
    }

    //Change sale number to reset whitelistClaimed mapping for next sale
    function incrementSaleNumberToResetWL() external onlyRole(URI_SETTER_ROLE) {
        saleNumber ++;
    }
    
    //turn public sale on/off
    function setSaleStatus(bool status) external onlyRole(URI_SETTER_ROLE) {
        publicSaleStatus = status;
    }

    //turn pre-sale on/off
    function setPreSaleStatus(bool status) external onlyRole(URI_SETTER_ROLE) {
        preSaleStatus = status;
    }

    //team mint
    function teamMint(uint256 id, uint256 amount) public onlyRole(URI_SETTER_ROLE) {
        require(maxTokenSupply[id] > 0);
        require(mintedSupply[id] + amount < maxTokenSupply[id]);
        mintedSupply[id] += amount;    
        _mint(msg.sender, id, amount, "");
    }

    //public sale
    function foundersMint() public payable { 
        require(publicSaleStatus == true, "!pub");
        uint tokenId = getRandomId ();
        _mint(msg.sender, tokenId, 1, "");
    }

    //presale
    function preSaleFoundersMint(bytes32[] calldata proof) public payable { 
        require(preSaleStatus == true, "!pre");
        require(!whitelistClaimedPerSale[msg.sender][saleNumber], "Claimed");
        require(isValid(proof) == true, "!WL");
        uint tokenId = getRandomId ();
        whitelistClaimedPerSale[msg.sender][saleNumber] = true;
        _mint(msg.sender, tokenId, 1, "");
    }

    //valadating merkle proof to check WL status
    function isValid(bytes32[] calldata proof) internal view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProofUpgradeable.verify(proof, merkleRoot, leaf);
    }

    //generating sudo-random number and choosing 1 of the remaining token IDs from availableTokens[] to pass back to foundersMint
    function getRandomId () internal returns (uint tokenId) {
        require (availableTokens.length > 0, "SO");
        require (msg.value >= founders_salePrice, "Insuff");
        require (tx.origin == msg.sender, 'NoSC');
        uint256 randomNumber = uint256 (keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty, block.number-1)));
        uint tokenIndex = (randomNumber % availableTokens.length);
        tokenId = availableTokens[tokenIndex];
        //checking supply and editing array of availableTokens 
        if(mintedSupply[tokenId] + 1 >= maxTokenSupply[tokenId]){
            availableTokens[tokenIndex] = availableTokens[availableTokens.length-1];
            availableTokens.pop();
        }
        mintedSupply[tokenId] ++;
        return tokenId;
    }

    //add token IDs to availableTokens[] array and setting maxTokenSupply so they can be made available for sale 
        //NOTE: Token IDs can be added to the array more than once but their maxTokenSupply will only be set if they do not have one yet
    function setTokensAvailableForSale(uint[] memory tokenIds, uint[] memory maxSupply) public onlyRole(URI_SETTER_ROLE) {
        require (tokenIds.length == maxSupply.length);
        for (uint i=0; i < tokenIds.length; i++) {
            uint token = tokenIds[i];
            if (maxTokenSupply[token] == mintedSupply[token]) {
                require (maxTokenSupply[token] == 0);
                maxTokenSupply[token] = maxSupply[i];
            }
            availableTokens.push(token);
        }
    }

    //remove token ID from sale by INDEX where the token ID resides in availableTokens array
        // NOTE: MUST use index of token ID in availableTokens[] array NOT token ID
    function removeTokenFromSaleByIndex(uint indexOfTokenIdToRemove) public onlyRole(URI_SETTER_ROLE) {
        availableTokens[indexOfTokenIdToRemove] = availableTokens[availableTokens.length-1];
        availableTokens.pop();
    }

}