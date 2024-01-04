// Casino Bank manager proxy for https://ytho.online
// @author: Carlos Mayorga http://github.com/cmayorga
// @notice: Audited by https://buclelabs.com/

//                    .*((/,                                                                                                                                 
//              ..,,**/(########(/,.                       .,,*,,.        .,,**,,.   ...     .,**,,..        .*(##((*,    ..,**********,,..                  
//         .,*((###########((####(/**/((*.               .*/####((*.    ..,/(#####(((###((*..*(####(*.      .*(####(*,  .,/(#############((*..               
//      .,/(#####((//(((*, .*(((/*,*(###((*..          .*/(######((((#####################(//(####((,      .,/(####/,..,/(#####((*,...*(###((*.              
//      .,(#####((*.*/(/,.         ,*(####(/,.        ,/(#####(((################((/**,,..,*(####(/,.      .*(####(*.,*(######(/..    ,/(####/,.             
//       .,*/((######((/.           .,*/(###(*.     .*/#####(/,..,,,.. .,/####(/,.        ,*(####/*.       ,/(####/*,/#######(*,      ,/(####(*.        
//           ..,*/(####(/,.            .,((##(/,  ..*(#####/*.         ,*(####(*.        .*(####(*.       .*(####(**/(####(*,..      .,((####(/,         
//                ,/(####((*..          .,/(###/*,,/(####(/,           ,((####/,.       .,/####(/,.    ...,/####((**(####(/..        .*(#####(*.         
//                ,/(#((####/,. ..........,*(###(((#####(*.          ..*(####(*.  .,*///((######((/(((((((((####(/*/(###(/*         .,*######/*.         
//      .......  .*((/,*(####(*.............*/(#######((,.           .,/####(/,. ..*((###############(((((######/,/(####(*,         .*/######/,.         
//     *(####(*,.,/#/*..*(####(*........    .,/(#####(/,.            .*(####(*.    ..,,*/#####(/*,,,,....*(####(*,*(####(*,        .,/(####((*.          
//     (#####/,..*(#*,..,/####(/,.          .,((####(*,             .,((####/,.       .,/####((,       ..*####((*.,/(###(*,       .,*(#####(*,           
//      ####(/, .,/((*...,/####((,.        ..*(####(/*             ..*(####(/..       .*/####(*,       .,/####(/, .*(###(/,      ../(#####(*..          
//     /(##(*, .,((/, .,/(####(/,         ,/(####(/,               .,/(####(*.        ./(####/,.       .*(####(*.  ./(###(/..  ..*((#####(*.             
//     .*((((*,*/((***/(#####(*..       .*/#####(*.. ......        .*/#####(/,.      .,/(###(/..      ,*(#####/,.  ..*/(##((////((#####(/,.              
//       .,/(#############(/*....    .,/(######/*.    .....       ../(######/,.      .,((###(/..      .,((###(/..     .,/(##########((*..                    
//          .,*(#(/*****,,...........*/(#####(/,.   ........      ..*/(###(/,        .,/(###(*..        ..,***,..       ..,,*******,..                       
//           .*(##/,.    ......    ../(#####(/..      ....                                ....                                                               
//           .*((/,.   ..........  .,*((###(*..      ....... 

pragma solidity ^0.5.17;
interface IERC20 {
    function mint(address account, uint amount) external;
}

pragma solidity ^0.5.17;

contract YTHOCasinoBank {
    address owner;
    
    IERC20 public BRADS = IERC20(0x37632d10812637f96405FFD78d9512791747282c);

    mapping(uint256 => bool) usedNonces;

    constructor() public{
        owner = msg.sender;
    }       

    function withdraw(uint256 amount, uint256 nonce, bytes memory sig) public {
        require(!usedNonces[nonce], "This transaction was made yet");
        usedNonces[nonce] = true;
        bytes32 message = keccak256(abi.encode(msg.sender, amount, nonce, this));
        require(recoverSigner(message, sig) == owner, "Wrong signature owner");
        
        BRADS.mint(msg.sender, amount);
    } 

    // Destroy contract and reclaim leftover funds.
    function kill() public {
        require(msg.sender == owner, "Sender is not the owner");
        selfdestruct(msg.sender);
    }

    function recoverSigner(bytes32 hash, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65, "Require correct length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }        
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "Signature version not match");
        return recoverSigner2(hash, v, r, s);
    }    
    
    function recoverSigner2(bytes32 h, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, h));
        address addr = ecrecover(prefixedHash, v, r, s);
        return addr;
    }    
}