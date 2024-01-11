// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./Initializable.sol";



                                 /*,,,,,,,,,,,,,,,,,,,,                  
                               * *                    * *               
                            *    *                    *    *            
                          /      /                    \      \          
                         /       /                    \       \         
                        (        (                    )        )        
                        (        (                    )        )        
                        #        #                    #        #        
                        #       ########################       #        
                        #   ##          ##     ##         ##   #            
                        ##                #   #               ##        
                    # #   #####CRYPTO######   ######AVATARS#####  # #   
                    #   #  #              #   #            #    #   #   
                     #   #   #           #     #          #    #   #    
                      #  #     #        #       #        #     #  #     
                       # #       #      #########      #       # #      
                         #        #                   #        #        
                          #       #      ########     #       #         
                           #      #    ############   #      #          
                             ##   #      ########     #   ##            
                                # #                   # #               
                                   #                 #                     
                                    * ..............*                   
                                                              
            _____                  _         ___             _                 
           /  __ \                | |       / _ \           | |                
           | /  \/_ __ _   _ _ __ | |_ ___ / /_\ \_   ____ _| |_ __ _ _ __ ___ 
           | |   | '__| | | | '_ \| __/ _ \|  _  \ \ / / _` | __/ _` | '__/ __|
           | \__/\ |  | |_| | |_) | || (_) | | | |\ V / (_| | || (_| | |  \__ \
            \____/_|   \__, | .__/ \__\___/\_| |_/ \_/ \__,_|\__\__,_|_|  |___/
                        __/ | |                                                
                       |___/|*/                 




contract CryptoAvatars is Initializable, ERC721Upgradeable, 
                        ERC721EnumerableUpgradeable,ERC721URIStorageUpgradeable, 
                        PausableUpgradeable, AccessControlUpgradeable, 
                        ERC721BurnableUpgradeable {
                            
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address private signer; 
    uint private counter; 
    mapping(bytes   => bool) signatures; 
    mapping(uint256 => bool) canSetUri;
    mapping(uint256 => uint256) counterBridge; 
    mapping(uint256 => address) creator;

    event MintBridgeEvent(address owner, string uri, uint tokenId); 
    event MintAvatarEvent(address owner, string uri, uint tokenId);
    event BurnBridgeEvent(address owner, uint tokenId); 
    event TransferAvatarEvent(address from, address to, uint tokenId);
    
    function initialize() initializer public {
        __ERC721_init("CryptoAvatars", "CANFT");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        counter = 101; 
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/";
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to, string memory uri) 
        public 
        onlyRole(MINTER_ROLE) 
    {
        uint256 tokenId = counter;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        canSetUri[tokenId] = true;
        creator[tokenId]=_msgSender();
        counter+=100;
        emit MintAvatarEvent(to, uri, tokenId);

    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, 
                ERC721EnumerableUpgradeable, 
                AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setSigner(address updateSigner) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        signer = updateSigner;
    }

    function setNewURI(uint tokenId,string memory _hash) 
        public 
        onlyRole(MINTER_ROLE) 
    {
        require(canSetUri[tokenId] == true, 
                "You have already transfered your token");
        require(creator[tokenId] == _msgSender(),"Caller is not the creator");
        _setTokenURI(tokenId, _hash);
    }

    function mintBridge(address owner , string memory uri , 
                        uint256 tokenId , bytes memory signature , 
                        uint chainId, uint _counterBridge) 
        public
    {
        require(signatures[signature] == false,
                "Token already bridged");
        require(chainId == block.chainid, 
                "Wrong chainId");
        require(owner == _msgSender(), 
                "You are not the owner");
        require(counterBridge[tokenId]<_counterBridge, 
                "Wrong avatar's 'nonce'");
        require(verify(owner, uri, 
                        tokenId, chainId, 
                        _counterBridge, signature),
                "Wrong signature");
        _safeMint(owner, tokenId); 
        _setTokenURI(tokenId , uri); 
        canSetUri[tokenId] = false; 
        signatures[signature] = true;
        counterBridge[tokenId] = _counterBridge;
        emit MintBridgeEvent(owner, uri, tokenId);
    }

    function burnBridge(uint tokenId)
        public 
    {
        super._burn(tokenId);
        emit BurnBridgeEvent(_msgSender(),tokenId);
    }

    function getMessageHash(
        address to , 
        string memory uri ,
        uint256 tokenId, 
        uint256 chainId, 
        uint256 _counterBridge) 
        public 
        pure 
        returns (bytes32) 
    {
        return keccak256(abi.encodePacked(to ,uri ,
                                            tokenId ,chainId 
                                            ,_counterBridge));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", 
                                    _messageHash)
            );
    }

    function verify(
        address owner , 
        string memory uri ,
        uint256 tokenId,
        uint256 chainId, 
        uint256 _counterBridge,
        bytes memory signature) 
        public 
        view 
        returns (bool) 
    {
        bytes32 messageHash = getMessageHash(owner, uri, 
                                                tokenId, chainId, 
                                                _counterBridge);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, 
                            bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data) 
        public 
        virtual 
        override {
        
        require(_isApprovedOrOwner(_msgSender(), tokenId), 
                "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);

        if(canSetUri[tokenId] == true){
            canSetUri[tokenId] = false;    
        }
        emit TransferAvatarEvent(from , to , tokenId);
        
    }

     function transferFrom(
        address from,
        address to,
        uint256 tokenId) 
        public 
        virtual 
        override {

        require(_isApprovedOrOwner(_msgSender(), tokenId), 
                "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);

        if(canSetUri[tokenId] == true){
            canSetUri[tokenId] = false;    
        }
        emit TransferAvatarEvent(from , to , tokenId);

    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, 
                "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function version() public virtual pure returns (string memory) {
        return "1.0.0";
    }
}

