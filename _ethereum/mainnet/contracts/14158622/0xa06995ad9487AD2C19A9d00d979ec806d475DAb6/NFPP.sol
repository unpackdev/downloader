/*


███╗   ██╗███████╗██╗   ██╗███████╗██████╗       ███████╗██╗   ██╗███╗   ██╗ ██████╗ ██╗██████╗ ██╗     ███████╗
████╗  ██║██╔════╝██║   ██║██╔════╝██╔══██╗      ██╔════╝██║   ██║████╗  ██║██╔════╝ ██║██╔══██╗██║     ██╔════╝
██╔██╗ ██║█████╗  ██║   ██║█████╗  ██████╔╝█████╗█████╗  ██║   ██║██╔██╗ ██║██║  ███╗██║██████╔╝██║     █████╗  
██║╚██╗██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════╝██╔══╝  ██║   ██║██║╚██╗██║██║   ██║██║██╔══██╗██║     ██╔══╝  
██║ ╚████║███████╗ ╚████╔╝ ███████╗██║  ██║      ██║     ╚██████╔╝██║ ╚████║╚██████╔╝██║██████╔╝███████╗███████╗
╚═╝  ╚═══╝╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝      ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═════╝ ╚══════╝╚══════╝
                                                                                                                
██████╗  █████╗ ███████╗████████╗ █████╗     ██████╗ ██╗      █████╗ ████████╗███████╗███████╗                  
██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██╔══██╗    ██╔══██╗██║     ██╔══██╗╚══██╔══╝██╔════╝██╔════╝                  
██████╔╝███████║███████╗   ██║   ███████║    ██████╔╝██║     ███████║   ██║   █████╗  ███████╗                  
██╔═══╝ ██╔══██║╚════██║   ██║   ██╔══██║    ██╔═══╝ ██║     ██╔══██║   ██║   ██╔══╝  ╚════██║                  
██║     ██║  ██║███████║   ██║   ██║  ██║    ██║     ███████╗██║  ██║   ██║   ███████╗███████║                  
╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝    ╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚══════╝                  
                                   
                                                                                                                    
by NFOG

*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./base64.sol";

contract NFOG {
    function ownerOf(uint tokenId) public view returns (address) {}

    function balanceOf(address addr) public view returns (uint) {}

    function totalSupply() public view returns (uint) {}
}

contract NFPP is ERC721, Ownable {


    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    struct Bowl {
        bool exists;
        uint pasta;
        uint refills;
        uint parm;
    }

    struct Pasta {
        bool exists;
        string name;
        string image;
        uint numMints;
    }

    struct NewPasta {
        uint id;
        string name;
        string image;
    }

    mapping (uint => Bowl) bowls;
    mapping (uint => bool) public franchiseeMints;
    mapping (uint => Pasta) pastas;

    uint maxParm = 10;
    uint minParm = 0;

    NFOG nfog;

    string[] parmLevels = ["None", "Whiff", "Dusting", "Sprinkling", "Coating", "Layer", "Mound", "Pile", "Heap", "Hill", "Monolith"];

    

    constructor(address nfogAddress) ERC721("Never-Fungible Pasta Plates", "NFPP") {
        nfog = NFOG(nfogAddress);
    }

    function getAddressFranchises(address addr) public view returns(uint[] memory, uint[] memory){
        uint balance = nfog.balanceOf(addr);
        uint[] memory tokens = new uint[](balance);
        uint[] memory redeemed = new uint[](balance);
        if(balance == 0){
            return (tokens, redeemed);
        }
        uint numFound = 0;
        for(uint i=0; i<nfog.totalSupply(); i++){
            if(nfog.ownerOf(i) == addr){
                tokens[numFound] = i;
                if(franchiseeMints[i]){
                    redeemed[numFound] = 1;
                }else{
                    redeemed[numFound] = 0;
                }
                numFound++;
                if(numFound > balance){
                    break;
                }
            }
        }
        return (tokens, redeemed);
    }

    function getAddressPlates(address addr) public view returns(uint[] memory){
        uint balance = balanceOf(addr);
        uint[] memory tokens = new uint[](balance);
        if(balance == 0){
            return tokens;
        }
        uint numFound = 0;
        for(uint i=0; i<totalSupply(); i++){
            if(ownerOf(i) == addr){
                tokens[numFound] = i;
                numFound++;
                if(numFound > balance){
                    break;
                }
            }
        }
        return tokens;
    }

    function totalSupply() public view returns(uint256){
        return _tokenIdCounter.current();
    }

    function getNFOGOwner(uint id) public view returns (address){
        address owner = nfog.ownerOf(id);
        return owner;
    }

    function addPastas(NewPasta[] memory newPastas) public onlyOwner{
        for(uint i=0; i<newPastas.length; i++){
            Pasta storage pasta = pastas[newPastas[i].id];
            pasta.name = newPastas[i].name;
            pasta.image = newPastas[i].image;
            if(!pasta.exists){
                pasta.exists = true;
                pasta.numMints = 0;
            } 
        }
    }

    function mintToFranchisee(uint[] memory tokenIds, uint pastaId, uint parmLevel) public{
        for(uint i=0 ;i<tokenIds.length; i++){
            require(getNFOGOwner(tokenIds[i]) == msg.sender, 'NOT_FRANCHISE_OWNER');
            require(!franchiseeMints[tokenIds[i]], 'ALREADY_MINTED');
            mint(msg.sender, pastaId, parmLevel);
            franchiseeMints[tokenIds[i]] = true;
        }
    }

    function mint(address addr, uint pastaId, uint parmLevel) private {
        require(parmLevel >= minParm, 'LOW_PARM');
        require(parmLevel <= maxParm, 'HIGH_PARM');
        require(pastas[pastaId].exists, 'BAD_PASTA');
        bowls[_tokenIdCounter.current()] = Bowl({
            exists: true,
            pasta: pastaId,
            refills: 0,
            parm: parmLevel
        });
        pastas[pastaId].numMints++;
        _safeMint(addr, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function refill(uint tokenId, uint pastaId, uint parmLevel) public {
        require(_exists(tokenId), 'NOT_EXIST');
        require(ownerOf(tokenId) == msg.sender, 'NOT_OWNER');
        require(parmLevel >= minParm, 'LOW_PARM');
        require(parmLevel <= maxParm, 'HIGH_PARM');
        require(pastas[pastaId].exists, 'BAD_PASTA');
        bowls[tokenId].pasta = pastaId;
        bowls[tokenId].refills ++;
        bowls[tokenId].parm = parmLevel;
        pastas[pastaId].numMints++;
    }

    function getPastaMints(uint pastaId) public view returns (uint) {
        require(pastas[pastaId].exists, 'BAD_PASTA');
        return pastas[pastaId].numMints;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Plate #', uint2str(tokenId) , '", "description": "A delicious never-fungible pasta plate from NFOG.", "image": "', pastas[bowls[tokenId].pasta].image ,'/', uint2str(bowls[tokenId].parm) ,'.png", "attributes": [{"trait_type": "Pasta","value": "', pastas[bowls[tokenId].pasta].name , '"}, {"trait_type": "Refills","value": "', uint2str(bowls[tokenId].refills) , '"}, {"trait_type": "Parm Level","value": "', parmLevels[bowls[tokenId].parm] , '"}]}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

/*


██╗    ██╗██╗   ██╗██╗  ██╗██╗   ██╗███████╗
██║    ██║╚██╗ ██╔╝██║  ██║╚██╗ ██╔╝██╔════╝
██║ █╗ ██║ ╚████╔╝ ███████║ ╚████╔╝ █████╗  
██║███╗██║  ╚██╔╝  ██╔══██║  ╚██╔╝  ██╔══╝  
╚███╔███╔╝   ██║   ██║  ██║   ██║   ██║     
 ╚══╝╚══╝    ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚═╝     
                                            

*/