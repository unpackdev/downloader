// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "Ownable.sol";
import "ERC721.sol";
import "ERC721Enumerable.sol";
import "IERC721.sol";
import "IChubbyKaijuDAOCorp.sol";
/***************************************************************************************************
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxddddddddddddddxxxxxdd
kkkkkkkkkkkkkkkkkkkkkkkxxkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxkxkkkkkkkkkkkkkkkkkkkkkxxddddddddddddxxkkkxx
kkkkkkkkkkkkkkkkkkkkkkkkkkkxxxkkkkkkkkkkkkkkkkkkkkkkxxdddddxxxxxkkkkkkkkkkkkkkkkxxddddddddddddxxkxkk
kkkkkkkkkkkkkkkkkkkkxxxxxddddxxkxxkkxxkkkkkkkxxkkxxkkkxxddddddddxxxxkkkkkkkkxxkkkxxddddddddddddxxkkk
kkkkkkkkkkkkkkkxxxxddddddddxxxxkxxoooodxkkkkkxxdooddxkxxkkkxxxxdddddxxxkkkkkkkkkkkxxdddddddddddddxkk
kkkkkkkkkkkkxxxdddddoddxxxxkkkxl,.',,''.',::;'.''','',lxxxkkkkxxddddddxxxkkkxxxxxkkxddddddddddddddxk
kkkkkkkkxxxdddddddddddxxxxdddo,.,d0XXK0kdl;,:ok0KKK0x;.'lxxxxxxxxddddddddxxkkxxxxxxddodddddddddddddx
kkkkkxxxddddddddddddddddddddl'.:KMMMMMMMMNKXWMMMWWMMWXc..';;;:cloddddddddddxkkxxdddddodddddddddddddd
kkxxxddddddddddddddddddddddc..c0WMMMMMMMMWXNMMMMMMMWk;,',;::;,'..':oxxxxddodxxxkxxdddddxdddddddddddd
kxxdddddddddddddddddddddoc'.'d0XWMMMMMMMMMWMMMMMMMMWXOKNWWMMMWX0kl,.'cdkkxxxddddxdddxxkkkxxxdddddddd
xddddxxxxxxdddddddddddl:'.,xXNKKNMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMNk:..cxkkxxxddddddxkkkkkkkxddddddd
xxxxxkkkxxxdddddddddo;..ckNMMMNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk,.,dxxkkxxxdddxkkkkkxkkxdddddd
kkkkxxxxdddddddoddo:..c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo..cxkkkkkxxxxkkkkkkkkkxddddd
kkkxxxddoddddddddd:..xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNXNWWMMMMMMMMMMWNO,.;dkkkkkxkkxxkkkkkkkxxdddd
kxxxdddddo:'',;:c;. lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWNNWMMMMMWMMMWMMMXc.'okxkkkkkkkkkkkkkkkxdddd
xxdddddodo' .;,',,,:ONWMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxc;;:xXMMMMMMMMMMMWNNNXd..lkkkkkkkkkxkkkkkkkxddd
ddddddddddc..oKKXWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMWkc'      ,0MMMMMMMMMWNNNXNWx..okkkkkkkkkkkkkkkkxdod
dddddddddddl..l0XNNWWWMMWXNMMMMMMMMMMMMMMMMMMMMNd.   ....  :XMMMMMMWWW0l,,;d0l.,xkkkxkkkkkkkkkkkxddd
ddddddddddxko'.,lxO0KXNNO;cXMMMMMMMMMMMMMMMMMMMk.  ....... .kMMMMMMMWk.     :x'.lkkkkkkkkkkkkkkkkxdd
ddddddddxxxkkxl;'.'',:cl:..dWMMMMMMMMMMMMMMMMMWl  ........ .kMMMMMMMNc  ... .c, :xxkkkkkkkkkkkkkkxdd
dddddddxkkkkkkkkxdoc:;,''. ;KMMMMMMMMMMMMMMMMMWl  .......  ,KWWMWX0Ox'       '..cxxkkkkkkkkkkkkkkxdd
dddddxxkkkkkkkkxxkkxkkkkxo'.oWMMMMMMMMMMMMMMMMMO'    ...  .xKkoc;,,,;,.   ,:;,...:dkxkkxkkkkkkkkkxdd
ddddxxkkkkkkkkkkkkkxkkxxddc..kWMMMMMMMMMMMMMMMMMXdc:.. ..;:;...'oOXNWO:colkWMWXk;.,xkxkkkkkkkkkkkxdd
ddxxkkxxkkkkkkkkkkkkxxddddo;.;KMMMMMMMMMMMMMMMMMMMMWX0O0XXxcod;cKMMMMWKl:OMMMMMM0,.lkxkkkkkkkkkkkxdd
dxxkkkkkkkkkkkkxxkkxxddddddo,.:XMMMMMMMMMMMMMMMMMMMMMMMMMMMWMKc:KMMMMMNxoKMMWMMM0,.lkxxxkkkkkkkkxxdd
xxkkkkkkkkkkkkkkkkxxddddddddl'.cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNWMWMMMMWWMMMWMMNl.,dkkkxkkkkkkkkxddd
xkkkkkkkkkkkkkkkkxdddddddddodl'.cXMMMMMMMMMMMMMMMMMMMMMMMMMMKdOWNxo0WNxlOWKcoXNo..okxxkkkkkkkkkkxddd
kkkkkkkkkkkkkkkkkxddodddddddddo'.,OWMMMMMMMMMMMMMMMMMMMMMN0Oc .lc. .l:. .;. .,, .lkxxkkkkkkkkkkxxddd
kkkkkkkkkkkkkkkkxddddddddddddddo' cNMMMMMMMMMMMMMMMMMMMMMKl,;'. .,,. .'. .,. '' 'xkkxkkkkkkkkkkxdddd
kkkkkkkkkkkkkkkkxddoddddl:,'..';. :NMMMMMMMMMMMMMMMMMMMMMWWWWKlc0WNd,xNx;kWx;xl ,xkkkkxxkkxxkkxxdddd
kkkkkkkkkkkkkkkkxdddddo:..:dxdl'  ,0MMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMWWWMWWMMWWK; :kkkkkkkkkkxkkxddddd
kkkkkkkkkxkkkkkxxdoddo; 'kNMWMNl.'kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMK:.'dkkkkkxkkkkkkxdddddd
kkkkkkkkkkkxkkkxxddddo' lXNMMWo.:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0o' 'dkkkkxxkkkkkkxxdddddd
kkkkkkkxkkkkkkkxdc;,,'.,kXNMMWK0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXXO:,,..ckkkkxkkkxkkxxddddddd
kkkkkkkkkxxkxkxc..;loox0KKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNNNNXXXXXXXXXXXKXXk'.cxkxkkxkkkxxdddddddd
kkkkkkkkkkkkxkl..xNMMMMWNXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWNNWWWWWMMMMMMWO'.ckxkkxkxxxdoddddddx
kkkkkkkkkkkkkx, cNMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx..okkkkxddddddddddxx
kkkkkkkkkkkkkx, cNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.'dkxxddddddddddxkk
kkkkkkkkkxkxxx: ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWMMMMMMMMMMMMMX; :ddddddddoddxxkkx
kkkkkkkkxxkkxko..dNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNNNNXXXXXXXNNWMMMMMMMMMWk..cdddddddddxxkxxd
kkkkkkkxxkkxkkx, cXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNWWMMMMMMMWWWNNNNWMMMMMMMMN: ,oddddddxxxkxxdd
kkkkkkkkkkkxkko..oXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNWMMMMMMMMMMMMMMMMWWWMMMMMMMMWk..ldddddxkkxkkxxx
xkkkkkkkkkkxkd,.lXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX; ;dddxxkkkkxxkkk
xxkkkkkkkxkkk: :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo 'dxxkkkkkkkkkkk
dxkkkkkkkkxkx, dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO..okxkkkkkkkkkkx
ddxkkxkkkkxkd'.dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMX; ckkkkkkkkkkxxd
dodxxkkkkxkkx; cWMMMMWNWMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWMMMWc ;xkkkxkkkxxddd
dddddxxkkkkxkl..OWMMWNXWMMMMMMMMMMMNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXNMMMMd.'dkkkkxxdddddd
ddddddxxkkkkkx; :KWWN0KWMMMMMMMMMMWXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMMk..okxxxdddddddd
ddddddddxxkkkkl..xXX0ccKMMMMMMMMMMWXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMM0'.lxddddddddddd
***************************************************************************************************/

contract ChubbyKaijuDAOInvasion is ERC721Enumerable, Ownable{
    using Address for address;
    using Strings for uint256;

    bool private ispreSale1;
    bool private ispreSale2;
    bool private ispreSale3;
    bool private ispublicSale;
    bool private isMutate;

    mapping(address => bool) public isPurchased1;
    mapping(address => uint256) public isPurchased2;
    mapping(address => uint256) public isPurchased3;
    mapping(address => uint256) public isPurchased4;

    uint256 public zombieMinted;
    uint256 public alienMinted;
    uint256 public superalienMinted;
    uint256 public undeadMinted;
    uint256 public superundeadMinted;
    //uint256 superMinted;

    uint256 public constant ALIEN_BASE = 6666;
    uint256 public constant UNDEAD_BASE = 9999;
    uint256 public constant SUPER_BASE = 20000;

    string private baseURI; 
    address private signer;
    
    uint256 public  PRESALE_MINT_PRICE = 0.08 ether;
    uint256 public  PUBLIC_MINT_PRICE = 0.1 ether;

    uint16 public round_gen2;

    address[] public alien_leaders;
    address[] public zombie_leaders;
    address[] public undead_leaders;

    mapping(uint256 => uint16) public traits; // 0 for zombie, 1 for alien, 2 for undead, 10 for burned zombie
    mapping(uint256 => bool) public usedZombie;

    IChubbyKaijuDAOCorp private chubbykaijudaocorp;

    constructor(address _corpAddress) ERC721("ChubbyKaijuDAOInvasion", "CKAIJU2"){
        chubbykaijudaocorp = IChubbyKaijuDAOCorp(_corpAddress);
    }

    function initialize(address _signer) public onlyOwner {
        signer = _signer;
    }

    function preSale(bytes memory signature, uint16 amount) external payable {
        require(ispreSale1 || ispreSale2 || ispreSale3, "Not Presale Period");
        require(isWhitelisted(msg.sender, signature),"Not Whitelisted");
        if(ispreSale1){
            require(!isPurchased1[msg.sender], "Already Minted All");
            require(amount==1,"You can mint only one in this stage");
            require(zombieMinted+amount<6667,"All zombies are minted");
            require(msg.value >= amount*PRESALE_MINT_PRICE, "Not Enough ETH");
            zombieMinted++;
            traits[zombieMinted]=0;
            _mint(msg.sender, zombieMinted);
            isPurchased1[msg.sender] = true;
        }else if(ispreSale2){
            require(isPurchased2[msg.sender]+amount<11, "Already Minted All");
            require(zombieMinted+amount<6667,"All zombies are minted");
            require(msg.value >= amount*PRESALE_MINT_PRICE, "Not Enough ETH");
            for(uint i=0; i<amount; i++){
                zombieMinted++;
                traits[zombieMinted]=0;
                _mint(msg.sender, zombieMinted);
                isPurchased2[msg.sender]++;
            }
        }else if(ispreSale3){
            require(isPurchased3[msg.sender]+amount<11, "Already Minted All");
            require(zombieMinted+amount<6667,"All zombies are minted");
            require(msg.value >= amount*PRESALE_MINT_PRICE, "Not Enough ETH");
            for(uint i=0; i<amount; i++){
                zombieMinted++;
                traits[zombieMinted]=0;
                _mint(msg.sender, zombieMinted);
                isPurchased3[msg.sender]++;
            }
        }

    }

    function publicSale(uint16 amount) external payable {
        require(ispublicSale, "Not Publicsale Preiod");
        require(isPurchased4[msg.sender]+amount<11, "Already Minted All");
        require(zombieMinted+amount<6667,"All zombies are minted");
        require(msg.value >= amount*PUBLIC_MINT_PRICE, "Not Enough ETH");
        for(uint i=0; i<amount; i++){
            zombieMinted++;
            traits[zombieMinted]=0;
            _mint(msg.sender, zombieMinted);
            isPurchased4[msg.sender]++;
        }
    }

    function mutateWithCorp(uint256 typeId, uint256 zombieId) external {
        require(isMutate, "Cannot mutate Yet");
        require(_exists(zombieId),"Not exist zombie");
        require(ownerOf(zombieId)==msg.sender,"Not Owner");
        require(zombieId<6667, "Only Zombie can Mutate");
        require(!usedZombie[zombieId],"Already Mutated");
        require(chubbykaijudaocorp.balanceOf(msg.sender, typeId)>0,"Must own this type of corp");

        if(typeId == 0){ // RADIO
            chubbykaijudaocorp.burnCorpForAddress(typeId, msg.sender);
            alienMinted++;
            _mint(msg.sender, alienMinted+ALIEN_BASE);
            traits[alienMinted+ALIEN_BASE] = 1;
        }else if(typeId == 1) { // SERUM
            chubbykaijudaocorp.burnCorpForAddress(typeId, msg.sender);
            _burn(zombieId);
            undeadMinted++;
            _mint(msg.sender, undeadMinted+UNDEAD_BASE);
            traits[undeadMinted+UNDEAD_BASE] = 2;
            traits[zombieId] = 10;
        }else if(typeId == 2) { // SUPER RAIDO
            chubbykaijudaocorp.burnCorpForAddress(typeId, msg.sender);
            superalienMinted++;
            _mint(msg.sender, superalienMinted+superundeadMinted+SUPER_BASE);
            traits[superalienMinted+superundeadMinted+SUPER_BASE] = 1;
        }else if(typeId == 3) { // SUPER SERUM
            chubbykaijudaocorp.burnCorpForAddress(typeId, msg.sender);
            _burn(zombieId);
            superundeadMinted++;
            _mint(msg.sender, superalienMinted+superundeadMinted+SUPER_BASE);
            traits[superalienMinted+superundeadMinted+SUPER_BASE] = 2;
            traits[zombieId] = 10;
        }
        usedZombie[zombieId] = true;
    }

    function ownerOf(uint256 tokenId) public view override(ERC721) returns (address) {
        return super.ownerOf(tokenId);
    }

    function tokensOf(address owner) external view returns (uint16[] memory) {
        uint32 tokenCount = uint32(balanceOf(owner));
        uint16[] memory tokensId = new uint16[](tokenCount);
        for (uint32 i = 0; i < tokenCount; i++){
        tokensId[i] = uint16(tokenOfOwnerByIndex(owner, i));
        }
        return tokensId;
    }    

    function contractURI() public pure returns (string memory) {
        //TODO change contractURI
        return "https://raw.githubusercontent.com/KaijuDAO/kaijudao/main/contracturi";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");
        return bytes(_baseURI()).length > 0 ? string(abi.encodePacked(_baseURI(), tokenId.toString())) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        //TODO change baseURI
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setLeadersGen2(address alien, address zombie, address undead) external onlyOwner {
        alien_leaders.push(alien);
        zombie_leaders.push(zombie);
        undead_leaders.push(undead);
        round_gen2++;
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
        keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );
    }

    function isWhitelisted(address user, bytes memory signature) public view returns (bool) {
        bytes32 messageHash = keccak256(abi.encode(user));
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "sig invalid");

        assembly {
        /*
        First 32 bytes stores the length of the signature

        add(sig, 32) = pointer of sig + 32
        effectively, skips first 32 bytes of signature

        mload(p) loads next 32 bytes starting at the memory address p into memory
        */

        // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
        // second 32 bytes
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
    function setSale(uint16 step) external onlyOwner {
        if(step==1){
            ispreSale1=true;
            ispreSale2=false;
            ispreSale3=false;
            ispublicSale=false;
        }else if(step==2){
            ispreSale1=false;
            ispreSale2=true;
            ispreSale3=false;
            ispublicSale=false;
        }else if(step==3){
            ispreSale1=false;
            ispreSale2=false;
            ispreSale3=true;
            ispublicSale=false;
        }else if(step==4){
            ispreSale1=false;
            ispreSale2=false;
            ispreSale3=false;
            ispublicSale=true;
        }else{
            ispreSale1=false;
            ispreSale2=false;
            ispreSale3=false;
            ispublicSale=false;
        }
    }
    function setMutate(bool mutate) external onlyOwner{
        isMutate=mutate;
    }
    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function withdraw() public onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }
}