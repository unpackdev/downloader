// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721Receiver.sol";
import "./ERC721.sol";

import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";

/*

    █████▀███████████████████████████████████████████████████████████████
    █─▄▄▄▄██▀▄─██▄─▀█▀─▄█▄─▄▄─███▄─▄▄▀█▄─▄█─▄▄▄▄█▄─▄▄─██▀▄─██─▄▄▄▄█▄─▄▄─█
    █─██▄─██─▀─███─█▄█─███─▄█▀████─██─██─██▄▄▄▄─██─▄█▀██─▀─██▄▄▄▄─██─▄█▀█
    ▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▀▄▄▄▀▄▄▄▄▄▀▀▀▄▄▄▄▀▀▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀


                                       .:--==----:..                                      
                               .:===----==+====-------::.:::                              
                            .-+*##%###***+--===+---------:=+*-                            
                         -*%%%%%%%%%%%%%%%%#+*+========---==-==.....                      
                       :#%%%%%%%%%%%%%%%%%%%%%#+----=+=---==-:==***++=-.                  
                      -#%%%%%@@@@@@@@@@@@@@@@@%%%*--------==----*#@@@%+--:-:              
                      ###%%%%@@@@@@@@@@@@@@@@@@@@@%*=---=====--:++#@*==-:-==-             
                    .=###%%%@@@@@@@%%%%%%%%@@@@@@@@@@*=--=+===--+*-#--:::-===             
                   .==###%%%@@%%@@@%%#####%%@@@@@@@@@@@*==-=+=-=*#+#########=.            
                  -*#*-##%%%%%#%%@@%%#**+*%%#*+++*#%@@@@%*====++#%%@#++==+*##:            
                 --=--:-#%#%%%==++#%@%#==*%+=-++::--+%%@@@%+++=+%@@*==---:-=-=            
                 .=----=+#++=---:=+#@@#==%#=-=%@#*--:*%%%%**#++*%@%+===-.:=+::            
                =##%#*-+*#**+++==**#@#+-=@#+==*##+==-*#***#%@@**@###%%%%%%##:             
              .#@@@%@#=%@*#%%##%%%%%*+=-=*%%#*****+===+++=+*+#@%%#%@@@@@@@@@%.            
               %@@@@@@***+++++***#*++==::==*%%#**++++++==-=+==*%#.*@@@@@@@@@@=            
                *@@@@@#+--==*###*#%%%%%%##+=***#**##*++++-.---:*@..+%##**+==:             
                  :-==**++****++###%%%%##%#*=++++###****+- :--:#%+                        
                      =#++++##%%@@@@@@%+%%#**#++*+##***+=..--:.***                        
                      .#++*#*#%%%#**++###*+#@@%***##***=:.-=-..*+=                        
                       +++%%#%%%#%%%@%%%@@%#%@@#**##**=::-=-::==:                         
                       :**%#*@@@@@@@@@%%##%@@@%**###*=--=+=: :=-                          
                        =#%%*%@@@%#*##*++*%@@@%=+##*==-=+=-::-.                           
                         *%#%##@#+++%*++*%@@@%#:-**=====+=--=.                            
                          *%#%##*+++%+==*%@@@#+-=+========--.                             
                           -%#%#*++*#=+=+##%%#+=--===-==-=-:                              
                            .#%%**+**===**%%#*+--====--===-                               
                              **++++====**@#**=-====--====                                
                              -%=+=+-==*+#%#*+=========--:                                
                              +*+++==+**-%#*+=-==++===-=-                                 
                             .#+++++=+==#**+=--=+++===--                                  
                              +%@%#%*#+****=-=+++++=--=.                                  
                               :+=*##*-+**+-=+++++==--:                                   
                                  -+#****+==+++++=----                                    
                                  :%###*+++++*+++---=.                                    
                                  .:=%%###*****++----                                     
                                     #@@%#*****+=-=-.                                     
                                     :%@%#*****+----                                      
                                      =%%##****+----                                      
                                       +%##***+=--::                                      
                                        #%#**++----:             
*/

contract GameDiseaseStaking is
    IERC721Receiver,
    Initializable,
    PausableUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    ERC721 sickos;
    ERC721 ogA;
    ERC721 ogB;

    mapping(address => bool) signers;

    mapping(address => mapping(uint32 => bool)) public nonces;

    event Staked(
        address indexed by,
        uint256 indexed tokenId,
        uint32 timestamp,
        uint8 indexed collection
    );

    event Gone(
        address indexed by,
        uint256 indexed tokenId,
        uint32 timestamp,
        uint32 nonce,
        uint8 indexed collection
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function initialize(
        address _sickos,
        address _ogA,
        address _ogB
    ) public initializer {
        __Pausable_init();
        __UUPSUpgradeable_init();
        __Ownable_init();

        sickos = ERC721(_sickos);
        ogA = ERC721(_ogA);
        ogB = ERC721(_ogB);
    }

    function setSigner(address signer, bool status) public onlyOwner {
        signers[signer] = status;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function stakeTokens(uint256[] memory tokenIds, uint8 collection) public {
        require(collection >= 0 && collection <= 2, "invalid collection");
        for (uint16 i = 0; i < tokenIds.length; i++) {
            emit Staked(
                msg.sender,
                tokenIds[i],
                uint32(block.timestamp),
                collection + 1
            );
            [sickos, ogA, ogB][collection].safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
        }
    }

    function expend(
        uint32 nonce,
        bytes memory signature,
        uint256[] memory tokenIds,
        uint32 date,
        uint8 collection
    ) public {
        require(collection >= 0 && collection <= 2, "invalid collection");
        require(block.timestamp < date, "expired");
        require(!nonces[msg.sender][nonce], "already seen");
        nonces[msg.sender][nonce] = true;
        require(
            signers[
                getMessageSigner(nonce, signature, tokenIds, date, collection)
            ],
            "not a signer"
        );
        for (uint16 i = 0; i < tokenIds.length; i++) {
            emit Gone(
                msg.sender,
                tokenIds[i],
                uint32(block.timestamp),
                nonce,
                collection + 1
            );
            [sickos, ogA, ogB][collection].safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );
        }
    }

    function getMessageSigner(
        uint32 nonce,
        bytes memory signature,
        uint256[] memory tokenIds,
        uint32 date,
        uint8 collection
    ) private view returns (address) {
        require(signature.length == 65);
        uint8 v;
        bytes32 r;
        bytes32 s;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        bytes32 signedHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        date,
                        nonce,
                        msg.sender,
                        tokenIds,
                        collection
                    )
                )
            )
        );
        return ecrecover(signedHash, v, r, s);
    }

    function onERC721Received(
        address operator,
        address, /*from*/
        uint256, /*tokenId*/
        bytes calldata /*data*/
    ) public virtual override returns (bytes4) {
        require(operator == address(this), "This is not okay");
        return this.onERC721Received.selector;
    }
}
