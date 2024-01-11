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
Contract: Genesis Ethlizards ERC721 Contract
Web: ethlizards.io
Underground Lizard Lounge Discord: https://discord.com/invite/ethlizards
Developer: Sp1cySauce - Discord: SpicySauce#1615 - Twitter: @SaucyCrypto
*/


pragma solidity ^0.8.9;

import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";


contract OGEthLizards is ERC721Enumerable, AccessControlEnumerable, Ownable {

    using Strings for uint256;           
      
    string public baseURI;
    string public baseExtension = ".json";

    address public proxyRegistryAddress;
    address private constant BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);

    mapping(address => bool) public projectProxy;
 
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public maxLizardSupply = 101; // Max Supply is 100

  
    constructor(string memory _BaseURI, address _proxyRegistryAddress) 
        ERC721("OGEthlizards", "OGLIZARD") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        setBaseURI(_BaseURI);        
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /***********Setters**************/
    function setBaseURI(string memory _newBaseURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Missing DEFAULT_ADMIN_ROLE");
        baseURI = _newBaseURI;
    }
    
    function setBaseExtension(string memory _newBaseExtension) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Missing DEFAULT_ADMIN_ROLE");
        baseExtension = _newBaseExtension;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Missing DEFAULT_ADMIN_ROLE");
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Missing DEFAULT_ADMIN_ROLE");
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function setMaxLizards(uint256 _maxLizardAmount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Missing DEFAULT_ADMIN_ROLE");
        maxLizardSupply = _maxLizardAmount;
    }

    /***********Minting**************/
    function mint(address _owner, uint256 _tokenId) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "Missing MINTER_ROLE");
        require(_tokenId > 0 && _tokenId < maxLizardSupply, "Token out of boundS");
        require(totalSupply() < maxLizardSupply, "Max supply reached");
        _mint(_owner, _tokenId);
    }

    /***********Views**************/
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
        {
            require(_exists(tokenId), "Token does not exist");      
            string memory currentBaseURI = _baseURI();
            return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
            }
        return tokenIds;
    }

    function _baseURI() internal view virtual override returns (string memory)  {
        return baseURI;
    }

    /***********Public Functions**************/
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isApprovedForAll(address _owner, address operator) public view override(IERC721,ERC721) returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    /***********Solidity Required Overrides**************/
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControlEnumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}