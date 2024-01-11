// SPDX-License-Identifier: MIT

/*
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - ++ - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
                            @@##%@@                                                                                 
                             @%&(((((@@#(((((&@                                                                         
                     #@@@           @(#**@*@*@/#@                                                                       
                   @@              /#/*@**@****(@&@@                                                                    
                  @@  @.            @(@**@/@*@/#@    &@                                                                 
                   @ .  @@.          @@#(///(#@         @@                                                              
                   @@....   @@,                           @                                                             
                    @@.....      @@@@                      @                                                            
                      @......    @ @,                       @@                                                          
                        @... . .                             @@                                                         
                          @@.....                             &@                                                        
                            @@.......                          (@                                                       
                               @@.......                         @.                                                     
                                 @@.......                         @                                                    
                                     @@....                          @.                                                 
                                        @@... .                        @@                                               
                                          @@.... .                        @@                                            
                                            @.......                          @@                                        
                                             @.........                           @@                                    
                                             @@..........                             @@                                
                                             @@.............             @@@@            @@                             
                                             @.................                (@@          @#                          
                                            @@.................                    @@         @@                        
                                           @@................... @,                  &@         @@                      
                                          @*.....*@................@..                 @@         @@                    
                                         @........@..................@@                  @          @.                  
                                        @..........@.....................@@.              @          /@                 
                                      &@..........@@@@.......................  @@@@       @,           @                
                                     @@.........@@    @@...................... .  @       %@            @               
                                    .@.........@.       *@...................... .@       @@             @              
                                    @@........@            ,@@.....................@.     @               @(            
@@@@@@@@@  @@@@@@@@@@@  @%      .@        @@         @@   @@@@@@@@@&     @@@      @@@@@@@@@@    @@@@@@@@      #@@@@@@@  
@.              @       @%      .@        @@         @@         @@      @@ @@     @@       @@   @@      @@   @@      @@ 
@@@@@@@@@       @       @@@@@@@@@@        @@         @@       @@       @@   @@    @@    .@@@    @@       @@   @@@@@@    
@.              @       @%      .@        @@         @@     @@        @@@@@@@@@   @@    @@@     @@       @@          @@ 
@.              @       @%      .@        @@         @@   @@         @@       @@  @@      @@    @@      @@   @@      %@ 
@@@@@@@@@@      @       @%      .@        @@@@@@@@@  @@  @@@@@@@@@@@@@         @@ @@        @@  @@@@@#          @@@@(   
                                                                                                                        
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - ++ - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
Contract: Genesis Migration Bridge
Web: ethlizards.io
Underground Lizard Lounge Discord: https://discord.com/invite/ethlizards
Developer: Sp1cySauce - Discord: SpicySauce#1615 - Twitter: @SaucyCrypto
*/

pragma solidity ^0.8.9;

import "./OGLizardsI.sol";
import "./IERC1155.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC1155Holder.sol";
import "./MerkleProof.sol";

contract OGLizardBridge is ERC1155Holder, Ownable, ReentrancyGuard {

    bool public bridgeEnabled = false;
  
    uint256[] public idsReceived;
    uint256[] public idsMigrated;  

    mapping(uint256 => address) public OSTokenOwner;
    mapping(address => uint256[]) public OSIDByAddress;
    mapping(address => uint256[]) public OSIDMigratedByAddress;
           
    bytes32 public merkleRoot;

    IERC1155 public openSeaSF;
    OGLizardsI public OGLizardContract;
    address public BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);

    event ReceivedFromOS(address indexed _sender, address indexed _receiver, uint256 indexed _tokenId, uint256 _amount);
    event Migrated (address indexed _sender, uint256 indexed _tokenId);
     
    constructor(address _openseaStoreFront)  {
        openSeaSF = IERC1155(_openseaStoreFront);
    }

    /**
     * @dev Is triggered when Ethlizard received from opensea contract
     */

    function onERC1155Received(
        address _sender,
        address _receiver,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) public override nonReentrant returns (bytes4) {
        require(msg.sender == address(openSeaSF), "Genesis Ethlizards must be from OpenSea");
        require(bridgeEnabled, "Genesis Bridge is Not Currently Enabled");

        triggerReceived1155(_sender, _tokenId);
        emit ReceivedFromOS(_sender, _receiver, _tokenId, _amount);

        return super.onERC1155Received(_sender, _receiver, _tokenId, _amount, _data);
    }

    /**
     * @dev Migrate function. Can only migrate if a valid ERC1155 has been received from opensea.
     */

    function migrate(uint256 _oldId, uint256 _newId, bytes32 _leaf, bytes32[] calldata _merkleProof) external nonReentrant { 
        require(bridgeEnabled, "Bridging is stopped");
        bytes32 node = keccak256(abi.encodePacked(_oldId, _newId));      
        require(node == _leaf, "Leaf does not match");
        require(MerkleProof.verify(_merkleProof, merkleRoot, _leaf), "Invalid proof provided.");
        require(OSTokenOwner[_oldId] == msg.sender, "Not owner of OS id");
        
        idsMigrated.push(_newId);
        OSIDMigratedByAddress[msg.sender].push(_oldId);

        openSeaSF.safeTransferFrom(address(this), BURN_ADDRESS, _oldId, 1, "");        
        mint(_newId);

        emit Migrated(msg.sender,_newId);      
    }

    /***********Internal Functions**************/

      /**
     * @dev Sets the required mappings once received from Opensea to allow migration.
     */
    function triggerReceived1155(address _sender, uint256 _tokenId) internal {
        require(_sender != address(0), "Update from address 0");        
        idsReceived.push(_tokenId);
        OSTokenOwner[_tokenId] = _sender;
        OSIDByAddress[_sender].push(_tokenId);
    }

   /**
     * @dev Mints on the the OGLizard Contract, required Roles must be set.
     */
    function mint(uint256 _tokenId) internal {
        OGLizardContract.mint(msg.sender, _tokenId);  
    }

    /***********Setters**************/

    function toggleBridge() external onlyOwner {
        bridgeEnabled = !bridgeEnabled;
    }

    function setOpenSeaSF(address _contract) external onlyOwner {
        require(_contract != address(0), "_contract !address 0");
        openSeaSF = IERC1155(_contract);
    }

    function setOGLizardContract(address _contract) external onlyOwner {
        require(_contract != address(0), "_contract !address 0");
        OGLizardContract = OGLizardsI(_contract);
    }

    function setBurnAddress(address _burnAddress) external onlyOwner {
        BURN_ADDRESS = _burnAddress;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /***********Views**************/

    /**
     * @dev check a OS token balance
     */
    function checkOSBalance(address _collector, uint256 _tokenId) external view returns (uint256) {
        require(_collector != address(0), "_collector is address 0");
        return openSeaSF.balanceOf(_collector, _tokenId);
    }

    /**
     * @dev get the ids already transferred by a collector
     */
    function getTransferredIds(address _collector) external view returns (uint256[] memory) {
        require(_collector != address(0), "_collector is address 0");
        return OSIDByAddress[_collector];
    }

    /**
     * @dev get the ids that have already been Migrated
     */
    function getMigratedIds(address _collector) external view returns (uint256[] memory) {
        require(_collector != address(0), "_collector is address 0");
        return OSIDMigratedByAddress[_collector];
    }

    function getMigratedCount() external view returns (uint256) {
        uint256 totalMigrated = idsMigrated.length; 
        return totalMigrated;
    }

    function getMigratedTokens() external view returns (uint256[] memory) {
        return idsMigrated;
    }

    function getIdsReceived() external view returns (uint256[] memory) {
        return idsReceived;
    }

    function getOGLizardContract() external view returns (address) {
        return address(OGLizardContract);
    }

    function getOpenSeaSF() external view returns (address) {
        return address(openSeaSF);
    }

    function walletOfOwner(address _owner) public view virtual returns (uint256[] memory){
          return OGLizardContract.walletOfOwner(_owner); 
    }

    function totalSupply () external view returns (uint256) {
        return OGLizardContract.totalSupply();
    }

    /***********Adminstrative**************/

    /**
     * @dev Administrative ERC1155 Functions
     */
    function transfer1155(uint256 _tokenId, address _owner) external onlyOwner {
        require(_owner != address(0), "Can not send to address 0");
        openSeaSF.safeTransferFrom(address(this), _owner, _tokenId, 1, "");
    }

    function batchTransfer1155(address _owner, uint256[] memory _tokenIds) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            openSeaSF.safeTransferFrom(address(this), _owner, _tokenIds[i], 1, "");
        }
    }

    function burn1155(uint256 _oldId) external onlyOwner {
        openSeaSF.safeTransferFrom(address(this), BURN_ADDRESS, _oldId, 1, "");
    }

    function batchBurn1155(uint256[] memory _tokenIds) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            openSeaSF.safeTransferFrom(address(this), BURN_ADDRESS, _tokenIds[i], 1, "");
        }
    }

    function reassign1155(address _sender, uint256 _tokenId) external onlyOwner {        
        OSTokenOwner[_tokenId] = _sender;
        OSIDByAddress[_sender].push(_tokenId);
    }


    /**
     * @dev Administrative ERC721 Functions
     */
    function onlyOwnerMint(uint256 _tokenId, address _to) external onlyOwner {
        require(_to != address(0), "Mint to address 0");
        require(!OGLizardContract.exists(_tokenId), "Token exists");
        OGLizardContract.mint(_to, _tokenId);   
    }

    function onlyOwnerTransfer(uint256 _tokenId, address _owner) external onlyOwner {
        require(OGLizardContract.exists(_tokenId), "Token does not exist");
        require(_owner != address(0), "Can not send to address 0");
        OGLizardContract.safeTransferFrom(address(this), _owner, _tokenId);
    }
    
}