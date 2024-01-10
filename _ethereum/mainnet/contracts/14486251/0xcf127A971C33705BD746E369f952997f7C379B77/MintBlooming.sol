pragma solidity ^0.8.1;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./Counters.sol";
import "./Initializable.sol";
import "./Permission.sol";
import "./IMossBlossoms.sol";

/**
 * This is an Spirit contract implementation of NFToken with metadata extension
 */
contract MintBlooming is Ownable,Initializable,Permission
{
     using Counters for Counters.Counter;
     Counters.Counter private _tokenIdTracker;
     bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IMossBlossoms mossBlossomsContract;
   
    mapping(address => uint8) mintWhilte;


    mapping(address => uint8) donateMintCount;


    event mintBloomingEvt(address indexed,uint256 tokenId);
    constructor(){
        _tokenIdTracker.increment();
        initWhilte();
    }

    function init(IMossBlossoms _mossBlossomsContract) public onlyOwner {
        mossBlossomsContract = _mossBlossomsContract;
        initialized = true;
    }

  

     function getSequence() public onlyRole(MINTER_ROLE) returns(uint256){
        uint256 tokenId = _tokenIdTracker.current();
        _tokenIdTracker.increment();
        return tokenId;
    }
    
    function mint() public needInit{
        require(mintWhilte[msg.sender]>0);
        for(uint8 indx = 1; indx <= mintWhilte[msg.sender]; indx++) {
                uint256 tokenId = _tokenIdTracker.current();
                _tokenIdTracker.increment();
                     
                mossBlossomsContract.mint(msg.sender, tokenId);
        }
         
        mintWhilte[msg.sender] = 0;
    }
    function setWhile(address _addr,uint8 number) public onlyRole(MINTER_ROLE){
       
        mintWhilte[msg.sender] = mintWhilte[msg.sender]+number;
       
    }

    function clearWhilte(address _addr) public onlyRole(MINTER_ROLE){
         mintWhilte[msg.sender] = 0 ;
    }

    function setBatchWilte(address[] memory _addrs,uint8[] memory numbers) public onlyRole(MINTER_ROLE){

        require(_addrs.length == numbers.length, "Invalid input parameters");

        for(uint256 indx = 0; indx < _addrs.length; indx++) {
             require(numbers[indx]>0 ,"parmas error");
          
             mintWhilte[_addrs[indx]] = mintWhilte[_addrs[indx]]+numbers[indx];
            
         }
    }

    function queryCount() public view returns(uint8){
        return mintWhilte[msg.sender] ;
    }
    function initWhilte() private{
        mintWhilte[0x5e7a1573620e0dF38e41dD302F68D7d8E5b99bba]=2;
        mintWhilte[0x9c434F02A31Ce03F26BF783821AbA9E8077CA737]=2;
        mintWhilte[0x278bD76Ef225EB7c72155251A7071a6567BA4bd4]=1;
        mintWhilte[0x01269fe93E085F833E09257A7542e1aD08F88ab9]=2;
        mintWhilte[0x01eDaAc7495023C59f314E258908B67db2f37BcC]=2;
        mintWhilte[0x149D7A4684ea84a38389Bd6C7f1bf5989285f83E]=2;
        mintWhilte[0x15AfDCce81873d5AcEdcB5C53c7661b91990E6f8]=2;
        mintWhilte[0x1A51cF5904E20Cf7fc8dbE9e18e05E21c6D036FE]=2;
        mintWhilte[0x2DdDb59499e2AbEe45Eeb3C1C0c6E44b200e11B9]=3;
        mintWhilte[0x33256635B7d200Dc0a1dE51c9089D93C44A5A55a]=2;
        mintWhilte[0x3655810F2eD910Cb72401B00261C33Fc2FD19B21]=2;
        mintWhilte[0x3D96e6DD529461748a85eaA2876A50d2B9008109]=2;
        mintWhilte[0x497336eA24aed7e66808BE54eB5DFaDb72769341]=1;
        mintWhilte[0x4bD053E73964e0ec4A35333F3b11063b1a671354]=1;
        mintWhilte[0x4Ed2F7EaDd13CdC339b67F371610bf26224E4B98]=1;
        mintWhilte[0x53827bbcf5b1317cE0b2c715feAD140B191f5Fd4]=2;
        mintWhilte[0x57f0E19b71fb8f4deCf9bA4B48000B605A10baD8]=2;
        mintWhilte[0x5E32732da1e3e1E14F0d12aaF3120Adc83BDFAAa]=2;
        mintWhilte[0x61b8455F978E4f9d466272A8912499a3C0D845C7]=2;
        mintWhilte[0x62f07535a44611B72C00eE4ef3dd423AaA42B60D]=2;
        mintWhilte[0x635eDbE10f73F956020C0ac016eA6d56B1101c72]=2;
        mintWhilte[0x644a40Cc841d64d13E2daB3B053FD83194f86E03]=2;
        mintWhilte[0x6458c69E3Ea2112B4F625850db3AAA7d19ddde57]=2;
        mintWhilte[0x68AC44d37381a20D00c012917Fe48321B36bE9Ac]=1;
        mintWhilte[0x695E468BC819820F444F077eB28442224164c99D]=2;
        mintWhilte[0x6a9F14b8a95c65b65D4dff7659274Bf77D9f0A96]=2;
        mintWhilte[0x6E685A45Db4d97BA160FA067cB81b40Dfed47245]=1;
        mintWhilte[0x8411ca148e1F9D7366aF8F370B37b8fF448456E1]=2;
        mintWhilte[0x84f56be719d6Ad01b392Cc29B8928AA96a97cCFA]=2;
        mintWhilte[0x8504A09352555ff1acF9C8a8D9fB5FDcC4161cbc]=2;
        mintWhilte[0x8979ebDc6ecf41Eb61b254d8A1F6007569F8dE02]=2;
        mintWhilte[0x8baFF0A70Ad75164657D9DC3DEcAC8f76927c612]=2;
        mintWhilte[0xf4d582ad29204750a4f68FEAe4678BA6C645c2BF]=1;
        mintWhilte[0x9522190011E4F3cfF52AD70be486C9ABA8888888]=2;
        mintWhilte[0x98455E47C98aDe007E4ED1E140a0ff82eca59cec]=2;
        mintWhilte[0x98c8469696c59588595D99eE3eCA8220FcB026c2]=2;
        mintWhilte[0x9EEd555A7b54471a0808CEC8d176980323674BC8]=1;
        mintWhilte[0xa333b4b69DBD8212330E3f1b9a9A33Db9D2B03E4]=2;
        mintWhilte[0xA8fe15445aE766706B49b16E447B0Fc64C60635a]=1;
        mintWhilte[0xAaA488EB314D3E009Fd4CFce2d0a94d3226eddD7]=2;
        mintWhilte[0xAf5d1fEA5Ae2656DDcd6CdB37471236B5C5Dcc17]=2;
        mintWhilte[0xb162f535f4DfAEa681f49D408963Db739Af1505e]=2;
        mintWhilte[0xB58d9dd553eeCEf78a9331678C2c712dd0791554]=1;
        mintWhilte[0xBBA0A9F8b72f1Ad3B0772D276D21f5C9A07E0154]=2;
        mintWhilte[0xC16176539680085618Dae41559104135D2f464e2]=2;
        mintWhilte[0xc28531bdF80A349d35bA5ED98519c7cbb423cCdc]=2;
        mintWhilte[0xC85441828BddF079FEB17de13e81B779AB855827]=2;
        mintWhilte[0xc9859FC94A2b777c97938A93E6eE092E904caA78]=2;
        mintWhilte[0xCc46a1A8268ab599e051e198edf5e87E9D0aF480]=2;
        mintWhilte[0xd52c41363b0deFD25cbDC568C93180340F8611a2]=2;
        mintWhilte[0xdB6A1EE4d52ae487819Df8524c13623966C42B47]=2;
        mintWhilte[0xE6A8dd986e03Cc3B419cf5C69aFb6484Ff9Ca372]=2;
        mintWhilte[0xe7804c37c13166fF0b37F5aE0BB07A3aEbb6e245]=3;
        mintWhilte[0xE8C7FFC11f518d6C77d871ca367423B46aaF419B]=2;
        mintWhilte[0xeafc862D143fA5BE12ceCA2C4E70Aa6d66f96109]=1;
        mintWhilte[0xEd443Bb6bC3f2889418eCF8D627CCBeDc7e2F920]=2;
        mintWhilte[0xf0f6036559Afa87214E3103e781DB47aAB7F7082]=0;
        mintWhilte[0xF942CE6643bC80D0Bcc1BEA4FD4657e600A1De88]=2;
        mintWhilte[0x1A4f69bACd5B14F339fc361039262128e0cBCc4e]=4;
        mintWhilte[0xc8F29114231Ad94458B3aA3c903fE454976335bC]=2;
        mintWhilte[0x4a73145693f1CEe36010239f120d3F0753b26705]=1;
        mintWhilte[0x25f874499695015Ca7900cB095f47Cd3F9C84FFa]=2;
        mintWhilte[0x62f07535a44611B72C00eE4ef3dd423AaA42B60D]=2;
        mintWhilte[0xC8fc855Dff9e04D6708840268E73ECA6a514066E]=1;
        mintWhilte[0x5f239ff2AF7f691173612e17a1Aed95cE5aDB1F0]=1;

      
    }

    
}
