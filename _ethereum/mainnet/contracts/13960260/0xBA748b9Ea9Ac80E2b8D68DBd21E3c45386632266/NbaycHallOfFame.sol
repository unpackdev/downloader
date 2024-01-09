// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
 _        ______   _______  _______  _______  _______           _______ 
( (    /|(  ___ \ (  ___  )(  ____ )(  ____ \(  ____ \|\     /|(  ____ \
|  \  ( || (   ) )| (   ) || (    )|| (    \/| (    \/( \   / )| (    \/
|   \ | || (__/ / | (___) || (____)|| (__    | (_____  \ (_) / | |      
| (\ \) ||  __ (  |  ___  ||  _____)|  __)   (_____  )  \   /  | |      
| | \   || (  \ \ | (   ) || (      | (            ) |   ) (   | |      
| )  \  || )___) )| )   ( || )      | (____/\/\____) |   | |   | (____/\
|/    )_)|/ \___/ |/     \||/       (_______/\_______)   \_/   (_______/

          _______  _        _          _______  _______    _______  _______  _______  _______ 
|\     /|(  ___  )( \      ( \        (  ___  )(  ____ \  (  ____ \(  ___  )(       )(  ____ \
| )   ( || (   ) || (      | (        | (   ) || (    \/  | (    \/| (   ) || () () || (    \/
| (___) || (___) || |      | |        | |   | || (__      | (__    | (___) || || || || (__    
|  ___  ||  ___  || |      | |        | |   | ||  __)     |  __)   |  ___  || |(_)| ||  __)   
| (   ) || (   ) || |      | |        | |   | || (        | (      | (   ) || |   | || (      
| )   ( || )   ( || (____/\| (____/\  | (___) || )        | )      | )   ( || )   ( || (____/\
|/     \||/     \|(_______/(_______/  (_______)|/         |/       |/     \||/     \|(_______/
 */
import "./ERC721.sol";
import "./Ownable.sol";

contract nbaychalloffame is ERC721, Ownable {

    bool public isActive = true;
    uint256 private totalSupply_ = 0;

    address payable public immutable shareholderAddress;

    struct Player {
        bytes32 name;
        string imageCID;
    }
    
    mapping(uint256 => Player) private idToPlayer;
    
    constructor(address payable shareholderAddress_) ERC721("nbaychalloffame", "NBAYC Hall of Fame") {
        require(shareholderAddress_ != address(0));
        shareholderAddress = shareholderAddress_;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function setSaleState(bool newState) public onlyOwner {
        isActive = newState;
    }

    function mint(address receiver, string memory name, string memory imageCID) public onlyOwner {
        require(isActive, "Sale must be active to mint nbaychalloffame tokens");        
        uint256 mintIndex = totalSupply_ + 1;
        totalSupply_ = totalSupply_ + 1;
        bytes32 bName;
        assembly {
        bName := mload(add(name, 32))
        }
        idToPlayer[mintIndex] = Player(bName, imageCID);
        _safeMint(receiver, mintIndex);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokenId > 0 && tokenId <= totalSupply_, "This token does not exists");
        Player memory p = idToPlayer[tokenId];
        string memory metadata = string(abi.encodePacked(
            '{"name":"',
            string(abi.encodePacked(p.name)),
            '","description":"Hall Of Fame","image": "ipfs://',
            p.imageCID,
            '","attributes":[{"trait_type":"Player name","value":"', 
            string(abi.encodePacked(p.name)),
            '}]}'
        ));
        return string(abi.encodePacked("data:application/json;base64,",base64(bytes(metadata))));
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(shareholderAddress, balance);
    }

    // BASE 64 - Written by Brech Devos
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
        // set the actual output length
        mstore(result, encodedLen)
        
        // prepare the lookup table
        let tablePtr := add(table, 1)
        
        // input ptr
        let dataPtr := data
        let endPtr := add(dataPtr, mload(data))
        
        // result ptr, jump over length
        let resultPtr := add(result, 32)
        
        // run over the input, 3 bytes at a time
        for {} lt(dataPtr, endPtr) {}
        {
            dataPtr := add(dataPtr, 3)
            
            // read 3 bytes
            let input := mload(dataPtr)
            
            // write 4 characters
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
            resultPtr := add(resultPtr, 1)
        }
        
        // padding with '='
        switch mod(mload(data), 3)
        case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
        case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}
