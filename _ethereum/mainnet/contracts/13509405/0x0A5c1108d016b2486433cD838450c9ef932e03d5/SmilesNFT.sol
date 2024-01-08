//
//    ░█████╗░░██████╗░█████╗░██╗██╗    ░██████╗███╗░░░███╗██╗██╗░░░░░███████╗░██████╗
//    ██╔══██╗██╔════╝██╔══██╗██║██║    ██╔════╝████╗░████║██║██║░░░░░██╔════╝██╔════╝
//    ███████║╚█████╗░██║░░╚═╝██║██║    ╚█████╗░██╔████╔██║██║██║░░░░░█████╗░░╚█████╗░
//    ██╔══██║░╚═══██╗██║░░██╗██║██║    ░╚═══██╗██║╚██╔╝██║██║██║░░░░░██╔══╝░░░╚═══██╗
//    ██║░░██║██████╔╝╚█████╔╝██║██║    ██████╔╝██║░╚═╝░██║██║███████╗███████╗██████╔╝
//    ╚═╝░░╚═╝╚═════╝░░╚════╝░╚═╝╚═╝    ╚═════╝░╚═╝░░░░░╚═╝╚═╝╚══════╝╚══════╝╚═════╝░
//
// Website: https://smiles.cards
//
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC20.sol";
import "./Ownable.sol";
import "./enumerable_simple.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Smiles is ERC721EnumerableSimple, Ownable {

    using Strings for uint256;
    using Address for address;
    
    struct iInfo {
        bytes4 item;
        uint8 rarity;
        bytes16 desc;
    }

    uint64 public MintPrice = 0.07 ether;
    uint16 public maxSupply = 10000;
    uint16 public giveaway_reserved = 200;
    uint16 public pre_mint_reserved = 1000;
    uint128 public REVEALED; // uint128
    bool public mint_active = false;
    bool public pre_mint_paused = true;
    address public constant CommunityFund = 0xBfDA4Ee93f99612f282F8bC4C234331406dbD4a0;
    bytes32 public merkleRoot;
    ASCIISmilesToken public ASCToken;
    address proxyRegistryAddress;
   
    iInfo[] private Hat;
    iInfo[] private Eye;
    iInfo[] private Nose;
    iInfo[] private Mouth;
    iInfo[] private Beard;
    iInfo private Empty = iInfo(0,0,0);

    mapping(uint256 => bytes32) private _nickname;

    event MintStopped();
    event MintStarted();
    event PreMintPaused();
    event PreMintStarted();
    event Revealed();
    event MerkleRootUpdated(bytes32 new_merkle_root);

    constructor(address _proxyRegistryAddress) ERC721("ASCII Smiles", "SML") {
        proxyRegistryAddress = _proxyRegistryAddress;
        
        Hat.push(iInfo('('   ,  9, 'Egghead'      ));
        Hat.push(iInfo('d'   , 19, 'Baseball'     ));
        Hat.push(iInfo('~'   , 29, 'Baby'         ));
        Hat.push(iInfo('3'   , 39, 'Rudolph'      ));
        Hat.push(iInfo('8'   , 49, 'Little Girl'  )); 
        Hat.push(iInfo('>'   , 59, 'Devil'        )); 
        Hat.push(iInfo('O'   , 68, 'Angel'        )); 
        Hat.push(iInfo('}'   , 78, 'Horns'        ));
        Hat.push(iInfo('<'   , 83, 'Dunce'        ));
        Hat.push(iInfo('S'   , 84, 'Fringe'        ));
        Hat.push(iInfo('+<'  , 85, 'Pope'         )); 
        Hat.push(iInfo('8<'  , 86, 'Wizard'       )); 
        Hat.push(iInfo('@}'  , 87, 'Flower'       )); 
        Hat.push(iInfo('=)'  , 88, 'Uncle Sam'    )); 
        Hat.push(iInfo('{'   , 89, 'Toupee'       )); 
        Hat.push(iInfo('*('  , 90, 'Pompon'       )); 
        Hat.push(iInfo('*<)' , 91, 'Clown'        ));
        Hat.push(iInfo('C='  , 92, 'Chef'         )); 
        Hat.push(iInfo('~~'  , 93, 'Snake'        )); 
        Hat.push(iInfo('&'   , 94, 'Curly'        )); 
        Hat.push(iInfo('@@'  , 95, 'Marge Simpson')); 
        Hat.push(iInfo(')'   , 96, 'Nordic'       )); 
        Hat.push(iInfo('='   , 97, 'Punk'         )); 
        Hat.push(iInfo('['   , 98, 'Walkman'      )); 
        Hat.push(iInfo('*<|' , 99, 'Santa Claus'  ));

        Eye.push(iInfo(':',  29, 'Regular'   ));
        Eye.push(iInfo(';',  49, 'Winking'   ));
        Eye.push(iInfo(':`', 69, 'Crying'    ));
        Eye.push(iInfo('`:', 79, 'Sweating'  ));
        Eye.push(iInfo('8',  84, 'Glasses'   ));
        Eye.push(iInfo('.',  89, 'One eyed'  ));
        Eye.push(iInfo('B',  91, 'Horn-rims' ));
        Eye.push(iInfo('+',  92, 'Crushed'   ));
        Eye.push(iInfo('0',  93, 'Snorkeling'));
        Eye.push(iInfo('=',  94, 'Happy'     ));
        Eye.push(iInfo('o',  95, 'Cyclops'   ));
        Eye.push(iInfo('X',  96, 'Blinded'   ));
        Eye.push(iInfo('#',  97, 'Dizzy'     ));
        Eye.push(iInfo('%',  98, 'Tired'     ));
        Eye.push(iInfo('|',  99, 'Asleep'    ));

        Nose.push(iInfo('-', 49, 'Straight' ));
        Nose.push(iInfo('^', 79, 'Pointy'   ));
        Nose.push(iInfo('o', 89, 'Clown'    ));
        Nose.push(iInfo('=', 93, 'Orangutan'));
        Nose.push(iInfo('~', 96, 'Wondering'));
        Nose.push(iInfo('*', 99, 'Drunk'    ));

        Mouth.push(iInfo(')',   39, 'Smiley'       ));
        Mouth.push(iInfo('(',   59, 'Sad'          ));
        Mouth.push(iInfo('D',   69, 'Laughing'     ));
        Mouth.push(iInfo('O',   79, 'Yelling'      ));
        Mouth.push(iInfo('C',   82, 'Bummed'       ));
        Mouth.push(iInfo('p',   85, 'Tongue'       ));
        Mouth.push(iInfo('Q',   88, 'Smoker'       ));
        Mouth.push(iInfo('I',   89, 'Indifferent'  ));
        Mouth.push(iInfo('*',   90, 'Kissing'      ));
        Mouth.push(iInfo('>',   91, 'Lewd'         ));
        Mouth.push(iInfo('<',   92, 'Walrus'       ));
        Mouth.push(iInfo(']',   93, 'Blockhead'    ));
        Mouth.push(iInfo('E',   94, 'Vampire'      ));
        Mouth.push(iInfo('@',   95, 'Yelling'      ));
        Mouth.push(iInfo('$',   96, 'Rich'         ));
        Mouth.push(iInfo('/',   97, 'Skeptical'    ));
        Mouth.push(iInfo('{',   98, 'Mustache'     ));
        Mouth.push(iInfo('(|)', 99, 'Homer Simpson'));

        Beard.push(iInfo('}',   9, 'Beard'    ));
        Beard.push(iInfo('X',  19, 'Bow-tie'  ));
        Beard.push(iInfo('{',  29, 'Shoulders'));
        Beard.push(iInfo('>',  39, 'Suit'     ));
        Beard.push(iInfo('~',  49, 'Goatee'   ));
        Beard.push(iInfo('>3', 59, 'Big bust' ));
        Beard.push(iInfo('3<', 69, 'Hands up' ));
        Beard.push(iInfo(']',  79, 'Robot'    ));
        Beard.push(iInfo('=',  89, 'Rave Dude'));
        Beard.push(iInfo('8<', 94, 'The Girl' ));
        Beard.push(iInfo('^<', 99, 'The Boy'  ));
    }

    fallback() external payable { }

    receive() external payable { }

    function getHat(uint256 tokenID) public view returns(iInfo memory){
        uint256 cRarity = random("SEEDRARITY", tokenID);
        if(cRarity < 20) {
            return pluck(tokenID, "SEEDHAT", Hat);
        } else {
            return Empty;
        }
    }

    function getEyes(uint256 tokenID) public view returns(iInfo memory){
        return pluck(tokenID, "SEEDEYES", Eye);
    }

    function getNose(uint256 tokenID) public view returns(iInfo memory){
        return pluck(tokenID, "SEEDNOSE", Nose);
    }

    function getMouth(uint256 tokenID) public view returns(iInfo memory){
        return pluck(tokenID, "SEEDMOUTH", Mouth);
    }

    function getBeard(uint256 tokenID) public view returns(iInfo memory){
        uint256 cRarity = random("SEEDRARITY", tokenID);
        if(cRarity < 4) {
            return pluck(tokenID, "SEEDBEARD", Beard);
        } else {
            return Empty;
        }
    }

    function getRarity(uint256 tokenID) public view returns(string[3] memory){
        uint256 cRarity = random("SEEDRARITY", tokenID);
        if(cRarity == 0)
            return ['#ffd500','#fff2b3','Legendary'];
        if(cRarity < 4)
            return ['#9c27b0','#eac0f2','Epic'];
        if(cRarity < 10)
            return ['#3f51b5','#c6cceb','Rare'];
        if(cRarity < 20)
            return ['#4caf50','#cae8ca','Uncommon'];
        return ['#9e9e9e','#d9d9d9','Common'];
    }

    function random(bytes16 seed, uint256 tokenID) private view returns (uint256) {
        require( REVEALED != 0, "Not revealed yet" );
        uint256 rand = uint256(keccak256(abi.encodePacked(seed, REVEALED, tokenID)));
        return rand % 100;
    }

    function pluck(uint256 tokenID, bytes16 seed, iInfo[] storage source) private view returns (iInfo storage) {
        uint256 rarity = random(seed, tokenID);
        for(uint i; i < source.length; i++) {
            if(rarity <= source[i].rarity) {
                return source[i];
            }
        }
        return Empty;
    }

    function getASCIISmile(uint256 tokenID) public view returns(string memory) {
        string[5] memory smilePart;
        uint256 cRarity = random("SEEDRARITY", tokenID);
        if(cRarity < 21)
            smilePart[0] = bytesToStr(getHat(tokenID).item);
        smilePart[1] = bytesToStr(getEyes(tokenID).item);
        smilePart[2] = bytesToStr(getNose(tokenID).item);
        smilePart[3] = bytesToStr(getMouth(tokenID).item);
        if(cRarity < 3)
            smilePart[4] = bytesToStr(getBeard(tokenID).item);
        string memory out = string(abi.encodePacked(smilePart[0],smilePart[1],smilePart[2],smilePart[3],smilePart[4]));
        return out;
    }
    
    function tokenURI(uint256 tokenID) override public view returns (string memory) {
        require(_exists(tokenID), "Nonexistent token");

        if( REVEALED == 0 ) {
            return string(abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(abi.encodePacked(
                    '{"name":"', 
                getNickname(tokenID), 
                '","description":"Unrevealed","image":"ipfs://Qmb7zK8nutb1Vh9gpitHpbhyZXxfCV8Af4rp5kaW67WLcS"}'
                ))));
        }
        string[3] memory cRarity = getRarity(tokenID);
        string[3] memory cHat = convert2array(getHat(tokenID));
        string[3] memory cEyes = convert2array(getEyes(tokenID));
        string[3] memory cNose = convert2array(getNose(tokenID));
        string[3] memory cMouth = convert2array(getMouth(tokenID));
        string[3] memory cBeard = convert2array(getBeard(tokenID));
        string[19] memory parts;

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" width="550" height="930"><defs><radialGradient id="G"><stop offset="10%" stop-color="#eee" /><stop offset="70%" stop-color="';
        parts[1] = cRarity[1];
        parts[2] = '" /></radialGradient></defs><g fill="';
        parts[3] = cRarity[0];
        parts[4] = '" font-family="sans-serif" font-size="70"><rect stroke="';
        parts[5] = cRarity[0];
        parts[6] = '" width="510" height="890" x="20" y="20" fill="url(#G)" stroke-width="30" rx="50"/><text x="60" y="120">:-)</text><text x="430" y="120">:-)</text><text x="60" y="850">:-)</text><text x="430" y="850">:-)</text><text x="275" y="500" font-size="160" text-anchor="middle" writing-mode="tb">';
        parts[7] = cHat[0];
        parts[8] = '<tspan fill="#555">';
        parts[9] = cEyes[0];
        parts[10] = cNose[0];
        parts[11] = cMouth[0];
        parts[12] = '</tspan>';
        parts[13] = cBeard[0];
        parts[14] = '</text></g></svg>';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2],  parts[3],  parts[4],  parts[5],  parts[6],  parts[7],  parts[8]));
        output =               string(abi.encodePacked(output,   parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));

        string memory ASCIISmile = string(abi.encodePacked(cHat[2], cEyes[2], cNose[2], cMouth[2], cBeard[2]));

        parts[0] = '{"name": "';
        parts[1] = getNickname(tokenID);
        parts[2] = '", "description": "ASCII Smiles is a collection of emoticons saved in the Ethereum blockchain.", "image": "data:image/svg+xml;base64,';
        parts[3] = Base64.encode(bytes(output));
        parts[4] = '", "attributes": [{"trait_type": "Rarity","value":"';
        parts[5] = cRarity[2];
        parts[6] = '"},{"trait_type": "Hat","value":"';
        parts[7] = cHat[1];
        parts[8] = '"},{"trait_type": "Eyes","value":"';
        parts[9] = cEyes[1];
        parts[10] = '"},{"trait_type": "Nose","value":"';
        parts[11] = cNose[1];
        parts[12] = '"},{"trait_type": "Mouth","value":"';
        parts[13] = cMouth[1];
        parts[14] = '"},{"trait_type": "Beard","value":"';
        parts[15] = cBeard[1];
        parts[16] = '"},{"trait_type": "ASCII","value":"';
        parts[17] = ASCIISmile;
        parts[18] = '"}]}';

        output = string(abi.encodePacked(parts[0], parts[1], parts[2],  parts[3],  parts[4],  parts[5],  parts[6],  parts[7],  parts[8]));
        output = string(abi.encodePacked(output,   parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        output = string(abi.encodePacked(output,   parts[17], parts[18]));
        
        string memory jsonOut = Base64.encode(bytes(output));
        output = string(abi.encodePacked('data:application/json;base64,', jsonOut));
        return output;
    }
    
    function giveAway(address[] calldata _to) external onlyOwner {
        uint16 length = uint16(_to.length);
        require(giveaway_reserved >= length, "Exceeds giveaway supply" );
        giveaway_reserved -= length;
        for(uint256 i; i < length; i++){
            _mint(_to[i], totalSupply());
        }
    }

    function preMint(bytes32[] calldata merkleProof, uint16 num) public payable {
        require( !pre_mint_paused, "Pre mint is paused");
        require( !_msgSender().isContract(), "No contract allowed" );
        require( num > 0 && num <= 10, "Maximum 10 Smiles" );
        require( msg.value >= MintPrice * 5 / 7 * num, "Not enought Ether" );
        require( num <= pre_mint_reserved, "Exceeds pre mint supply" );
        require( balanceOf(_msgSender()) + num <= 10, "Maximum 10 Smiles per wallet" );
        require( MerkleProof.verify(merkleProof, merkleRoot,  keccak256(abi.encodePacked(_msgSender())) ), "Invalid proof");

        pre_mint_reserved = pre_mint_reserved - num;
        for(uint256 i; i < num; i++) {
            _mint(_msgSender(), totalSupply());
        }
    }

    function mintASCIISmiles(uint256 num) public payable {
        require( mint_active, "Mint is stopped");
        require( !_msgSender().isContract(), "No contract allowed");
        require( num > 0 && num <= 5, "Maximum 5 Smiles" );
        require( balanceOf(_msgSender()) + num <= 10, "Maximum 10 Smiles per wallet" );
        require( totalSupply() + num <= maxSupply - giveaway_reserved, "Exceeds maximum supply" );
        require( msg.value >= MintPrice * num, "Not enought Ether" );

        for(uint256 i; i < num; i++) {
            _mint(_msgSender(), totalSupply());
        }
    }

    function Reveal() public onlyOwner {
        require( REVEALED == 0, "Only once");
        REVEALED = uint128(uint256(blockhash(block.number - 1)));
        emit Revealed();
    }

    function setPrice(uint64 newPrice) public onlyOwner {
        MintPrice = newPrice;
    }

    function setNickname(uint256 tokenID, string memory nick) public {
        require( ownerOf(tokenID) == _msgSender(), 'Only token owner');
        bytes memory nickB = bytes(nick);
        require( nickB.length <=32, 'Maximum 32 bytes');
        _nickname[tokenID] = bytes32(nickB);
        ASCToken.payNick(_msgSender(), 50 * 10 ** 18);
    }

    function resetNickname(uint256 tokenID) public onlyOwner {
        _nickname[tokenID] = bytes32(0x00);
    }

    function getNickname(uint256 tokenID) public view returns (string memory result) {
        result = string(abi.encodePacked('ASCII Smile #', (tokenID+1).toString()));
        if(_nickname[tokenID] != 0x00)
            result = bytesToStr(_nickname[tokenID]);
    }

    function stopMint() public onlyOwner {
        mint_active = false;
        emit MintStopped();
    }

    function startMint() public onlyOwner {
        mint_active = true;
        emit MintStarted();
    }

    function pausePreMint() public onlyOwner {
        pre_mint_paused = true;
        emit PreMintPaused();
    }

    function unpausePreMint() public onlyOwner {
        pre_mint_paused = false;
        emit PreMintStarted();
    }

    function updateMerkleRoot(bytes32 newmerkleRoot) public onlyOwner {
        merkleRoot = newmerkleRoot;
        emit MerkleRootUpdated(merkleRoot);
    }

    function setASCToken(address _token) public onlyOwner {
        ASCToken = ASCIISmilesToken(_token);
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance ;
        require(_balance > 0, "Call without balance");
        payable(_msgSender()).transfer(_balance / 2);
        payable(CommunityFund).transfer(address(this).balance);
    }

    function reclaimERC20(IERC20 erc20Token) public onlyOwner {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }

    function decreaseMaxSupply(uint16 newMaxSupply) external onlyOwner {
        require(newMaxSupply < maxSupply, "only decrease");
        require(newMaxSupply >= totalSupply(), "bellow supply");
        maxSupply = newMaxSupply;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function isApprovedForAll(address owner, address operator) override public view returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }


    function is_pre_mint_allowed(bytes32[] calldata merkleProof, address account) public view  returns (bool) {
        if( balanceOf(account) >= 10 )
            return false;
        if( account.isContract() )
            return false;
        if( MerkleProof.verify(merkleProof, merkleRoot,  keccak256(abi.encodePacked(account))) )
            return true;
        return false;
    }
    
    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = owner();
        royaltyAmount = (salePrice * 3) / 100;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721EnumerableSimple) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function bytesToStr(bytes32 input) private pure returns (string memory) {
        uint256 i;
        bytes memory output;
        if(input[0] == 0)
            return '';
        while(input[i] != 0) {
            output = abi.encodePacked(output, input[i]);
            i++;
            if(i > 31) break;
        }
        return string(output);
    }

    function convert2array(iInfo memory iinfo) private pure returns (string[3] memory) {
        return [SVGEncode(iinfo.item), bytesToStr(iinfo.desc), bytesToStr(iinfo.item)];
    }

    function SVGEncode(bytes4 input) private pure returns(string memory) {
        uint256 i;
        bytes memory output;
        if(input[0] == 0)
            return '';
        while(input[i] != 0) {
            if(input[i] == '<') {
                output = abi.encodePacked(output, "&lt;");
            } else if(input[i] == '>') {
                output = abi.encodePacked(output, "&gt;");
            } else if(input[i] == '&') {
                output = abi.encodePacked(output, "&amp;");
            } else {
                output = abi.encodePacked(output, input[i]);
            }
            i++;
            if(i > 3) break;
        }
        return string(output);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
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

interface ASCIISmilesToken is IERC20 {
    function payNick(address from, uint256 amount) external;
}

// @openzeppelin/contracts/cryptography/MerkleProof.sol

library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}