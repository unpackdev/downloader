// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

/**

 __      __             __________         _____  _____.__           _________             
/  \    /  \ ____   ____\______   \_____ _/ ____\/ ____\  |   ____  /   _____/ ___________ 
\   \/\/   // __ \ /    \|       _/\__  \\   __\\   __\|  | _/ __ \ \_____  \_/ __ \_  __ \
 \        /\  ___/|   |  \    |   \ / __ \|  |   |  |  |  |_\  ___/ /        \  ___/|  | \/
  \__/\  /  \___  >___|  /____|_  /(____  /__|   |__|  |____/\___  >_______  /\___  >__|   
       \/       \/     \/       \/      \/                       \/        \/     \/       

*/


import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";


/// @title An ERC721A minting contract for WenRaffleSer NFTs
contract WRSContractV7 is ERC721A, Ownable, Pausable, ReentrancyGuard {

    using ECDSA for bytes32;
   
    uint public constant MAX_SUPPLY = 3993;
    uint public constant PRICE = 0.05 ether; 
    uint public constant MAX_PER_MINT = 5;
    uint public constant MAX_PER_WALLET = 10;
    uint public constant MAX_MINT_DURING_WHITELIST = 2023;
    uint public constant MAX_PER_WHITELISTED_WALLET = 3;
    uint public constant MAX_MINTS_BY_OWNER = 23;
    uint public WHITELIST_START_TIME = 1651593600;
    uint public WHITELIST_END_TIME = WHITELIST_START_TIME + 360 minutes;
    uint public currentWhitelistMints;
    uint public ownerCurrentMints; 
    address public multisigWallet = 0xBBF6DbdD752841478ABff02C685A8cb20c344221; 
    string public baseURI="https://gateway.pinata.cloud/ipfs/Qmb3ybcQxQEy5jomtLYirXVRHYmG57xvLJLszPqGK3sNRW";
    bool public isPublicMintStarted;   
    mapping(address=>uint) public addressToMints; 


    constructor() 
    ERC721A("WenRaffleSer", "WRS")
    {
        _pause();
    }


    /// @notice mints allowed only by the owner
    function ownerMint(uint256 _quantity) external whenNotPaused onlyOwner {
        require(ownerCurrentMints + _quantity <= MAX_MINTS_BY_OWNER,"Limit exceeding");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Not enough NFTs left to mint");
        ownerCurrentMints = ownerCurrentMints + _quantity;
        currentWhitelistMints=currentWhitelistMints+_quantity;
        _safeMint(msg.sender, _quantity);
    }

    /// @notice only owner can start the public mint
    function startPublicMint() external whenNotPaused onlyOwner{
        isPublicMintStarted=true;
    }
    

    /// @notice mints allowed only by the whitelisted addresses with signature
    function whitelistMint(uint256 _quantity, bytes memory _signature) external payable whenNotPaused nonReentrant {
        require(block.timestamp >= WHITELIST_START_TIME, "Whitelist sale has'nt yet started");
        require(addressToMints[msg.sender]+ _quantity<=MAX_PER_WHITELISTED_WALLET,"Max mints reached");
        require(block.timestamp <= WHITELIST_END_TIME, "Whitelist sale has ended");
        require(_quantity <= MAX_PER_MINT, "Can mint at max 5 in each batch");
        require(currentWhitelistMints+_quantity<=MAX_MINT_DURING_WHITELIST,"Whitelist minting quota exceeded");
        require(isMessageValid(owner(),_signature), "Invalid signature");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Not enough NFTs left to mint");
        require(PRICE * _quantity <= msg.value, "Insufficient funds sent");
        require(balanceOf(msg.sender) + _quantity <= MAX_PER_WHITELISTED_WALLET, "Max limit per wallet reached");
        addressToMints[msg.sender]=addressToMints[msg.sender]+_quantity;
        currentWhitelistMints=currentWhitelistMints+_quantity;
        _safeMint(msg.sender, _quantity);
        
    }


    /// @notice mint open to public
    function mint(uint256 _quantity) external payable whenNotPaused nonReentrant {
        require(isPublicMintStarted, "Public mint has'nt yet started");
        require(_quantity <= MAX_PER_MINT, "Can mint at max 5 in each batch");
        require(addressToMints[msg.sender]+ _quantity<=MAX_PER_WALLET,"Max mints reached");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Not enough NFTs left to mint");
        require(PRICE * _quantity <= msg.value, "Insufficient funds sent");
        require(balanceOf(msg.sender) + _quantity <= MAX_PER_WALLET, "Max limit per wallet reached");
        addressToMints[msg.sender]=addressToMints[msg.sender]+_quantity;
        _safeMint(msg.sender, _quantity);
    }


    /// @return array of tokens owned by the specified parameter address
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(_owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return ids;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }


    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token.");
        return _baseURI();
    }

    function setWhitelistStartTime(uint _time) external whenNotPaused onlyOwner{
        WHITELIST_START_TIME=_time;
        WHITELIST_END_TIME = WHITELIST_START_TIME + 360 minutes;
    }


    function tokenOfOwnerByIndex(address _owner, uint256 _index) internal view returns (uint256) {
        require(_index < balanceOf(_owner), 'ERC721A: owner index out of bounds');
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == _owner) {
                    if (tokenIdsIdx == _index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        revert('ERC721A: unable to get token of owner by index');
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function isMessageValid(address _owner,bytes memory _signature)
        internal
        view
        returns (bool)
    {
        bytes32 messagehash = keccak256(
            abi.encodePacked(address(this), msg.sender)
        );
        address signer = messagehash.toEthSignedMessageHash().recover(
            _signature
        );

        if (_owner == signer) {
            return true;
        } else {
            return false;
        }
    }
    
    /// @notice only owner can withdraw the money
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = multisigWallet.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }    
    
}