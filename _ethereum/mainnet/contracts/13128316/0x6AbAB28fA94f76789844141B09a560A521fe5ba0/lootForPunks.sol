pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./Ownable.sol";

interface Cryptopunks
{
    function punkIndexToAddress (uint256 punkIndex) external view returns (address);
}

interface CryptopunksData
{
    function punkAttributes (uint16 punkIndex) external view returns (string memory);
}


contract LootForPunks is ERC721, Ownable
{
    using Strings for uint256;
    using Strings for uint16;
    address public cryptopunksAddress=0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    address public cryptopunksDataAddress=0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2;
    Cryptopunks punksContract=Cryptopunks(cryptopunksAddress);
    CryptopunksData dataContract=CryptopunksData(cryptopunksDataAddress);
    //initial prices may be updated 
    uint256 public punkPrice = 20000000000000000; //0.02 ETH
    uint256 public publicPrice = 100000000000000000; //0.1 ETH
    bool public saleIsActive = true;
    bool public privateSale = true;
    address private t1=0x879253B5Cc2B13bb976e075F0571F85454A315f6;

    constructor () public ERC721("Loot (for Punks)", "Loot4Punks") {}

    //Private sale minting (reserved for Punks owners)
    function mintWithPunk(uint256 punkId) public payable  {
        require(privateSale, "Private sale minting is over");
        require(saleIsActive, "Sale must be active to mint");
        require(punkPrice <= msg.value, "Ether value sent is not correct");
        require(punksContract.punkIndexToAddress(punkId) == msg.sender, "Not the owner of this punk.");
        require(!_exists(punkId),"Already Minted!");
        _safeMint(msg.sender, punkId);
    }

    //Public sale minting
    function mint(uint256 punkId) public payable  {
        require(!privateSale, "Public sale minting not started");
        require(saleIsActive, "Sale must be active to mint");
        require(publicPrice <= msg.value, "Ether value sent is not correct");
        require(punkId < 10000, "Token ID invalid");
        require(!_exists(punkId),"Already Minted!");
        _safeMint(msg.sender, punkId);
    }

    function withdraw() public onlyOwner {
        uint256 share = address(this).balance * 4 / 10;
        payable(t1).send(share); 
        payable(owner()).send(address(this).balance); 
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function endPrivateSale() public onlyOwner {
        require(privateSale);
        privateSale = false;
    }

    function setPunkPrice(uint256 newPrice) public onlyOwner {
        punkPrice = newPrice;
    }

    function setPublicPrice(uint256 newPrice) public onlyOwner {
        publicPrice = newPrice;
    }

    function viewAttributes(uint256 __tokenId) public view returns ( string [8] memory) {
        uint16 tokenId=uint16(__tokenId);
        require(_exists(tokenId),"Token does not exist!");
        string[30] memory parts;
        string memory _punkMetaData=dataContract.punkAttributes(tokenId);
        string[8] memory punkMetadata =stringToArray(_punkMetaData);
        return punkMetadata;
        }

    function tokenURI(uint256 __tokenId) override public view returns (string memory) {
        uint16 tokenId=uint16(__tokenId);
        require(_exists(tokenId),"Token does not exist!");
        string[30] memory parts;
        string memory _punkMetaData=dataContract.punkAttributes(tokenId);
        string[8] memory punkMetadata =stringToArray(_punkMetaData);
        parts[0] =( '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">');
        for (uint i=0;i<punkMetadata.length;i++)
        {
            if (bytes(punkMetadata[i]).length!=0)
            {
                parts[i+1]=punkMetadata[i];
            }
        }
        string memory output;
        uint coord;
        for (uint i=0;i<parts.length;i++)
        {
            coord=20*(i+1);
            output=string(abi.encodePacked(output,parts[i],'</text><text x="10" y="',coord.toString(),'" class="base">'));
        }   
        coord+=20;
        output=string(abi.encodePacked(output,'</text><text x="10" y="',coord.toString(),'" class="base">','</text></svg>'));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Loot (for Punks) #', tokenId.toString(), '", "description": "Loot (for Punks) is derived entirely from on-chain Cryptopunks metadata. Loot (for Punks) is not affiliated with Larva Labs.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function stringToArray(string memory _input) public view returns (string [8] memory)
    {
        bytes memory input = bytes (_input);
        bytes memory delimiter = bytes (",");
        string [8] memory output;
        uint counter=0;
        for (uint i;i<input.length;i++)
            {
                if (input[i]==delimiter[0])
                {
                    counter++; //move to next word
                    i++; //skip spaces
                }
                else
                {   
                    output[counter]=string(abi.encodePacked(output[counter],input[i]));
                }
            }
    
        return output;
    }

}


/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

